import 'dart:io';

import 'package:collection/collection.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart' hide NestedScrollView, showSearch;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../search/search_widgets.dart';
import '../type/tab_configuration.dart';
import '../util/selection_controller.dart';

import '../playlists/playlist_home.dart';
import '../state/audio_state.dart';
import '../state/settings/setting_state.dart';
import '../util/extension_helper.dart';
import '../widgets/audiopanel.dart';
import '../widgets/episodegrid.dart';
import '../widgets/feature_discovery.dart';
import '../widgets/multiselect_bar.dart';
import 'audioplayer.dart';
import 'download_list.dart';
import 'home_groups.dart';
import 'home_menu.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();
  final GlobalKey searchKey = GlobalKey();
  late TabController controller;

  final _androidAppRetain = MethodChannel("android_app_retain");
  var feature1OverflowMode = OverflowMode.clipContent;
  var feature1EnablePulsingAnimation = false;
  double top = 0;

  late List<HomeTabConfiguration> homeTabs = context.superSettingState.homeTabs
      .get();
  List<SelectionController>? selectionControllers;
  List<Key>? tabKeys;
  List<Widget>? headerSlivers;

  /// Checks if home tabs changed and if so updates them.
  /// This is done here and not in a selector as it changes more seldomly than
  /// most other things (like theme or audio player) and updating it causes visual
  /// disturbance.
  void updateTabs() {
    final newHomeTabs = context.superSettingState.homeTabs.get();
    if (!newHomeTabs.equals(homeTabs)) {
      homeTabs = newHomeTabs;
      final index = controller.index;
      controller.dispose();
      controller = TabController(length: homeTabs.length + 1, vsync: this);
      controller.index = index;
      headerSlivers = null;
      selectionControllers = null;
      tabKeys = null;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    context.superSettingState.addListener(updateTabs);
    controller = TabController(length: homeTabs.length + 1, vsync: this);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(context, const <String>{
        addFeature,
        menuFeature,
        playlistFeature,
        //groupsFeature,
        //podcastFeature,
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    context.superSettingState.removeListener(updateTabs);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Theme.of(context); // This fixes the color of the tab text.
    selectionControllers ??= List.generate(
      controller.length - 1,
      (_) => SelectionController(),
    );
    tabKeys ??= List.generate(controller.length - 1, (_) => UniqueKey());
    return Selector<AudioState, bool>(
      selector: (_, audio) => audio.playerRunning,
      builder: (context, playerRunning, _) {
        context.originalPadding = MediaQuery.of(context).padding;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: context.iconBrightness,
            systemNavigationBarIconBrightness: context.iconBrightness,
          ),
          child: PopScope(
            canPop:
                // !(_playerKey.currentState != null &&
                //     _playerKey.currentState!.size! > 100) &&
                !selectionControllers![controller.index].selectMode,
            onPopInvokedWithResult: (_, __) {
              if (_playerKey.currentState != null &&
                  _playerKey.currentState!.size! > 100) {
                _playerKey.currentState!.backToMini();
              } else if (selectionControllers![controller.index].selectMode) {
                selectionControllers![controller.index].selectMode = false;
              } else if (Platform.isAndroid) {
                // _androidAppRetain
                //     .invokeMethod('sendToBackground'); // This doesn't work
              }
            },
            child: Stack(
              children: <Widget>[
                Scaffold(
                  backgroundColor: context.surface,
                  body: SafeArea(
                    child: ExtendedNestedScrollView(
                      pinnedHeaderSliverHeightBuilder: () => 50,
                      // floatHeaderSlivers: true,
                      headerSliverBuilder: (context, innerBoxScrolled) {
                        // Otherwise this rebuilds every time inner box scrolls
                        headerSlivers ??= [
                          SliverToBoxAdapter(
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 50.0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      featureDiscoveryOverlay(
                                        context,
                                        featureId: addFeature,
                                        tapTarget: Icon(Icons.search),
                                        title: s.featureDiscoverySearch,
                                        backgroundColor: Colors.cyan[600],
                                        buttonColor: Colors.cyan[500],
                                        description:
                                            s.featureDiscoverySearchDes,
                                        child: SearchButton(searchKey),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          final settings =
                                              context.superSettingState;
                                          switch ((
                                            context.brightness,
                                            settings.trueBlack.get(),
                                          )) {
                                            case (Brightness.light, _):
                                              settings.themeMode.set(
                                                ThemeMode.dark,
                                              );
                                              settings.trueBlack.set(false);
                                            case (Brightness.dark, false):
                                              settings.trueBlack.set(true);
                                            case (Brightness.dark, true):
                                              settings.themeMode.set(
                                                ThemeMode.light,
                                              );
                                          }
                                        },
                                        child: Text(
                                          'Tsacdop',
                                          style: GoogleFonts.quicksand(
                                            color: context.primaryColor,
                                            textStyle:
                                                context.textTheme.headlineLarge,
                                          ),
                                        ),
                                      ),
                                      featureDiscoveryOverlay(
                                        context,
                                        featureId: menuFeature,
                                        tapTarget: Icon(Icons.more_vert),
                                        backgroundColor: Colors.cyan[500],
                                        buttonColor: Colors.cyan[600],
                                        title: s.featureDiscoveryOMPL,
                                        description: s.featureDiscoveryOMPLDes,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 5.0,
                                          ),
                                          child: HomeMenu(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // StatusBar(),
                              ],
                            ),
                          ),
                          SliverToBoxAdapter(child: ScrollPodcasts()),
                          Selector<SettingState, List<String>>(
                            selector: (_, settings) => settings.homeTabs
                                .get()
                                .map((t) => t.name)
                                .toList(),
                            builder: (context, value, _) => SliverToBoxAdapter(
                              child: Stack(
                                children: <Widget>[
                                  Padding(
                                    padding: .only(right: 32),
                                    child: TabBar(
                                      isScrollable: true,
                                      indicatorSize: TabBarIndicatorSize.label,
                                      controller: controller,
                                      labelStyle: context.textTheme.titleMedium,
                                      // labelColor: context.textColor,
                                      dividerHeight: 0,
                                      tabAlignment: TabAlignment.start,
                                      tabs:
                                          value
                                              .map((e) => Tab(text: e))
                                              .toList()
                                            ..add(Tab(text: s.downloading)),
                                    ),
                                  ),
                                  Align(
                                    alignment: .centerRight,
                                    child: featureDiscoveryOverlay(
                                      context,
                                      featureId: playlistFeature,
                                      tapTarget: Icon(Icons.playlist_play),
                                      backgroundColor: Colors.cyan[500],
                                      title: s.featureDiscoveryPlaylist,
                                      description:
                                          s.featureDiscoveryPlaylistDes,
                                      buttonColor: Colors.cyan[600],
                                      child: _PlaylistButton(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ];
                        return headerSlivers!;
                      },
                      body: TabBarView(
                        // TODO: Add pull to refresh?
                        controller: controller,
                        children:
                            homeTabs
                                .mapIndexed(
                                  (i, e) => KeyedSubtree(
                                    key: Key('tab$i'),
                                    child:
                                        ChangeNotifierProvider<
                                          SelectionController
                                        >.value(
                                          value: selectionControllers![i],
                                          child: _HomeTab(
                                            key: tabKeys![i],
                                            Stack(
                                              children: [
                                                InteractiveEpisodeGrid(
                                                  noEpisodesWidget:
                                                      _NoEpisodes(),
                                                  refreshNotifier:
                                                      context.podcastState,
                                                  openPodcast: true,
                                                  actionBarConfiguration:
                                                      e.actionBarConfiguration,
                                                ),
                                                MultiSelectPanelIntegration(),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ),
                                )
                                .toList()
                              ..add(
                                KeyedSubtree(
                                  key: Key('downloading'),
                                  child: _HomeTab(
                                    CustomScrollView(slivers: [DownloadList()]),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                PlayerWidget(playerKey: _playerKey),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatefulWidget {
  final Widget child;

  const _HomeTab(this.child, {super.key});
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with AutomaticKeepAliveClientMixin {
  //final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  //    GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class _NoEpisodes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          LineIcons.alternateCloudDownload,
          size: 80,
          color: Colors.grey[500],
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 10)),
        Text(
          context.s.noEpisodesFound,
          style: TextStyle(color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _PlaylistButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final audio = context.audioState;
    return ColoredBox(
      color: context.surface,
      child: PopupMenuButton<int>(
        menuPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        elevation: 1,
        icon: Icon(Icons.playlist_play, size: 24),
        tooltip: s.menu,
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints.tightFor(width: 160),
        itemBuilder: (context) => [
          if (!audio.playerRunning && audio.episodeBrief != null)
            PopupMenuItem(
              value: 1,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: <Widget>[
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: audio.episodeBrief!.avatarImage,
                    child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  Text(
                    (audio.historyPosition ~/ 1000).toTime,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    audio.episodeBrief!.title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          if (!audio.playerRunning && audio.episodeBrief != null)
            PopupMenuDivider(thickness: 1, height: 1),
          PopupMenuItem(
            value: 0,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Icon(Icons.playlist_play),
                SizedBox(width: 10),
                Text(s.homeMenuPlaylist),
              ],
            ),
          ),
          // PopupMenuItem(
          //   value: 2,
          //   child: Container(
          //     padding: EdgeInsets.only(left: 10),
          //     child: Row(
          //       children: <Widget>[
          //         Icon(Icons.history),
          //         Padding(
          //           padding: const EdgeInsets.symmetric(horizontal: 5.0),
          //         ),
          //         Text(s.settingsHistory),
          //       ],
          //     ),
          //   ),
          // ),
          // PopupMenuDivider(
          //   height: 1,
          // ),
        ],
        onSelected: (value) async {
          switch (value) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaylistHome()),
              );
            case 1:
              await audio.playFromLastPosition();
              await Navigator.maybePop<int>(context);
          }
        },
      ),
    );
  }
}
