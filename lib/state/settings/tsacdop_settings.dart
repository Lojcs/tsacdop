import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/l10n.dart';
import '../../local_storage/key_value_storage.dart';
import '../../type/requirement_combinator.dart';
import 'preference.dart';
import '../../search/search_api.dart';
import '../../search/search_web.dart';
import '../../type/media_control.dart';
import '../../type/playlist.dart';
import '../../type/tab_configuration.dart';
import '../../util/extension_helper.dart';
import '../../util/helpers.dart';
import '../../widgets/episodegrid.dart';

/// The settings keys of the app.
///
/// To add a new setting:
/// 1. Create a preference variable in [TsacdopSettings].
/// 2. Add it to the [TsacdopPreference] enum.
/// 3. Add it to the [getPref] function.
/// 4. Add it to a [PreferenceCategory].
abstract class TsacdopSettings<T extends SharedPreferencesWithCache> {
  /// Settings about settings.

  /// Version of the setting preferences schema.
  late final settingsVersion = IntPreference(
    backend,
    key: 'settingsVersion',
    defaultValue: 0,
  );

  /// Version of the setting preferences schema.
  late final settingsInitialized = BoolPreference(
    backend,
    key: 'settingsInitialized',
    defaultValue: false,
  );

  /// App use times.

  /// Last app use time. (Updated at each databse episode fetch)
  /// Does not notify when updated.
  late final lastUsedTime = DateTimePreference(
    backend,
    key: 'lastUsedMilliseconds',
    defaultValue: DateTime.now(),
  );

  /// Last sync time.
  late final lastSyncTime = DateTimePreference(
    backend,
    key: 'lastSyncMilliseconds',
    defaultValue: DateTime.fromMillisecondsSinceEpoch(0),
    updateCallback: settingsChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('refreshdate');
      return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
    },
  );

  /// General settings.

  /// Show app intro on launch.
  late final showIntro = BoolPreference(
    backend,
    key: 'showIntro',
    defaultValue: true,
    updateCallback: settingsChanged,
    getLegacy: () => legacyBackend.getBool('intro', reverse: true),
  );

  /// Locale override.
  /// Stores either null, or the locale to override the device local with.
  late final localeOverride = StringProxyPreference<Locale?>(
    backend,
    key: 'localeOverride',
    defaultValue: null,
    updateCallback: settingsChanged,
    serialize: (value) => switch (value) {
      null => "",
      Locale(:String languageCode, scriptCode: null) => languageCode,
      Locale(:String languageCode, :String scriptCode) =>
        "${languageCode}_$scriptCode",
    },
    deserialize: (serial) {
      var splt = serial.split("_");
      return switch (splt) {
        [""] => null,
        [var languageCode] => Locale(languageCode),
        [var languageCode, var scriptCode] => Locale.fromSubtags(
          languageCode: languageCode,
          scriptCode: scriptCode,
        ),
        _ => Locale("en"),
      };
    },
    getLegacy: () async =>
        switch (await legacyBackend.getStringList('localeKey')) {
          [] => null,
          [""] => null,
          [var languageCode] => Locale(languageCode),
          [var languageCode, var scriptCode] => Locale.fromSubtags(
            languageCode: languageCode,
            scriptCode: scriptCode,
          ),
          _ => Locale("en"),
        },
  );

  /// Look and feel settings.

  /// Theme mode (brightness).
  late final themeMode = IntProxyPreference<ThemeMode>(
    backend,
    key: 'themeMode',
    defaultValue: ThemeMode.system,
    updateCallback: settingsChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('theme');
      return value == null ? null : ThemeMode.values[value];
    },
    serialize: (value) => value.index,
    deserialize: (serial) => ThemeMode.values[serial],
  );

  /// Enable true black mode when [themeMode] is dark.
  late final trueBlack = BoolPreference(
    backend,
    key: 'trueBlack',
    defaultValue: false,
    updateCallback: settingsChanged,
    getLegacy: () => legacyBackend.getBool('realDark'),
  );

  /// Theme accent color.
  late final accentColor = StringProxyPreference<Color>(
    backend,
    key: 'accentColor',
    defaultValue: Colors.teal,
    updateCallback: themesChanged,
    getLegacy: () async =>
        (await legacyBackend.getString('accents'))?.toargbColor(),
    serialize: (value) => value.toargbString(),
    deserialize: (serial) => serial.toargbColor(),
  );

  /// Use the accent color provided by the system.
  late final useSystemAccentColor = BoolPreference(
    backend,
    key: 'useSystemAccentColor',
    defaultValue: false,
    updateCallback: settingsChanged,
    getLegacy: () => legacyBackend.getBool('useWallpaperThemeKet'),
  );

  /// Font style of the shownotes.
  late final showNotesFont = StringProxyPreference<TextStyle>(
    backend,
    key: 'showNotesFont',
    defaultValue: GoogleFonts.getFont("Martel"),
    updateCallback: settingsChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('showNotesFontKey');
      return switch (value) {
        0 => TextStyle(),
        1 => GoogleFonts.getFont("Martel"),
        2 => GoogleFonts.getFont("Bitter"),
        _ => null,
      };
    },
    serialize: (value) => (value.fontFamily ?? "null").split("_").first,
    deserialize: (serial) =>
        serial == "null" ? TextStyle() : GoogleFonts.getFont(serial),
  );

  /// Strength of haptic feedback.
  /// Used as intensity = baseIntensity * 2 ** (strength / 2)
  late final hapticsStrength = IntPreference(
    backend,
    key: 'hapticsStrength',
    defaultValue: 0,
    updateCallback: settingsChanged,
    getLegacy: () => legacyBackend.getInt('hapticsStrengthKey'),
  );

  /// Interface settings.

  /// Layout of the audio notification.
  late final notificationLayout =
      StringListProxyPreference<List<TsacdopMediaControl>>(
        backend,
        key: 'notificationLayout',
        defaultValue: [
          StopControl(),
          RewindControl(),
          SkipToNextControl(),
          FastForwardControl(),
        ],
        updateCallback: settingsChanged,
        serialize: (value) => value.map((e) => e.serial).toList(),
        deserialize: (serial) =>
            serial.map((e) => TsacdopMediaControl.fromSerial(e)).toList(),
        getLegacy: () async =>
            switch (await legacyBackend.getInt('notificationLayoutKey')) {
              0 => [
                StopControl(),
                FastForwardControl(),
                SkipToNextControl(),
                NoneControl(),
              ],
              1 => [
                StopControl(),
                RewindControl(),
                SkipToNextControl(),
                NoneControl(),
              ],
              2 => [
                StopControl(),
                RewindControl(),
                FastForwardControl(),
                NoneControl(),
              ],
              _ => null,
            },
      );

  /// Default search mode.
  /// Stored as string in case more is added.
  late final searchMode = StringProxyPreference<bool>(
    backend,
    key: 'searchMode',
    defaultValue: false,
    updateCallback: settingsChanged,
    serialize: (value) => value ? "web" : "api",
    deserialize: (serial) => serial == "web",
  );

  /// Api to use with api search.
  late final searchApi = StringProxyPreference<SearchApi>(
    backend,
    key: 'searchApi',
    defaultValue: SearchApi.podcastIndex,
    updateCallback: settingsChanged,
    serialize: (value) => value.serial,
    deserialize: (serial) => SearchApi.fromSerial(serial),
  );

  /// Engine to use with web search.
  late final searchEngine = StringProxyPreference<SearchEngine>(
    backend,
    key: 'searchEngine',
    defaultValue: SearchEngine.ecosia,
    updateCallback: settingsChanged,
    serialize: (value) => value.serial,
    deserialize: (serial) => SearchEngine.fromSerial(serial),
  );

  /// Podcasts screen action bar configuration.
  late final actionBarPodcasts = StringProxyPreference<ActionBarConfiguration>(
    backend,
    key: 'actionBarPodcasts',
    defaultValue: ActionBarConfiguration(),
    updateCallback: settingsChanged,
    serialize: (value) => value.toSerial(),
    deserialize: (serial) => ActionBarConfiguration.fromSerial(serial),
    getLegacy: () async {
      final index = await legacyBackend.getInt('podcastLayoutKey');
      final hideListened = await legacyBackend.getBool('hideListenedKey');
      return index == null || hideListened == null
          ? null
          : ActionBarConfiguration(
              layout: EpisodeGridLayout.values[index],
              filterPlayed: hideListened ? false : null,
            );
    },
  );

  /// Android auto filters configuration.
  late final actionBarAndroidAuto =
      StringProxyPreference<ActionBarConfiguration>(
        backend,
        key: 'actionBarAndroidAuto',
        defaultValue: ActionBarConfiguration(),
        updateCallback: settingsChanged,
        serialize: (value) => value.toSerial(),
        deserialize: (serial) => ActionBarConfiguration.fromSerial(serial),
        getLegacy: () async {
          final hideListened = await legacyBackend.getBool('hideListenedKey');
          return hideListened == null
              ? null
              : ActionBarConfiguration(
                  filterPlayed: hideListened ? false : null,
                );
        },
      );

  /// Configuration of home tabs.
  late final homeTabs = StringListProxyPreference<List<HomeTabConfiguration>>(
    backend,
    key: 'homeTabs',
    defaultValue: [
      HomeTabConfiguration(
        name: S.current.homeTabMenuRecent,
        actionBarConfiguration: ActionBarConfiguration(),
      ),
    ],
    updateCallback: settingsChanged,
    serialize: (value) => value.map((e) => e.toSerial()).toList(),
    deserialize: (serial) =>
        serial.map((e) => HomeTabConfiguration.fromSerial(e)).toList(),
    getLegacy: () async {
      final s = S.current;
      final recentIndex = await legacyBackend.getInt('recentLayoutKey');
      final hideListened = await legacyBackend.getBool('hideListenedKey');
      final favIndex = await legacyBackend.getInt('favLayoutKey');
      final downloadIndex = await legacyBackend.getInt('downloadLayoutKey');
      return recentIndex == null ||
              hideListened == null ||
              favIndex == null ||
              downloadIndex == null
          ? null
          : [
              HomeTabConfiguration(
                name: s.homeTabMenuRecent,
                actionBarConfiguration: ActionBarConfiguration(
                  filterPlayed: hideListened ? false : null,
                  layout: EpisodeGridLayout.values[recentIndex],
                ),
              ),
              HomeTabConfiguration(
                name: s.homeTabMenuFavotite,
                actionBarConfiguration: ActionBarConfiguration(
                  filterPlayed: hideListened ? false : null,
                  layout: EpisodeGridLayout.values[favIndex],
                ),
              ),
              HomeTabConfiguration(
                name: s.download,
                actionBarConfiguration: ActionBarConfiguration(
                  filterPlayed: hideListened ? false : null,
                  layout: EpisodeGridLayout.values[downloadIndex],
                ),
              ),
            ];
    },
  );

  /// Playback settings.

  /// Auto play next episode in a playlist.
  late final autoPlay = BoolPreference(
    backend,
    key: 'autoPlay',
    defaultValue: true,
    updateCallback: playbackChanged,
    getLegacy: () => legacyBackend.getBool('autoPlay', reverse: true),
  );

  /// Auto play next episode in a playlist.
  late final markPlayedWhenSkipped = BoolPreference(
    backend,
    key: 'markPlayedWhenSkipped',
    defaultValue: false,
    updateCallback: playbackChanged,
    getLegacy: () => legacyBackend.getBool('markListenedAfterSkipKey'),
  );

  /// Fast forward interval.
  late final fastForwardInterval = DurationPreference(
    backend,
    key: 'fastForwardMilliseconds',
    defaultValue: Duration(seconds: 30),
    updateCallback: playbackChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('fastForwardSecondsKey');
      return value == null ? null : Duration(seconds: value);
    },
  );

  /// Rewind interval.
  late final rewindInterval = DurationPreference(
    backend,
    key: 'rewindMilliseconds',
    defaultValue: Duration(seconds: 10),
    updateCallback: playbackChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('rewindSecondsKey');
      return value == null ? null : Duration(seconds: value);
    },
  );

  /// Skip silence enabled.
  late final skipSilence = BoolPreference(
    backend,
    key: 'skipSilence',
    defaultValue: false,
    updateCallback: playbackChanged,
    getLegacy: () async => await legacyBackend.getBool('skipSilenceKey'),
  );

  /// Volume boost enabled.
  late final volumeBoost = BoolPreference(
    backend,
    key: 'volumeBoost',
    defaultValue: false,
    updateCallback: playbackChanged,
    getLegacy: () async => await legacyBackend.getBool('boostVolumeKey'),
  );

  /// Volume boost decibels.
  late final volumeBoostDecibels = DoublePreference(
    backend,
    key: 'volumeBoostDecibels',
    defaultValue: 1.5,
    updateCallback: playbackChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('volumeGainKey');
      return value == null ? null : value / 2000;
    },
  );

  /// Speed to play audio.
  late final audioSpeedRatio = DoublePreference(
    backend,
    key: 'audioSpeedRatio',
    defaultValue: 1.0,
    updateCallback: playbackChanged,
    getLegacy: () async => await legacyBackend.getDouble('speedKey'),
  );

  /// Sleep timer settings.

  /// Auto enable sleep timer according to schedule.
  late final sleepTimerAuto = BoolPreference(
    backend,
    key: 'sleepTimerAuto',
    defaultValue: false,
    updateCallback: settingsChanged,
    getLegacy: () async => await legacyBackend.getBool('autoSleepTimerKey'),
  );

  /// Start of auto sleep timer schedule period.
  late final sleepTimerScheduleStart = TimeOfDayPreference(
    backend,
    key: 'sleepTimerScheduleStartMinutes',
    defaultValue: TimeOfDay(hour: 23, minute: 0),
    updateCallback: settingsChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('autoSleepTimerStartKey');
      return value == null ? null : minutesToTimeOfDay(value);
    },
  );

  /// End of auto sleep timer schedule period.
  late final sleepTimerScheduleEnd = TimeOfDayPreference(
    backend,
    key: 'sleepTimerScheduleEndMinutes',
    defaultValue: TimeOfDay(hour: 6, minute: 0),
    updateCallback: settingsChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('autoSleepTimerEndKey');
      return value == null ? null : minutesToTimeOfDay(value);
    },
  );

  /// Wait for playing episode to end to stop playback when sleep timer expires.
  late final sleepTimerWaitEpisodeEnd = BoolPreference(
    backend,
    key: 'sleepTimerWaitEpisodeEnd',
    defaultValue: false,
    updateCallback: settingsChanged,
    getLegacy: () async =>
        (await legacyBackend.getInt('autoSleepTimerModeKey')) == 0,
  );

  /// Default sleep timer wait interval and the interval used for auto sleep timer.
  late final sleepTimerInterval = DurationPreference(
    backend,
    key: 'sleepTimerMilliseconds',
    defaultValue: Duration(minutes: 30),
    updateCallback: settingsChanged,
    getLegacy: () async {
      final mode = await legacyBackend.getInt('autoSleepTimerModeKey');
      if (mode == null) return null;
      if (mode == 1) {
        final value = await legacyBackend.getInt('defaultSleepTimerKey');
        return value == null ? null : Duration(minutes: value);
      } else {
        return Duration.zero;
      }
    },
  );

  /// Player state.

  /// Id of the currently playing playlist.
  late final currentPlaylistId = StringPreference(
    backend,
    key: 'currentPlaylistId',
    defaultValue: mainQueueId,
    getLegacy: () async =>
        (await legacyBackend.getPlayerState('playerStateKey')).$1,
  );

  /// Index of the current episode in playlist.
  late final currentEpisodeIndex = IntPreference(
    backend,
    key: 'currentEpisodeIndex',
    defaultValue: 0,
    getLegacy: () async =>
        (await legacyBackend.getPlayerState('playerStateKey')).$2,
  );

  /// Position of the playback in the current episode.
  late final currentPosition = DurationPreference(
    backend,
    key: 'currentPositionMilliseconds',
    defaultValue: Duration.zero,
    getLegacy: () async => Duration(
      milliseconds: (await legacyBackend.getPlayerState('playerStateKey')).$3,
    ),
  );

  /// Sync settings.

  /// Auto sync podcasts.
  late final autoSync = BoolPreference(
    backend,
    key: 'autoSyncEnabled',
    defaultValue: true,
    updateCallback: syncChanged,
    getLegacy: () => legacyBackend.getBool('autoAdd', reverse: true),
  );

  /// Auto sync podcasts interval.
  late final autoSyncInterval = DurationPreference(
    backend,
    key: 'autoSyncIntervalMilliseconds',
    defaultValue: Duration(days: 1),
    updateCallback: syncChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('updateInterval');
      return value == null ? null : Duration(hours: value);
    },
  );

  /// New episodes (syncing)

  /// Allow duplicate episodes to be marked as new.
  late final markNewAllowDuplicate = BoolPreference(
    backend,
    key: 'markNewAllowDuplicate',
    defaultValue: false,
    updateCallback: settingsChanged,
  );

  /// Allow episodes of a newly subscribed podcast to be marked as new.
  late final markNewAllowNewSubscription = BoolPreference(
    backend,
    key: 'markNewAllowNewSubscription',
    defaultValue: false,
    updateCallback: settingsChanged,
  );

  /// The combinator used to combine mark new requirements.
  late final markNewRequirementCombinator =
      StringProxyPreference<RequirementCombinator>(
        backend,
        key: 'markNewRequirementCombinator',
        defaultValue: RequirementCombinator.any,
        updateCallback: settingsChanged,
        serialize: (value) => value.serial,
        deserialize: (serial) => RequirementCombinator.fromSerial(serial),
      );

  /// Mark episode as new if it is not in the database.
  late final markNewRequireUnseen = BoolPreference(
    backend,
    key: 'markNewRequireUnseen',
    defaultValue: true,
    updateCallback: settingsChanged,
  );

  /// Mark episode as new if its publish date is at most this long ago.
  late final markNewRequireAgeMax = DurationPreference(
    backend,
    key: 'markNewRequireAgeMaxMilliseconds',
    defaultValue: Duration.zero,
    updateCallback: settingsChanged,
  );

  /// Wait until syncing to remove the new mark from episodes.
  late final unmarkNewWaitForSync = BoolPreference(
    backend,
    key: 'unmarkNewWaitForSync',
    defaultValue: true,
    updateCallback: settingsChanged,
  );

  /// The combinator used to combine remove new mark requirements.
  late final unmarkNewRequirementCombinator =
      StringProxyPreference<RequirementCombinator>(
        backend,
        key: 'unmarkNewRequirementCombinator',
        defaultValue: RequirementCombinator.any,
        updateCallback: settingsChanged,
        serialize: (value) => value.serial,
        deserialize: (serial) => RequirementCombinator.fromSerial(serial),
      );

  /// Remove the new mark if the episode details were opened or the episode is selected.
  late final unmarkNewRequireInteracted = BoolPreference(
    backend,
    key: 'unmarkNewRequireInteracted',
    defaultValue: false,
    updateCallback: settingsChanged,
  );

  /// Remove the new mark if the episode was plaged.
  late final unmarkNewRequirePlayed = BoolPreference(
    backend,
    key: 'unmarkNewRequirePlayed',
    defaultValue: true,
    updateCallback: settingsChanged,
  );

  /// Remove the new mark if its publish date is at least this long ago.
  late final unmarkNewRequireAgeMin = DurationPreference(
    backend,
    key: 'unmarkNewRequireAgeMinMilliseconds',
    defaultValue: Duration(days: 3),
    updateCallback: settingsChanged,
  );

  /// Download settings.

  /// Auto download new episodes master switch.
  late final autoDownload = BoolPreference(
    backend,
    key: 'autoDownloadEnabled',
    defaultValue: true,
    updateCallback: settingsChanged,
  );

  /// Default value of the downloadStoragePath, initialized during app start.
  String defaultDownloadStoragePath = "unset_sentinel";

  /// Path of downloads storage directory.
  late final downloadStoragePath = StringPreference(
    backend,
    key: 'downloadStoragePath',
    defaultValue: defaultDownloadStoragePath,
    updateCallback: settingsChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('downloadPositionKey');
      return value == null
          ? null
          : (await getExternalStorageDirectories())![value].path;
    },
  );

  /// Network connections on which downloads are forbidden.
  late final forbiddenDownloadConnections =
      StringListProxyPreference<Set<ConnectivityResult>>(
        backend,
        key: 'forbiddenDownloadConnections',
        defaultValue: {ConnectivityResult.mobile},
        updateCallback: settingsChanged,
        serialize: (value) => value.map(resultToString).toList(),
        deserialize: (serial) => serial.map(stringToResult).toSet(),
      );

  /// Auto download new episodes even on mobile data.
  /// If false the downloads are started and paused.
  late final autoDownloadOnForbidden = BoolPreference(
    backend,
    key: 'autoDownloadOnForbidden',
    defaultValue: false,
    updateCallback: settingsChanged,
    getLegacy: () => legacyBackend.getBool('autoDownloadNetwork'),
  );

  /// Pause downloads when mobile data connection starts (wifi is lost).
  /// Resume paused downloads when it ends.
  late final pauseDownloadOnForbiddenConnected = BoolPreference(
    backend,
    key: 'pauseDownloadOnForbiddenConnected',
    defaultValue: true,
    updateCallback: settingsChanged,
  );

  /// Show warning when manually starting downloads with no wifi.
  late final downloadAskOnForbidden = BoolPreference(
    backend,
    key: 'manualDownloadAskOnForbidden',
    defaultValue: true,
    updateCallback: settingsChanged,
    getLegacy: () => legacyBackend.getBool('downloadUsingData', reverse: true),
  );

  /// Delete downloads after they are played. (during cleanup)
  late final autoDeleteAfterPlayed = BoolPreference(
    backend,
    key: 'autoDeleteAfterPlayed',
    defaultValue: true,
    updateCallback: settingsChanged,
    getLegacy: () => legacyBackend.getBool('removeAfterPlayedKey'),
  );

  /// Delete downloads after specified amount of time passes. (during cleanup)
  /// 0 disables.
  late final autoDeleteAfterTime = DurationPreference(
    backend,
    key: 'autoDeleteAfterMilliseconds',
    defaultValue: Duration(days: 30),
    updateCallback: settingsChanged,
    getLegacy: () async {
      final value = await legacyBackend.getInt('autoDeleteKey');
      return value == null ? null : Duration(days: value);
    },
  );

  /// Delete oldest downloads if downloads directory is bigger than this. (during cleanup)
  /// 0 disables.
  late final autoDeleteOldestIfTotalAbove = IntPreference(
    backend,
    key: 'autoDeleteOldestIfTotalAboveBytes',
    defaultValue: 1048576 * 1024 * 16, // 16 GiB
    updateCallback: settingsChanged,
  );

  /// Prefs instance to use.
  late final T backend;

  /// Backend to retrieve legacy values from.
  KeyValueStorage legacyBackend;

  /// Do not forget to wait for [ready] before use.
  TsacdopSettings() : legacyBackend = KeyValueStorage() {
    ready = init();
  }

  /// Await to ensure the instance is ready to use.
  late Future<void> ready;

  /// Do not call. Allows async operations when initializing.
  Future<void> init();

  /// Called when generic settings change.
  void settingsChanged();

  /// Called when theme parameters change. Not called when theme mode changes.
  void themesChanged();

  /// Called when sync settings change.
  void syncChanged();

  /// Called when playback settings change.
  void playbackChanged();

  Pref getPref(TsacdopPreference tsacdopPreference) =>
      switch (tsacdopPreference) {
        .settingsVersion => settingsVersion,
        .settingsInitialized => settingsInitialized,
        .lastUsedTime => lastUsedTime,
        .lastSyncTime => lastSyncTime,
        .showIntro => showIntro,
        .localeOverride => localeOverride,
        .themeMode => themeMode,
        .trueBlack => trueBlack,
        .accentColor => accentColor,
        .useSystemAccentColor => useSystemAccentColor,
        .showNotesFont => showNotesFont,
        .hapticsStrength => hapticsStrength,
        .notificationLayout => notificationLayout,
        .searchMode => searchMode,
        .searchApi => searchApi,
        .searchEngine => searchEngine,
        .actionBarPodcasts => actionBarPodcasts,
        .actionBarAndroidAuto => actionBarAndroidAuto,
        .homeTabs => homeTabs,
        .autoPlay => autoPlay,
        .markPlayedWhenSkipped => markPlayedWhenSkipped,
        .fastForwardInterval => fastForwardInterval,
        .rewindInterval => rewindInterval,
        .skipSilence => skipSilence,
        .volumeBoost => volumeBoost,
        .volumeBoostDecibels => volumeBoostDecibels,
        .audioSpeedRatio => audioSpeedRatio,
        .sleepTimerAuto => sleepTimerAuto,
        .sleepTimerScheduleStart => sleepTimerScheduleStart,
        .sleepTimerScheduleEnd => sleepTimerScheduleEnd,
        .sleepTimerWaitEpisodeEnd => sleepTimerWaitEpisodeEnd,
        .sleepTimerInterval => sleepTimerInterval,
        .currentPlaylistId => currentPlaylistId,
        .currentEpisodeIndex => currentEpisodeIndex,
        .currentPosition => currentPosition,
        .autoSync => autoSync,
        .autoSyncInterval => autoSyncInterval,
        .markNewAllowDuplicate => markNewAllowDuplicate,
        .markNewAllowNewSubscription => markNewAllowNewSubscription,
        .markNewRequirementCombinator => markNewRequirementCombinator,
        .markNewRequireUnseen => markNewRequireUnseen,
        .markNewRequireAgeMax => markNewRequireAgeMax,
        .unmarkNewWaitForSync => unmarkNewWaitForSync,
        .unmarkNewRequirementCombinator => unmarkNewRequirementCombinator,
        .unmarkNewRequireInteracted => unmarkNewRequireInteracted,
        .unmarkNewRequirePlayed => unmarkNewRequirePlayed,
        .unmarkNewRequireAgeMin => unmarkNewRequireAgeMin,
        .autoDownload => autoDownload,
        .downloadStoragePath => downloadStoragePath,
        .forbiddenDownloadConnections => forbiddenDownloadConnections,
        .autoDownloadOnForbidden => autoDownloadOnForbidden,
        .pauseDownloadOnForbiddenConnected => pauseDownloadOnForbiddenConnected,
        .downloadAskOnForbidden => downloadAskOnForbidden,
        .autoDeleteAfterPlayed => autoDeleteAfterPlayed,
        .autoDeleteAfterTime => autoDeleteAfterTime,
        .autoDeleteOldestIfTotalAbove => autoDeleteOldestIfTotalAbove,
      };
}

enum TsacdopPreference {
  settingsVersion,
  settingsInitialized,
  lastUsedTime,
  lastSyncTime,
  showIntro,
  localeOverride,
  themeMode,
  trueBlack,
  accentColor,
  useSystemAccentColor,
  showNotesFont,
  hapticsStrength,
  notificationLayout,
  searchMode,
  searchApi,
  searchEngine,
  actionBarPodcasts,
  actionBarAndroidAuto,
  homeTabs,
  autoPlay,
  markPlayedWhenSkipped,
  fastForwardInterval,
  rewindInterval,
  skipSilence,
  volumeBoost,
  volumeBoostDecibels,
  audioSpeedRatio,
  sleepTimerAuto,
  sleepTimerScheduleStart,
  sleepTimerScheduleEnd,
  sleepTimerWaitEpisodeEnd,
  sleepTimerInterval,
  currentPlaylistId,
  currentEpisodeIndex,
  currentPosition,
  autoSync,
  autoSyncInterval,
  markNewAllowDuplicate,
  markNewAllowNewSubscription,
  markNewRequirementCombinator,
  markNewRequireUnseen,
  markNewRequireAgeMax,
  unmarkNewWaitForSync,
  unmarkNewRequirementCombinator,
  unmarkNewRequireInteracted,
  unmarkNewRequirePlayed,
  unmarkNewRequireAgeMin,
  autoDownload,
  downloadStoragePath,
  forbiddenDownloadConnections,
  autoDownloadOnForbidden,
  pauseDownloadOnForbiddenConnected,
  downloadAskOnForbidden,
  autoDeleteAfterPlayed,
  autoDeleteAfterTime,
  autoDeleteOldestIfTotalAbove,
}

enum PreferenceCategory {
  meta([.settingsVersion, .settingsInitialized]),
  times([.lastUsedTime, .lastSyncTime]),
  general([.showIntro, .localeOverride]),
  lookAndFeel([
    .themeMode,
    .trueBlack,
    .accentColor,
    .useSystemAccentColor,
    .showNotesFont,
    .hapticsStrength,
  ]),
  interface([
    .notificationLayout,
    .searchMode,
    .searchApi,
    .searchEngine,
    .actionBarPodcasts,
    .actionBarAndroidAuto,
    .homeTabs,
  ]),
  playback([
    .autoPlay,
    .markPlayedWhenSkipped,
    .fastForwardInterval,
    .rewindInterval,
    .skipSilence,
    .volumeBoost,
    .volumeBoostDecibels,
    .audioSpeedRatio,
  ]),
  sleepTimer([
    .sleepTimerAuto,
    .sleepTimerScheduleStart,
    .sleepTimerScheduleEnd,
    .sleepTimerWaitEpisodeEnd,
    .sleepTimerInterval,
  ]),
  playerState([.currentPlaylistId, .currentEpisodeIndex, .currentPosition]),
  sync([
    .autoSync,
    .autoSyncInterval,
    .markNewAllowDuplicate,
    .markNewAllowNewSubscription,
    .markNewRequirementCombinator,
    .markNewRequireUnseen,
    .markNewRequireAgeMax,
    .unmarkNewWaitForSync,
    .unmarkNewRequirementCombinator,
    .unmarkNewRequireInteracted,
    .unmarkNewRequirePlayed,
    .unmarkNewRequireAgeMin,
  ]),
  download([
    .autoDownload,
    .downloadStoragePath,
    .forbiddenDownloadConnections,
    .autoDownloadOnForbidden,
    .pauseDownloadOnForbiddenConnected,
    .downloadAskOnForbidden,
    .autoDeleteAfterPlayed,
    .autoDeleteAfterTime,
    .autoDeleteOldestIfTotalAbove,
  ]);

  const PreferenceCategory(this.preferences);

  final List<TsacdopPreference> preferences;

  static List<TsacdopPreference> getPrefSet(
    Set<PreferenceCategory> prefClasses,
  ) => prefClasses.expand((e) => e.preferences).toList();

  static List<TsacdopPreference> allPrefs() =>
      getPrefSet(PreferenceCategory.values.toSet());
}
