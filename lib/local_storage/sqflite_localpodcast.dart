import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../type/fireside_data.dart';
import '../type/podcastgroup.dart';
import '../util/extension_helper.dart';
import 'package:tuple/tuple.dart';

import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/podcastbrief.dart';
import '../type/sub_history.dart';
import 'key_value_storage.dart';

enum Filter { downloaded, liked, search, all }

enum SortOrder {
  asc(sql: "ASC"),
  desc(sql: "DESC");

  const SortOrder({required this.sql});

  final String sql;
}

enum Sorter {
  pubDate(sql: "E.milliseconds"),
  enclosureSize(sql: "E.enclosure_length"),
  enclosureDuration(sql: "E.duration"),
  downloadDate(sql: "E.download_date"),
  likedDate(sql: "E.liked_date"),
  random(sql: "RANDOM()");

  const Sorter({required this.sql});

  final String sql;
}

class DBHelper {
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    var documentsDirectory = await getDatabasesPath();
    var path = join(documentsDirectory, "podcasts.db");
    var theDb = await openDatabase(path,
        version: 9, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    await db
        .execute("""CREATE TABLE PodcastLocal(id TEXT PRIMARY KEY, title TEXT, 
        imageUrl TEXT, rssUrl TEXT UNIQUE, primaryColor TEXT, author TEXT, 
        description TEXT, add_date INTEGER, imagePath TEXT, provider TEXT, link TEXT, 
        background_image TEXT DEFAULT '', hosts TEXT DEFAULT '', update_count INTEGER DEFAULT 0,
        episode_count INTEGER DEFAULT 0, skip_seconds INTEGER DEFAULT 0, 
        auto_download INTEGER DEFAULT 0, skip_seconds_end INTEGER DEFAULT 0,
        never_update INTEGER DEFAULT 0, funding TEXT DEFAULT '[]', 
        hide_new_mark INTEGER DEFAULT 0, rss_hash TEXT DEFAULT '')""");
    await db.execute("""CREATE TABLE Groups(id TEXT PRIMARY KEY, name TEXT,
        color TEXT)""");
    await db.execute("""CREATE TABLE Podcast_Group(podcast_id TEXT REFERENCES
        PodcastLocal(id), group_id TEXT REFERENCES Groups(id),
        PRIMARY KEY (podcast_id, group_id))""");
    await db
        .execute("""CREATE TABLE Episodes(id INTEGER PRIMARY KEY,title TEXT, 
        enclosure_url TEXT UNIQUE, enclosure_length INTEGER, pubDate TEXT, 
        description TEXT, feed_id TEXT, feed_link TEXT, milliseconds INTEGER,
        duration INTEGER DEFAULT 0, explicit INTEGER DEFAULT 0,
        liked INTEGER DEFAULT 0, liked_date INTEGER DEFAULT 0, downloaded TEXT DEFAULT 'ND', 
        download_date INTEGER DEFAULT 0, media_id TEXT, is_new INTEGER DEFAULT 0, 
        chapter_link TEXT DEFAULT '', hosts TEXT DEFAULT '', episode_image TEXT DEFAULT '',
        number INTEGER DEFAULT -1, display_version_id INTEGER DEFAULT -1)""");
    await db.execute(
        """CREATE TABLE PlayHistory(id INTEGER PRIMARY KEY, title TEXT, enclosure_url TEXT,
        seconds REAL, seek_value REAL, add_date INTEGER, listen_time INTEGER DEFAULT 0)""");
    await db.execute(
        """CREATE TABLE SubscribeHistory(id TEXT PRIMARY KEY, title TEXT, rss_url TEXT UNIQUE, 
        add_date INTEGER, remove_date INTEGER DEFAULT 0, status INTEGER DEFAULT 0)""");
    await db
        .execute("CREATE INDEX podcast_search ON PodcastLocal (id, rssUrl);");
    await db.execute(
        "CREATE INDEX episode_search ON Episodes (enclosure_url, feed_id);");
    await db.execute(
        """CREATE TRIGGER episode_version_downloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded != 'ND' AND NEW.display_version_id != NEW.id) BEGIN
        UPDATE Episodes SET display_version_id = NEW.id
        WHERE (display_version_id = NEW.display_version_id AND (downloaded = 'ND' OR id = NEW.id));
        END
        """); // Change display version of undownloaded episodes to the newly downloaded version on episode download. Other downloaded versions remain as display versions.
    await db.execute(
        """CREATE TRIGGER episode_version_undownloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded = 'ND') BEGIN
        UPDATE Episodes SET display_version_id = (SELECT id FROM Episodes
        WHERE (feed_id = NEW.feed_id AND title = NEW.title AND display_version_id = id)
        ORDER BY download_date DESC LIMIT 1) WHERE display_version_id = NEW.display_version_id;
        END
        """); // Change display version of undownloaded episodes to the newest downloaded version (if exists) on episode download removal.
    await db.execute(
        "CREATE INDEX general_chronological ON Episodes (milliseconds ASC);");
    await db.execute(
        "CREATE INDEX home_display ON Episodes (display_version_id = id, milliseconds ASC);");
    await db.execute(
        "CREATE INDEX podcast_chronological ON Episodes (feed_id, milliseconds ASC);");
    await db.execute(
        "CREATE INDEX podcast_display ON Episodes (display_version_id = id, feed_id, milliseconds ASC);");

    await db.rawInsert("INSERT INTO Groups(id, name, color) VALUES(?, ?, ?)",
        [homeGroupId, 'Home', Colors.teal.toargbString()]);
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 7) await _v7Fix(db);
    for (int i = oldVersion; i < newVersion; i++) {
      await updaters[i](db);
    }
  }

  late List<Future<void> Function(Database db)> updaters = [
    (_) async {},
    _v2Update,
    _v3Update,
    _v4Update,
    _v5Update,
    _v6Update,
    _v7Update,
    _v8Update,
    _v9Update,
  ];

  Future<void> _v2Update(Database db) async {
    await db.execute(
        "ALTER TABLE PodcastLocal ADD skip_seconds INTEGER DEFAULT 0 ");
  }

  Future<void> _v3Update(Database db) async {
    await db.execute(
        "ALTER TABLE PodcastLocal ADD auto_download INTEGER DEFAULT 0");
  }

  Future<void> _v4Update(Database db) async {
    await db.execute(
        "ALTER TABLE PodcastLocal ADD skip_seconds_end INTEGER DEFAULT 0 ");
    await db.execute(
        "ALTER TABLE PodcastLocal ADD never_update INTEGER DEFAULT 0 ");
  }

  Future<void> _v5Update(Database db) async {
    await db.execute("ALTER TABLE PodcastLocal ADD funding TEXT DEFAULT '[]' ");
  }

  Future<void> _v6Update(Database db) async {
    await db.execute("ALTER TABLE Episodes ADD chapter_link TEXT DEFAULT '' ");
    await db.execute("ALTER TABLE Episodes ADD hosts TEXT DEFAULT '' ");
    await db.execute("ALTER TABLE Episodes ADD episode_image TEXT DEFAULT '' ");
    await db
        .execute("""CREATE INDEX  podcast_search ON PodcastLocal (id, rssUrl)
    """);
    await db.execute(
        """CREATE INDEX  episode_search ON Episodes (enclosure_url, feed_id)
    """);
  }

  Future<void> _v7Update(Database db) async {
    await db.execute(
        "ALTER TABLE PodcastLocal ADD hide_new_mark INTEGER DEFAULT 0");
  }

  Future<void> _v7Fix(Database db) async {
    try {
      await db.rawQuery("SELECT hide_new_mark FROM PodcastLocal");
    } catch (e) {
      await db.execute(
          "ALTER TABLE PodcastLocal ADD hide_new_mark INTEGER DEFAULT 0");
    }
  }

  Future<void> _v8Update(Database db) async {
    await db.execute("ALTER TABLE Episodes ADD number INTEGER DEFAULT -1");
    await db.execute(
        "ALTER TABLE Episodes ADD display_version_id INTEGER DEFAULT -1");
    await db.execute(
        """CREATE TRIGGER episode_number_trigger AFTER INSERT ON Episodes
        WHEN (NEW.number = -1) BEGIN
        UPDATE Episodes SET number = 1 + IFNULL((SELECT MAX(number) FROM Episodes
        WHERE feed_id = NEW.feed_id), 0) WHERE id = NEW.id;
        END
        """); // New episode gets the highest number
    await db.execute(
        """CREATE TRIGGER episode_version_trigger AFTER INSERT ON Episodes 
        WHEN (NEW.display_version_id = -1) BEGIN
        UPDATE Episodes SET display_version_id = IFNULL(IFNULL((SELECT display_version_id FROM Episodes
        WHERE (feed_id = NEW.feed_id AND title = NEW.title AND downloaded = 'ND' AND NEW.id != id)
        LIMIT 1), (SELECT display_version_id FROM Episodes WHERE
        (feed_id = NEW.feed_id AND title = NEW.title AND NEW.id != id)
        ORDER BY download_date DESC LIMIT 1)), NEW.id) WHERE id = NEW.id;
        END
        """); // Preserve existing display version(s) on new version insertion.
    await db.execute(
        """CREATE TRIGGER episode_version_downloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded != 'ND' AND NEW.display_version_id != NEW.id) BEGIN
        UPDATE Episodes SET display_version_id = NEW.id
        WHERE (display_version_id = NEW.display_version_id AND (downloaded = 'ND' OR id = NEW.id));
        END
        """); // Change display version of undownloaded episodes to the newly downloaded version on episode download. Other downloaded versions remain as display versions.
    await db.execute(
        """CREATE TRIGGER episode_version_undownloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded = 'ND') BEGIN
        UPDATE Episodes SET display_version_id = (SELECT id FROM Episodes
        WHERE (feed_id = NEW.feed_id AND title = NEW.title AND display_version_id = id)
        ORDER BY download_date DESC LIMIT 1) WHERE display_version_id = NEW.display_version_id;
        END
        """); // Change display version of undownloaded episodes to the newest downloaded version (if exists) on episode download removal.
    List<Map> podcasts = await db.rawQuery("SELECT id FROM PodcastLocal");
    List<Future> futures = [];
    for (var podcast in podcasts) {
      futures.add(rescanPodcastEpisodesVersions(db, podcast['id']));
    }
    await Future.wait(futures);
    futures.clear();
    for (var podcast in podcasts) {
      futures.add(renumberPodcastEpisodes(db, podcast['id']));
    }
    await Future.wait(futures);
  }

  Future<void> _v9Update(Database db) async {
    await db.execute("""CREATE TABLE Groups(id TEXT PRIMARY KEY, name TEXT,
        color TEXT)""");
    await db.execute("""CREATE TABLE Podcast_Group(podcast_id TEXT REFERENCES
        PodcastLocal(id), group_id TEXT REFERENCES Groups(id),
        PRIMARY KEY (podcast_id, group_id))""");
    final KeyValueStorage groupStorage = KeyValueStorage(groupsKey);
    final groups = await groupStorage.getGroups();
    for (var group in groups) {
      final groupId = group.name == "Home" ? homeGroupId : group.id;
      await db.rawInsert("INSERT INTO Groups(id, name, color) VALUES (?, ?, ?)",
          [groupId, group.name, group.color.toargbString()]);
      for (var podcastId in group.podcastIds) {
        await db.rawInsert(
            "INSERT INTO Podcast_Group(podcast_id, group_id) VALUES (?, ?)",
            [podcastId, groupId]);
      }
    }
    final podcasts =
        await db.rawQuery("SELECT id, primaryColor FROM PodcastLocal");
    for (var podcast in podcasts) {
      final newColor =
          (podcast['primaryColor'] as String).toJsonColor().toargbString();
      await db.rawUpdate(
          "UPDATE PodcastLocal SET primaryColor = ? WHERE id = ?",
          [newColor, podcast['id']]);
    }
    await db.execute("ALTER TABLE PodcastLocal ADD rss_hash TEXT DEFAULT ''");
    final episodes =
        await db.rawQuery("""SELECT id, description FROM Episodes""");
    for (var episode in episodes) {
      final newDescription =
          EpisodeBrief.linkifyShownotes(episode['description'] as String);
      await db.rawUpdate("UPDATE Episodes SET description = ? WHERE id = ?",
          [newDescription, episode['id']]);
    }
    await db.execute(
        "CREATE INDEX general_chronological ON Episodes (milliseconds ASC);");
    await db.execute(
        "CREATE INDEX home_display ON Episodes (display_version_id = id, milliseconds ASC);");
    await db.execute(
        "CREATE INDEX podcast_chronological ON Episodes (feed_id, milliseconds ASC);");
    await db.execute(
        "CREATE INDEX podcast_display ON Episodes (display_version_id = id, feed_id, milliseconds ASC);");
    await db.execute("DROP TRIGGER IF EXISTS episode_number_trigger;");
    await db.execute("DROP TRIGGER IF EXISTS episode_version_trigger;");
  }

  /// Queries the database with the provided options and returns found podcasts.
  /// Filters are tri-state (null - no filter, true - only, false - exclude)
  /// Don't use directly, use [PodcastState].getPodcasts instad.
  Future<List<PodcastBrief>> getPodcasts(
      {List<String>? groupIds,
      List<String>? podcastIds,
      List<String>? rssUrls,
      bool? filterNoAutoSync}) async {
    List<String> query = [
      """SELECT P.id, P.title, P.rssUrl, P.author, P.provider, P.hosts, P.description, P.link, P.funding,
      P.imageUrl, P.imagePath, P.background_image, P.primaryColor, P.update_count, P.episode_count,
      P.hide_new_mark, P.never_update, P.auto_download, P.skip_seconds, P.skip_seconds_end, P.rss_hash
      FROM PodcastLocal P"""
    ];
    List<String> filters = [];
    List arguments = [];
    if (groupIds != null && groupIds.isNotEmpty) {
      query.add(" LEFT JOIN Podcast_Group PD ON P.id = PD.podcast_id");
      filters
          .add(" PD.group_id IN (${(", ?" * groupIds.length).substring(2)})");
      arguments.addAll(groupIds);
    }
    if (podcastIds != null && podcastIds.isNotEmpty) {
      filters.add(" P.id IN (${(", ?" * podcastIds.length).substring(2)})");
      arguments.addAll(podcastIds);
    }
    if (rssUrls != null && rssUrls.isNotEmpty) {
      filters.add(" P.rssUrl IN (${(", ?" * rssUrls.length).substring(2)})");
      arguments.addAll(rssUrls);
    }
    if (filterNoAutoSync == false) {
      filters.add(" P.never_update = 0");
    } else if (filterNoAutoSync == true) {
      filters.add(" P.never_update = 1");
    }
    if (filters.isNotEmpty) {
      query.add(" WHERE");
      query.add(filters.join(" AND"));
    }

    var dbClient = await database;
    List<PodcastBrief> podcasts = [];
    List<Map> result;
    result = await dbClient.rawQuery(query.join(), arguments);
    if (result.isNotEmpty) {
      for (var item in result) {
        PodcastBrief podcast = PodcastBrief(
            id: item['id'],
            title: item['title'],
            rssUrl: item['rssUrl'],
            rssHash: item['rss_hash'],
            author: item['author'],
            provider: item['provider'],
            firesideHosts: item['hosts'] != ""
                ? json
                    .decode(item['hosts'])['hosts']
                    .cast<Map<String, Object>>()
                    .map<PodcastHost>(PodcastHost.fromJson)
                    .toList()
                : [],
            description: item['description'],
            webpage: item['link'],
            funding: List<String>.from(jsonDecode(item['funding'])),
            imageUrl: item['imageUrl'],
            imagePath: item['imagePath'],
            firesideBackgroundImage: item['background_image'],
            primaryColor: (item['primaryColor'] as String).toargbColor(),
            syncEpisodeCount: item['update_count'],
            episodeCount: item['episode_count'],
            hideNewMark: item['hide_new_mark'] == 1,
            noAutoSync: item['never_update'] == 1,
            autoDownload: item['auto_download'] == 1,
            skipSecondsStart: item['skip_seconds'],
            skipSecondsEnd: item['skip_seconds_end'],
            source: DataSource.database);
        podcasts.add(podcast);
      }
    }
    return podcasts;
  }

  Future<void> savePodcastProperties(
    List<String> ids, {
    bool? hideNewMark,
    bool? noAutoSync,
    bool? autoDownload,
    int? skipSecondsStart,
    int? skipSecondsEnd,
  }) async {
    bool go = false;
    var dbClient = await database;
    List<String> update = ["UPDATE PodcastLocal SET"];
    List<String> changes = [];
    List arguements = [];
    if (hideNewMark == false) {
      go = true;
      changes.add(" hide_new_mark = 0");
    } else if (hideNewMark == true) {
      go = true;
      changes.add(" hide_new_mark = 1");
    }
    if (noAutoSync == false) {
      go = true;
      changes.add(" never_update = 0");
    } else if (noAutoSync == true) {
      go = true;
      changes.add(" never_update = 1");
    }
    if (autoDownload == false) {
      go = true;
      changes.add(" auto_download = 0");
    } else if (autoDownload == true) {
      go = true;
      changes.add(" auto_download = 1");
    }
    if (skipSecondsStart != null) {
      go = true;
      changes.add(" skip_seconds = ?");
      arguements.add(skipSecondsStart);
    }
    if (skipSecondsEnd != null) {
      go = true;
      changes.add(" skip_seconds_end = ?");
      arguements.add(skipSecondsStart);
    }
    if (go) {
      update.add(changes.join(", "));
      update.add(" WHERE id IN (${(", ?" * ids.length).substring(2)})");
      await dbClient.rawUpdate(update.join(), [...arguements, ...ids]);
    }
  }

  Future<String?> checkPodcast(String? url) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT id FROM PodcastLocal WHERE rssUrl = ?', [url]);
    if (list.isEmpty) return null;
    return list.first['id'];
  }

  Future<void> savePodcastLocal(PodcastBrief podcastLocal) async {
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawInsert(
          """INSERT OR REPLACE INTO PodcastLocal (id, title, imageUrl, rssUrl, 
          primaryColor, author, description, add_date, imagePath, provider, link, funding) 
          VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
          [
            podcastLocal.id,
            podcastLocal.title,
            podcastLocal.imageUrl,
            podcastLocal.rssUrl,
            podcastLocal.primaryColor.toargbString(),
            podcastLocal.author,
            podcastLocal.description,
            milliseconds,
            podcastLocal.imagePath,
            podcastLocal.provider,
            podcastLocal.webpage,
            jsonEncode(podcastLocal.funding)
          ]);
      if (podcastLocal.id != localFolderId) {
        await txn.rawInsert(
            """REPLACE INTO SubscribeHistory(id, title, rss_url, add_date) VALUES (?, ?, ?, ?)""",
            [
              podcastLocal.id,
              podcastLocal.title,
              podcastLocal.rssUrl,
              milliseconds
            ]);
      }
    });
  }

  Future<List<PodcastGroup>> getGroups() async {
    var dbClient = await database;
    List<Map> result;
    result = await dbClient.rawQuery("SELECT id, name, color FROM Groups");
    final List<PodcastGroup> groups = [];
    if (result.isNotEmpty) {
      for (var item in result) {
        final podcastResults = await dbClient.rawQuery(
            "SELECT podcast_id FROM Podcast_Group WHERE group_id = ?",
            [item['id']]);
        final podcasts =
            podcastResults.map((item) => item['podcast_id'] as String).toList();
        final group = PodcastGroup(
            id: item['id'],
            name: item['name'],
            color: (item['color'] as String).toargbColor(),
            podcastIds: podcasts);
        groups.add(group);
      }
    }
    return groups;
  }

  Future<void> addGroup(PodcastGroup podcastGroup) async {
    var dbClient = await database;
    await dbClient.rawInsert(
        "INSERT OR REPLACE INTO Groups(id, name, color) VALUES(?, ?, ?)", [
      podcastGroup.id,
      podcastGroup.name,
      podcastGroup.color.toargbString()
    ]);
  }

  Future<void> removeGroup(String groupId) async {
    var dbClient = await database;
    await dbClient
        .rawDelete("DELETE FROM PodcastLocal WHERE id = ?", [groupId]);
  }

  Future<void> addPodcastToGroup(
      {required String podcastId, required String groupId}) async {
    var dbClient = await database;
    await dbClient.rawInsert(
        "INSERT OR IGNORE INTO Podcast_Group(podcast_id, group_id) VALUES (?, ?)",
        [podcastId, groupId]);
  }

  Future<void> removePodcastFromGroup(
      {required String podcastId, required String groupId}) async {
    var dbClient = await database;
    await dbClient.rawDelete(
        "DELETE FROM Podcast_Group WHERE podcast_id = ? AND group_id = ?",
        [podcastId, groupId]);
  }

  Future<int> saveFiresideData(List<String?> list) async {
    var dbClient = await database;
    var result = await dbClient.rawUpdate(
        'UPDATE PodcastLocal SET background_image = ? , hosts = ? WHERE id = ?',
        [list[1], list[2], list[0]]);
    return result;
  }

  Future<void> delPodcast(String? id) async {
    var dbClient = await database;
    await dbClient.rawDelete('DELETE FROM PodcastLocal WHERE id = ?', [id]);
    await dbClient
        .rawDelete('DELETE FROM Podcast_Group WHERE podcast_id = ?', [id]);
    await dbClient.rawDelete('DELETE FROM Episodes WHERE feed_id=?', [id]);
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    await dbClient.rawUpdate(
        """UPDATE SubscribeHistory SET remove_date = ? , status = ? WHERE id = ?""",
        [milliseconds, 1, id]);
  }

  Future<void> saveHistory(PlayHistory history) async {
    if (history.url!.substring(0, 7) != 'file://') {
      var dbClient = await database;
      final milliseconds = DateTime.now().millisecondsSinceEpoch;
      var recent = await getPlayHistory(1);
      if (recent.isNotEmpty && recent.first.url == history.url) {
        await dbClient.rawDelete("DELETE FROM PlayHistory WHERE add_date = ?",
            [recent.first.playdate!.millisecondsSinceEpoch]);
      }
      await dbClient.transaction((txn) async {
        return await txn.rawInsert(
            """INSERT INTO PlayHistory (title, enclosure_url, seconds, seek_value, add_date, listen_time)
       VALUES (?, ?, ?, ?, ?, ?) """,
            [
              history.title,
              history.url,
              history.seconds,
              history.seekValue,
              milliseconds,
              history.seekValue! > 0.95 ? 1 : 0
            ]);
      });
    }
  }

  Future<List<PlayHistory>> getPlayHistory(int top) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT title, enclosure_url, seconds, seek_value, add_date FROM PlayHistory
         ORDER BY add_date DESC LIMIT ?
     """, [top]);
    var playHistory = <PlayHistory>[];
    for (var record in list) {
      playHistory.add(PlayHistory(record['title'], record['enclosure_url'],
          (record['seconds']).toInt(), record['seek_value'],
          playdate: DateTime.fromMillisecondsSinceEpoch(record['add_date'])));
    }
    return playHistory;
  }

  /// History list in playlist page, not include marked episdoes.
  Future<List<PlayHistory>> getPlayRecords(int? top) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT title, enclosure_url, seconds, seek_value, add_date FROM PlayHistory 
        WHERE seconds != 0 ORDER BY add_date DESC LIMIT ?
     """, [top]);
    var playHistory = <PlayHistory>[];
    for (var record in list) {
      playHistory.add(PlayHistory(record['title'], record['enclosure_url'],
          (record['seconds']).toInt(), record['seek_value'],
          playdate: DateTime.fromMillisecondsSinceEpoch(record['add_date'])));
    }
    return playHistory;
  }

  /// Sets the episodes as not listened
  Future<int?> unsetListened(List<String> urls) async {
    var dbClient = await database;
    int? count = await dbClient.rawUpdate(
        "UPDATE OR IGNORE PlayHistory SET listen_time = 0 WHERE enclosure_url IN (${(", ?" * urls.length).substring(2)})",
        urls);
    await dbClient.rawDelete(
        'DELETE FROM PlayHistory WHERE enclosure_url in (${(", ?" * urls.length).substring(2)}) '
        'AND listen_time = 0 AND seconds = 0',
        urls);
    return count;
  }

  Future<List<SubHistory>> getSubHistory() async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT title, rss_url, add_date, remove_date, status FROM SubscribeHistory
      ORDER BY add_date DESC""");
    return list
        .map((record) => SubHistory(
              DateTime.fromMillisecondsSinceEpoch(record['remove_date']),
              DateTime.fromMillisecondsSinceEpoch(record['add_date']),
              record['rss_url'],
              record['title'],
              status: record['status'] == 0 ? true : false,
            ))
        .toList();
  }

  Future<double> listenMins(int day) async {
    var dbClient = await database;
    var now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: day))
        .millisecondsSinceEpoch;
    var end = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (day - 1)))
        .millisecondsSinceEpoch;
    List<Map> list = await dbClient.rawQuery(
        "SELECT seconds FROM PlayHistory WHERE add_date > ? AND add_date < ?",
        [start, end]);
    var sum = 0.0;
    if (list.isEmpty) {
      sum = 0.0;
    } else {
      for (var record in list) {
        sum += record['seconds'];
      }
    }
    return (sum ~/ 60).toDouble();
  }

  Future<PlayHistory> getPosition(EpisodeBrief episodeBrief) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT title, enclosure_url, seconds, seek_value, add_date FROM PlayHistory 
        WHERE enclosure_url = ? ORDER BY add_date DESC LIMIT 1""",
        [episodeBrief.enclosureUrl]);
    return list.isNotEmpty
        ? PlayHistory(list.first['title'], list.first['enclosure_url'],
            (list.first['seconds']).toInt(), list.first['seek_value'],
            playdate:
                DateTime.fromMillisecondsSinceEpoch(list.first['add_date']))
        : PlayHistory(episodeBrief.title, episodeBrief.enclosureUrl, 0, 0);
  }

  /// Check if episode was marked listend.
  Future<bool> checkMarked(EpisodeBrief episodeBrief) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT title, enclosure_url, seconds, seek_value, add_date FROM PlayHistory 
        WHERE enclosure_url = ? AND seek_value = 1 ORDER BY add_date DESC LIMIT 1""",
        [episodeBrief.enclosureUrl]);
    return list.isNotEmpty;
  }

  int _getExplicit(bool? b) {
    int result;
    if (b == true) {
      result = 1;
      return result;
    } else {
      result = 0;
      return result;
    }
  }

  /// Assigns each episode in a podcast numbers based on its publish date
  Future<void> renumberPodcastEpisodes(
      DatabaseExecutor dbClient, String feedId) async {
    List<Map> episodes = await dbClient.rawQuery(
        "SELECT id, number FROM Episodes WHERE feed_id = ? ORDER BY milliseconds ASC",
        [feedId]);
    Batch batchOp = dbClient.batch();
    for (int i = 0; i < episodes.length; i++) {
      Map episode = episodes[i];
      if (i + 1 != episode['number']) {
        batchOp.rawUpdate("UPDATE Episodes SET number = ? WHERE id = ?",
            [i + 1, episode['id']]);
      }
    }
    await batchOp.commit(noResult: true);
  }

  /// Reinitializes display_version_id of Episodes.
  /// Versions are episodes with different enclosure_urls but same titles and feed_ids
  /// Display versions are the versions of an episode that should be displayed by default in ui
  /// Downloaded episodes are always their own display versions.
  /// Non downloaded episodes' display versions point to (first available)
  /// a) Manually set version / newsest downloaded version (whichever is newer)
  /// b) The version all other undownloaded versions point to (newest on rescan)
  /// c) Itself
  Future<void> rescanPodcastEpisodesVersions(
      DatabaseExecutor dbClient, String feedId) async {
    List<Map<String, dynamic>> episodes = (await dbClient.rawQuery(
            "SELECT id, title, milliseconds, downloaded FROM Episodes WHERE feed_id = ?",
            [feedId]))
        .toList();
    episodes.sort((a, b) => b['milliseconds'] - a['milliseconds']);
    Map<String, Tuple3<int, bool, List<int>>> titles = {};
    for (var episode in episodes) {
      Tuple3<int, bool, List<int>> result;
      if (titles[episode['title']] == null) {
        result = Tuple3(
            episode['id'], episode['downloaded'] != 'ND', [episode['id']]);
      } else {
        result = titles[episode['title']]!;
        if (!result.item2 && episode['downloaded'] != 'ND') {
          result = Tuple3(episode['id'], true, [episode['id']]);
        } else {
          result.item3.add(episode['id']);
        }
      }
      titles[episode['title']] = result;
    }
    Batch batchOp = dbClient.batch();
    for (var title in titles.keys) {
      Tuple3<int, bool, List<int>> result = titles[title]!;
      for (var id in result.item3) {
        batchOp.rawInsert(
            "UPDATE Episodes SET display_version_id = ? WHERE id = ?",
            [result.item1, id]);
      }
    }
    await batchOp.commit();
  }

  /// Sets the episode as the display version among its undownloaded versions.
  /// Display version might still change afterwards according to usual display version rules.
  Future<void> setDisplayVersion(EpisodeBrief episode,
      {bool reset = false}) async {
    var dbClient = await database;
    await dbClient.rawUpdate("""UPDATE Episodes SET display_version_id = ?
        WHERE (feed_id = ? AND downloaded = 'ND' AND title = ?)""",
        [episode.id, episode.podcastId, episode.title]);
  }

  /// Populates the EpisodeBrief.versions set with ids of episode versions.
  /// Returns the set of EpisodeBriefs of the episode versions.
  /// Doesn't populate if it is not null unless [force] is set.
  Future<List<EpisodeBrief>> populateReturnVersions(EpisodeBrief episode,
      {bool force = false}) async {
    var dbClient = await database;
    if (episode.versions != null && !force) return [episode];
    List<Map> results = await dbClient
        .rawQuery("""SELECT id FROM Episodes WHERE (feed_id = ? AND title = ?)
        ORDER BY milliseconds DESC""", [episode.podcastId, episode.title]);
    if (results.length == 1) {
      episode.copyWith(versions: [episode.id]);
      return [episode];
    }
    List<int> versionIds = results.map<int>((result) => result['id']).toList();
    List<EpisodeBrief> versions = await getEpisodes(episodeIds: versionIds);
    versions = versions.map((e) => e.copyWith(versions: [])).toList();
    for (EpisodeBrief version1 in versions) {
      for (EpisodeBrief version2 in versions) {
        version1.versions!.add(version2.id);
      }
    }
    return versions;
  }

  /// Saves episodes to the database. It is assumed that all episodes belong to
  /// the same podcast. Set [update] for existing feeds.
  Future<void> _savePodcastEpisodes(
      Transaction txn, List<EpisodeBrief> episodes,
      {bool update = true}) async {
    final hideNew = Sqflite.firstIntValue(await txn.rawQuery(
        'SELECT hide_new_mark FROM PodcastLocal WHERE id = ?',
        [episodes.first.podcastId]));
    final newMark = update && hideNew == 0;
    Batch batchOp = txn.batch();
    for (var episode in episodes) {
      batchOp.rawInsert(
          """INSERT OR REPLACE INTO Episodes(title, enclosure_url, enclosure_length,
              pubDate, description, feed_id, milliseconds, duration, explicit, media_id,
              chapter_link, episode_image, number, display_version_id, is_new)
              VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
          [
            episode.title,
            episode.enclosureUrl,
            episode.enclosureSize,
            '',
            episode.showNotes,
            episode.podcastId,
            episode.pubDate,
            episode.enclosureDuration,
            _getExplicit(episode.isExplicit),
            episode.enclosureUrl,
            episode.chapterLink,
            episode.episodeImageUrl,
            update ? -1 : episode.number,
            update ? -1 : 0,
            newMark ? 1 : 0
          ]);
    }
    await batchOp.commit();
    final feedId = episodes.first.podcastId;
    await renumberPodcastEpisodes(txn, feedId);
    await rescanPodcastEpisodesVersions(txn, feedId);
    int? count = Sqflite.firstIntValue(await txn
        .rawQuery('SELECT COUNT(*) FROM Episodes WHERE feed_id = ?', [feedId]));
    await txn.rawUpdate(
        """UPDATE PodcastLocal SET episode_count = ? WHERE id = ?""",
        [count ?? 0, feedId]);
  }

  Future<void> saveNewPodcastEpisodes(List<EpisodeBrief> episodes) async {
    var dbClient = await database;
    await dbClient.transaction<void>((txn) async {
      await _savePodcastEpisodes(txn, episodes, update: false);
      await rescanPodcastEpisodesVersions(txn, episodes.first.podcastId);
    });
  }

  Future<void> saveUpdatedPodcastEpisodes(List<EpisodeBrief> episodes) async {
    var dbClient = await database;
    await dbClient.transaction<void>((txn) async {
      await _savePodcastEpisodes(txn, episodes, update: true);
    });
  }

  Future<void> unmarkNewOldEpisodes(String podcastId) async {
    var dbClient = await database;
    await dbClient.rawUpdate(
        "UPDATE Episodes SET is_new = 0 WHERE feed_id = ? AND milliseconds < ?",
        [
          podcastId,
          DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch
        ]);
  }

  Future<int> saveLocalEpisode(EpisodeBrief episode) async {
    assert(false, "Don't use this");
    var dbClient = await database;
    int episodeId = await dbClient.rawInsert(
        """INSERT OR REPLACE INTO Episodes(title, enclosure_url, enclosure_length, pubDate, 
                description, feed_id, milliseconds, duration, explicit, media_id, episode_image) 
                VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        [
          episode.title,
          episode.enclosureUrl,
          episode.enclosureSize,
          '',
          '',
          localFolderId,
          episode.pubDate,
          episode.enclosureDuration,
          0,
          episode.enclosureUrl,
          episode.episodeImageUrl
        ]);
    return episodeId;
  }

  Future<void> deleteLocalEpisodes(List<int> ids,
      {String podcastId = localFolderId}) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      Batch batchOp = txn.batch();
      for (var id in ids) {
        batchOp.rawDelete('DELETE FROM Episodes WHERE id = ? AND feed_id = ?',
            [id, podcastId]);
      }
      await batchOp.commit();
    });
  }

  /// Queries the database with the provided options and returns found episodes.
  /// Filters are tri-state (null - no filter, true - only, false - exclude)
  Future<List<EpisodeBrief>> getEpisodes(
      // TODO: Optimize the query via indexes and intersects
      {List<String>? feedIds,
      List<String>? excludedFeedIds,
      List<int>? episodeIds,
      List<int>? excludedEpisodeIds,
      List<String>? episodeUrls,
      List<String>? excludedEpisodeUrls,
      List<String>? episodeTitles,
      List<String>? excludedEpisodeTitles,
      List<String>? likeEpisodeTitles,
      List<String>? excludedLikeEpisodeTitles,
      Sorter? sortBy,
      SortOrder sortOrder = SortOrder.desc,
      List<Sorter>? rangeParameters,
      List<(int, int)>? rangeDelimiters,
      int limit = -1,
      int offset = -1,
      bool? filterNew,
      bool? filterLiked,
      bool? filterPlayed,
      bool? filterDownloaded,
      bool? filterDuplicateVersions,
      bool? filterAutoDownload,
      List<String>? customFilters,
      List<String>? customArguements}) async {
    List<String> query = [
      """SELECT E.id, E.title, E.enclosure_url, E.feed_id, P.title as feed_title,
      E.milliseconds, E.description, E.number, E.duration, E.enclosure_length,
      E.downloaded, E.download_date, E.media_id, E.episode_image, P.imagePath,
      P.primaryColor, E.explicit, E.chapter_link, SUM(H.listen_time) as play_time,
      E.is_new, E.display_version_id, P.skip_seconds, P.skip_seconds_end, E.liked"""
    ];
    List<String> filters = [];
    List arguements = [];
    query.add(" FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id");
    query.add(" LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url");

    if (feedIds != null && feedIds.isNotEmpty) {
      filters.add(" P.id IN (${(", ?" * feedIds.length).substring(2)})");
      arguements.addAll(feedIds);
    }
    if (excludedFeedIds != null && excludedFeedIds.isNotEmpty) {
      filters.add(
          " P.id NOT IN (${(", ?" * excludedFeedIds.length).substring(2)})");
      arguements.addAll(excludedFeedIds);
    }
    if (episodeIds != null && episodeIds.isNotEmpty) {
      filters.add(" E.id IN (${(", ?" * episodeIds.length).substring(2)})");
      arguements.addAll(episodeIds);
    }
    if (excludedEpisodeIds != null && excludedEpisodeIds.isNotEmpty) {
      filters.add(
          " E.id NOT IN (${(", ?" * excludedEpisodeIds.length).substring(2)})");
      arguements.addAll(excludedEpisodeIds);
    }
    if (episodeUrls != null && episodeUrls.isNotEmpty) {
      filters.add(
          " E.enclosure_url IN (${(", ?" * episodeUrls.length).substring(2)})");
      arguements.addAll(episodeUrls);
    }
    if (excludedEpisodeUrls != null && excludedEpisodeUrls.isNotEmpty) {
      filters.add(
          " E.enclosure_url NOT IN (${(", ?" * excludedEpisodeUrls.length).substring(2)})");
      arguements.addAll(excludedEpisodeUrls);
    }
    if (episodeTitles != null && episodeTitles.isNotEmpty) {
      filters
          .add(" E.title IN (${(", ?" * episodeTitles.length).substring(2)})");
      arguements.addAll(episodeTitles);
    }
    if (excludedEpisodeTitles != null && excludedEpisodeTitles.isNotEmpty) {
      filters.add(
          " E.title NOT IN (${(", ?" * excludedEpisodeTitles.length).substring(2)})");
      arguements.addAll(excludedEpisodeTitles);
    }
    if (likeEpisodeTitles != null && likeEpisodeTitles.isNotEmpty) {
      filters.add(
          " (${(" OR E.title LIKE ?" * likeEpisodeTitles.length).substring(4)})");
      arguements.addAll(likeEpisodeTitles.map(
        (e) => "%$e%",
      ));
    }
    if (excludedLikeEpisodeTitles != null &&
        excludedLikeEpisodeTitles.isNotEmpty) {
      filters.add(
          " (${(" OR E.title LIKE ?" * excludedLikeEpisodeTitles.length).substring(4)})");
      arguements.addAll(excludedLikeEpisodeTitles.map(
        (e) => "%$e%",
      ));
    }
    if (filterNew == false) {
      filters.add(" E.is_new = 0");
    } else if (filterNew == true) {
      filters.add(" E.is_new = 1");
    }
    if (filterLiked == false) {
      filters.add(" E.liked = 0");
    } else if (filterLiked == true) {
      filters.add(" E.liked = 1");
    }
    if (filterDownloaded == false) {
      filters.add(" E.downloaded = 'ND'");
    } else if (filterDownloaded == true) {
      filters.add(" E.downloaded != 'ND'");
    }
    if (filterDuplicateVersions == false) {
      filters.add(" E.display_version_id = E.id");
    } else if (filterDuplicateVersions == true) {
      filters.add(" E.display_version_id != E.id");
    }
    if (filterAutoDownload == false) {
      filters.add(" P.auto_download = 0");
    } else if (filterAutoDownload == true) {
      filters.add(" P.auto_download = 1");
    }
    if (rangeParameters != null &&
        rangeParameters.isNotEmpty &&
        rangeDelimiters != null &&
        rangeParameters.length == rangeDelimiters.length &&
        !rangeParameters.contains(Sorter.random)) {
      for (int i = 0; i < rangeParameters.length; i++) {
        if (rangeDelimiters[i].$1 != -1 && rangeDelimiters[i].$2 != -1) {
          filters.add(
              " ${rangeParameters[i].sql} BETWEEN ${rangeDelimiters[i].$1} AND ${rangeDelimiters[i].$2}");
        } else if (rangeDelimiters[i].$1 != -1) {
          filters.add(" ${rangeParameters[i].sql} > ${rangeDelimiters[i].$1}");
        } else if (rangeDelimiters[i].$2 != -1) {
          filters.add(" ${rangeParameters[i].sql} < ${rangeDelimiters[i].$2}");
        }
      }
    }
    if (customFilters != null && customFilters.isNotEmpty) {
      for (var filter in customFilters) {
        filters.add(" $filter");
      }
      if (customArguements != null && customFilters.isNotEmpty) {
        arguements.addAll(customArguements);
      }
    }
    if (filters.isNotEmpty) {
      query.add(" WHERE");
    }
    query.add(filters.join(" AND"));
    query.add(" GROUP BY E.enclosure_url");
    if (filterPlayed == false) {
      query.add(" HAVING SUM(H.listen_time) IS Null OR SUM(H.listen_time) = 0");
    } else if (filterPlayed == true) {
      query.add(" HAVING SUM(H.listen_time) > 0");
    }
    if (sortBy != null) {
      if (sortBy == Sorter.random) {
        query.add(" ORDER BY ${sortBy.sql}");
      } else {
        query.add(" ORDER BY ${sortBy.sql} ${sortOrder.sql}");
      }
    }
    if (limit != -1) {
      query.add(" LIMIT ${limit.toString()}");
      if (offset != -1) {
        query.add(" OFFSET ${offset.toString()}");
      }
    }

    var dbClient = await database;
    List<EpisodeBrief> episodes = [];
    List<Map> result;
    result = await dbClient.rawQuery(query.join(), arguements);
    if (result.isNotEmpty) {
      for (var i in result) {
        EpisodeBrief episode = EpisodeBrief(
          id: i['id'],
          title: i['title'],
          enclosureUrl: i['enclosure_url'],
          podcastId: i['feed_id'],
          podcastTitle: i['feed_title'],
          pubDate: i['milliseconds'],
          showNotes:
              parse(parse(i['description']).body!.text).documentElement!.text,
          number: i['number'],
          enclosureDuration: i['duration'],
          enclosureSize: i['enclosure_length'],
          isDownloaded: i['downloaded'] != 'ND',
          downloadDate: i['download_date'],
          mediaId: i['media_id'],
          episodeImageUrl: i['episode_image'],
          podcastImagePath: i['imagePath'],
          primaryColor: (i['primaryColor'] as String).toargbColor(),
          isExplicit: i['explicit'] == 1,
          isLiked: i['liked'] == 1,
          isNew: i['is_new'] == 1,
          isPlayed: i['play_time'] != null && i['play_time'] != 0,
          isDisplayVersion: i['display_version_id'] == i['id'],
          versions: null,
          skipSecondsStart: i['skip_seconds'],
          skipSecondsEnd: i['skip_seconds_end'],
          chapterLink: i['chapter_link'],
          source: DataSource.database,
        );
        episodes.add(episode);
      }
    }
    return episodes;
  }

  Future<void> removeAllNewMark() async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate("UPDATE Episodes SET is_new = 0 ");
    });
  }

  Future<void> removeGroupNewMark(List<String?> group) async {
    var dbClient = await database;
    if (group.isNotEmpty) {
      var s = group.map<String>((e) => "'$e'").toList();
      await dbClient.transaction((txn) async {
        await txn.rawUpdate(
            "UPDATE Episodes SET is_new = 0 WHERE feed_id in (${s.join(',')})");
      });
    }
  }

  Future<void> removeEpisodesNewMark(List<int> ids) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET is_new = 0 WHERE id IN (${(", ?" * ids.length).substring(2)})",
          [...ids]);
    });
  }

  Future setLiked(List<int> ids) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    await dbClient.rawUpdate(
        "UPDATE Episodes SET liked = 1, liked_date = ? WHERE id IN (${(", ?" * ids.length).substring(2)})",
        [milliseconds, ...ids]);
  }

  Future setUnliked(List<int> ids) async {
    var dbClient = await database;
    await dbClient.rawUpdate(
        "UPDATE Episodes SET liked = 0 WHERE id IN (${(", ?" * ids.length).substring(2)})",
        [...ids]);
  }

  Future<bool> isDownloaded(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        "SELECT id FROM Episodes WHERE enclosure_url = ? AND enclosure_url != media_id",
        [url]);
    return list.isNotEmpty;
  }

  /// Sets the episode as downloaded and saves its mediaId, download task id
  /// size and duration
  Future<void> setDownloaded(int episodeId,
      {required String mediaId,
      required String taskId,
      required int size,
      required int duration}) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    await dbClient.rawUpdate(
        """UPDATE Episodes SET downloaded = ?, download_date = ?, media_id = ?,
        enclosure_length = ?, duration = ? WHERE id = ?""",
        [taskId, milliseconds, mediaId, size, duration, episodeId]);
  }

  /// Sets the episode as not downloaded and sets its mediaId to enclosureUrl
  Future<void> unsetDownloaded(int episodeId,
      {required String enclosureUrl}) async {
    var dbClient = await database;
    await dbClient.rawUpdate(
        "UPDATE Episodes SET downloaded = 'ND', media_id = ? WHERE id = ?",
        [enclosureUrl, episodeId]);
  }

  Future<String?> getDescription(int id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT description FROM Episodes WHERE id = ?', [id]);
    String? description = list[0]['description'];
    return description;
  }

  Future saveEpisodeDes(int id, {String? description}) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate("UPDATE Episodes SET description = ? WHERE id = ?",
          [description, id]);
    });
  }

  Future<String?> getFeedDescription(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT description FROM PodcastLocal WHERE id = ?', [id]);
    String? description = list[0]['description'];
    return description;
  }

  Future<String?> getChapter(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECT chapter_link FROM Episodes WHERE enclosure_url = ?', [url]);
    String? chapter = list[0]['chapter_link'];
    return chapter;
  }

  Future<String?> getEpisodeImage(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECT episode_image FROM Episodes WHERE enclosure_url = ?', [url]);
    String? image = list[0]['episode_image'];
    return image;
  }

  Future<String?> getImageUrl(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT P.imageUrl FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        WHERE E.enclosure_url = ?""", [url]);
    if (list.isEmpty) return null;
    return list.first["imageUrl"];
  }
}
