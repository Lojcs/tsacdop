import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../state/podcast_state.dart';
import '../type/theme_data.dart';
import '../widgets/action_bar.dart';
import 'package:tuple/tuple.dart';

import '../home/audioplayer.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../type/fireside_data.dart';
import '../type/podcastbrief.dart';
import '../util/extension_helper.dart';
import '../util/selection_controller.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_widget.dart';
import '../widgets/episodegrid.dart';
import '../widgets/general_dialog.dart';
import '../widgets/multiselect_bar.dart';
import 'podcast_settings.dart';

class PodcastDetail extends StatefulWidget {
  const PodcastDetail(
      {super.key, required this.podcastId, this.initIds, this.hide = false});
  final String podcastId;
  final bool hide;

  /// Prefetched episode ids to display at first
  final List<int>? initIds;
  @override
  State<PodcastDetail> createState() => _PodcastDetailState();
}

class _PodcastDetailState extends State<PodcastDetail> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();
  final _dbHelper = DBHelper();
  CardColorScheme get cardColorScheme =>
      context.select<PodcastState, CardColorScheme>(
          (pState) => pState[widget.podcastId].cardColorScheme(context));

  late ScrollController _controller;

  late SelectionController selectionController;

  late Widget body = RefreshIndicator(
    key: _refreshIndicatorKey,
    displacement: context.paddingTop + 40,
    color: cardColorScheme.colorScheme.primary,
    onRefresh: () async {
      await _updateRssItem(context, context.podcastState[widget.podcastId]);
    },
    child: PodcastDetailBody(
      podcastId: widget.podcastId,
      selectionController: selectionController,
      initIds: widget.initIds,
      hide: widget.hide,
    ),
  );

  late Widget multiSelect = MultiSelectPanelIntegration();
  late Widget player = PlayerWidget(playerKey: _playerKey);

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
      BuildContext context, PodcastBrief podcastLocal) async {
    final result = await _dbHelper.updatePodcastRss(podcastLocal);
    if (result >= 0) {
      Fluttertoast.showToast(
        msg: context.s.updateEpisodesCount(result),
        gravity: ToastGravity.TOP,
      );
    }
    if (result > 0) {
      if (podcastLocal.autoDownload) {
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
              filterDisplayVersion: false,
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
                        : cardColorScheme.saturated,
                    extendBody: true,
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
  final String podcastId;

  /// Prefetched episode ids to display at first
  final List<int>? initIds;
  final bool hide;

  const PodcastDetailBody(
      {super.key,
      required this.podcastId,
      required this.selectionController,
      this.initIds,
      this.hide = false});
  @override
  State<PodcastDetailBody> createState() => _PodcastDetailBodyState();
}

class _PodcastDetailBodyState extends State<PodcastDetailBody> {
  final GlobalKey _infoKey = GlobalKey();
  late ScrollController _controller;

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
    return ColoredBox(
        color: context.realDark
            ? context.surface
            : context.select<CardColorScheme, Color>(
                (colors) => colors.colorScheme.surface),
        child: InteractiveEpisodeGrid(
          additionalSliversList: [
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
                      context.realDark
                          ? context.surface
                          : cardColorScheme.saturated,
                      cardColorScheme.colorScheme.onPrimaryContainer),
                  builder: (context, data, _) => _PodcastDetailAppBar(
                    podcastId: widget.podcastId,
                    color: data.item1,
                    textColor: data.item2,
                    infoHeight: _infoHeight,
                  ),
                );
              },
            ), // Hidden widget to get the height of [HostsList]
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  _infoHeight == 0
                      ? Opacity(
                          opacity: 0,
                          key: _infoKey,
                          child: HostsList(context, widget.podcastId),
                        )
                      : Center(),
                ],
              ),
            ),
          ],
          sliverInsertIndicies: (
            actionBarIndex: 1,
            loadingIndicatorIndex: 2,
            gridIndex: 3
          ),
          showGrid: !widget.hide,
          openPodcast: true,
          actionBarWidgetsFirstRow: const [
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
          actionBarWidgetsSecondRow: const [
            ActionBarFilterDisplayVersion(1, 0),
            ActionBarSearchTitle(1, 1),
            ActionBarSpacer(1, 2),
            ActionBarButtonRemoveNewMark(1, 3),
            ActionBarSwitchLayout(1, 4),
            ActionBarButtonRefresh(1, 5),
          ],
          actionBarSortByItems: const [
            Sorter.downloadDate,
            Sorter.pubDate,
            Sorter.enclosureSize,
            Sorter.enclosureDuration
          ],
          actionBarPodcastId: widget.podcastId,
          layoutKey: podcastLayoutKey,
          initNum: widget.initIds != null ? 0 : 1 << 32,
          initIds: widget.initIds,
        ));
  }
}

class _PodcastDetailAppBar extends StatefulWidget {
  final String podcastId;
  final Color color;
  final Color textColor;
  final double infoHeight;

  const _PodcastDetailAppBar({
    required this.podcastId,
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

  late final PodcastState pState = context.podcastState;

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
          onPressed: () async {
            await generalSheet(
              context,
              title: pState[widget.podcastId].title,
              color: pState[widget.podcastId].primaryColor,
              child: PodcastSetting(podcastId: widget.podcastId),
            );
            if (pState.deletedIds.contains(widget.podcastId) &&
                context.mounted) {
              Navigator.of(context).pop();
            }
          },
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
                  text: pState[widget.podcastId].title,
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
                Container(
                  margin: EdgeInsets.only(top: 120),
                  color: context.brightness == Brightness.light
                      ? Color.lerp(widget.color, Colors.black, 0.08)
                      : Color.lerp(widget.color, Colors.white, 0.12),
                  child: Material(
                    color: Colors.transparent,
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
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Selector<PodcastState, String>(
                                    selector: (_, pState) =>
                                        pState[widget.podcastId].author,
                                    builder: (context, author, _) => Text(
                                        author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.textTheme.titleMedium),
                                  ),
                                  Selector<PodcastState, String>(
                                    selector: (_, pState) =>
                                        pState[widget.podcastId].provider,
                                    builder: (context, provider, _) => provider
                                            .isNotEmpty
                                        ? Text(
                                            provider,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context.textTheme.titleSmall,
                                          )
                                        : Center(),
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
                    child: Selector<PodcastState, String>(
                      selector: (_, pState) =>
                          pState[widget.podcastId].imagePath,
                      builder: (context, imagePath, _) => Image.file(
                        File(imagePath),
                        errorBuilder: (context, _, __) => ColoredBox(
                          color: widget.color,
                          child: Icon(Icons.error),
                        ),
                      ),
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
                        child: HostsList(context, widget.podcastId),
                      ),
                    ),
                  ),
              ],
            ),
            title: Opacity(
              opacity: 1,
              child: Selector<PodcastState, String>(
                selector: (_, pState) => pState[widget.podcastId].title,
                builder: (context, title, _) => Tooltip(
                  message: title,
                  child: Text(
                    title,
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
            ),
          );
        },
      ),
    );
  }
}

class HostsList extends StatelessWidget {
  final BuildContext context;
  final String podcastId;
  const HostsList(this.context, this.podcastId, {super.key});

  @override
  Widget build(BuildContext context) {
    final PodcastState pState = context.podcastState;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
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
                    onTap: () => pState[podcastId].webpage.launchUrl),
                _podcastLink(context,
                    title: 'Rss',
                    child: Icon(
                      LineIcons.rssSquare,
                      size: 30,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.blue[600]!,
                    onTap: () => pState[podcastId].rssUrl.launchUrl),
                Selector<PodcastState, List<String>>(
                  selector: (_, pState) => pState[podcastId].funding,
                  builder: (context, fundings, _) => fundings.isNotEmpty
                      ? Row(
                          children: fundings
                              .map(
                                (funding) => _podcastLink(context,
                                    title: 'Donate',
                                    child: Icon(
                                        funding.contains('paypal')
                                            ? LineIcons.paypal
                                            : LineIcons.donate,
                                        size: 30),
                                    backgroundColor: Colors.red[600]!,
                                    onTap: () => funding.launchUrl),
                              )
                              .toList(),
                        )
                      : Center(),
                ),
                Selector<PodcastState, List<PodcastHost>>(
                  selector: (_, pState) => pState[podcastId].firesideHosts,
                  builder: (context, hosts, _) => Row(
                    children: hosts
                        .map<Widget>(
                          (host) => Container(
                            padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                            width: 60.0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                CachedNetworkImage(
                                  imageUrl: host.image!,
                                  progressIndicatorBuilder:
                                      (context, url, downloadProgress) =>
                                          CircleAvatar(
                                    backgroundColor: Colors.cyan[600]!
                                        .withValues(alpha: 0.5),
                                    child: SizedBox(
                                      width: 30,
                                      height: 2,
                                      child: LinearProgressIndicator(
                                          value: downloadProgress.progress),
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
                                          backgroundColor: Colors.grey[400],
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
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
          alignment: Alignment.topLeft,
          color: Colors.transparent,
          child: Selector<PodcastState, (String, Color)>(
            selector: (_, pState) =>
                (pState[podcastId].description, pState[podcastId].primaryColor),
            builder: (context, data, _) => Linkify(
              text: data.$1,
              style: context.textTheme.bodyMedium,
              onOpen: (link) {
                link.url.launchUrl;
              },
              linkStyle: TextStyle(
                  color: data.$2,
                  decoration: TextDecoration.underline,
                  textBaseline: TextBaseline.ideographic),
            ),
          ),
        ),
      ],
    );
  }
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
            backgroundColor: backgroundColor.withValues(alpha: 0.5),
            child: child,
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
