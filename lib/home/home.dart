import 'dart:async';
import 'dart:io';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart' hide NestedScrollView, showSearch;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../local_storage/key_value_storage.dart';
import '../search/search_widgets.dart';
import '../util/selection_controller.dart';
import '../widgets/action_bar.dart';
import 'package:tuple/tuple.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../playlists/playlist_home.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../state/setting_state.dart';
import '../type/episodebrief.dart';
import '../util/extension_helper.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_popupmenu.dart';
import '../widgets/episodegrid.dart';
import '../widgets/feature_discovery.dart';
import '../widgets/multiselect_bar.dart';
import 'audioplayer.dart';
import 'download_list.dart';
import 'home_groups.dart';
import 'home_menu.dart';
import 'status_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();
  final GlobalKey searchKey = GlobalKey();
  late TabController _controller;
  Decoration _getIndicator(BuildContext context) {
    return UnderlineTabIndicator(
      borderSide: BorderSide(color: context.accentColor, width: 3),
    );
  }

  final _androidAppRetain = MethodChannel("android_app_retain");
  var feature1OverflowMode = OverflowMode.clipContent;
  var feature1EnablePulsingAnimation = false;
  double top = 0;

  final SelectionController _recentUpdateSelectionController =
      SelectionController();
  final SelectionController _myFavouriteSelectionController =
      SelectionController();
  final SelectionController _myDownloadedSelectionController =
      SelectionController();

  List<Widget>? headerSlivers;

  SelectionController _tabSelectionController(int i) => i == 0
      ? _recentUpdateSelectionController
      : i == 1
          ? _myFavouriteSelectionController
          : _myDownloadedSelectionController;

  @override
  void initState() {
    _controller = TabController(length: 3, vsync: this);
    //  FeatureDiscovery.hasPreviouslyCompleted(context, addFeature).then((value) {
    //   if (!value) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        const <String>{
          addFeature,
          menuFeature,
          playlistFeature,
          //groupsFeature,
          //podcastFeature,
        },
      );
    });
    //   }
    // });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = (context.width - 20) / 3 + 145;
    final settings = Provider.of<SettingState>(context, listen: false);
    final s = context.s;
    headerSlivers = null;
    return Selector<AudioPlayerNotifier, bool>(
        selector: (_, audio) => audio.playerRunning,
        builder: (_, playerRunning, __) {
          context.originalPadding = MediaQuery.of(context).padding;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: context.iconBrightness,
              systemNavigationBarColor:
                  playerRunning ? context.cardColorSchemeCard : context.surface,
              systemNavigationBarIconBrightness: context.iconBrightness,
            ),
            child: PopScope(
              canPop: !settings.openPlaylistDefault! &&
                  !(_playerKey.currentState != null &&
                      _playerKey.currentState!.size! > 100) &&
                  !_tabSelectionController(_controller.index).selectMode,
              onPopInvokedWithResult: (_, __) {
                if (_playerKey.currentState != null &&
                    _playerKey.currentState!.size! > 100) {
                  _playerKey.currentState!.backToMini();
                } else if (_tabSelectionController(_controller.index)
                    .selectMode) {
                  _tabSelectionController(_controller.index).selectMode = false;
                } else if (!settings.openPlaylistDefault! &&
                    Platform.isAndroid) {
                  // _androidAppRetain
                  //     .invokeMethod('sendToBackground'); // This doesn't work
                }
              },
              child: Scaffold(
                backgroundColor: context.surface,
                body: SafeArea(
                  // bottom: playerRunning,
                  child: Stack(children: <Widget>[
                    ExtendedNestedScrollView(
                      pinnedHeaderSliverHeightBuilder: () => 50,
                      // floatHeaderSlivers: true,
                      headerSliverBuilder: (context, innerBoxScrolled) {
                        // Otherwise this rebuilds every time inner bos scrolls
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
                                          if (context.brightness ==
                                              Brightness.light) {
                                            settings.setTheme = ThemeMode.dark;
                                            settings.setRealDark = false;
                                          } else if (settings.realDark!) {
                                            settings.setTheme = ThemeMode.light;
                                          } else {
                                            settings.setRealDark = true;
                                          }
                                        },
                                        child: Text(
                                          'Tsacdop',
                                          style: GoogleFonts.quicksand(
                                              color: context.accentColor,
                                              textStyle: context
                                                  .textTheme.headlineLarge),
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
                                          padding:
                                              const EdgeInsets.only(right: 5.0),
                                          child: PopupMenu(),
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
                          SliverPersistentHeader(
                            delegate: _SliverAppBarDelegate(
                              TabBar(
                                indicator: _getIndicator(context),
                                isScrollable: true,
                                indicatorSize: TabBarIndicatorSize.label,
                                controller: _controller,
                                labelStyle: context.textTheme.titleMedium,
                                // labelColor: context.textColor,
                                dividerHeight: 0,
                                tabAlignment: TabAlignment.start,
                                tabs: <Widget>[
                                  Tab(
                                    text: s.homeTabMenuRecent,
                                  ),
                                  Tab(
                                    text: s.homeTabMenuFavotite,
                                  ),
                                  Tab(
                                    text: s.download,
                                  )
                                ],
                              ),
                            ),
                            pinned: true,
                          ),
                        ];
                        return headerSlivers!;
                      },
                      body: TabBarView(
                        // TODO: Add pull to refresh?
                        controller: _controller,
                        children: <Widget>[
                          KeyedSubtree(
                            key: Key('tab0'),
                            child: ChangeNotifierProvider<
                                SelectionController>.value(
                              value: _recentUpdateSelectionController,
                              child: Stack(
                                children: [
                                  _RecentUpdate(),
                                  MultiSelectPanelIntegration(),
                                ],
                              ),
                            ),
                          ),
                          KeyedSubtree(
                            key: Key('tab1'),
                            child: ChangeNotifierProvider<
                                SelectionController>.value(
                              value: _myFavouriteSelectionController,
                              child: Stack(
                                children: [
                                  _MyFavorite(),
                                  MultiSelectPanelIntegration(),
                                ],
                              ),
                            ),
                          ),
                          KeyedSubtree(
                            key: Key('tab2'),
                            child: ChangeNotifierProvider<
                                SelectionController>.value(
                              value: _myDownloadedSelectionController,
                              child: Stack(
                                children: [
                                  _MyDownload(),
                                  MultiSelectPanelIntegration(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PlayerWidget(playerKey: _playerKey),
                  ]),
                ),
              ),
            ),
          );
        });
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final s = context.s;
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _tabBar,
              Spacer(),
              featureDiscoveryOverlay(context,
                  featureId: playlistFeature,
                  tapTarget: Icon(Icons.playlist_play),
                  backgroundColor: Colors.cyan[500],
                  title: s.featureDiscoveryPlaylist,
                  description: s.featureDiscoveryPlaylistDes,
                  buttonColor: Colors.cyan[600],
                  child: _PlaylistButton()),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
}

class _PlaylistButton extends StatefulWidget {
  const _PlaylistButton();

  @override
  __PlaylistButtonState createState() => __PlaylistButtonState();
}

class __PlaylistButtonState extends State<_PlaylistButton> {
  late bool _loadPlay;

  Future<void> _getPlaylist() async {
    if (mounted) setState(() => _loadPlay = true);
  }

  @override
  void initState() {
    super.initState();
    _loadPlay = false;
    _getPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final audio = context.read<AudioPlayerNotifier>();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.hardEdge,
      child: MyPopupMenuButton<int>(
        menuPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        elevation: 1,
        icon: Icon(Icons.playlist_play),
        color: context.cardColorSchemeCard,
        tooltip: s.menu,
        itemBuilder: (context) => [
          MyPopupMenuItem(
            height: 50,
            value: 1,
            child:
                Selector<AudioPlayerNotifier, Tuple3<bool, EpisodeBrief?, int>>(
              selector: (_, audio) => Tuple3(audio.playerRunning,
                  audio.episodeBrief, audio.historyPosition),
              builder: (_, data, __) => !_loadPlay ||
                      data.item1 ||
                      data.item2 == null
                  ? Center()
                  : InkWell(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.0),
                          topRight: Radius.circular(10.0)),
                      onTap: () async {
                        await audio.playFromLastPosition();
                        await Navigator.maybePop<int>(context);
                      },
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 5),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              CircleAvatar(
                                  radius: 20,
                                  backgroundImage: data.item2!.avatarImage),
                              Container(
                                height: 40.0,
                                width: 40.0,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black12),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                          ),
                          SizedBox(
                            height: 77,
                            width: 140,
                            child: Column(
                              children: <Widget>[
                                Text(
                                  (data.item3 ~/ 1000).toTime,
                                  style: TextStyle(color: context.textColor),
                                ),
                                Text(
                                  data.item2!.title,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: context.textColor),
                                  // style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          PopupMenuItem(
            value: 0,
            child: Container(
              padding: EdgeInsets.only(left: 10),
              child: Row(
                children: <Widget>[
                  Icon(Icons.playlist_play),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                  ),
                  Text(
                    s.homeMenuPlaylist,
                    style: TextStyle(color: context.textColor),
                  ),
                ],
              ),
            ),
          ),
          //PopupMenuDivider(
          //  height: 1,
          //),
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
        onSelected: (value) {
          if (value == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistHome(),
              ),
            );
          }
        },
      ),
    );
  }
}

class _RecentUpdate extends StatefulWidget {
  @override
  _RecentUpdateState createState() => _RecentUpdateState();
}

class _RecentUpdateState extends State<_RecentUpdate>
    with AutomaticKeepAliveClientMixin {
  //final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  //    GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InteractiveEpisodeGrid(
      noEpisodesWidget: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(LineIcons.alternateCloudDownload,
              size: 80, color: Colors.grey[500]),
          Padding(padding: EdgeInsets.symmetric(vertical: 10)),
          Text(
            context.s.noEpisodeRecent,
            style: TextStyle(color: Colors.grey[500]),
          )
        ],
      ),
      openPodcast: true,
      layoutKey: recentLayoutKey,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _MyFavorite extends StatefulWidget {
  @override
  _MyFavoriteState createState() => _MyFavoriteState();
}

class _MyFavoriteState extends State<_MyFavorite>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InteractiveEpisodeGrid(
      noEpisodesWidget: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(LineIcons.heartbeat, size: 80, color: Colors.grey[500]),
          Padding(padding: EdgeInsets.symmetric(vertical: 10)),
          Text(
            context.s.noEpisodeFavorite,
            style: TextStyle(color: Colors.grey[500]),
          )
        ],
      ),
      openPodcast: true,
      actionBarWidgetsFirstRow: const [
        ActionBarDropdownSortBy(0, 0),
        ActionBarSwitchSortOrder(0, 1),
        ActionBarDropdownGroups(0, 2),
        ActionBarSpacer(0, 3),
        ActionBarFilterLiked(0, 4),
        ActionBarSwitchLayout(0, 5),
        ActionBarSwitchSelectMode(0, 6),
      ],
      actionBarWidgetsSecondRow: [],
      actionBarSortByItems: const [
        Sorter.likedDate,
        Sorter.pubDate,
        Sorter.enclosureSize,
        Sorter.enclosureDuration
      ],
      actionBarSortBy: Sorter.likedDate,
      actionBarFilterLiked: true,
      actionBarFilterDisplayVersion: null,
      actionBarFilterPlayed: null,
      actionBarFilterPlayedOverride: true,
      layoutKey: favLayoutKey,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _MyDownload extends StatefulWidget {
  @override
  _MyDownloadState createState() => _MyDownloadState();
}

class _MyDownloadState extends State<_MyDownload>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InteractiveEpisodeGrid(
      additionalSliversList: [DownloadList()],
      sliverInsertIndicies: (
        actionBarIndex: 0,
        loadingIndicatorIndex: 1,
        gridIndex: 3
      ),
      noEpisodesWidget: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(LineIcons.download, size: 80, color: Colors.grey[500]),
          Padding(padding: EdgeInsets.symmetric(vertical: 10)),
          Text(
            context.s.noEpisodeDownload,
            style: TextStyle(color: Colors.grey[500]),
          )
        ],
      ),
      openPodcast: true,
      refreshNotifier: context.downloadState,
      actionBarWidgetsFirstRow: const [
        ActionBarDropdownSortBy(0, 0),
        ActionBarSwitchSortOrder(0, 1),
        ActionBarDropdownGroups(0, 2),
        ActionBarSpacer(0, 3),
        ActionBarFilterPlayed(0, 4),
        ActionBarFilterDownloaded(0, 5),
        ActionBarSwitchLayout(0, 6),
        ActionBarSwitchSelectMode(0, 7),
      ],
      actionBarWidgetsSecondRow: [],
      actionBarSortByItems: const [
        Sorter.downloadDate,
        Sorter.pubDate,
        Sorter.enclosureSize,
        Sorter.enclosureDuration
      ],
      actionBarSortBy: Sorter.downloadDate,
      actionBarFilterDownloaded: true,
      actionBarFilterDisplayVersion: null,
      actionBarFilterPlayed: null,
      actionBarFilterPlayedOverride: true,
      layoutKey: favLayoutKey,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
