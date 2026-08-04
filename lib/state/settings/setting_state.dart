import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../generated/l10n.dart';
import '../../local_storage/key_value_storage.dart';
import '../../type/theme_data.dart';
import '../podcast_state.dart';
import 'preference.dart';
import 'settings_backup.dart';
import 'tsacdop_settings.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "update_podcasts") {
      final pState = PodcastState(await getApplicationDocumentsDirectory());
      await pState.ready;
      await pState.syncAllPodcasts();
      dev.log("${DateTime.now()} - Background sync finished.");
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
    if (!settingsInitialized.get()) {
      final legacyInitialized = await legacyBackend.getInt('intro');
      if (legacyInitialized != null && legacyInitialized != 0) {
        await _migrateSettings(PreferenceCategory.values.toSet());
      }
      await _initDefaultSettings();
    }

    await startWorkManager();
    await setThemes();
    await settingsInitialized.set(true);
  }

  /// Migrates settings from the old [SharedPreferences] backend
  /// to the new [SharedPreferencesWithCache] backend.
  Future<void> _migrateSettings(Set<PreferenceCategory> prefClasses) async {
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    if (prefSet.contains(TsacdopPreference.localeOverride)) {
      final value = await localeOverride.getLegacy!();
      S.load(
        value ??
            localeOverride.get() ??
            localeOverride.deserialize(Platform.localeName)!,
      );
    } else {
      S.load(
        localeOverride.get() ??
            localeOverride.deserialize(Platform.localeName)!,
      );
    }
    for (var pref in prefSet) {
      final currentPref = getPref(pref);
      if (currentPref.getLegacy != null) {
        final value = await currentPref.getLegacy!();
        if (value != null ||
            (currentPref is ProxyPreference && currentPref.nullAllowed)) {
          await currentPref.set(value);
        }
      }
    }
    await legacyBackend.clear();
  }

  /// Initializes default settings that can't auto-initialize.
  Future<void> _initDefaultSettings() async {
    if (downloadStoragePath.get() == unsetSentinel) {
      downloadStoragePath.set((await getExternalStorageDirectories())![0].path);
    }
  }

  /// Sets up the work manager.
  Future<void> startWorkManager() async {
    Workmanager().initialize(callbackDispatcher);
    final scheduled = await Workmanager().isScheduledByUniqueName("1");
    if (!scheduled && Platform.isAndroid && autoSync.get()) {
      await _scheduleSync();
    }
  }

  @override
  void settingsChanged() => notifyListeners();

  @override
  void themesChanged() async {
    await setThemes();
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

  VoidCallback? onPlaybackChanged;

  @override
  void playbackChanged() {
    onPlaybackChanged?.call();
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

  Future<ColorScheme> getColorScheme(TBrightness brightness) async =>
      useSystemAccentColor.get()
      ? getColorSchemeFromPlatform(accentColor.get(), brightness)
      : getColorSchemeFromSeed(accentColor.get(), brightness);

  late ThemeData lightTheme;
  late ThemeData darkTheme;
  late ThemeData blackTheme;
  Future<void> setThemes() async {
    final lightColorScheme = await getColorScheme(.light);
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
    final darkColorScheme = await getColorScheme(.dark);
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
    final blackColorScheme = await getColorScheme(.black);
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

  Future<void> debugSync() => Workmanager().registerOneOffTask(
    "2",
    "update_podcasts",
    initialDelay: Duration(seconds: 1),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  Future<void> backup(
    File backupFile,
    Set<PreferenceCategory> prefClasses,
    String? password,
  ) async {
    final settingsBackup = SettingsBackup(backupFile, password);
    await settingsBackup.ready;
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    for (var pref in prefSet) {
      final currentValue = getPref(pref).get();
      settingsBackup.getPref(pref).set(currentValue);
    }
    await settingsBackup.save();
  }

  Future<bool> restore(
    File backupFile,
    Set<PreferenceCategory> prefClasses,
    String? password,
  ) async {
    final settingsBackup = SettingsBackup(backupFile, password);
    await settingsBackup.ready;
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    try {
      await settingsBackup.load();
      for (var pref in prefSet) {
        final backupValue = settingsBackup.getPref(pref).get();
        final preference = getPref(pref);
        final fixedValue =
            await preference.fixValue?.call(backupValue) ?? backupValue;
        await preference.set(fixedValue);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreLegacy(
    File backupFile,
    Set<PreferenceCategory> prefClasses,
  ) async {
    try {
      var data = await backupFile.readAsString();
      legacyBackend = KeyValueStorage.withBackend(
        LegacyBackupPreferences(json.decode(data)),
      );
      await _migrateSettings(prefClasses);
      legacyBackend = KeyValueStorage();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> reset(Set<PreferenceCategory> prefClasses) async {
    final prefSet = PreferenceCategory.getPrefSet(prefClasses);
    for (var pref in prefSet) {
      getPref(pref).reset();
    }
    await _initDefaultSettings();
    await startWorkManager();
    await setThemes();
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
