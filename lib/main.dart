import 'package:dynamic_color/dynamic_color.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'intro_slider/app_intro.dart';
import 'state/episode_state.dart';

import 'generated/l10n.dart';
import 'home/home.dart';
import 'state/audio_state.dart';
import 'state/download_state.dart';
import 'state/podcast_state.dart';
import 'state/settings/setting_state.dart';
import 'type/playlist.dart';
import 'type/theme_data.dart';
import 'util/extension_helper.dart';

Future main() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  timeDilation = 1.0;
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingState();
  await settings.ready;

  final documents = await getApplicationDocumentsDirectory();
  final podcastState = PodcastState(documents);
  await podcastState.ready;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => EpisodeState()),
        ChangeNotifierProvider.value(value: podcastState),
        ChangeNotifierProvider(
          lazy: false, // TODO: Check if these are actually needed.
          create: (_) => DownloadState(),
        ),
        ChangeNotifierProvider(lazy: false, create: (_) => AudioState()),
      ],
      child: MyApp(),
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  // await SystemChrome.setPreferredOrientations(
  //     [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // These are to allow access to other state objects.
    // They are assigned here instead of at construction to allow quick reloading. // TODO: Is that really true?
    context.episodeState.context = context;
    context.podcastState.context = context;
    context.downloadState.context = context;
    context.audioState.context = context;
    final browsableLibrary = BrowsableLibrary(context);
    context.audioState.browsableLibrary = browsableLibrary;
    return Selector<
      SettingState,
      ({
        Locale? localeOverride,
        ThemeMode themeMode,
        bool useSystemAccent,
        bool trueBlack,
        ThemeData lightTheme,
        ThemeData darkTheme,
        ThemeData blackTheme,
      })
    >(
      selector: (_, setting) => (
        localeOverride: setting.localeOverride.get(),
        themeMode: setting.themeMode.get(),
        useSystemAccent: setting.useSystemAccentColor.get(),
        trueBlack: setting.trueBlack.get(),
        lightTheme: setting.lightTheme,
        darkTheme: setting.darkTheme,
        blackTheme: setting.blackTheme,
      ),
      builder: (context, data, _) {
        return FeatureDiscovery(
          child: DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              final lightTheme = data.useSystemAccent && lightDynamic != null
                  ? data.lightTheme.copyWith(
                      colorScheme: lightDynamic,
                      extensions: [
                        TsacdopTheme(TBrightness.light),
                        ActionBarTheme.light(),
                        CardColorScheme(lightDynamic, data.trueBlack),
                      ],
                    )
                  : data.lightTheme;
              var darkTheme = data.trueBlack ? data.blackTheme : data.darkTheme;
              darkTheme = data.useSystemAccent && darkDynamic != null
                  ? darkTheme.copyWith(
                      colorScheme: darkDynamic.copyWith(
                        surface: data.trueBlack ? Colors.black : null,
                      ),
                      extensions: [
                        TsacdopTheme(
                          data.trueBlack ? TBrightness.black : TBrightness.dark,
                        ),
                        ActionBarTheme.dark(),
                        CardColorScheme(darkDynamic, data.trueBlack),
                      ],
                    )
                  : darkTheme;
              return MaterialApp(
                themeMode: data.themeMode,
                debugShowCheckedModeBanner: false,
                title: 'Tsacdop',
                theme: lightTheme,
                darkTheme: darkTheme,
                localizationsDelegates: [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                locale: data.localeOverride,
                supportedLocales: S.delegate.supportedLocales,
                home: context.settingState.showIntro.get()
                    ? SlideIntro(goto: Goto.home)
                    : Home(),
              );
            },
          ),
        );
      },
    );
  }
}
