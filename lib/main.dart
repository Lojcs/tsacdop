import 'package:dynamic_color/dynamic_color.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state/episode_state.dart';
import 'package:tuple/tuple.dart';

import 'generated/l10n.dart';
import 'home/home.dart';
import 'intro_slider/app_intro.dart';
import 'playlists/playlist_home.dart';
import 'state/audio_state.dart';
import 'state/download_state.dart';
import 'state/podcast_group.dart';
import 'state/refresh_podcast.dart';
import 'state/setting_state.dart';
import 'type/theme_data.dart';

///Initial theme settings
final SettingState themeSetting = SettingState();
Future main() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  timeDilation = 1.0;
  WidgetsFlutterBinding.ensureInitialized();
  await themeSetting.initData();
  await FlutterDownloader.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeSetting),
        ChangeNotifierProvider(create: (_) => EpisodeState()),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => AudioPlayerNotifier(context),
        ),
        ChangeNotifierProvider(create: (_) => GroupList()),
        ChangeNotifierProvider(create: (_) => RefreshWorker()),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => DownloadState(context),
        )
      ],
      child: MyApp(),
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  // await SystemChrome.setPreferredOrientations(
  //     [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<SettingState>(context, listen: false).context = context;
    Provider.of<EpisodeState>(context, listen: false).context = context;
    return Selector<SettingState,
        Tuple4<ThemeMode?, ThemeData, ThemeData, bool?>>(
      selector: (_, setting) => Tuple4(setting.theme, setting.lightTheme,
          setting.darkTheme, setting.useWallpaperTheme),
      builder: (_, data, child) {
        return FeatureDiscovery(
          child: DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
            final lightTheme = data.item4! && lightDynamic != null
                ? data.item2.copyWith(colorScheme: lightDynamic, extensions: [
                    ActionBarTheme(
                      iconColor: Colors.grey[800],
                      size: 24,
                      radius: const Radius.circular(16),
                      padding: const EdgeInsets.all(6),
                    ),
                    CardColorScheme(lightDynamic),
                  ])
                : data.item2;
            final darkTheme = data.item4! && darkDynamic != null
                ? data.item3.copyWith(
                    colorScheme: darkDynamic.copyWith(
                      surface: Provider.of<SettingState>(context, listen: false)
                              .realDark!
                          ? Colors.black
                          : null,
                    ),
                    extensions: [
                        ActionBarTheme(
                          iconColor: Colors.grey[200],
                          size: 24,
                          radius: const Radius.circular(16),
                          padding: const EdgeInsets.all(6),
                        ),
                        CardColorScheme(darkDynamic),
                      ])
                : data.item3;
            return MaterialApp(
              themeMode: data.item1,
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
              supportedLocales: S.delegate.supportedLocales,
              home: context.read<SettingState>().showIntro!
                  ? SlideIntro(goto: Goto.home)
                  : context.read<SettingState>().openPlaylistDefault!
                      ? PlaylistHome()
                      : Home(),
            );
          }),
        );
      },
    );
  }
}
