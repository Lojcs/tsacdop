import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

import '../state/episode_state.dart';
import '../state/podcast_group.dart';
import '../type/playlist.dart';
import '../type/podcastgroup.dart';

const String groupsKey = 'groups';
const String playlistKey = 'playlist';
const String autoPlayKey = 'autoPlay';
const String audioPositionKey = 'audioposition';
const String lastWorkKey = 'lastWork';
const String refreshdateKey = 'refreshdate';
const String themesKey = 'themes';
const String accentsKey = 'accents';
const String autoUpdateKey = 'autoAdd';
const String updateIntervalKey = 'updateInterval';

/// This is 'ask before foreground downloading using data'! (unused)
const String downloadUsingDataKey = 'downloadUsingData';
const String introKey = 'intro';
const String realDarkKey = 'realDark';
const String cacheMaxKey = 'cacheMax';
const String podcastLayoutKey = 'podcastLayoutKey';
const String recentLayoutKey = 'recentLayoutKey';
const String favLayoutKey = 'favLayoutKey';
const String downloadLayoutKey = 'downloadLayoutKey';

/// This is 'background download using data'!
const String autoDownloadNetworkKey = 'autoDownloadNetwork';
const String episodePopupMenuKey = 'episodePopupMenuKey';
const String autoDeleteKey = 'autoDeleteKey';
const String autoSleepTimerKey = 'autoSleepTimerKey';
const String autoSleepTimerStartKey = 'autoSleepTimerStartKey';
const String autoSleepTimerEndKey = 'autoSleepTimerEndKey';
const String defaultSleepTimerKey = 'defaultSleepTimerKey';
const String autoSleepTimerModeKey = 'autoSleepTimerModeKey';
const String tapToOpenPopupMenuKey = 'tapToOpenPopupMenuKey';
const String fastForwardSecondsKey = 'fastForwardSecondsKey';
const String rewindSecondsKey = 'rewindSecondsKey';
const String playerHeightKey = 'playerHeightKey';
const String speedKey = 'speedKey';
const String skipSilenceKey = 'skipSilenceKey';
const String localeKey = 'localeKey';
const String boostVolumeKey = 'boostVolumeKey';
const String volumeGainKey = 'volumeGainKey';
const String hideListenedKey = 'hideListenedKey';
const String notificationLayoutKey = 'notificationLayoutKey';
const String showNotesFontKey = 'showNotesFontKey';
const String speedListKey = 'speedListKey';
const String searchHistoryKey = 'searchHistoryKey';
const String gpodderApiKey = 'gpodderApiKey';
const String gpodderAddKey = 'gpodderAddKey';
const String gpodderRemoveKey = 'gpodderRemoveKey';
const String gpodderSyncStatusKey = 'gpodderSyncStatusKey';
const String gpodderSyncDateTimeKey = 'gpodderSyncDateTimeKey';
const String gpodderRemoteAddKey = 'gpodderRemoteAddKey';
const String gpodderRemoteRemoveKey = 'gpodderRemoteRemoveKey';
const String hidePodcastDiscoveryKey = 'hidePodcastDiscoveryKey';
const String searchEngineKey = 'searchEngineKey';
const String markListenedAfterSkipKey = 'markListenedAfterSkipKey';
const String downloadPositionKey = 'downloadPositionKey';
const String deleteAfterPlayedKey = 'removeAfterPlayedKey';
const String playlistsAllKey = 'playlistsAllKey';
const String playerStateKey = 'playerStateKey';
const String openPlaylistDefaultKey = 'openPlaylistDefaultKey';
const String openAllPodcastDefaultKey = 'openAllPodcastDefaultKey';
const String useWallpapterThemeKey = 'useWallpaperThemeKet';
const String hapticsStrengthKey = 'hapticsStrengthKey';

class KeyValueStorage {
  final String key;
  const KeyValueStorage(this.key);
  Future<List<SuperPodcastGroup>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == null) {
      final home = SuperPodcastGroup.create(id: homeGroupId, name: 'Home');
      await prefs.setString(
          key,
          json.encode({
            'groups': [home.toJson()]
          }));
    }
    final groups =
        json.decode(prefs.getString(key)!)['groups'] as List<dynamic>;
    for (int i = 0; i < groups.length; i++) {
      final color = groups[i]['color'] as String;
      if (color == "#000000") groups[i]['color'] = "009688";
    }
    return [for (var g in groups) SuperPodcastGroup.fromJson(g)];
  }

  Future<bool> saveGroup(List<SuperPodcastGroup> groupList) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(
        key,
        json.encode({
          'groups': [for (var g in groupList) g.toJson()]
        }));
  }

  Future<List<Playlist>> getPlaylists(EpisodeState eState) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == null) {
      var playlist = Playlist('Queue');
      await prefs.setString(
          key,
          json.encode({
            'playlists': [playlist.toJson()]
          }));
    }
    final playlists = json.decode(prefs.getString(key)!)['playlists'];
    List<Playlist> result = [];
    for (var playlist in playlists) {
      if (playlist.containsKey('episodeList')) {
        final urlList = List<String>.from(playlist['episodeList']);
        List<int> idList = await eState.getEpisodes(episodeUrls: urlList);
        List<int> sortedList = List<int>.filled(idList.length, -1);
        for (var id in idList) {
          sortedList[urlList.indexOf(eState[id].enclosureUrl)] = id;
        }
        playlist['episodeIdList'] = sortedList;
      }
      result.add(Playlist.fromJson(playlist));
    }
    return result;
  }

  Future<bool> savePlaylists(List<Playlist> playlists) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setString(
        key,
        json.encode({
          'playlists': [for (var p in playlists) p.toJson()]
        }));
  }

  Future<bool> savePlayerState(
      String playlist, int episodeIndex, int position) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(
        key, [playlist, episodeIndex.toString(), position.toString()]);
  }

  Future<Tuple3<String, int, int>> getPlayerState() async {
    var prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList(key);
    if (saved == null) {
      final position = prefs.getInt(audioPositionKey) ?? 0;
      await savePlayerState('', 0, position);
      saved = ['', '0', position.toString()];
    }
    int episodeIndex = 0;
    int position = 0;
    try {
      episodeIndex = int.parse(saved[1]);
    } catch (e) {
      if (e is! FormatException) {
        rethrow;
      }
    }
    position = int.parse(saved[2]);
    return Tuple3<String, int, int>(saved[0], episodeIndex, position);
  }

  Future<bool> saveInt(int? setting) async {
    if (setting != null) {
      var prefs = await SharedPreferences.getInstance();
      return prefs.setInt(key, setting);
    } else {
      return Future.value(false);
    }
  }

  Future<int> getInt({int defaultValue = 0}) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(key) == null) await prefs.setInt(key, defaultValue);
    return prefs.getInt(key)!;
  }

  Future<bool> saveStringList(List<String?>? playList) async {
    if (playList != null) {
      var prefs = await SharedPreferences.getInstance();
      return prefs.setStringList(key, playList.nonNulls.toList());
    } else {
      return Future.value(false);
    }
  }

  Future<List<String>> getStringList() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList(key) == null) {
      await prefs.setStringList(key, []);
    }
    return prefs.getStringList(key) ?? [];
  }

  Future<bool> saveString(String? string) async {
    if (string != null) {
      var prefs = await SharedPreferences.getInstance();
      return prefs.setString(key, string);
    } else {
      return Future.value(false);
    }
  }

  Future<String> getString({String defaultValue = ''}) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == null) {
      await prefs.setString(key, defaultValue);
    }
    return prefs.getString(key)!;
  }

  Future<bool> saveMenu(List<int> list) async {
    var prefs = await SharedPreferences.getInstance();
    return await prefs.setStringList(
        key, list.map((e) => e.toString()).toList());
  }

  Future<List<int>> getMenu() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList(key) == null || prefs.getStringList(key)!.isEmpty) {
      await prefs.setStringList(key, ['0', '1', '2', '13', '14', '15']);
    }
    var list = prefs.getStringList(key)!;
    if (list.length == 5) list = [...list, '15'];
    return list.map(int.parse).toList();
  }

  /// For player speed settings.
  Future<bool> saveSpeedList(List<double> list) async {
    var prefs = await SharedPreferences.getInstance();
    list.sort();
    return await prefs.setStringList(
        key, list.map((e) => e.toStringAsFixed(1)).toList());
  }

  Future<List<double>> getSpeedList() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList(key) == null || prefs.getStringList(key)!.isEmpty) {
      await prefs.setStringList(
          key, ['0.5', '0.6', '0.8', '1.0', '1.1', '1.2', '1.5', '2.0']);
    }
    var list = prefs.getStringList(key)!;
    return list.map(double.parse).toList();
  }

  /// Rreverse is used for compatite bool value save before which set true = 0, false = 1
  Future<bool> getBool(
      {required bool defaultValue, bool reverse = false}) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(key) == null) {
      reverse
          ? await prefs.setInt(key, defaultValue ? 0 : 1)
          : await prefs.setInt(key, defaultValue ? 1 : 0);
    }
    var i = prefs.getInt(key);
    return reverse ? i == 0 : i == 1;
  }

  /// Rreverse is used for compatite bool value save before which set true = 0, false = 1
  Future<bool> saveBool(bool? boo, {reverse = false}) async {
    if (boo != null) {
      var prefs = await SharedPreferences.getInstance();
      return reverse
          ? prefs.setInt(key, boo ? 0 : 1)
          : prefs.setInt(key, boo ? 1 : 0);
    } else {
      return Future.value(false);
    }
  }

  Future<bool> saveDouble(double data) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(key, data);
  }

  Future<double> getDouble({double defaultValue = 0.0}) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getDouble(key) == null) await prefs.setDouble(key, defaultValue);
    return prefs.getDouble(key)!;
  }

  Future<void> addList(List<String?> addList) async {
    final list = await getStringList();
    await saveStringList([...list, ...addList]);
  }

  Future<void> clearList() async {
    await saveStringList([]);
  }
}
