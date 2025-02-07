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
import 'package:tsacdop/util/selection_controller.dart';
import 'package:tsacdop/widgets/action_bar.dart';
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
import '../widgets/custom_search_delegate.dart';
import '../widgets/custom_widget.dart';
import '../widgets/episodegrid.dart';
import '../widgets/feature_discovery.dart';
import '../widgets/multiselect_bar.dart';
import 'audioplayer.dart';
import 'download_list.dart';
import 'home_groups.dart';
import 'home_menu.dart';
import 'import_opml.dart';
import 'search_podcast.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();
  late TabController _controller;
  Decoration _getIndicator(BuildContext context) {
    return UnderlineTabIndicator(
        borderSide: BorderSide(color: context.accentColor, width: 3),
        insets: EdgeInsets.only(
          left: 10.0,
          right: 10.0,
        ));
  }

  final _androidAppRetain = MethodChannel("android_app_retain");
  var feature1OverflowMode = OverflowMode.clipContent;
  var feature1EnablePulsingAnimation = false;
  double top = 0;

  SelectionController _recentUpdateSelectionController = SelectionController();
  SelectionController _myFavouriteSelectionController = SelectionController();
  SelectionController _myDownloadedSelectionController = SelectionController();

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
    return Selector<AudioPlayerNotifier, bool>(
        selector: (_, audio) => audio.playerRunning,
        builder: (_, playerRunning, __) {
          context.originalPadding = MediaQuery.of(context).padding;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: playerRunning
                ? context.overlay.copyWith(
                    systemNavigationBarColor: context.cardColorSchemeCard)
                : context.overlay,
            child: PopScope(
              canPop: settings.openPlaylistDefault! &&
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
                  _androidAppRetain
                      .invokeMethod('sendToBackground'); // This doesn't work
                }
              },
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: context.surface,
                body: SafeArea(
                  bottom: playerRunning,
                  child: Stack(children: <Widget>[
                    ExtendedNestedScrollView(
                      pinnedHeaderSliverHeightBuilder: () => 50,
                      // floatHeaderSlivers: true,
                      headerSliverBuilder: (context, innerBoxScrolled) {
                        return <Widget>[
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
                                        tapTarget:
                                            Icon(Icons.add_circle_outline),
                                        title: s.featureDiscoverySearch,
                                        backgroundColor: Colors.cyan[600],
                                        buttonColor: Colors.cyan[500],
                                        description:
                                            s.featureDiscoverySearchDes,
                                        child: IconButton(
                                          tooltip: s.add,
                                          splashRadius: 20,
                                          icon: Icon(Icons.add_circle_outline),
                                          onPressed: () async {
                                            await showSearch<int?>(
                                              context: context,
                                              delegate: MyHomePageDelegate(
                                                  searchFieldLabel:
                                                      s.searchPodcast),
                                            );
                                          },
                                        ),
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
                                Import(),
                              ],
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: height,
                              width: context.width,
                              child: ScrollPodcasts(),
                            ),
                          ),
                          SliverPersistentHeader(
                            delegate: _SliverAppBarDelegate(
                              TabBar(
                                indicator: _getIndicator(context),
                                isScrollable: true,
                                indicatorSize: TabBarIndicatorSize.tab,
                                controller: _controller,
                                labelStyle: context.textTheme.titleMedium,
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
                      },
                      body: Column(
                        children: [
                          Expanded(
                            child: TabBarView(
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
                                        MultiSelectPanelIntegration(
                                            expanded: true),
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
                                        MultiSelectPanelIntegration(
                                            expanded: true),
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
                                        MultiSelectPanelIntegration(
                                            expanded: true),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      child: PlayerWidget(playerKey: _playerKey),
                    )
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
  _PlaylistButton({Key? key}) : super(key: key);

  @override
  __PlaylistButtonState createState() => __PlaylistButtonState();
}

class __PlaylistButtonState extends State<_PlaylistButton> {
  late bool _loadPlay;

  Future<void> _getPlaylist() async {
    await context.read<AudioPlayerNotifier>().initPlaylists();
    if (mounted) {
      setState(() {
        _loadPlay = true;
      });
    }
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
              selector: (_, audio) => Tuple3(
                  audio.playerRunning, audio.episode, audio.historyPosition),
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

  /// Episodes to display
  List<EpisodeBrief> _episodes = [];

  /// Function to get episodes
  Future<List<EpisodeBrief>> Function(int count, {int offset}) _getEpisodes =
      (int _, {int offset = 0}) async {
    return <EpisodeBrief>[];
  };

  /// Episodes loaded first time.
  int _top = 108;

  /// Load more episodes when scroll to bottom.
  bool _loadMore = false;

  EpisodeGridLayout? _layout;

  // Stop animating after first scroll
  bool _scroll = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.s;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - context.width &&
            _episodes.length == _top) {
          if (!_loadMore) {
            Future.microtask(() async {
              if (mounted) setState(() => _loadMore = true);
              _episodes.addAll(await _getEpisodes(36, offset: _top));
              _top = _top + 36;
              Provider.of<SelectionController>(context, listen: false)
                  .setSelectableEpisodes(_episodes, compatible: true);
              if (mounted) setState(() => _loadMore = false);
            });
          }
        }
        if (mounted && !_scroll && scrollInfo.metrics.pixels > 0) {
          setState(() => _scroll = true);
        }
        return true;
      },
      child: ScrollConfiguration(
        behavior: NoGrowBehavior(),
        child: CustomScrollView(
          key: PageStorageKey<String>('update'),
          slivers: <Widget>[
            FutureBuilder<Tuple2<EpisodeGridLayout, bool?>>(
              future: getLayoutAndShowListened(),
              builder: (_, snapshot) {
                if (_layout == null) {
                  _layout = snapshot.data?.item1;
                }
                return ActionBar(
                  onGetEpisodesChanged: (getEpisodes) async {
                    _getEpisodes = getEpisodes;
                    _episodes = await _getEpisodes(_top);
                    Provider.of<SelectionController>(context, listen: false)
                        .setSelectableEpisodes(_episodes);
                    if (mounted) setState(() {});
                  },
                  onLayoutChanged: (layout) {
                    _layout = layout;
                    if (mounted) setState(() {});
                  },
                  widgetsFirstRow: const [
                    ActionBarDropdownSortBy(0, 0),
                    ActionBarSwitchSortOrder(0, 1),
                    ActionBarDropdownGroups(0, 2),
                    ActionBarSpacer(0, 3),
                    ActionBarFilterPlayed(0, 4),
                    ActionBarFilterNew(0, 5),
                    ActionBarButtonRemoveNewMark(0, 6),
                    ActionBarSwitchSelectMode(0, 7),
                    ActionBarSwitchSecondRow(0, 8),
                  ],
                  widgetsSecondRow: const [
                    ActionBarDropdownPodcasts(1, 0),
                    ActionBarSearchTitle(1, 1),
                    ActionBarSpacer(1, 2),
                    ActionBarFilterDownloaded(1, 3),
                    ActionBarFilterLiked(1, 4),
                    ActionBarSwitchLayout(1, 5),
                    ActionBarButtonRefresh(1, 6),
                  ],
                  filterPlayed: false,
                  filterDisplayVersion: true,
                  layout: _layout ?? EpisodeGridLayout.large,
                );
              },
            ),
            SliverAppBar(
              pinned: true,
              leading: Center(),
              toolbarHeight: 2,
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              flexibleSpace: _loadMore
                  ? LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                    )
                  : Center(),
            ),
            _episodes.length != 0
                ? EpisodeGrid(
                    episodes: _episodes,
                    layout: _layout ?? EpisodeGridLayout.large,
                    initNum: _scroll ? 0 : 12,
                    openPodcast: true,
                  )
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 150),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(LineIcons.alternateCloudDownload,
                              size: 80, color: Colors.grey[500]),
                          Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                          Text(
                            s.noEpisodeRecent,
                            style: TextStyle(color: Colors.grey[500]),
                          )
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
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
  /// Episodes to display
  List<EpisodeBrief> _episodes = [];

  /// Function to get episodes
  Future<List<EpisodeBrief>> Function(int count, {int offset}) _getEpisodes =
      (int _, {int offset = 0}) async {
    return <EpisodeBrief>[];
  };

  /// Episodes loaded first time.
  int _top = 108;

  /// Load more episodes when scroll to bottom.
  bool _loadMore = false;

  EpisodeGridLayout? _layout;

  // Stop animating after first scroll
  bool _scroll = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.s;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - context.width &&
            _episodes.length == _top) {
          if (!_loadMore) {
            Future.microtask(() async {
              if (mounted) setState(() => _loadMore = true);
              _episodes.addAll(await _getEpisodes(36, offset: _top));
              _top = _top + 36;
              Provider.of<SelectionController>(context, listen: false)
                  .setSelectableEpisodes(_episodes, compatible: true);
              if (mounted) setState(() => _loadMore = false);
            });
          }
        }
        if (mounted && !_scroll && scrollInfo.metrics.pixels > 0) {
          setState(() => _scroll = true);
        }
        return true;
      },
      child: ScrollConfiguration(
        behavior: NoGrowBehavior(),
        child: CustomScrollView(
          key: PageStorageKey<String>('favorite'),
          slivers: <Widget>[
            FutureBuilder<Tuple2<EpisodeGridLayout, bool?>>(
              future: getLayoutAndShowListened(),
              builder: (_, snapshot) {
                if (_layout == null) {
                  _layout = snapshot.data?.item1;
                }
                return ActionBar(
                  onGetEpisodesChanged: (getEpisodes) async {
                    _getEpisodes = getEpisodes;
                    _episodes = await _getEpisodes(_top);
                    Provider.of<SelectionController>(context, listen: false)
                        .setSelectableEpisodes(_episodes);
                    if (mounted) setState(() {});
                  },
                  onLayoutChanged: (layout) {
                    _layout = layout;
                    if (mounted) setState(() {});
                  },
                  widgetsFirstRow: const [
                    ActionBarDropdownSortBy(0, 0),
                    ActionBarSwitchSortOrder(0, 1),
                    ActionBarDropdownGroups(0, 2),
                    ActionBarSpacer(0, 3),
                    ActionBarFilterLiked(0, 4),
                    ActionBarSwitchLayout(0, 5),
                    ActionBarSwitchSelectMode(0, 6),
                  ],
                  sortByItems: const [
                    Sorter.likedDate,
                    Sorter.pubDate,
                    Sorter.enclosureSize,
                    Sorter.enclosureDuration
                  ],
                  sortBy: Sorter.likedDate,
                  filterLiked: true,
                  layout: _layout ?? EpisodeGridLayout.large,
                );
              },
            ),
            SliverAppBar(
              pinned: true,
              leading: Center(),
              toolbarHeight: 2,
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              flexibleSpace: _loadMore
                  ? LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                    )
                  : Center(),
            ),
            _episodes.length != 0
                ? EpisodeGrid(
                    episodes: _episodes,
                    layout: _layout ?? EpisodeGridLayout.large,
                    initNum: _scroll ? 0 : 12,
                    openPodcast: true,
                  )
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 150),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(LineIcons.heartbeat,
                              size: 80, color: Colors.grey[500]),
                          Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                          Text(
                            s.noEpisodeFavorite,
                            style: TextStyle(color: Colors.grey[500]),
                          )
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
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
  /// Episodes to display
  List<EpisodeBrief> _episodes = [];

  /// Function to get episodes
  Future<List<EpisodeBrief>> Function(int count, {int offset}) _getEpisodes =
      (int _, {int offset = 0}) async {
    return <EpisodeBrief>[];
  };

  /// Episodes loaded first time.
  int _top = 108;

  /// Load more episodes when scroll to bottom.
  bool _loadMore = false;

  EpisodeGridLayout? _layout;

  // Stop animating after first scroll
  bool _scroll = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.s;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - context.width &&
            _episodes.length == _top) {
          if (!_loadMore) {
            Future.microtask(() async {
              if (mounted) setState(() => _loadMore = true);
              _episodes.addAll(await _getEpisodes(36, offset: _top));
              _top = _top + 36;
              Provider.of<SelectionController>(context, listen: false)
                  .setSelectableEpisodes(_episodes, compatible: true);
              if (mounted) setState(() => _loadMore = false);
            });
          }
        }
        if (mounted && !_scroll && scrollInfo.metrics.pixels > 0) {
          setState(() => _scroll = true);
        }
        return true;
      },
      child: ScrollConfiguration(
        behavior: NoGrowBehavior(),
        child: CustomScrollView(
          key: PageStorageKey<String>('download_list'),
          slivers: <Widget>[
            FutureBuilder<Tuple2<EpisodeGridLayout, bool?>>(
              future: getLayoutAndShowListened(),
              builder: (_, snapshot) {
                if (_layout == null) {
                  _layout = snapshot.data?.item1;
                }
                return ActionBar(
                  onGetEpisodesChanged: (getEpisodes) async {
                    _getEpisodes = getEpisodes;
                    _episodes = await _getEpisodes(_top);
                    Provider.of<SelectionController>(context, listen: false)
                        .setSelectableEpisodes(_episodes);
                    if (mounted) setState(() {});
                  },
                  onLayoutChanged: (layout) {
                    _layout = layout;
                    if (mounted) setState(() {});
                  },
                  widgetsFirstRow: const [
                    ActionBarDropdownSortBy(0, 0),
                    ActionBarSwitchSortOrder(0, 1),
                    ActionBarDropdownGroups(0, 2),
                    ActionBarSpacer(0, 3),
                    ActionBarFilterPlayed(0, 4),
                    ActionBarFilterDownloaded(0, 5),
                    ActionBarSwitchLayout(0, 6),
                    ActionBarSwitchSelectMode(0, 7),
                  ],
                  sortByItems: const [
                    Sorter.downloadDate,
                    Sorter.pubDate,
                    Sorter.enclosureSize,
                    Sorter.enclosureDuration
                  ],
                  sortBy: Sorter.downloadDate,
                  filterDownloaded: true,
                  layout: _layout ?? EpisodeGridLayout.large,
                );
              },
            ),
            SliverAppBar(
              pinned: true,
              leading: Center(),
              toolbarHeight: 2,
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              flexibleSpace: _loadMore
                  ? LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                    )
                  : Center(),
            ),
            DownloadList(),
            Selector<DownloadState, bool>(
              selector: (_, downloadState) => downloadState.downloadFinished,
              builder: (context, value, _) => FutureBuilder(
                future: Future.microtask(() async {
                  _episodes = await _getEpisodes(_top);
                  Provider.of<SelectionController>(context, listen: false)
                      .setSelectableEpisodes(_episodes, compatible: false);
                }),
                builder: (context, snapshot) => _episodes.length != 0
                    ? EpisodeGrid(
                        episodes: _episodes,
                        layout: _layout ?? EpisodeGridLayout.large,
                        openPodcast: true,
                        initNum: 0,
                      )
                    : SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 110),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(LineIcons.download,
                                  size: 80, color: Colors.grey[500]),
                              Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10)),
                              Text(
                                s.noEpisodeDownload,
                                style: TextStyle(color: Colors.grey[500]),
                              )
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
