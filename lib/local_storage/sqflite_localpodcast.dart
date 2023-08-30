import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tsacdop/state/episode_state.dart';
import 'package:tuple/tuple.dart';
import 'package:webfeed/webfeed.dart';

import '../local_storage/key_value_storage.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/podcastlocal.dart';
import '../type/sub_history.dart';
import '../state/setting_state.dart';

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

enum Sorter { pubDate, downloadDate, enclosureLength, likedDate, random }

String sorterToString(Sorter sorter) {
  switch (sorter) {
    case Sorter.pubDate:
      return "E.milliseconds";
    case Sorter.downloadDate:
      return "E.download_date";
    case Sorter.enclosureLength:
      return "E.enclosure_length";
    case Sorter.likedDate:
      return "E.liked_date";
    case Sorter.random:
      return "RANDOM()";
  }
}

enum EpisodeField {
  description,
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
  versionInfo,
  versions,
  versionsPopulated,
  skipSecondsStart,
  skipSecondsEnd,
  chapterLink
}

enum VersionInfo {
  NONE,
  FHAS,
  HAS,
  IS;
}

VersionInfo versionInfoFromString(String string) {
  switch (string) {
    case "NONE":
      return VersionInfo.NONE;
    case "FHAS":
      return VersionInfo.FHAS;
    case "HAS":
      return VersionInfo.HAS;
    case "IS":
      return VersionInfo.IS;
    default:
      throw "Invalid VersionInfo string";
  }
}

String versionInfoToString(VersionInfo versionInfo) {
  switch (versionInfo) {
    case VersionInfo.NONE:
      return "NONE";
    case VersionInfo.FHAS:
      return "FHAS";
    case VersionInfo.HAS:
      return "HAS";
    case VersionInfo.IS:
      return "IS";
    default:
      throw "Invalid VersionInfo string";
  }
}

enum VersionPolicy { Default, New, Old, NewIfNoDownloaded }

// Maybe make this a method of String?
VersionPolicy versionPolicyFromString(String string) {
  switch (string) {
    case "NEW":
      return VersionPolicy.New;
    case "OLD":
      return VersionPolicy.Old;
    case "DON":
      return VersionPolicy.NewIfNoDownloaded;
    case "DEF":
      return VersionPolicy.Default;
    default:
      throw "Invalid VersionPolicy string";
  }
}

String versionPolicyToString(VersionPolicy versionPolicy) {
  switch (versionPolicy) {
    case VersionPolicy.Default:
      return "DEF";
    case VersionPolicy.New:
      return "NEW";
    case VersionPolicy.Old:
      return "OLD";
    case VersionPolicy.NewIfNoDownloaded:
      return "DON";
  }
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
        hide_new_mark INTEGER DEFAULT 0, version_policy TEXT DEFAULT 'DEF')""");
    await db
        .execute("""CREATE TABLE Episodes(id INTEGER PRIMARY KEY,title TEXT, 
        enclosure_url TEXT UNIQUE, enclosure_length INTEGER, pubDate TEXT, 
        description TEXT, feed_id TEXT, feed_link TEXT, milliseconds INTEGER,
        version_info TEXT DEFAULT 'NONE', duration INTEGER DEFAULT 0, explicit INTEGER DEFAULT 0,
        liked INTEGER DEFAULT 0, liked_date INTEGER DEFAULT 0, downloaded TEXT DEFAULT 'ND', 
        download_date INTEGER DEFAULT 0, media_id TEXT, is_new INTEGER DEFAULT 0, 
        chapter_link TEXT DEFAULT '', hosts TEXT DEFAULT '', episode_image TEXT DEFAULT '',
        versions TEXT DEFAULT '')""");
    await db.execute(
        """CREATE TABLE PlayHistory(id INTEGER PRIMARY KEY, title TEXT, enclosure_url TEXT,
        seconds REAL, seek_value REAL, add_date INTEGER, listen_time INTEGER DEFAULT 0)""");
    await db.execute(
        """CREATE TABLE SubscribeHistory(id TEXT PRIMARY KEY, title TEXT, rss_url TEXT UNIQUE, 
        add_date INTEGER, remove_date INTEGER DEFAULT 0, status INTEGER DEFAULT 0)""");
    await db
        .execute("""CREATE INDEX  podcast_search ON PodcastLocal (id, rssUrl);
    """);
    await db.execute(
        """CREATE INDEX  episode_search ON Episodes (enclosure_url, feed_id);
    """);
    // await db.execute(
    //     """CREATE INDEX episode_names ON Episodes (title, milliseconds ASC, feed_id);
    // """);
    // await db.execute(
    //     """CREATE INDEX episode_display ON Episodes (feed_id, version_info, is_new);
    // """);
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
    await db
        .execute("ALTER TABLE Episodes ADD version_info TEXT DEFAULT 'NONE'");
    await db.execute("ALTER TABLE Episodes ADD versions TEXT DEFAULT ''");
    await db.execute(
        "ALTER TABLE PodcastLocal ADD version_policy TEXT DEFAULT 'DEF'");
    List<Map> podcasts = await db.rawQuery("SELECT id FROM PodcastLocal");
    List<Future> futures = [];
    for (var podcast in podcasts) {
      futures.add(_rescanPodcastEpisodesVersions(db, podcast['id']));
    }
    await Future.wait(futures);
  }

  Future<VersionPolicy> _getGlobalVersionPolicy() async {
    var storage = KeyValueStorage(versionPolicyKey);
    String value = await storage.getString(defaultValue: "DON");
    return versionPolicyFromString(value);
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
          link ,update_count, episode_count, funding FROM PodcastLocal WHERE id = ? AND 
          never_update = 0""", [s]);
      } else {
        list = await dbClient.rawQuery(
            """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath , provider, 
          link ,update_count, episode_count, funding FROM PodcastLocal WHERE id = ?""",
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
         provider, link, funding FROM PodcastLocal WHERE never_update = 0 ORDER BY 
         add_date DESC""");
    } else {
      list = await dbClient.rawQuery(
          """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath,
         provider, link, funding FROM PodcastLocal ORDER BY add_date DESC""");
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
        ));
      }
    }
    return podcastLocal;
  }

  Future<PodcastLocal?> getPodcastWithUrl(String? url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        """SELECT P.id, P.title, P.imageUrl, P.rssUrl, P.primaryColor, P.author, P.imagePath,
         P.provider, P.link ,P.update_count, P.episode_count, P.funding FROM PodcastLocal P INNER JOIN 
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

  Future<VersionPolicy> getPodcastVersionPolicy(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT version_policy FROM PodcastLocal WHERE id = ?', [id]);
    return versionPolicyFromString(list.first['version_policy']);
  }

  Future<int> saveVersionPolicy(String? id, VersionPolicy versionPolicy) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET version_policy = ? WHERE id = ?",
        [versionPolicyToString(versionPolicy), id]);
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

  Future<int> saveSkipSecondsStart(String? id, int? seconds) async {
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

  Future savePodcastLocal(PodcastLocal podcastLocal) async {
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawInsert(
          """INSERT OR IGNORE INTO PodcastLocal (id, title, imageUrl, rssUrl, 
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

  Future<int> updatePodcastImage({String? id, String? filePath}) async {
    var dbClient = await database;
    return await dbClient.rawUpdate(
        "UPDATE PodcastLocal SET imagePath= ? WHERE id = ?", [filePath, id]);
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
      if (i != null) {
        await FlutterDownloader.remove(
            taskId: i['downloaded'], shouldDeleteContent: true);
      }
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

  Future<int?> markNotListened(String url) async {
    var dbClient = await database;
    int? count;
    await dbClient.transaction((txn) async {
      count = await txn.rawUpdate(
          "UPDATE OR IGNORE PlayHistory SET listen_time = 0 WHERE enclosure_url = ?",
          [url]);
    });
    await dbClient.rawDelete(
        'DELETE FROM PlayHistory WHERE enclosure_url=? '
        'AND listen_time = 0 AND seconds = 0',
        [url]);
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

  /// Checks every episode from the given podcast, gives it a unique milliseconds value among its versions
  /// and sets their version_info values. Two episodes are considered versions of each other if their titles match.
  /// dbClient should be a Transaction or a Database wrapped in transaction.
  Future<void> _rescanPodcastEpisodesVersions(
      // TODO: Optimize using versions
      DatabaseExecutor dbClient,
      String id) async {
    List<Map> episodesList = await dbClient.rawQuery(
        """SELECT E.id, E.enclosure_url, E.milliseconds, E.downloaded, E.title,
        P.version_policy FROM Episodes E INNER JOIN PodcastLocal P ON
        E.feed_id = P.id WHERE E.feed_id = ? ORDER BY E.milliseconds ASC""",
        [id]);
    Map<String, List<Map>> episodes = groupBy(
        episodesList,
        (Map episode) =>
            episode['title']); // TODO: Add support for rebroadcasts.
    Batch batchOp = dbClient.batch();
    for (var episodeTitle in episodes.keys) {
      List<Map> versions = episodes[episodeTitle]!;
      if (versions.length == 1) {
        batchOp.rawUpdate(
            "UPDATE Episodes SET version_info = 'NONE' WHERE enclosure_url = ?",
            [versions.first['enclosure_url']]);
      } else {
        List<Map<String, dynamic>> versionsTimes = [];
        for (Map version in versions) {
          versionsTimes.add({
            'enclosure_url': version['enclosure_url'],
            'milliseconds': version['milliseconds']
          });
        }
        Map<int, List<Map>> timeline =
            groupBy(versionsTimes, (version) => version['milliseconds']);
        List<int> times = timeline.keys.toList();
        times.sort();
        // TODO: Optimize this?
        for (int i = 0, time; i < times.length; i++) {
          time = times[i];
          timeline[time]!.first['milliseconds'] = time;
          if (timeline[time]!.length > 1) {
            if (times.contains(time + 1)) {
              timeline[time + 1]!.insertAll(
                  0, timeline[time]!.getRange(1, timeline[time]!.length));
            } else {
              timeline[time + 1] =
                  timeline[time]!.getRange(1, timeline[time]!.length).toList();
              times.add(time + 1);
            }
          }
        }
        for (Map version in versionsTimes) {
          batchOp.rawUpdate(
              "UPDATE Episodes SET milliseconds = ?, versions = ? WHERE enclosure_url = ?",
              [
                version['milliseconds'],
                [for (Map eachVersion in versions) eachVersion['id'].toString()]
                    .join(','),
                version['enclosure_url']
              ]);
        }
        versions.sort((a, b) => a['milliseconds'].compareTo(b['milliseconds']));
        VersionPolicy versionPolicy =
            versionPolicyFromString(versions.first['version_policy']);
        if (versionPolicy == VersionPolicy.Default) {
          versionPolicy = await _getGlobalVersionPolicy();
        }
        switch (versionPolicy) {
          case VersionPolicy.NewIfNoDownloaded:
            Map candidate = versions.last;
            for (Map version in versions.reversed) {
              if (version['downloaded'] != "ND") {
                candidate = version;
                break;
              }
            }
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE enclosure_url = ?",
                [candidate["enclosure_url"]]);
            versions.remove(candidate);
            break;
          case VersionPolicy.Old:
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE enclosure_url = ?",
                [versions.first["enclosure_url"]]);
            versions.removeAt(0);
            break;
          default: //case VersionPolicy.New:
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE enclosure_url = ?",
                [versions.last["enclosure_url"]]);
            versions.removeLast();
            break;
        }
        Iterable<String> versionUrls = versions.map((e) => e['enclosure_url']);
        for (String versionUrl in versionUrls) {
          batchOp.rawUpdate(
              "UPDATE Episodes SET version_info = 'IS' WHERE enclosure_url == ?",
              [versionUrl]);
        }
      }
    }
    await batchOp.commit(noResult: true);
  }

  /// Checks for other versions of an episode, gives it a unique milliseconds value among them,
  /// sets their version_info values and the episode's own version_info value.
  /// Two episodes are considered versions of each other if their titles match.
  /// Call this after adding the episode to the database.
  Future<void> _updateNewEpisodeVersions(
      // TODO: Optimize using versions
      Transaction txn,
      String?
          feedId, //TODO: Make changes to other properties also produce versions.
      String? title,
      int episodeId,
      int milliseconds) async {
    List<Map> versions = await txn
        .rawQuery("""SELECT E.id, E.milliseconds, E.version_info, E.downloaded,
        P.version_policy FROM Episodes E INNER JOIN PodcastLocal P ON
        E.feed_id = P.id WHERE E.feed_id = ? AND E.title = ? AND E.id != ?
        ORDER BY E.milliseconds ASC""", [feedId, title, episodeId]);
    Batch batchOp = txn.batch();
    List<String> versionIdList = [
      for (Map eachVersion in versions) eachVersion['id'].toString()
    ];
    versionIdList.add(episodeId.toString());
    batchOp.rawUpdate("UPDATE Episodes SET versions = ? WHERE id = ?",
        [versionIdList.join(','), episodeId]);
    if (versions.isNotEmpty) {
      for (int i = 0; i < versions.length; i++) {
        batchOp.rawUpdate("UPDATE Episodes SET versions = ? WHERE id = ?",
            [versionIdList.join(','), versions[i]['id']]);
        if (versions[i]['milliseconds'] == milliseconds) {
          for (; versions[i]['milliseconds'] == milliseconds; i++) {
            milliseconds++;
          }
          batchOp.rawUpdate("UPDATE Episodes SET milliseconds = ? WHERE id = ?",
              [milliseconds, episodeId]);
        }
      }
      if (versions.any((version) => version['version_info'] == 'FHAS')) {
        batchOp.rawUpdate(
            "UPDATE Episodes SET version_info = 'IS' WHERE id = ?",
            [episodeId]);
      } else {
        VersionPolicy versionPolicy =
            versionPolicyFromString(versions.first['version_policy']);
        if (versionPolicy == VersionPolicy.Default) {
          versionPolicy = await _getGlobalVersionPolicy();
        }
        switch (versionPolicy) {
          case VersionPolicy.NewIfNoDownloaded:
            String result = "HAS";
            if (versions.last['version_info'] == "NONE") {
              // TODO: Get rid of none.
              if (versions.first['downloaded'] != "ND") {
                result = "IS";
                batchOp.rawUpdate(
                    "UPDATE Episodes SET version_info = 'HAS' WHERE id = ?",
                    [versions.first["id"]]);
              } else {
                batchOp.rawUpdate(
                    "UPDATE Episodes SET version_info = 'IS' WHERE id = ?",
                    [versions.first["id"]]);
              }
            } else if (versions.last['version_info'] == "HAS") {
              if (versions.last['downloaded'] != "ND") {
                result = "IS";
              } else {
                batchOp.rawUpdate(
                    "UPDATE Episodes SET version_info = 'IS' WHERE id = ?",
                    [versions.last["id"]]);
              }
            } else {
              result = "IS";
            }
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = ? WHERE id = ?",
                [result, episodeId]);
            break;
          case VersionPolicy.Old:
            if (versions.length == 1) {
              batchOp.rawUpdate(
                  "UPDATE Episodes SET version_info = 'HAS' WHERE id = ?",
                  [versions.first['id']]);
            }
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'IS' WHERE id = ?",
                [episodeId]);
            break;
          default: //case VersionPolicy.New:
            Iterable<String> versionUrls = versions.map((e) => e['id']);
            for (String versionUrl in versionUrls) {
              batchOp.rawUpdate(
                  "UPDATE Episodes SET version_info = 'IS' WHERE id = ?",
                  [versionUrl]);
            }
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE id = ?",
                [episodeId]);
            break;
        }
      }
    } else {
      batchOp.rawUpdate(
          "UPDATE Episodes SET version_info = 'NONE' WHERE id = ?",
          [episodeId]);
    }
    batchOp.commit(noResult: true);
  }

  /// Checks for versions of an episode to be deleted and sets their version_info values.
  /// Two episodes are considered versions if their titles match.
  /// Call this before deleting the episode.
  Future<void> _updateDeletedEpisodeVersions(Transaction txn, String? id,
      String? title, String url, String versionStatus) async {
    // TODO: Optimize using versions
    List<Map> versions = await txn.rawQuery(
        """SELECT E.id E.enclosure_url, E.downloaded, P.version_policy FROM Episodes E
        INNER JOIN PodcastLocal P ON E.feed_id = P.id WHERE E.feed_id = ? AND E.title = ?
        AND E.enclosure_url != ? ORDER BY E.milliseconds ASC""",
        [id, title, url]);
    if (versions.isNotEmpty) {
      Batch batchOp = txn.batch();
      for (Map version in versions) {
        batchOp.rawUpdate(
            "UPDATE Episodes SET versions = ? WHERE enclosure_url = ?", [
          [for (Map eachVersion in versions) eachVersion['id'].toString()]
              .join(','),
          version['enclosure_url']
        ]);
      }
      if (versions.length == 1) {
        batchOp.rawUpdate(
            "UPDATE Episodes SET version_info = 'NONE' WHERE enclosure_url = ?",
            [versions.first['enclosure_url']]);
      } else if (versionStatus == "HAS" || versionStatus == "FHAS") {
        VersionPolicy versionPolicy =
            versionPolicyFromString(versions.first['version_policy']);
        if (versionPolicy == VersionPolicy.Default) {
          versionPolicy = await _getGlobalVersionPolicy();
        }
        switch (versionPolicy) {
          case VersionPolicy.NewIfNoDownloaded:
            var candidate = versions.last;
            for (var version in versions.reversed) {
              if (version['downloaded'] != "ND") {
                candidate = version;
                break;
              }
            }
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE enclosure_url = ?",
                [candidate["enclosure_url"]]);
            break;
          case VersionPolicy.Old:
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE enclosure_url = ?",
                [versions.first["enclosure_url"]]);
            break;
          default: //case VersionPolicy.New:
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE enclosure_url = ?",
                [versions.last["enclosure_url"]]);
            break;
        }
      }
      batchOp.commit(noResult: true);
    }
  }

  /// Sets the episode as the display version among its other versions.
  /// If reset is true, reverts the display version among its versions to default.
  /// FHAS indicates an episode is the display version but not the default.
  Future<void> setEpisodeDisplayVersion(EpisodeBrief episode,
      {bool reset = false}) async {
    var dbClient = await database;
    dbClient.transaction((txn) async {
      Batch batchOp = txn.batch();
      if (reset) {
        List<Map> versions = await txn.rawQuery(
            """SELECT E.id, E.version_info, P.version_policy E.downloaded
          FROM Episodes E inner join PodcastLocal P E.feed_id = P.id WHERE feed_id = ?
          AND title = ? ORDER BY milliseconds DESC""",
            [episode.podcastId, episode.title]);
        VersionPolicy versionPolicy =
            versionPolicyFromString(versions.first['version_policy']);
        if (versionPolicy == VersionPolicy.Default) {
          versionPolicy = await _getGlobalVersionPolicy();
        }
        switch (versionPolicy) {
          case VersionPolicy.New:
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE id = ?",
                [versions.removeAt(0)['id']]);
            break;
          case VersionPolicy.Old:
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE id = ?",
                [versions.removeLast()['id']]);
            break;
          default: // VersionPolicy.NewIfNoDownloaded:
            Map candidate = versions.last;
            for (Map version in versions.reversed) {
              if (version['downloaded'] != "ND") {
                candidate = version;
                break;
              }
            }
            batchOp.rawUpdate(
                "UPDATE Episodes SET version_info = 'HAS' WHERE id = ?",
                [candidate["id"]]);
            versions.remove(candidate);
            break;
        }
        batchOp.rawUpdate(
            "UPDATE Episodes SET version_info = 'IS' WHERE id in (${(", ?" * versions.length).substring(2)})",
            versions.map((e) => e['id']).toList());
      } else {
        List<Map> versions = await txn.rawQuery(
            """SELECT id, version_info FROM Episodes WHERE feed_id = ? AND title = ? AND 
          id != ?""", [episode.podcastId, episode.title, episode.id]);
        batchOp.rawUpdate(
            "UPDATE Episodes SET version_info = 'FHAS' WHERE id = ?",
            [episode.id]);
        batchOp.rawUpdate(
            "UPDATE Episodes SET version_info = 'IS' WHERE id in (${(", ?" * versions.length).substring(2)})",
            versions.map((e) => e['id']).toList());
      }
      batchOp.commit();
    });
  }

  /// Populates the EpisodeBrief.versions map. Versions have all the
  /// fields that the original episode has.
  Future<EpisodeBrief> populateEpisodeVersions(EpisodeBrief episode) async {
    var dbClient = await database;
    if (episode.versions == null) {
      List<Map> versions = await dbClient
          .rawQuery("SELECT versions FROM Episodes WHERE id = ?", [episode.id]);
      episode = episode.copyWith(versions: {
        for (String version in versions.first['versions'].split(","))
          int.parse(version): null
      });
    } else if (episode.versions!.length != 0 &&
        episode.versions!.values.first != null) return episode;
    if (episode.versions!.length == 1) {
      episode.versions![episode.id] = episode;
    }
    List<int> otherVersionIds = episode.versions!.keys.toList();
    otherVersionIds.remove(episode.id);
    List<EpisodeBrief> versions = await getEpisodes(
        episodeIds: otherVersionIds, optionalFields: episode.fields);
    versions.add(episode);
    for (EpisodeBrief version1 in versions) {
      for (EpisodeBrief version2 in versions) {
        version1.versions![version2.id] = version2;
      }
    }
    return episode;
  }

  Future<int> savePodcastRss(RssFeed feed, String id) async {
    feed.items!.removeWhere((item) => item == null);
    var result = feed.items!.length;
    var dbClient = await database;
    String? description, url;
    for (var i = 0; i < result; i++) {
      developer.log(feed.items![i].title!);
      description = _getDescription(
          feed.items![i].content?.value ?? '',
          feed.items![i].description ?? '',
          feed.items![i].itunes!.summary ?? '');
      if (feed.items![i].enclosure != null) {
        _isXimalaya(feed.items![i].enclosure!.url!)
            ? url = feed.items![i].enclosure!.url!.split('=').last
            : url = feed.items![i].enclosure!.url;
      }

      final title = feed.items![i].itunes!.title ?? feed.items![i].title;
      final length = feed.items![i].enclosure?.length;
      final pubDate = feed.items![i].pubDate;
      final date = _parsePubDate(pubDate);
      final milliseconds = date.millisecondsSinceEpoch;
      final duration = feed.items![i].itunes!.duration?.inSeconds ?? 0;
      final explicit = _getExplicit(feed.items![i].itunes!.explicit);
      final chapter = feed.items![i].podcastChapters?.url ?? '';
      final image =
          feed.items![i].itunes!.image?.href ?? ''; // TODO: Maybe cache these?
      if (url != null) {
        await dbClient.transaction((txn) async {
          int episodeId = await txn.rawInsert(
              """INSERT OR REPLACE INTO Episodes(title, enclosure_url, enclosure_length, pubDate, 
                description, feed_id, milliseconds, duration, explicit, media_id, chapter_link,
                episode_image) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
              [
                title,
                url,
                length,
                pubDate,
                description,
                id,
                milliseconds,
                duration,
                explicit,
                url,
                chapter,
                image
              ]);
          await _updateNewEpisodeVersions(
              txn, id, title, episodeId, milliseconds);
          return episodeId;
        });
      }
    }
    var countUpdate = Sqflite.firstIntValue(await dbClient
        .rawQuery('SELECT COUNT(*) FROM Episodes WHERE feed_id = ?', [id]));

    await dbClient.rawUpdate(
        """UPDATE PodcastLocal SET episode_count = ? WHERE id = ?""",
        [countUpdate, id]);
    return result;
  }

  Future<int> updatePodcastRss(PodcastLocal podcastLocal,
      {int? removeMark = 0}) async {
    final options = BaseOptions(
      connectTimeout: 20000,
      receiveTimeout: 20000,
    );
    final hideNewMark = await getHideNewMark(podcastLocal.id);
    try {
      var response = await Dio(options).get(podcastLocal.rssUrl);
      if (response.statusCode == 200) {
        var feed = RssFeed.parse(response.data);
        String? url, description;
        feed.items!.removeWhere((item) => item == null);

        var dbClient = await database;
        var count = Sqflite.firstIntValue(await dbClient.rawQuery(
            'SELECT COUNT(*) FROM Episodes WHERE feed_id = ?',
            [podcastLocal.id]))!;
        if (removeMark == 0) {
          await dbClient.rawUpdate(
              "UPDATE Episodes SET is_new = 0 WHERE feed_id = ?",
              [podcastLocal.id]);
        }
        for (var item in feed.items!) {
          developer.log(item.title!);
          description = _getDescription(item.content!.value,
              item.description ?? '', item.itunes!.summary ?? '');

          if (item.enclosure?.url != null) {
            _isXimalaya(item.enclosure!.url!)
                ? url = item.enclosure!.url!.split('=').last
                : url = item.enclosure!.url;
          }

          final title = item.itunes!.title ?? item.title;
          final length = item.enclosure?.length ?? 0;
          final pubDate = item.pubDate;
          final date = _parsePubDate(pubDate);
          final milliseconds = date.millisecondsSinceEpoch;
          final duration = item.itunes!.duration?.inSeconds ?? 0;
          final explicit = _getExplicit(item.itunes!.explicit);
          final chapter = item.podcastChapters?.url ?? '';
          final image = item.itunes!.image?.href ?? '';

          if (url != null) {
            await dbClient.transaction((txn) async {
              int episodeId = await txn.rawInsert(
                  """INSERT OR IGNORE INTO Episodes(title, enclosure_url, enclosure_length, pubDate, 
                description, feed_id, milliseconds, duration, explicit, media_id, chapter_link,
                episode_image, is_new) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                  [
                    title,
                    url,
                    length,
                    pubDate,
                    description,
                    podcastLocal.id,
                    milliseconds,
                    duration,
                    explicit,
                    url,
                    chapter,
                    image,
                    hideNewMark ? 0 : 1
                  ]);
              await _updateNewEpisodeVersions(
                  txn, podcastLocal.id, title, episodeId!, milliseconds);
            });
          }
        }
        var countUpdate = Sqflite.firstIntValue(await dbClient.rawQuery(
            'SELECT COUNT(*) FROM Episodes WHERE feed_id = ?',
            [podcastLocal.id]))!;

        await dbClient.rawUpdate(
            """UPDATE PodcastLocal SET update_count = ?, episode_count = ? WHERE id = ?""",
            [countUpdate - count, countUpdate, podcastLocal.id]);
        return countUpdate - count;
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
      await _updateNewEpisodeVersions(
          txn, localFolderId, episode.title, episodeId, episode.pubDate!);
    });
  }

  Future<void> deleteLocalEpisodes(List<String> files) async {
    var dbClient = await database;
    var s = files.map<String>((e) => "'$e'").toList();
    List<String> query = [
      "SELECT feed_id, title, enclosure_url, milliseconds FROM Episodes WHERE"
    ];
    query.add([for (var _ in s) " enclosure_url = ?"].join(" OR"));
    List<Map> episodes = await dbClient.rawQuery(query.join(), s);
    dbClient.transaction((txn) async {
      for (var episode in episodes) {
        await _updateDeletedEpisodeVersions(
          txn,
          episode['feed_id'],
          episode['title'],
          episode['enclosure_url'],
          episode['milliseconds'],
        );
      }
      Batch batchOp = txn.batch();
      for (String episode in s) {
        batchOp.rawDelete(
            'DELETE FROM Episodes WHERE enclosure_url = ?', [episode]);
      }
      batchOp.commit();
    });
  }

  /// Queries the database with the provided options and returns found episodes.
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
      int filterVersions = 0,
      int filterNew = 0,
      int filterLiked = 0,
      int filterPlayed = 0,
      int filterDownloaded = 0,
      int filterAutoDownload = 0,
      List<String>? customFilters,
      List<String>? customArguements,
      EpisodeState? episodeState}) async {
    bool doGroup = false;
    bool getVersions = false;
    bool populateVersions = false;
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
          case EpisodeField.versionInfo:
            query.add(", E.version_info");
            break;
          case EpisodeField.versions:
            if (!getVersions) {
              query.add(", E.versions");
            }
            getVersions = true;
            break;
          case EpisodeField.versionsPopulated:
            if (!getVersions) {
              query.add(", E.versions");
            }
            getVersions = true;
            populateVersions = true;
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
    if (filterPlayed != 0 || doGroup) {
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
    if (filterVersions == 2) {
      filters.add(" E.version_info = 'NONE'");
    } else if (filterVersions == 1) {
      filters.add(
          " (E.version_info = 'HAS' OR E.version_info = 'FHAS' OR E.version_info = 'NONE')");
    } else if (filterVersions == -1) {
      filters.add(" E.version_info = 'IS'");
    } else if (filterVersions == -2) {
      filters.add(" (E.version_info = 'HAS' OR E.version_info = 'FHAS')");
    }
    if (filterNew == 1) {
      filters.add(" E.is_new = 0");
    } else if (filterNew == -1) {
      filters.add(" E.is_new = 1");
    }
    if (filterLiked == 1) {
      filters.add(" E.liked = 0");
    } else if (filterLiked == -1) {
      filters.add(" E.liked = 1");
    }
    if (filterDownloaded == 1) {
      filters.add(" E.downloaded = 'ND'");
    } else if (filterDownloaded == -1) {
      filters.add(" E.downloaded != 'ND'");
    }
    if (filterAutoDownload == 1) {
      filters.add(" P.auto_download = 0");
    } else if (filterAutoDownload == -1) {
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
    if (filterPlayed != 0 || doGroup) {
      query.add(" GROUP BY E.enclosure_url");
    }
    if (filterPlayed == 1) {
      query.add(" HAVING SUM(H.listen_time) IS Null OR SUM(H.listen_time) = 0");
    } else if (filterPlayed == -1) {
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

    var dbClient = await database;
    List<EpisodeBrief> episodes = [];
    List<Map> result;
    result = await dbClient.rawQuery(query.join(), arguements);
    if (result.isNotEmpty) {
      for (var i in result) {
        getVersions = false;
        Map<Symbol, dynamic> fields = {};
        if (optionalFields != null) {
          for (var field in optionalFields) {
            switch (field) {
              case EpisodeField.description:
                fields[const Symbol("description")] = i['description'];
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
                fields[const Symbol("primaryColor")] = i['primaryColor'];
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
              case EpisodeField.versionInfo:
                fields[const Symbol("versionInfo")] =
                    versionInfoFromString(i['version_info']);
                break;
              case EpisodeField.versions:
                if (!getVersions) {
                  fields[const Symbol("versions")] = <int, EpisodeBrief?>{
                    for (String id in i['versions'].split(","))
                      int.parse(id): null
                  };
                }
                getVersions = true;
                break;
              case EpisodeField.versionsPopulated:
                if (!getVersions) {
                  fields[const Symbol("versions")] = <int, EpisodeBrief?>{
                    for (String id in i['versions'].split(","))
                      int.parse(id): null
                  };
                }
                getVersions = true;
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

  Future<void> removeEpisodeNewMark(String? url) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET is_new = 0 WHERE enclosure_url = ?", [url]);
    });
    developer.log('remove episode mark $url');
  }

  Future setLiked(String url) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET liked = 1, liked_date = ? WHERE enclosure_url= ?",
          [milliseconds, url]);
    });
  }

  Future setUnliked(String url) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET liked = 0 WHERE enclosure_url = ?", [url]);
    });
  }

  Future<bool> isLiked(String url) async {
    var dbClient = await database;
    var list = <Map>[];
    list = await dbClient
        .rawQuery("SELECT liked FROM Episodes WHERE enclosure_url = ?", [url]);
    if (list.isNotEmpty) {
      return list.first['liked'] == 0 ? false : true;
    }
    return false;
  }

  Future<bool> isDownloaded(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        "SELECT id FROM Episodes WHERE enclosure_url = ? AND enclosure_url != media_id",
        [url]);
    return list.isNotEmpty;
  }

  Future<int?> saveDownloaded(String url, String? id) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    int? count;
    await dbClient.transaction((txn) async {
      count = await txn.rawUpdate(
          "UPDATE Episodes SET downloaded = ?, download_date = ? WHERE enclosure_url = ?",
          [id, milliseconds, url]);
    });
    return count;
  }

  Future<int?> saveMediaId(
      String url, String path, String? id, int size) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    int? count;
    await dbClient.transaction((txn) async {
      count = await txn.rawUpdate(
          "UPDATE Episodes SET enclosure_length = ?, media_id = ?, download_date = ?, downloaded = ? WHERE enclosure_url = ?",
          [size, path, milliseconds, id, url]);
    });
    return count;
  }

  Future<int?> delDownloaded(String url) async {
    var dbClient = await database;
    int? count;
    await dbClient.transaction((txn) async {
      count = await txn.rawUpdate(
          "UPDATE Episodes SET downloaded = 'ND', media_id = ? WHERE enclosure_url = ?",
          [url, url]);
    });
    developer.log('Deleted $url');
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
