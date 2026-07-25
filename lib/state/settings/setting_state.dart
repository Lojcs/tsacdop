import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../local_storage/key_value_storage.dart';
import '../../type/theme_data.dart';
import '../podcast_state.dart';
import 'settings_backup.dart';
import 'tsacdop_settings.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "update_podcasts") {
      final pState = PodcastState(await getApplicationDocumentsDirectory());
      await pState.ready;
      await pState.syncAllPodcasts();
    } else if (task == "gpodder_sync") {}
    return Future.value(true);
  });
}

/// Stores the settings of the running app.
class SettingState extends TsacdopSettings with ChangeNotifier {
  /// Original screen padding (out of the safe area) stored for animation calculations.
  EdgeInsets? originalPadding;

  @override
  Future<void> init() async {
    backend = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(),
    );
    if (await legacyBackend.getBool('intro') != null) {
      await _migrateSettings(PreferenceCategory.values.toSet());
    }
    if (!settingsInitialized.get()) {
      await _initDefaultSettings();
    }
    startWorkManager();
    setThemes();
  }

  /// Migrates settings from the old [SharedPreferences] backend
  /// to the new [SharedPreferencesWithCache] backend.
  Future<void> _migrateSettings(Set<PreferenceCategory> prefClasses) async {
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    for (var pref in prefSet) {
      final currentPref = getPref(pref);
      if (currentPref.getLegacy != null) {
        final value = await currentPref.getLegacy!();
        if (value != null) await currentPref.set(value);
      }
    }
    await legacyBackend.clear();
    await settingsInitialized.set(true);
  }

  /// Initializes default settings that can't auto-initialize.
  Future<void> _initDefaultSettings([bool force = false]) async {
    defaultDownloadStoragePath =
        (await getExternalStorageDirectories())![0].path;
    if (force) {
      downloadStoragePath.set(defaultDownloadStoragePath);
    } else {
      downloadStoragePath.get();
    }
    await settingsInitialized.set(true);
  }

  /// Sets up the work manager.
  void startWorkManager() async {
    Workmanager().initialize(callbackDispatcher);
    final scheduled = await Workmanager().isScheduledByUniqueName("1");
    if (!scheduled && Platform.isAndroid && autoSync.get()) {
      await _scheduleSync();
    }
  }

  @override
  void settingsChanged() => notifyListeners();

  @override
  void themesChanged() {
    setThemes();
    notifyListeners();
  }

  @override
  void syncChanged() async {
    await _cancelSync();
    if (Platform.isAndroid && autoSync.get()) {
      await _scheduleSync();
    }
    notifyListeners();
  }

  late final VoidCallback onPlaybackChanged;

  @override
  void playbackChanged() {
    onPlaybackChanged();
    notifyListeners();
  }

  late final TextTheme _textTheme = TextTheme(
    bodyLarge: TextStyle(fontSize: 15.0, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal),
    labelSmall: TextStyle(fontSize: 10.0, fontWeight: FontWeight.normal),
    titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.normal),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
    headlineLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.normal),
    headlineMedium: TextStyle(fontSize: 22.0, fontWeight: FontWeight.normal),
    headlineSmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.normal),
  );

  /// Adds brightness-independent customizations to the theme.
  ThemeData _customized(ThemeData theme) => theme.copyWith(
    buttonTheme: ButtonThemeData(height: 32),
    sliderTheme: theme.sliderTheme.copyWith(
      showValueIndicator: .onDrag,
      trackHeight: 8,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 8,
        pressedElevation: 0,
      ),
      overlayColor: theme.colorScheme.primary,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: theme.colorScheme.surface,
    ),
    dialogTheme: DialogThemeData(backgroundColor: theme.colorScheme.surface),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateColor.fromMap({
        WidgetState.selected: theme.colorScheme.surface,
        WidgetState.any: theme.colorScheme.outline,
      }),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: theme.extension<CardColorScheme>()!.card,
    ),
  );

  late ThemeData lightTheme;
  late ThemeData darkTheme;
  late ThemeData blackTheme;
  void setThemes() {
    final lightColorScheme = getColorScheme(accentColor.get(), .light);
    lightTheme = _customized(
      ThemeData(
        colorScheme: lightColorScheme,
        brightness: Brightness.light,
        primaryColor: Colors.grey[100],
        primaryColorLight: Colors.white,
        primaryColorDark: Colors.grey[300],
        textTheme: _textTheme,
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[400],
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: accentColor.get(),
          selectionHandleColor: accentColor.get(),
        ),
        useMaterial3: true,
        extensions: [
          TsacdopTheme(TBrightness.light),
          ActionBarTheme.light(),
          CardColorScheme(lightColorScheme, false),
        ],
      ),
    );
    final darkColorScheme = getColorScheme(accentColor.get(), .dark);
    darkTheme = _customized(
      ThemeData(
        colorScheme: darkColorScheme,
        brightness: Brightness.dark,
        textTheme: _textTheme,
        useMaterial3: true,
        extensions: [
          TsacdopTheme(TBrightness.dark),
          ActionBarTheme.dark(),
          CardColorScheme(darkColorScheme, false),
        ],
      ),
    );
    final blackColorScheme = getColorScheme(accentColor.get(), .black);
    blackTheme = _customized(
      ThemeData(
        colorScheme: blackColorScheme,
        brightness: Brightness.dark,
        textTheme: _textTheme,
        popupMenuTheme: PopupMenuThemeData().copyWith(color: Colors.black),
        useMaterial3: true,
        extensions: [
          TsacdopTheme(TBrightness.black),
          ActionBarTheme.dark(),
          CardColorScheme(blackColorScheme, true),
        ],
        dialogTheme: DialogThemeData(backgroundColor: Colors.black),
      ),
    );
  }

  Future<void> _cancelSync() => Workmanager().cancelByUniqueName('1');

  Future<void> _scheduleSync() => Workmanager().registerPeriodicTask(
    "1",
    "update_podcasts",
    frequency: autoSyncInterval.get(),
    initialDelay: Duration(seconds: 10),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  Future<void> backup(
    File backupFile,
    Set<PreferenceCategory> prefClasses, [
    String? password,
  ]) async {
    final settingsBackup = SettingsBackup(backupFile, password);
    await settingsBackup.ready;
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    for (var pref in prefSet) {
      final currentValue = getPref(pref).get();
      settingsBackup.getPref(pref).set(currentValue);
    }
    await settingsBackup.save();
  }

  Future<void> restore(
    File backupFile,
    Set<PreferenceCategory> prefClasses, [
    String? password,
  ]) async {
    final settingsBackup = SettingsBackup(backupFile, password);
    await settingsBackup.ready;
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    await settingsBackup.load();
    for (var pref in prefSet) {
      final backupValue = settingsBackup.getPref(pref).get();
      getPref(pref).set(backupValue);
    }
  }

  Future<void> restoreLegacy(
    File backupFile,
    Set<PreferenceCategory> prefClasses,
  ) async {
    var data = await backupFile.readAsString();
    legacyBackend = KeyValueStorage.withBackend(
      LegacyBackupPreferences(json.decode(data)),
    );
    await _migrateSettings(prefClasses);
    legacyBackend = KeyValueStorage();
  }

  Future<void> reset(Set<PreferenceCategory> prefClasses) async {
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    for (var pref in prefSet) {
      getPref(pref).reset();
    }
    await _initDefaultSettings(true);
    startWorkManager();
    setThemes();
  }
}

/// SettingState that's safe to construct from a background isolate.
class BackgroundSettingState extends TsacdopSettings {
  @override
  Future<void> init() async {
    backend = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(),
    );
  }

  @override
  void playbackChanged() {}
  @override
  void settingsChanged() {}
  @override
  void syncChanged() {}
  @override
  void themesChanged() {}
}
