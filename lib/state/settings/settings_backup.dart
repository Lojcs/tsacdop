import 'dart:convert';
import 'dart:io';

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
    String serial;
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
  List<String>? getStringList(String key) => List<String>.from(prefs[key]);
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
