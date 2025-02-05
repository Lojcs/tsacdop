import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tsacdop/state/episode_state.dart';
import 'package:tsacdop/util/extension_helper.dart';
import 'package:tuple/tuple.dart';
import 'package:webfeed/webfeed.dart';

import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/podcastlocal.dart';
import '../type/sub_history.dart';

enum Filter { downloaded, liked, search, all }

enum SortOrder { ASC, DESC }

String sortOrderToString(SortOrder sortOrder) {
  switch (sortOrder) {
    case SortOrder.ASC:
      return "ASC";
    case SortOrder.DESC:
      return "DESC";
  }
}

enum Sorter {
  pubDate,
  enclosureSize,
  enclosureDuration,
  downloadDate,
  likedDate,
  random
}

String sorterToString(Sorter sorter) {
  switch (sorter) {
    case Sorter.pubDate:
      return "E.milliseconds";
    case Sorter.enclosureSize:
      return "E.enclosure_length";
    case Sorter.enclosureDuration:
      return "E.duration";
    case Sorter.downloadDate:
      return "E.download_date";
    case Sorter.likedDate:
      return "E.liked_date";
    case Sorter.random:
      return "RANDOM()";
  }
}

enum EpisodeField {
  description,
  number,
  enclosureDuration,
  enclosureSize,
  isDownloaded,
  downloadDate,
  mediaId,
  episodeImage,
  podcastImage,
  primaryColor,
  isExplicit,
  isLiked,
  isNew,
  isPlayed,
  isDisplayVersion,
  versions,
  skipSecondsStart,
  skipSecondsEnd,
  chapterLink
}

const localFolderId = "46e48103-06c7-4fe1-a0b1-68aa7205b7f0";

class DBHelper {
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    var documentsDirectory = await getDatabasesPath();
    var path = join(documentsDirectory, "podcasts.db");
    var theDb = await openDatabase(path,
        version: 8, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    await db
        .execute("""CREATE TABLE PodcastLocal(id TEXT PRIMARY KEY,title TEXT, 
        imageUrl TEXT,rssUrl TEXT UNIQUE, primaryColor TEXT, author TEXT, 
        description TEXT, add_date INTEGER, imagePath TEXT, provider TEXT, link TEXT, 
        background_image TEXT DEFAULT '', hosts TEXT DEFAULT '',update_count INTEGER DEFAULT 0,
        episode_count INTEGER DEFAULT 0, skip_seconds INTEGER DEFAULT 0, 
        auto_download INTEGER DEFAULT 0, skip_seconds_end INTEGER DEFAULT 0,
        never_update INTEGER DEFAULT 0, funding TEXT DEFAULT '[]', 
        hide_new_mark INTEGER DEFAULT 0)""");
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
        """CREATE TRIGGER episode_number_trigger AFTER INSERT ON Episodes
        WHEN (NEW.number = -1) BEGIN
        UPDATE Episodes SET number = 1 + IFNULL((SELECT MAX(number) FROM Episodes
        WHERE feed_id = NEW.feed_id), 0) WHERE id = NEW.id;
        END
        """); // New episode gets the highest number
    await db.execute(
        """CREATE TRIGGER episode_version_trigger AFTER INSERT ON Episodes 
        WHEN (NEW.display_version_id = -1) BEGIN
        UPDATE Episodes SET display_version_id = IFNULL((SELECT display_version_id FROM Episodes
        WHERE (feed_id = NEW.feed_id AND title = NEW.title AND downloaded = 'ND')
        ORDER BY download_date DESC LIMIT 1), NEW.id) WHERE id = NEW.id;
        END
        """); // Preserve existing display version(s) on new version insertion.
    await db.execute(
        """CREATE TRIGGER episode_version_downloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded != 'ND' AND NEW.display_version_id != NEW.id) BEGIN
        UPDATE Episodes SET display_version_id = NEW.id
        WHERE (display_version_id = NEW.display_version_id AND (downloaded == 'ND' OR id == NEW.id));
        END
        """); // Change display version of undownloaded episodes to the newly downloaded version on episode download. Other downloaded versions remain as display versions.
    await db.execute(
        """CREATE TRIGGER episode_version_undownloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded = 'ND') BEGIN
        UPDATE Episodes SET display_version_id = IFNULL((SELECT id FROM Episodes
        WHERE (feed_id = NEW.feed_id AND title = NEW.title AND downloaded != 'ND')
        ORDER BY download_date DESC LIMIT 1), NEW.id) WHERE display_version_id = NEW.display_version_id;
        END
        """); // Change display version of undownloaded episodes to the newest downloaded version (if exists) on episode download removal.
    // await db.execute(
    //     "CREATE INDEX episode_names ON Episodes (title, milliseconds ASC, feed_id);");
    // await db.execute(
    //     "CREATE INDEX episode_display ON Episodes (feed_id, version_info, is_new);");
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case (1):
        await _v2Update(db);
        await _v3Update(db);
        await _v4Update(db);
        await _v5Update(db);
        await _v6Update(db);
        await _v7Update(db);
        await _v8Update(db);
        break;
      case (2):
        await _v3Update(db);
        await _v4Update(db);
        await _v5Update(db);
        await _v6Update(db);
        await _v7Update(db);
        await _v8Update(db);
        break;
      case (3):
        await _v4Update(db);
        await _v5Update(db);
        await _v6Update(db);
        await _v7Update(db);
        await _v8Update(db);
        break;
      case (4):
        await _v5Update(db);
        await _v6Update(db);
        await _v7Update(db);
        await _v8Update(db);
        break;
      case (5):
        await _v6Update(db);
        await _v7Update(db);
        await _v8Update(db);
        break;
      case (6):
        await _v7Update(db);
        await _v8Update(db);
        break;
      case (7):
        await _v7Fix(db);
        await _v8Update(db);
    }
  }

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
        UPDATE Episodes SET display_version_id = IFNULL((SELECT display_version_id FROM Episodes
        WHERE (feed_id = NEW.feed_id AND title = NEW.title AND downloaded = 'ND')
        ORDER BY download_date DESC LIMIT 1), NEW.id) WHERE id = NEW.id;
        END
        """); // Preserve existing display version(s) on new version insertion.
    await db.execute(
        """CREATE TRIGGER episode_version_downloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded != 'ND' AND NEW.display_version_id != NEW.id) BEGIN
        UPDATE Episodes SET display_version_id = NEW.id
        WHERE (display_version_id = NEW.display_version_id AND (downloaded == 'ND' OR id == NEW.id));
        END
        """); // Change display version of undownloaded episodes to the newly downloaded version on episode download. Other downloaded versions remain as display versions.
    await db.execute(
        """CREATE TRIGGER episode_version_undownloaded_trigger AFTER UPDATE OF downloaded ON Episodes
        WHEN (NEW.downloaded = 'ND') BEGIN
        UPDATE Episodes SET display_version_id = IFNULL((SELECT id FROM Episodes
        WHERE (feed_id = NEW.feed_id AND title = NEW.title AND downloaded != 'ND')
        ORDER BY download_date DESC LIMIT 1), NEW.id) WHERE display_version_id = NEW.display_version_id;
        END
        """); // Change display version of undownloaded episodes to the newest downloaded version (if exists) on episode download removal.
    List<Map> podcasts = await db.rawQuery("SELECT id FROM PodcastLocal");
    List<Future> futures = [];
    for (var podcast in podcasts) {
      futures.add(_rescanPodcastEpisodesVersions(db, podcast['id']));
    }
    await Future.wait(futures);
    futures.clear();
    for (var podcast in podcasts) {
      futures.add(_rescanEpisodeNumbers(db, podcast['id']));
    }
    await Future.wait(futures);
  }

  Future<List<PodcastLocal>> getPodcastLocal(List<String?> podcasts,
      {bool updateOnly = false}) async {
    var dbClient = await database;
    var podcastLocal = <PodcastLocal>[];

    for (var s in podcasts) {
      List<Map> list;
      if (updateOnly) {
        list = await dbClient.rawQuery(
            """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath , provider, 
          link ,update_count, episode_count, funding, description FROM PodcastLocal WHERE id = ? AND 
          never_update = 0""", [s]);
      } else {
        list = await dbClient.rawQuery(
            """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath , provider, 
          link ,update_count, episode_count, funding, description FROM PodcastLocal WHERE id = ?""",
            [s]);
      }
      if (list.length > 0) {
        podcastLocal.add(PodcastLocal(
            list.first['title'],
            list.first['imageUrl'],
            list.first['rssUrl'],
            list.first['primaryColor'],
            list.first['author'],
            list.first['id'],
            list.first['imagePath'],
            list.first['provider'],
            list.first['link'],
            List<String>.from(jsonDecode(list.first['funding'])),
            description: list.first['description'],
            updateCount: list.first['update_count'],
            episodeCount: list.first['episode_count']));
      }
    }
    return podcastLocal;
  }

  Future<List<PodcastLocal>> getPodcastLocalAll(
      {bool updateOnly = false}) async {
    var dbClient = await database;

    List<Map> list;
    if (updateOnly) {
      list = await dbClient.rawQuery(
          """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath,
         provider, link, funding, description FROM PodcastLocal WHERE never_update = 0 ORDER BY 
         add_date DESC""");
    } else {
      list = await dbClient.rawQuery(
          """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath,
         provider, link, funding, description FROM PodcastLocal ORDER BY add_date DESC""");
    }

    var podcastLocal = <PodcastLocal>[];

    for (var i in list) {
      if (i['id'] != localFolderId) {
        podcastLocal.add(PodcastLocal(
          i['title'],
          i['imageUrl'],
          i['rssUrl'],
          i['primaryColor'],
          i['author'],
          i['id'],
          i['imagePath'],
          i['provider'],
          i['link'],
          List<String>.from(jsonDecode(list.first['funding'])),
          description: i['description'],
        ));
      }
    }
    return podcastLocal;
  }

  Future<PodcastLocal?> getPodcastWithUrl(String? url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT P.id, P.title, P.imageUrl, P.rssUrl, P.primaryColor, P.author, P.imagePath,
         P.provider, P.link ,P.update_count, P.episode_count, P.funding, P.description FROM PodcastLocal P INNER JOIN 
         Episodes E ON P.id = E.feed_id WHERE E.enclosure_url = ?""", [url]);
    if (list.isNotEmpty) {
      return PodcastLocal(
          list.first['title'],
          list.first['imageUrl'],
          list.first['rssUrl'],
          list.first['primaryColor'],
          list.first['author'],
          list.first['id'],
          list.first['imagePath'],
          list.first['provider'],
          list.first['link'],
          List<String>.from(jsonDecode(list.first['funding'])),
          description: list.first['description'],
          updateCount: list.first['update_count'],
          episodeCount: list.first['episode_count']);
    }
    return null;
  }

  Future<int?> getPodcastCounts(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT episode_count FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) return list.first['episode_count'];
    return 0;
  }

  Future<void> removePodcastNewMark(String? id) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET is_new = 0 WHERE feed_id = ? AND is_new = 1",
          [id]);
    });
  }

  Future<bool> getNeverUpdate(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT never_update FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) return list.first['never_update'] == 1;
    return false;
  }

  Future<int> saveNeverUpdate(String? id, {required bool boo}) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET never_update = ? WHERE id = ?",
        [boo ? 1 : 0, id]);
  }

  Future<bool> getHideNewMark(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT hide_new_mark FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) return list.first['hide_new_mark'] == 1;
    return false;
  }

  Future<int> saveHideNewMark(String? id, {required bool boo}) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET hide_new_mark = ? WHERE id = ?",
        [boo ? 1 : 0, id]);
  }

  Future<int?> getPodcastUpdateCounts(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECt count(*) as count FROM Episodes WHERE feed_id = ? AND is_new = 1',
        [id]);
    if (list.isNotEmpty) return list.first['count'];
    return 0;
  }

  Future<int?> getSkipSecondsStart(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT skip_seconds FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) return list.first['skip_seconds'];
    return 0;
  }

  Future<int> saveSkipSecondsStart(String? id, int seconds) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET skip_seconds = ? WHERE id = ?", [seconds, id]);
  }

  Future<int?> getSkipSecondsEnd(String id) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECT skip_seconds_end FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) return list.first['skip_seconds_end'];
    return 0;
  }

  Future<int> saveSkipSecondsEnd(String? id, int seconds) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET skip_seconds_end = ? WHERE id = ?",
        [seconds, id]);
  }

  Future<bool> getAutoDownload(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT auto_download FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) return list.first['auto_download'] == 1;
    return false;
  }

  Future<int> saveAutoDownload(String? id, {required bool boo}) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET auto_download = ? WHERE id = ?",
        [boo ? 1 : 0, id]);
  }

  Future<String?> checkPodcast(String? url) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT id FROM PodcastLocal WHERE rssUrl = ?', [url]);
    if (list.isEmpty) return '';
    return list.first['id'];
  }

  Future<PodcastLocal?> getPodcast(String id) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath , provider, 
          link ,update_count, episode_count, funding, description FROM PodcastLocal WHERE id = ?""",
        [id]);
    if (list.length > 0) {
      return PodcastLocal(
          list.first['title'],
          list.first['imageUrl'],
          list.first['rssUrl'],
          list.first['primaryColor'],
          list.first['author'],
          list.first['id'],
          list.first['imagePath'],
          list.first['provider'],
          list.first['link'],
          List<String>.from(jsonDecode(list.first['funding'])),
          description: list.first['description'],
          updateCount: list.first['update_count'],
          episodeCount: list.first['episode_count']);
    }
    return null;
  }

  Future savePodcastLocal(PodcastLocal podcastLocal) async {
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
            podcastLocal.primaryColor,
            podcastLocal.author,
            podcastLocal.description,
            milliseconds,
            podcastLocal.imagePath,
            podcastLocal.provider,
            podcastLocal.link,
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

  Future<int> updatePodcastImage(
      {String? id, String? filePath, String? color}) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET primaryColor = ?, imagePath = ? WHERE id = ?",
        [color, filePath, id]);
  }

  Future<int> saveFiresideData(List<String?> list) async {
    var dbClient = await database;
    var result = await dbClient.rawUpdate(
        'UPDATE PodcastLocal SET background_image = ? , hosts = ? WHERE id = ?',
        [list[1], list[2], list[0]]);
    return result;
  }

  Future<List<String?>> getFiresideData(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECT background_image, hosts FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) {
      var data = <String?>[list.first['background_image'], list.first['hosts']];
      return data;
    }
    return ['', ''];
  }

  Future<void> delPodcastLocal(String? id) async {
    var dbClient = await database;
    await dbClient.rawDelete('DELETE FROM PodcastLocal WHERE id =?', [id]);
    List<Map> list = await dbClient.rawQuery(
        """SELECT downloaded FROM Episodes WHERE downloaded != 'ND' AND feed_id = ?""",
        [id]);
    for (var i in list) {
      await FlutterDownloader.remove(
          taskId: i['downloaded'], shouldDeleteContent: true);
    }
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
      if (recent.isNotEmpty && recent.first.title == history.title) {
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

  Future<int> isListened(String url) async {
    var dbClient = await database;
    int? i = 0;
    List<Map> list = await dbClient.rawQuery(
        "SELECT SUM(listen_time) FROM PlayHistory WHERE enclosure_url = ?",
        [url]);
    if (list.isNotEmpty) {
      i = list.first['SUM(listen_time)'];
      return i ?? 0;
    }
    return 0;
  }

  Future<int?> markNotListened(List<String> urls) async {
    var dbClient = await database;
    int? count;
    await dbClient.transaction((txn) async {
      count = await txn.rawUpdate(
          "UPDATE OR IGNORE PlayHistory SET listen_time = 0 WHERE enclosure_url IN (${(", ?" * urls.length).substring(2)})",
          [...urls]);
    });
    await dbClient.rawDelete(
        'DELETE FROM PlayHistory WHERE enclosure_url in (${(", ?" * urls.length).substring(2)}) '
        'AND listen_time = 0 AND seconds = 0',
        [...urls]);
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

  DateTime _parsePubDate(String? pubDate) {
    if (pubDate == null) return DateTime.now();
    DateTime date;
    var yyyy = RegExp(r'[1-2][0-9]{3}');
    var hhmm = RegExp(r'[0-2][0-9]\:[0-5][0-9]');
    var ddmmm = RegExp(r'[0-3][0-9]\s[A-Z][a-z]{2}');
    var mmDd = RegExp(r'([1-2][0-9]{3}\-[0-1]|\s)[0-9]\-[0-3][0-9]');
    // RegExp timezone
    var z = RegExp(r'(\+|\-)[0-1][0-9]00');
    var timezone = z.stringMatch(pubDate);
    var timezoneInt = 0;
    if (timezone != null) {
      if (timezone.substring(0, 1) == '-') {
        timezoneInt = int.parse(timezone.substring(1, 2));
      } else {
        timezoneInt = -int.parse(timezone.substring(1, 2));
      }
    }
    try {
      date = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z', 'en_US').parse(pubDate);
    } catch (e) {
      try {
        date = DateFormat('dd MMM yyyy HH:mm:ss Z', 'en_US').parse(pubDate);
      } catch (e) {
        try {
          date = DateFormat('EEE, dd MMM yyyy HH:mm Z', 'en_US').parse(pubDate);
        } catch (e) {
          var year = yyyy.stringMatch(pubDate);
          var time = hhmm.stringMatch(pubDate);
          var month = ddmmm.stringMatch(pubDate);
          if (year != null && time != null && month != null) {
            try {
              date = DateFormat('dd MMM yyyy HH:mm', 'en_US')
                  .parse('$month $year $time');
            } catch (e) {
              date = DateTime.now();
            }
          } else if (year != null && time != null && month == null) {
            var month = mmDd.stringMatch(pubDate);
            try {
              date =
                  DateFormat('yyyy-MM-dd HH:mm', 'en_US').parse('$month $time');
            } catch (e) {
              date = DateTime.now();
            }
          } else {
            date = DateTime.now();
          }
        }
      }
    }
    date.add(Duration(hours: timezoneInt)).add(DateTime.now().timeZoneOffset);
    developer.log(date.toString());
    return date;
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

  bool _isXimalaya(String input) {
    var ximalaya = RegExp(r"ximalaya.com");
    return ximalaya.hasMatch(input);
  }

  String _getDescription(String content, String description, String summary) {
    if (content.length >= description.length) {
      if (content.length >= summary.length) {
        return content;
      } else {
        return summary;
      }
    } else if (description.length >= summary.length) {
      return description;
    } else {
      return summary;
    }
  }

  /// Assigns each episode in a podcast numbers based on its publish date
  Future<void> _rescanEpisodeNumbers(
      DatabaseExecutor dbClient, String id) async {
    List<Map> episodes = await dbClient.rawQuery(
        """SELECT E.id, E.number FROM Episodes E INNER JOIN PodcastLocal P ON
        E.feed_id = P.id WHERE E.feed_id = ? ORDER BY E.milliseconds ASC""",
        [id]);
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
  /// a) Manually set version
  /// b) Newest downladed version
  /// c) The version all other undownloaded versions point to (newest on rescan)
  Future<void> _rescanPodcastEpisodesVersions(
      DatabaseExecutor dbClient, String feedId) async {
    await dbClient.rawUpdate(
        "UPDATE Episodes SET display_version_id = id WHERE (feed_id = ? AND downloaded != 'ND')",
        [feedId]);
    await dbClient.rawUpdate(
        """UPDATE Episodes SET display_version_id = IFNULL((SELECT e.id FROM Episodes e
        WHERE (e.feed_id = Episodes.feed_id AND e.title = Episodes.title AND e.downloaded != 'ND')
        ORDER BY e.download_date DESC LIMIT 1), (SELECT e.id FROM Episodes e
        WHERE (e.feed_id = Episodes.feed_id AND e.title = Episodes.title)
        ORDER BY e.milliseconds DESC LIMIT 1))
        WHERE (feed_id = ? AND downloaded = 'ND')""", [feedId]);
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

  /// Populates the EpisodeBrief.versions set. Expects the set to be not null.
  /// Doesn't populate if it is not empty.
  /// Versions have all the fields that the original episode has.
  Future<EpisodeBrief> populateEpisodeVersions(EpisodeBrief episode) async {
    var dbClient = await database;
    if (episode.versions!.isNotEmpty) return episode;
    List<Map> results = await dbClient.rawQuery(
        "SELECT id FROM Episodes WHERE (feed_id = ? AND title = ?)",
        [episode.podcastId, episode.title]);
    if (results.length == 1) {
      episode.versions!.add(episode);
      return episode;
    }
    List<int> otherVersionIds =
        results.map<int>((result) => result['id']).toList();
    otherVersionIds.remove(episode.id);
    List<EpisodeField> fields = episode.fields.toList()
      ..remove(EpisodeField.versions);
    List<EpisodeBrief> versions =
        await getEpisodes(episodeIds: otherVersionIds, optionalFields: fields);
    versions = versions.map((e) => e.copyWith(versions: {})).toList();
    versions.add(episode);
    for (EpisodeBrief version1 in versions) {
      for (EpisodeBrief version2 in versions) {
        version1.versions!.add(version2);
      }
    }
    return episode;
  }

  /// Parses and saves episodes in an [RssFeed]. Set [update] for existing feeds.
  Future<int> savePodcastRss(RssFeed feed, String feedId,
      {bool update = false}) async {
    var dbClient = await database;
    List<EpisodeBrief> episodes = [];
    developer.log("Parsing ${feed.title}");
    for (var i = 0; i < feed.items!.length; i++) {
      String? url;
      if (feed.items![i].enclosure != null) {
        _isXimalaya(feed.items![i].enclosure!.url!)
            ? url = feed.items![i].enclosure!.url!.split('=').last
            : url = feed.items![i].enclosure!.url;
      }
      if (url != null) {
        final title =
            feed.items![i].itunes!.title ?? feed.items![i].title ?? '';
        final length = feed.items![i].enclosure?.length ?? 0;
        final pubDate = feed.items![i].pubDate;
        final milliseconds = pubDate?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;
        final duration = feed.items![i].itunes!.duration?.inSeconds ?? 0;
        final explicit = feed.items![i].itunes!.explicit;
        final chapter = feed.items![i].podcastChapters?.url ?? '';
        final image = feed.items![i].itunes!.image?.href ??
            ''; // TODO: Maybe cache these?
        episodes.add(
          EpisodeBrief(-1, title, url, feedId, "", milliseconds,
              description: _getDescription(
                  feed.items![i].content?.value ?? '',
                  feed.items![i].description ?? '',
                  feed.items![i].itunes!.summary ?? ''),
              enclosureDuration: duration,
              enclosureSize: length,
              episodeImage: image,
              isExplicit: explicit,
              chapterLink: chapter),
        );
      }
    }
    if (!update) {
      developer.log("Sorting ${feed.title}");
      episodes.sortBy<num>((episode) => episode.pubDate);
      episodes = episodes
          .mapIndexed((i, episode) => episode.copyWith(number: i + 1))
          .toList();
      developer.log("Saving ${feed.title}");
      return await dbClient.transaction<int>((txn) async {
        Batch batchOp = txn.batch();
        for (var episode in episodes) {
          batchOp.rawInsert(
              """INSERT OR REPLACE INTO Episodes(title, enclosure_url, enclosure_length, pubDate, 
                description, feed_id, milliseconds, duration, explicit, media_id, chapter_link,
                episode_image, number, display_version_id) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
              [
                episode.title,
                episode.enclosureUrl,
                episode.enclosureSize,
                '',
                episode.description,
                feedId,
                episode.pubDate,
                episode.enclosureDuration,
                _getExplicit(episode.isExplicit),
                episode.enclosureUrl,
                episode.chapterLink,
                episode.episodeImage,
                episode.number,
                0 // To disable the triggers
              ]);
        }
        await batchOp.commit();
        developer.log("Versioning ${feed.title}");
        await _rescanPodcastEpisodesVersions(txn, feedId);
        int count = Sqflite.firstIntValue(await txn.rawQuery(
                'SELECT COUNT(*) FROM Episodes WHERE feed_id = ?', [feedId])) ??
            0;
        await txn.rawUpdate(
            """UPDATE PodcastLocal SET episode_count = ? WHERE id = ?""",
            [count, feedId]);
        return count;
      }).then((countUpdate) {
        developer.log("Commited ${feed.title}: $countUpdate episodes");
        return countUpdate;
      });
    } else {
      developer.log("Saving ${feed.title}");
      return await dbClient.transaction<int>((txn) async {
        Batch batchOp = txn.batch();
        for (var episode in episodes) {
          batchOp.rawInsert(
              """INSERT OR IGNORE INTO Episodes(title, enclosure_url, enclosure_length, pubDate, 
                description, feed_id, milliseconds, duration, explicit, media_id, chapter_link,
                episode_image) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
              [
                episode.title,
                episode.enclosureUrl,
                episode.enclosureSize,
                '',
                episode.description,
                feedId,
                episode.pubDate,
                episode.enclosureDuration,
                _getExplicit(episode.isExplicit),
                episode.enclosureUrl,
                episode.chapterLink,
                episode.episodeImage,
              ]);
        }
        await batchOp.commit();
        int newCount = Sqflite.firstIntValue(await txn.rawQuery(
                'SELECT COUNT(*) FROM Episodes WHERE feed_id = ?', [feedId])) ??
            0;
        int oldCount = Sqflite.firstIntValue(await txn.rawQuery(
                'SELECT episode_count FROM PodcastLocal WHERE id = ?',
                [feedId])) ??
            0;

        await dbClient.rawUpdate(
            """UPDATE PodcastLocal SET update_count = ?, episode_count = ? WHERE id = ?""",
            [newCount - oldCount, newCount, feedId]);
        return newCount - oldCount;
      }).then((count) {
        developer.log("Commited ${feed.title}: $count episodes");
        return count;
      });
    }
  }

  Future<int> updatePodcastRss(PodcastLocal podcastLocal,
      {int? keepNewMark = 0}) async {
    final options = BaseOptions(
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
    );
    final hideNewMark = await getHideNewMark(podcastLocal.id);
    try {
      var response = await Dio(options).get(podcastLocal.rssUrl);
      if (response.statusCode == 200) {
        var feed = RssFeed.parse(response.data);
        String? url, description;

        var dbClient = await database;
        List<String> urls = (await dbClient.rawQuery(
                'SELECT enclosure_url FROM Episodes WHERE feed_id = ?',
                [podcastLocal.id]))
            .map(
              (e) => e['enclosure_url'] as String,
            )
            .toList();
        var count = urls.length;
        if (keepNewMark == 0) {
          await dbClient.rawUpdate(
              "UPDATE Episodes SET is_new = 0 WHERE feed_id = ? AND milliseconds < ?",
              [
                podcastLocal.id,
                DateTime.now()
                    .subtract(Duration(days: 1))
                    .millisecondsSinceEpoch
              ]);
        }
        return savePodcastRss(feed, podcastLocal.id, update: true);
      }
      return 0;
    } catch (e) {
      developer.log(e.toString(), name: 'Update podcast error');
      return -1;
    }
  }

  Future<void> saveLocalEpisode(EpisodeBrief episode) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      int episodeId = await txn.rawInsert(
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
            episode.episodeImage
          ]);
    });
  }

  Future<void> deleteLocalEpisodes(List<String> files) async {
    var dbClient = await database;
    var s = files.map<String>((e) => "'$e'").toList();
    await dbClient.transaction((txn) async {
      Batch batchOp = txn.batch();
      for (String episode in s) {
        batchOp.rawDelete(
            'DELETE FROM Episodes WHERE enclosure_url = ?', [episode]);
      }
      await batchOp.commit();
    });
  }

  /// Queries the database with the provided options and returns found episodes.
  /// Filters are tri-state with false being inverse
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
      List<EpisodeField>? optionalFields,
      Sorter? sortBy,
      SortOrder sortOrder = SortOrder.DESC,
      List<Sorter>? rangeParameters,
      List<Tuple2<int, int>>? rangeDelimiters,
      int limit = -1,
      bool? filterNew,
      bool? filterLiked,
      bool? filterPlayed,
      bool? filterDownloaded,
      bool? filterDisplayVersion,
      bool? filterAutoDownload,
      List<String>? customFilters,
      List<String>? customArguements,
      EpisodeState? episodeState}) async {
    bool doGroup = false;
    List<String> query = [
      """SELECT E.id, E.title, E.enclosure_url, E.feed_id, P.title as feed_title,
      E.milliseconds"""
    ];
    List<String> filters = [];
    List arguements = [];
    if (optionalFields != null && optionalFields.isNotEmpty) {
      for (var field in optionalFields) {
        switch (field) {
          case EpisodeField.description:
            query.add(", E.description");
            break;
          case EpisodeField.number:
            query.add(", E.number");
            break;
          case EpisodeField.enclosureDuration:
            query.add(", E.duration");
            break;
          case EpisodeField.enclosureSize:
            query.add(", E.enclosure_length");
            break;
          case EpisodeField.isDownloaded:
            query.add(", E.downloaded");
            break;
          case EpisodeField.downloadDate:
            query.add(", E.download_date");
            break;
          case EpisodeField.mediaId:
            query.add(", E.media_id");
            break;
          case EpisodeField.episodeImage:
            query.add(", E.episode_image");
            break;
          case EpisodeField.podcastImage:
            query.add(", P.imagePath");
            break;
          case EpisodeField.primaryColor:
            query.add(", P.primaryColor");
            break;
          case EpisodeField.isExplicit:
            query.add(", E.explicit");
            break;
          case EpisodeField.isLiked:
            query.add(", E.liked");
            break;
          case EpisodeField.isNew:
            query.add(", E.is_new");
            break;
          case EpisodeField.isPlayed:
            doGroup = true;
            query.add(", SUM(H.listen_time) as play_time");
            break;
          case EpisodeField.isDisplayVersion:
            query.add(", E.display_version_id");
            break;
          case EpisodeField.versions:
            break;
          case EpisodeField.skipSecondsStart:
            query.add(", P.skip_seconds");
            break;
          case EpisodeField.skipSecondsEnd:
            query.add(", P.skip_seconds_end");
            break;
          case EpisodeField.chapterLink:
            query.add(", E.chapter_link");
            break;
        }
      }
    }
    query.add(" FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id");
    if (filterPlayed != null || doGroup) {
      query
          .add(" LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url");
    }

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
        (e) => "%" + e + "%",
      ));
    }
    if (excludedLikeEpisodeTitles != null &&
        excludedLikeEpisodeTitles.isNotEmpty) {
      filters.add(
          " (${(" OR E.title LIKE ?" * excludedLikeEpisodeTitles.length).substring(4)})");
      arguements.addAll(excludedLikeEpisodeTitles.map(
        (e) => "%" + e + "%",
      ));
    }
    if (filterDisplayVersion == 2) {
      filters.add(" E.version_info = 'NONE'");
    } else if (filterDisplayVersion == 1) {
      filters.add(
          " (E.version_info = 'HAS' OR E.version_info = 'FHAS' OR E.version_info = 'NONE')");
    } else if (filterDisplayVersion == -1) {
      filters.add(" E.version_info = 'IS'");
    } else if (filterDisplayVersion == -2) {
      filters.add(" (E.version_info = 'HAS' OR E.version_info = 'FHAS')");
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
    if (filterDisplayVersion == false) {
      filters.add(" E.display_version_id != E.id");
    } else if (filterDisplayVersion == true) {
      filters.add(" E.display_version_id = E.id");
    }
    if (filterAutoDownload == false) {
      filters.add(" P.auto_download = 0");
    } else if (filterAutoDownload == true) {
      filters.add(" P.auto_download = 1");
    }
    if (rangeParameters != null &&
        rangeParameters.isNotEmpty &&
        rangeDelimiters != null &&
        rangeParameters.length == rangeDelimiters.length) {
      for (int i = 0; i < rangeParameters.length; i++) {
        if (rangeDelimiters[i].item1 != -1 && rangeDelimiters[i].item2 != -1) {
          filters.add(
              " ${sorterToString(rangeParameters[i])} BETWEEN ${rangeDelimiters[i].item1} AND ${rangeDelimiters[i].item2}");
        } else if (rangeDelimiters[i].item1 != -1) {
          filters.add(
              " ${sorterToString(rangeParameters[i])} > ${rangeDelimiters[i].item1}");
        } else if (rangeDelimiters[i].item2 != -1) {
          filters.add(
              " ${sorterToString(rangeParameters[i])} < ${rangeDelimiters[i].item2}");
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
    if (filterPlayed != null || doGroup) {
      query.add(" GROUP BY E.enclosure_url");
    }
    if (filterPlayed == false) {
      query.add(" HAVING SUM(H.listen_time) IS Null OR SUM(H.listen_time) = 0");
    } else if (filterPlayed == true) {
      query.add(" HAVING SUM(H.listen_time) > 0");
    }
    if (sortBy != null) {
      if (sortBy == Sorter.random) {
        query.add(" ORDER BY ${sorterToString(sortBy)}");
      } else {
        query.add(
            " ORDER BY ${sorterToString(sortBy)} ${sortOrderToString(sortOrder)}");
      }
    }
    if (limit != -1) {
      query.add(" LIMIT ${limit.toString()}");
    }

    bool populateVersions = false;
    var dbClient = await database;
    List<EpisodeBrief> episodes = [];
    List<Map> result;
    result = await dbClient.rawQuery(query.join(), arguements);
    if (result.isNotEmpty) {
      for (var i in result) {
        Map<Symbol, dynamic> fields = {};
        if (optionalFields != null) {
          for (var field in optionalFields) {
            switch (field) {
              case EpisodeField.description:
                fields[const Symbol("description")] = i['description'];
                break;
              case EpisodeField.number:
                fields[const Symbol("number")] = i['number'];
                break;
              case EpisodeField.enclosureDuration:
                fields[const Symbol("enclosureDuration")] = i['duration'];
                break;
              case EpisodeField.enclosureSize:
                fields[const Symbol("enclosureSize")] = i['enclosure_length'];
                break;
              case EpisodeField.isDownloaded:
                fields[const Symbol("isDownloaded")] = i['downloaded'] != 'ND';
                break;
              case EpisodeField.downloadDate:
                fields[const Symbol("downloadDate")] = i['download_date'];
                break;
              case EpisodeField.mediaId:
                fields[const Symbol("mediaId")] = i['media_id'];
                break;
              case EpisodeField.episodeImage:
                fields[const Symbol("episodeImage")] = i['episode_image'];
                break;
              case EpisodeField.podcastImage:
                fields[const Symbol("podcastImage")] = i['imagePath'];
                break;
              case EpisodeField.primaryColor:
                fields[const Symbol("primaryColor")] =
                    (i['primaryColor'] as String).toColor();
                break;
              case EpisodeField.isExplicit:
                fields[const Symbol("isExplicit")] = i['explicit'] == 1;
                break;
              case EpisodeField.isLiked:
                fields[const Symbol("isLiked")] = i['liked'] == 1;
                break;
              case EpisodeField.isNew:
                fields[const Symbol("isNew")] = i['is_new'] == 1;
                break;
              case EpisodeField.isPlayed:
                fields[const Symbol("isPlayed")] =
                    (i['play_time'] != null && i['play_time'] != 0);
                break;
              case EpisodeField.isDisplayVersion:
                fields[const Symbol("isDisplayVersion")] =
                    i['display_version_id'] == i['id'];
                break;
              case EpisodeField.versions:
                fields[const Symbol("versions")] = Set<EpisodeBrief>();
                populateVersions = true;
                break;
              case EpisodeField.skipSecondsStart:
                fields[const Symbol("skipSecondsStart")] = i['skip_seconds'];
                break;
              case EpisodeField.skipSecondsEnd:
                fields[const Symbol("skipSecondsEnd")] = i['skip_seconds_end'];
                break;
              case EpisodeField.chapterLink:
                fields[const Symbol("chapterLink")] = i['chapter_link'];
                break;
            }
          }
        }
        EpisodeBrief episode = Function.apply(
            EpisodeBrief.new,
            [
              i['id'],
              i['title'],
              i['enclosure_url'],
              i['feed_id'],
              i['feed_title'],
              i['milliseconds']
            ],
            fields);
        if (populateVersions) episode = await populateEpisodeVersions(episode);
        episodes.add(episode);
        if (episodeState != null) {
          episodeState.addEpisode(episode);
        }
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
    developer.log('remove episode mark $ids');
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

  /// Saves [mediaId] and optionally [size] of an [episode]. Sets or unsets downloaded status based on [mediaId].
  Future<int?> saveMediaId(EpisodeBrief episode, String mediaId,
      {EpisodeState? episodeState, String? taskId, int? size}) async {
    var dbClient = await database;
    int? count;
    count = await dbClient.rawUpdate(
        "UPDATE Episodes SET media_id = ? WHERE enclosure_url = ?",
        [mediaId, episode.enclosureUrl]);
    if (size != null) {
      await dbClient.rawUpdate(
          "UPDATE Episodes SET enclosure_length = ? WHERE enclosure_url = ?",
          [size, episode.enclosureUrl]);
    }
    if (episodeState != null) {
      if (episode.enclosureUrl != mediaId) {
        await episodeState.setDownloaded([episode], taskId!);
      } else {
        await episodeState.unsetDownloaded([episode]);
      }
    } else {
      if (episode.enclosureUrl != mediaId) {
        await setDownloaded(episode.id, taskId!);
      } else {
        await unsetDownloaded([episode.id]);
      }
    }
    return count;
  }

  Future<int> setDownloaded(int episodeId, String taskId) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    int count = await dbClient.rawUpdate(
        "UPDATE Episodes SET downloaded = ?, download_date = ? WHERE id = ?",
        [taskId, milliseconds, episodeId]);
    return count;
  }

  Future<int> unsetDownloaded(List<int> ids) async {
    var dbClient = await database;
    int count = await dbClient.rawUpdate(
        "UPDATE Episodes SET downloaded = 'ND' WHERE id IN (${(", ?" * ids.length).substring(2)})",
        [...ids]);
    return count;
  }

  Future<String?> getDescription(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECT description FROM Episodes WHERE enclosure_url = ?', [url]);
    String? description = list[0]['description'];
    return description;
  }

  Future saveEpisodeDes(String url, {String? description}) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET description = ? WHERE enclosure_url = ?",
          [description, url]);
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
