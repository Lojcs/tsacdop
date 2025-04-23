import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/parser.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../state/episode_state.dart';
import '../type/theme_data.dart';
import '../widgets/action_bar.dart';
import 'package:tuple/tuple.dart';

import '../home/audioplayer.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../type/episodebrief.dart';
import '../type/fireside_data.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/selection_controller.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_widget.dart';
import '../widgets/episodegrid.dart';
import '../widgets/general_dialog.dart';
import '../widgets/multiselect_bar.dart';
import 'podcast_settings.dart';

const String kDefaultAvatar = """http://xuanmei.us/assets/default/avatar_small-
170afdc2be97fc6148b283083942d82c101d4c1061f6b28f87c8958b52664af9.jpg""";

class PodcastDetail extends StatefulWidget {
  const PodcastDetail(
      {super.key, required this.podcastLocal, this.hide = false});
  final PodcastLocal podcastLocal;
  final bool hide;
  @override
  _PodcastDetailState createState() => _PodcastDetailState();
}

class _PodcastDetailState extends State<PodcastDetail> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();
  final _dbHelper = DBHelper();
  late final CardColorScheme cardColorScheme = CardColorScheme(
    ColorScheme.fromSeed(
      seedColor: widget.podcastLocal.primaryColor!.toColor(),
      brightness: context.brightness,
    ),
  );

  late ScrollController _controller;

  late SelectionController selectionController;

  late Widget body = RefreshIndicator(
    key: _refreshIndicatorKey,
    displacement: context.paddingTop + 40,
    color: cardColorScheme.colorScheme.primary,
    onRefresh: () async {
      await _updateRssItem(context, widget.podcastLocal);
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: PodcastDetailBody(
            podcastLocal: widget.podcastLocal,
            selectionController: selectionController,
            key: Key("${widget.podcastLocal.id}_body"),
          ),
        ),
      ],
    ),
  );

  late Widget multiSelect = MultiSelectPanelIntegration();
  late Widget player = Container(child: PlayerWidget(playerKey: _playerKey));

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateRssItem(
      BuildContext context, PodcastLocal podcastLocal) async {
    final result = await _dbHelper.updatePodcastRss(podcastLocal);
    if (result >= 0) {
      Fluttertoast.showToast(
        msg: context.s.updateEpisodesCount(result),
        gravity: ToastGravity.TOP,
      );
    }
    if (result > 0) {
      final autoDownload = await _dbHelper.getAutoDownload(podcastLocal.id);
      if (autoDownload) {
        final downloader = Provider.of<DownloadState>(context, listen: false);
        final result = await Connectivity().checkConnectivity();
        final autoDownloadStorage = KeyValueStorage(autoDownloadNetworkKey);
        final autoDownloadNetwork = await autoDownloadStorage.getInt();
        if (autoDownloadNetwork == 1 ||
            result.contains(ConnectivityResult.wifi)) {
          var episodes = await _dbHelper.getEpisodes(
              feedIds: [podcastLocal.id],
              filterNew: true,
              filterDownloaded: false,
              filterDisplayVersion: true,
              filterAutoDownload: true);
          // For safety
          if (episodes.length < 100) {
            for (var episode in episodes) {
              downloader.startTask(episode, showNotification: false);
            }
          }
        }
      }
    } else if (result != 0) {
      Fluttertoast.showToast(
        msg: context.s.updateFailed,
        gravity: ToastGravity.TOP,
      );
    }
    if (mounted && result > 0) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SelectionController>(
            create: (context) => SelectionController()),
        Provider<CardColorScheme>.value(value: cardColorScheme),
      ],
      child: Selector<AudioPlayerNotifier, bool>(
        selector: (_, audio) => audio.playerRunning,
        builder: (context, playerRunning, __) {
          selectionController =
              Provider.of<SelectionController>(context, listen: false);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: context.realDark
                  ? context.surface
                  : cardColorScheme.saturated,
              statusBarIconBrightness: context.iconBrightness,
              systemNavigationBarColor:
                  playerRunning ? context.cardColorSchemeCard : context.surface,
              systemNavigationBarIconBrightness: context.iconBrightness,
            ),
            child: Selector<SelectionController, bool>(
              selector: (_, selectionController) =>
                  selectionController.selectMode,
              builder: (context, selectMode, __) {
                return PopScope(
                  canPop: !(_playerKey.currentState != null &&
                          _playerKey.currentState!.size! > 100) &&
                      !selectMode,
                  onPopInvokedWithResult: (_, __) {
                    if (_playerKey.currentState != null &&
                        _playerKey.currentState!.size! > 100) {
                      _playerKey.currentState!.backToMini();
                    } else if (selectionController.selectMode) {
                      selectionController.selectMode = false;
                    }
                  },
                  child: Scaffold(
                    backgroundColor: context.realDark
                        ? context.surface
                        : cardColorScheme.colorScheme.surface,
                    body: SafeArea(
                      child: Stack(
                        children: <Widget>[
                          body,
                          multiSelect,
                          player,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PodcastDetailBody extends StatefulWidget {
  final SelectionController selectionController;
  final PodcastLocal podcastLocal;
  final bool hide;

  const PodcastDetailBody(
      {super.key,
      required this.podcastLocal,
      required this.selectionController,
      this.hide = false});
  @override
  _PodcastDetailBodyState createState() => _PodcastDetailBodyState();
}

class _PodcastDetailBodyState extends State<PodcastDetailBody> {
  final GlobalKey _infoKey = GlobalKey();

  /// Episodes to display
  List<EpisodeBrief> _episodes = [];

  /// Function to get episodes
  Future<List<EpisodeBrief>> Function(int count, {int offset}) _getEpisodes =
      (int _, {int offset = 0}) async {
    return <EpisodeBrief>[];
  };

  /// Default layout.
  EpisodeGridLayout? _layout;

  /// If true, stop grid load animation.
  bool _scroll = false;

  late ScrollController _controller;

  /// Episodes num load first time.
  late int _top = 108;

  /// Load more episodes when scroll to bottom.
  bool _loadMore = false;

  double _infoHeightValue = 0;
  double get _infoHeight => _infoHeightValue;
  set _infoHeight(double height) {
    _infoHeightValue = math.max(_infoHeightValue, height);
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: NoGrowBehavior(),
      child: CustomScrollView(
        controller: _controller
          ..addListener(() async {
            if (_controller.offset >=
                    _controller.position.maxScrollExtent - context.width &&
                _episodes.length == _top) {
              if (!_loadMore) {
                if (mounted) setState(() => _loadMore = true);
                _episodes.addAll(await _getEpisodes(36, offset: _top));
                _top = _top + 36;
                widget.selectionController
                    .setSelectableEpisodes(_episodes, compatible: true);
                if (mounted) setState(() => _loadMore = false);
              }
            }
            if (mounted && !_scroll && _controller.offset > 0) {
              setState(() => _scroll = true);
            }
          }),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          Builder(
            builder: (context) {
              if (_infoHeight == 0 && _infoKey.currentContext != null) {
                _infoHeight =
                    (_infoKey.currentContext!.findRenderObject() as RenderBox)
                        .size
                        .height;
              }
              return Selector<CardColorScheme, Tuple2<Color, Color>>(
                selector: (context, cardColorScheme) => Tuple2(
                    context.realDark ? Colors.black : cardColorScheme.saturated,
                    cardColorScheme.colorScheme.onPrimaryContainer),
                builder: (context, data, _) => _PodcastDetailAppBar(
                  podcastLocal: widget.podcastLocal,
                  color: data.item1,
                  textColor: data.item2,
                  infoHeight: _infoHeight,
                ),
              );
            },
          ),
          FutureBuilder<Tuple2<EpisodeGridLayout, bool?>>(
            future: getLayoutAndShowListened(),
            builder: (_, snapshot) {
              _layout ??= snapshot.data?.item1;
              return ActionBar(
                onGetEpisodesChanged: (getEpisodes) async {
                  _getEpisodes = getEpisodes;
                  _episodes = await _getEpisodes(_top);
                  widget.selectionController.setSelectableEpisodes(_episodes);
                  if (mounted) setState(() {});
                },
                onLayoutChanged: (layout) {
                  _layout = layout;
                  if (mounted) setState(() {});
                },
                widgetsFirstRow: const [
                  ActionBarDropdownSortBy(0, 0),
                  ActionBarSwitchSortOrder(0, 1),
                  ActionBarSpacer(0, 2),
                  ActionBarFilterNew(0, 3),
                  ActionBarFilterLiked(0, 4),
                  ActionBarFilterPlayed(0, 5),
                  ActionBarFilterDownloaded(0, 6),
                  ActionBarSwitchSelectMode(0, 7),
                  ActionBarSwitchSecondRow(0, 8),
                ],
                widgetsSecondRow: const [
                  ActionBarFilterDisplayVersion(1, 0),
                  ActionBarSearchTitle(1, 1),
                  ActionBarSpacer(1, 2),
                  ActionBarButtonRemoveNewMark(1, 3),
                  ActionBarSwitchLayout(1, 4),
                  ActionBarButtonRefresh(1, 5),
                ],
                podcast: widget.podcastLocal,
                filterPlayed: snapshot.data?.item2,
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
                    color: Provider.of<CardColorScheme>(context).saturated,
                    backgroundColor: Colors.transparent,
                  )
                : Center(),
          ),
          if (!widget.hide)
            Selector<EpisodeState, bool>(
              selector: (_, episodeState) => episodeState.globalChange,
              builder: (context, value, _) => FutureBuilder(
                  future: Future.microtask(() async {
                    _episodes = await _getEpisodes(_top);
                    Provider.of<SelectionController>(context, listen: false)
                        .setSelectableEpisodes(_episodes, compatible: false);
                  }),
                  builder: (context, snapshot) => EpisodeGrid(
                        episodes: _episodes,
                        layout: _layout ?? EpisodeGridLayout.large,
                        openPodcast: true,
                        initNum: 0,
                      )),
            ),

          // Hidden widget to get the height of [HostsList]
          SliverToBoxAdapter(
            child: Stack(
              children: [
                _infoHeight == 0
                    ? Opacity(
                        opacity: 0,
                        key: _infoKey,
                        child: HostsList(context, widget.podcastLocal),
                      )
                    : Center(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastDetailAppBar extends StatefulWidget {
  final PodcastLocal podcastLocal;
  final Color color;
  final Color textColor;
  final double infoHeight;

  const _PodcastDetailAppBar({
    required this.podcastLocal,
    required this.color,
    required this.textColor,
    required this.infoHeight,
  });
  @override
  __PodcastDetailAppBarState createState() => __PodcastDetailAppBarState();
}

class __PodcastDetailAppBarState extends State<_PodcastDetailAppBar>
    with SingleTickerProviderStateMixin {
  double _topHeight = 0;

  ///Show podcast info.
  bool _showInfo = false;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late Tween<double> _infoHeightTween =
      Tween<double>(begin: 0, end: widget.infoHeight);
  double get currentInfoHeight => _infoHeightTween.evaluate(_slideAnimation);
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCirc,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PodcastDetailAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.infoHeight != widget.infoHeight) {
      _infoHeightTween = Tween<double>(begin: 0, end: widget.infoHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.more_vert),
          splashRadius: 20,
          tooltip: context.s.menu,
          onPressed: () => generalSheet(
            context,
            title: widget.podcastLocal.title,
            color: widget.podcastLocal.primaryColor!.toColor(),
            child: PodcastSetting(podcastLocal: widget.podcastLocal),
          ).then((value) async {
            await _checkPodcast();
            if (mounted) setState(() {});
          }),
        ),
      ],
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(
        color: context.realDark ? widget.textColor : context.textColor,
      ),
      expandedHeight:
          math.max(130 + context.paddingTop, 180) + currentInfoHeight,
      backgroundColor: widget.color,
      floating: true,
      pinned: true,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          _topHeight = constraints.biggest.height;
          double expandRatio = (1 -
                  ((context.paddingTop + currentInfoHeight - _topHeight + 180) /
                      124))
              .clamp(0, 1);
          double fullExpandRatio =
              (1 - ((context.paddingTop - _topHeight + 180) / 124)).clamp(0, 1);
          final titleLineTest = TextPainter(
              text: TextSpan(
                  text: widget.podcastLocal.title,
                  style: context.textTheme.headlineSmall!),
              textDirection: TextDirection.ltr);
          titleLineTest.layout(maxWidth: context.width - 185);
          double titleScale =
              ((context.width - 185) / titleLineTest.size.width).clamp(1, 1.2);
          double titleLineHeight = titleLineTest.size.height /
              titleLineTest.computeLineMetrics().length;
          int titleLineCount = titleLineTest.computeLineMetrics().length;
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
                left: 55,
                right: 55 + (fullExpandRatio == 0 ? 0 : 75),
                bottom: _topHeight -
                    (40 +
                        (titleLineCount == 1
                            ? expandRatio * 54
                            : titleLineCount == 2
                                ? expandRatio * 39 +
                                    (expandRatio < 0.2 ? 0 : titleLineHeight)
                                : expandRatio * 24 +
                                    (expandRatio < 0.2
                                        ? 0
                                        : expandRatio < 0.4
                                            ? titleLineHeight
                                            : titleLineHeight * 2)))),
            expandedTitleScale: titleScale,
            background: Stack(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: InkWell(
                    onTap: () => setState(() {
                      if (_showInfo) {
                        _showInfo = false;
                        _slideController.reverse();
                      } else {
                        _showInfo = true;
                        _slideController.forward();
                      }
                    }),
                    child: Container(
                      height: 60,
                      padding: EdgeInsets.only(left: 40, right: 130),
                      color: context.brightness == Brightness.light
                          ? Color.lerp(widget.color, Colors.black, 0.08)
                          : Color.lerp(widget.color, Colors.white, 0.12),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(widget.podcastLocal.author ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleMedium),
                                if (widget.podcastLocal.provider.isNotEmpty)
                                  Text(
                                    widget.podcastLocal.provider,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleSmall,
                                  ),
                              ],
                            ),
                          ),
                          UpDownIndicator(
                              status: _showInfo, color: context.textColor),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  padding: EdgeInsets.only(right: 20, top: 70),
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Image.file(
                      File("${widget.podcastLocal.imagePath}"),
                      errorBuilder: (context, _, __) {
                        return ColoredBox(
                            color: widget.color, child: Icon(Icons.error));
                      },
                    ),
                  ),
                ),
                if (currentInfoHeight > 0)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: context.surface,
                      height: currentInfoHeight,
                      child: SingleChildScrollView(
                        clipBehavior: Clip.hardEdge,
                        child: HostsList(context, widget.podcastLocal),
                      ),
                    ),
                  )
              ],
            ),
            title: Opacity(
              opacity: 1,
              child: Tooltip(
                message: widget.podcastLocal.title,
                child: Text(
                  widget.podcastLocal.title,
                  maxLines: titleLineCount < 3
                      ? expandRatio < 0.2
                          ? 1
                          : 2
                      : expandRatio < 0.2
                          ? 1
                          : expandRatio < 0.4
                              ? 2
                              : 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall?.copyWith(
                      color: context.realDark ? widget.textColor : null),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkPodcast() async {
    DBHelper dbHelper = DBHelper();
    final exist = await dbHelper.checkPodcast(widget.podcastLocal.rssUrl);
    if (exist == '') {
      Navigator.of(context).pop();
    }
  }
}

class HostsList extends StatelessWidget {
  final BuildContext context;
  final PodcastLocal podcastLocal;
  const HostsList(this.context, this.podcastLocal, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FutureBuilder<Tuple2<String?, List<PodcastHost>?>>(
            future: _getHosts(podcastLocal),
            builder: (context, snapshot) {
              return Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _podcastLink(context,
                            title: 'Link',
                            child: Icon(
                              Icons.link,
                              size: 30,
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.green[600]!,
                            onTap: () => podcastLocal.link!.launchUrl),
                        _podcastLink(context,
                            title: 'Rss',
                            child: Icon(
                              LineIcons.rssSquare,
                              size: 30,
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.blue[600]!,
                            onTap: () => podcastLocal.rssUrl.launchUrl),
                        if (podcastLocal.funding.isNotEmpty)
                          for (var funding in podcastLocal.funding)
                            _podcastLink(context,
                                title: 'Donate',
                                child: Icon(
                                    funding.contains(
                                      'paypal',
                                    )
                                        ? LineIcons.paypal
                                        : LineIcons.donate,
                                    size: 30),
                                backgroundColor: Colors.red[600]!,
                                onTap: () => funding.launchUrl),
                        if (snapshot.hasData)
                          ...snapshot.data!.item2!
                              .map<Widget>((host) {
                                final image = host.image == kDefaultAvatar
                                    ? kDefaultAvatar
                                    : host.image;
                                return Container(
                                  padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                  width: 60.0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      CachedNetworkImage(
                                        imageUrl: image!,
                                        progressIndicatorBuilder:
                                            (context, url, downloadProgress) =>
                                                CircleAvatar(
                                          backgroundColor: Colors.cyan[600]!
                                              .withValues(alpha: 0.5),
                                          child: SizedBox(
                                            width: 30,
                                            height: 2,
                                            child: LinearProgressIndicator(
                                                value:
                                                    downloadProgress.progress),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            CircleAvatar(
                                          backgroundColor: Colors.grey[400],
                                          backgroundImage:
                                              AssetImage('assets/fireside.jpg'),
                                        ),
                                        imageBuilder: (context, hostImage) =>
                                            CircleAvatar(
                                                backgroundColor:
                                                    Colors.grey[400],
                                                backgroundImage: hostImage),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        host.name!,
                                        style: context.textTheme.titleSmall,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.fade,
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList()
                              .cast<Widget>()
                      ]),
                ),
              );
            }),
        Container(
          padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
          alignment: Alignment.topLeft,
          color: Colors.transparent,
          child: AboutPodcast(
            podcastLocal: podcastLocal,
            accentColor: ColorScheme.fromSeed(
                    seedColor: podcastLocal.primaryColor!.toColor(),
                    brightness: context.brightness)
                .primary,
          ),
        ),
      ],
    );
  }
}

Future<Tuple2<String?, List<PodcastHost>?>> _getHosts(
    PodcastLocal podcastLocal) async {
  if (!podcastLocal.provider.contains('fireside')) return Tuple2('', []);
  var data = FiresideData(podcastLocal.id, podcastLocal.link);
  await data.getData();
  var backgroundImage = data.background;
  var hosts = data.hosts;
  return Tuple2(backgroundImage, hosts);
}

Widget _podcastLink(BuildContext context,
    {required String title,
    Widget? child,
    VoidCallback? onTap,
    required Color backgroundColor}) {
  return Container(
    padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
    width: 60.0,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: CircleAvatar(
            radius: 20,
            child: child,
            backgroundColor: backgroundColor.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: context.textTheme.titleSmall,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.fade,
        ),
      ],
    ),
  );
}

class AboutPodcast extends StatefulWidget {
  final PodcastLocal? podcastLocal;
  final Color? accentColor;
  const AboutPodcast({this.podcastLocal, this.accentColor, super.key});

  @override
  _AboutPodcastState createState() => _AboutPodcastState();
}

class _AboutPodcastState extends State<AboutPodcast> {
  late String _description;
  late bool _load;

  @override
  void initState() {
    super.initState();
    _load = false;
    getDescription(widget.podcastLocal!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_load)
      return Linkify(
        text: _description,
        style: context.textTheme.bodyMedium,
        onOpen: (link) {
          link.url.launchUrl;
        },
        linkStyle: TextStyle(
            color: widget.accentColor ?? context.accentColor,
            decoration: TextDecoration.underline,
            textBaseline: TextBaseline.ideographic),
      );
    return Center();
  }

  void getDescription(String? id) async {
    final dbHelper = DBHelper();
    if (widget.podcastLocal!.description == "") {
      final description = await dbHelper.getFeedDescription(id);
      if (description == null || description.isEmpty) {
        _description = '';
      } else {
        final doc = parse(description);
        _description = parse(doc.body!.text).documentElement!.text;
      }
    } else {
      _description = widget.podcastLocal!.description;
    }
    if (mounted) setState(() => _load = true);
  }
}
