import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../util/helpers.dart';
import 'tsacdop_settings.dart';

class SettingsBackup extends TsacdopSettings<BackupPreferences> {
  /// File the backup is stored.
  final File backupFile;

  /// User-given password.
  final String? password;
  SettingsBackup(this.backupFile, [this.password]) {
    backend = BackupPreferences();
  }

  @override
  Future<void> init() async {}

  Future<void> load() async {
    String? serial;
    if (password != null) {
      final data = await decryptWithPassword(
        await backupFile.readAsBytes(),
        password!,
      );
      serial = String.fromCharCodes(data);
    } else {
      serial = await backupFile.readAsString();
    }
    backend.load(serial);
  }

  Future<void> save() async {
    if (password != null) {
      final encrypted = await encryptWithPassword(
        backend.save().codeUnits,
        password!,
      );
      await backupFile.writeAsBytes(encrypted);
    } else {
      await backupFile.writeAsString(backend.save());
    }
  }

  @override
  void settingsChanged() {}

  @override
  void syncChanged() {}

  @override
  void themesChanged() {}

  @override
  void playbackChanged() {}
}

class BackupPreferences implements SharedPreferencesWithCache {
  Map<String, dynamic> prefs;

  BackupPreferences() : prefs = {};

  /// Saves preferences to the file.
  String save() => json.encode(prefs);

  /// Loads preferences from the file.
  void load(String serial) => prefs
    ..clear()
    ..addAll(json.decode(serial));

  @override
  Future<void> clear() async => prefs.clear();
  @override
  bool containsKey(String key) => prefs.containsKey(key);
  @override
  Object? get(String key) => prefs[key];
  @override
  bool? getBool(String key) => prefs[key] as bool?;
  @override
  double? getDouble(String key) => prefs[key] as double?;
  @override
  int? getInt(String key) => prefs[key] as int?;
  @override
  String? getString(String key) => prefs[key] as String?;
  @override
  List<String>? getStringList(String key) =>
      prefs[key] == null ? null : List<String>.from(prefs[key]);
  @override
  Set<String> get keys => prefs.keys.toSet();
  @override
  Future<void> reloadCache() async {}
  @override
  Future<void> remove(String key) async => prefs.remove(key);
  @override
  Future<void> setBool(String key, bool value) async => prefs[key] = value;
  @override
  Future<void> setDouble(String key, double value) async => prefs[key] = value;
  @override
  Future<void> setInt(String key, int value) async => prefs[key] = value;
  @override
  Future<void> setString(String key, String value) async => prefs[key] = value;
  @override
  Future<void> setStringList(String key, List<String> value) async =>
      prefs[key] = value;
}

class LegacyBackupPreferences implements SharedPreferences {
  final Map<String, dynamic> json;

  LegacyBackupPreferences(this.json);

  /// Translates old SharedPreferences keys to old SettingsBackup keys and returns the value.
  dynamic getValue(String key) => switch (key) {
    'themes' => json['theme'],
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
    'autoSleepTimerStartKey' => json['autoSleepTimerStart'],
    'autoSleepTimerEndKey' => json['autoSleepTimerEnd'],
    'autoSleepTimerModeKey' => json['autoSleepTimerMode'],
    'fastForwardSecondsKey' => json['fastForwardSeconds'],
    'rewindSecondsKey' => json['rewindSeconds'],
    'localeKey' =>
      (json['locale'] as String).split("-").whereNot((e) => e == ""),
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
  int? getInt(String key) => switch (getValue(key)) {
    int i => i,
    bool b => b ? 1 : 0,
    _ => null,
  };
  @override
  Set<String> getKeys() => {}; // Can't bother
  @override
  String? getString(String key) => getValue(key) as String?;
  @override
  List<String>? getStringList(String key) =>
      getValue(key) == null ? null : List<String>.from(getValue(key));
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
