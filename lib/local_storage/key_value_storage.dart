import 'package:shared_preferences/shared_preferences.dart';

class KeyValueStorage {
  late final SharedPreferences backend;
  late final Future<void> ready;
  KeyValueStorage() {
    ready = _initDefault();
  }

  Future<void> _initDefault() async {
    backend = await SharedPreferences.getInstance();
  }

  KeyValueStorage.withBackend(this.backend) : ready = Future.value();

  Future<void> clear() => backend.clear();

  Future<(String, int, int)> getPlayerState(String key) async {
    await ready;
    List<String> saved = backend.getStringList(key) ?? ['', '0', '0'];
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
    return (saved[0], episodeIndex, position);
  }

  Future<int?> getInt(String key) async {
    await ready;
    return backend.getInt(key);
  }

  Future<List<String>?> getStringList(String key) async {
    await ready;
    return backend.getStringList(key);
  }

  Future<String?> getString(String key) async {
    await ready;
    return backend.getString(key);
  }

  /// Rreverse is used for compatite bool value save before which set true = 0, false = 1
  Future<bool?> getBool(String key, {bool reverse = false}) async {
    await ready;
    return switch (backend.getInt(key)) {
      0 => reverse,
      1 => !reverse,
      _ => null,
    };
  }

  Future<double?> getDouble(String key) async {
    await ready;
    return backend.getDouble(key);
  }
}

class LegacyBackupPreferences implements SharedPreferences {
  final Map<String, dynamic> json;

  LegacyBackupPreferences(this.json);

  /// Translates old SharedPreferences keys to old SettingsBackup keys and returns the value.
  dynamic getValue(String key) => switch (key) {
    'theme' => json['theme'],
    'accents' => json['accentColor'],
    'realDark' => json['realDark'],
    'useWallpaperThemeKet' => json['useWallpaperTheme'],
    'autoPlay' => !(json['autoPlay'] as bool),
    'autoAdd' => !(json['autoUpdate'] as bool),
    'updateInterval' => json['updateInterval'],
    'downloadUsingData' => !(json['downloadUsingData'] as bool),
    'podcastLayoutKey' => json['podcastLayout'],
    'recentLayoutKey' => json['recentLayout'],
    'favLayoutKey' => json['favLayout'],
    'downloadLayoutKey' => json['downloadLayout'],
    'autoDownloadNetwork' => json['autoDownloadNetwork'],
    'autoDeleteKey' => json['autoDelete'],
    'autoSleepTimerKey' => json['autoSleepTimer'],
    'autoSleepTimerStartKey' => json['autoSleepeTimerStart'],
    'autoSleepTimerEndKey' => json['autoSleepTimerEnd'],
    'autoSleepTimerModeKey' => json['autoSleepTimerMode'],
    'fastForwardSecondsKey' => json['fastForwardSeconds'],
    'rewindSecondsKey' => json['rewindSeconds'],
    'localeKey' => json['locale'],
    'hideListenedKey' => json['hideListened'],
    'notificationLayoutKey' => json['notificationLayout'],
    'showNotesFontKey' => json['showNotesFont'],
    'markListenedAfterSkipKey' => json['markListenedAfterSkip'],
    'removeAfterPlayedKey' => json['deleteAfterPlayed'],
    'hapticsStrengthKey' => json['hapticsStrength'],
    _ => null,
  };

  @override
  Future<bool> clear() async => false;
  @override
  Future<bool> commit() async => false;
  @override
  bool containsKey(String key) => getValue(key) != null;
  @override
  Object? get(String key) => getValue(key);
  @override
  bool? getBool(String key) => getValue(key) as bool?;
  @override
  double? getDouble(String key) => getValue(key) as double?;
  @override
  int? getInt(String key) => getValue(key) as int?;
  @override
  Set<String> getKeys() => {}; // Can't bother
  @override
  String? getString(String key) => getValue(key) as String?;
  @override
  List<String>? getStringList(String key) => getValue(key) as List<String>?;
  @override
  Future<void> reload() async {}
  @override
  Future<bool> remove(String key) async => false;
  @override
  Future<bool> setBool(String key, bool value) async => false;
  @override
  Future<bool> setDouble(String key, double value) async => false;
  @override
  Future<bool> setInt(String key, int value) async => false;
  @override
  Future<bool> setString(String key, String value) async => false;
  @override
  Future<bool> setStringList(String key, List<String> value) async => false;
}
