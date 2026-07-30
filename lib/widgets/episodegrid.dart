import 'dart:math';

import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../type/tab_configuration.dart';
import '../util/extension_helper.dart';
import '../util/selection_controller.dart';
import 'action_bar.dart';
import 'custom_widget.dart';
import '../episodes/episode_card.dart';

enum EpisodeGridLayout {
  small(1, 120, 134, "small"),
  medium(1.5, 150, 201, "medium"),
  large(4, 300, 402, "large");

  const EpisodeGridLayout(
    this.ratio,
    this.minWidth,
    this.targetWidth,
    this.serial,
  );

  final double ratio;
  final double minWidth;
  final double targetWidth;
  final String serial;

  factory EpisodeGridLayout.fromSerial(String serial) => switch (serial) {
    "small" => small,
    "medium" => medium,
    "large" => large,
    _ => medium,
  };

  /// The number of cards to display per row ([maxWidth] includes spacing)
  int getHorizontalCount(double maxWidth) {
    int overshootCount = (maxWidth / targetWidth).ceil();
    double overshootWidth = maxWidth / overshootCount;
    return overshootWidth > minWidth ? overshootCount : overshootCount - 1;
  }

  /// Height of each card (including spacing)
  double getRowHeight(double maxWidth) =>
      maxWidth / (getHorizontalCount(maxWidth) * ratio);

  /// Number of cards that fit the area.
  int getVerticalCount(double maxWidth, double height) {
    int count = getHorizontalCount(maxWidth);
    return (height * (pow(count, 2) * ratio) ~/ maxWidth) + count;
  }
}

/// Integrates [EpisodeGrid] with an [ActionBar] and if provided with a provider,
/// a [SelectionController]. Implements pagination.
class InteractiveEpisodeGrid extends StatefulWidget {
  /// Widget to display when no episodes are returned from the database
  final Widget? noEpisodesWidget;

  /// Slivers to display in addition to the 3 included here
  final List<Widget> additionalSliversList;

  /// Indicies to insert included slivers at the [additionalSliversList]
  final ({int actionBarIndex, int loadingIndicatorIndex, int gridIndex})
  sliverInsertIndicies;

  /// Prefer episode image over podcast image for card avatar image
  final bool preferEpisodeImage;

  /// Opens the podcast details if card avatar image is tapped
  final bool openPodcast;

  /// Enables selection if a [SelectionController] provider is in the tree
  final bool selectable;

  /// Count of animation items.
  final int initNum;

  /// Prefetched episode ids to display before query
  final List<int>? initIds;

  /// Show or hide grid
  final bool showGrid;

  /// Episode list is refetched when this notifies.
  final Listenable? refreshNotifier;

  /// Items to show on the sction bar
  final List<ActionBarWidget> actionBarWidgetsFirstRow;

  /// Items to show in custom popup menu
  final List<ActionBarWidget> actionBarWidgetsSecondRow;

  /// Sorters to show in the second row of the action bar
  final List<Sorter> actionBarSortByItems;

  /// Default action bar configuration.
  final ActionBarConfiguration actionBarConfiguration;

  const InteractiveEpisodeGrid({
    super.key,
    this.noEpisodesWidget,
    this.additionalSliversList = const [],
    this.sliverInsertIndicies = (
      actionBarIndex: 0,
      loadingIndicatorIndex: 1,
      gridIndex: 2,
    ),
    this.preferEpisodeImage = false,
    this.openPodcast = false,
    this.selectable = true,
    this.initNum = 12,
    this.initIds,
    this.showGrid = true,
    this.refreshNotifier,
    this.actionBarWidgetsFirstRow = const [
      ActionBarDropdownSortBy(0, 0),
      ActionBarSwitchSortOrder(0, 1),
      ActionBarDropdownGroups(0, 2),
      ActionBarSpacer(0, 3),
      ActionBarFilterPlayed(0, 4),
      ActionBarFilterNew(0, 5),
      ActionBarSwitchSelectMode(0, 6),
      ActionBarSwitchSecondRow(0, 7),
    ],
    this.actionBarWidgetsSecondRow = const [
      ActionBarDropdownPodcasts(1, 0),
      ActionBarFilterDisplayVersion(1, 1),
      ActionBarSearchTitle(1, 2),
      ActionBarSpacer(1, 3),
      ActionBarFilterDownloaded(1, 4),
      ActionBarFilterLiked(1, 5),
      ActionBarSwitchLayout(1, 6),
      ActionBarButtonSync(1, 7),
    ],
    this.actionBarSortByItems = const [
      Sorter.pubDate,
      Sorter.enclosureSize,
      Sorter.enclosureDuration,
      Sorter.downloadDate,
      Sorter.likedDate,
      Sorter.random,
    ],
    this.actionBarConfiguration = const ActionBarConfiguration(),
  });

  @override
  State<StatefulWidget> createState() => _InteractiveEpisodeGridState();
}

class _InteractiveEpisodeGridState extends State<InteractiveEpisodeGrid> {
  _InteractiveEpisodeGridState();

  /// Episodes to display
  late List<int> _episodeIds = widget.initIds ?? [];

  /// Function to get episodes
  Future<List<int>> Function(int count, {int offset}) _getEpisodeIds =
      (int _, {int offset = 0}) async {
        return <int>[];
      };

  /// Episodes loaded first time.
  int _top = 108;

  /// Load more episodes when scroll to bottom.
  bool _loadMore = false;

  /// Layout of the grid
  late EpisodeGridLayout _layout = widget.actionBarConfiguration.layout;

  /// Stop animating after first scroll
  bool _scroll = false;

  List<Widget>? slivers;
  bool update = true;

  Future<void>? _delayedRefreshFuture;
  @override
  void initState() {
    super.initState();
    if (widget.refreshNotifier != null) {
      widget.refreshNotifier!.addListener(() {
        _delayedRefreshFuture ??= Future.delayed(
          Duration(milliseconds: 500),
          _onNotified,
        );
      });
    }
  }

  void _onNotified() async {
    final newEpisodeIds = await _getEpisodeIds(_top);
    final newSet = newEpisodeIds.toSet();
    final oldSet = _episodeIds.toSet();
    if ((newSet.difference(oldSet).isNotEmpty ||
            oldSet.difference(newSet).isNotEmpty) &&
        mounted) {
      _episodeIds = newEpisodeIds;
      SelectionController? selectionController =
          Provider.of<SelectionController?>(context, listen: false);
      if (selectionController != null) {
        selectionController.setSelectableEpisodes(_episodeIds);
      }
      setState(() {});
    }
    _delayedRefreshFuture = null;
  }

  @override
  void didUpdateWidget(covariant InteractiveEpisodeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actionBarConfiguration.layout != _layout) {
      _layout = widget.actionBarConfiguration.layout;
      update = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eState = context.episodeState;
    slivers ??= [...widget.additionalSliversList]
      ..insert(
        widget.sliverInsertIndicies.actionBarIndex,
        ActionBar(
          onConfigurationChanged: (configuration) async {
            _getEpisodeIds = (count, {offset = -1}) =>
                eState.getEpisodesWithConfiguration(
                  configuration,
                  count,
                  offset: offset,
                );
            _episodeIds = await _getEpisodeIds(_top);
            if (mounted && context.mounted) {
              SelectionController? selectionController =
                  Provider.of<SelectionController?>(context, listen: false);
              if (selectionController != null) {
                selectionController.setSelectableEpisodes(_episodeIds);
              }
              setState(() {});
            }
            update = true;
          },
          sendInitialConfig: true,
          onLayoutChanged: (layout) {
            _layout = layout;
            update = true;
            if (mounted) setState(() {});
          },
          widgetsFirstRow: widget.actionBarWidgetsFirstRow,
          widgetsSecondRow: widget.actionBarWidgetsSecondRow,
          sortByItems: widget.actionBarSortByItems,
          configuration: widget.actionBarConfiguration,
        ),
      )
      ..insert(
        widget.sliverInsertIndicies.loadingIndicatorIndex,
        SliverAppBar(
          pinned: true,
          leading: Center(),
          toolbarHeight: 2,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          flexibleSpace: _loadMore
              ? LinearProgressIndicator(backgroundColor: Colors.transparent)
              : Center(),
        ),
      )
      ..insert(widget.sliverInsertIndicies.gridIndex, Center());
    if (update) updateGrid();
    update = false;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - (context.height * 2) &&
            _episodeIds.length == _top) {
          if (!_loadMore) {
            Future.microtask(() async {
              setState(() => _loadMore = true);
              int newCount = 9 * (_top ~/ 36);
              _episodeIds.addAll(await _getEpisodeIds(newCount, offset: _top));
              _top = _top + newCount;
              if (mounted && context.mounted) {
                SelectionController? selectionController =
                    Provider.of<SelectionController?>(context, listen: false);
                if (selectionController != null) {
                  selectionController.setSelectableEpisodes(
                    _episodeIds,
                    compatible: true,
                  );
                }
                update = true;
                setState(() => _loadMore = false);
              }
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
        child: CustomScrollView(slivers: slivers!),
      ),
    );
  }

  void updateGrid() {
    slivers![widget.sliverInsertIndicies.gridIndex] = widget.showGrid
        ? _episodeIds.isNotEmpty
              ? EpisodeGrid(
                  episodeIds: _episodeIds,
                  initNum: widget.initNum,
                  preferEpisodeImage: widget.preferEpisodeImage,
                  layout: _layout,
                  openPodcast: widget.openPodcast,
                  selectable: widget.selectable,
                  externallyRefreshed: true,
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 150),
                    child: widget.noEpisodesWidget,
                  ),
                )
        : SliverToBoxAdapter();
  }
}

/// Widget that displays [InteractiveEpisodeCard]s in a grid.
class EpisodeGrid extends StatelessWidget {
  final List<int> episodeIds;
  final bool preferEpisodeImage;
  final EpisodeGridLayout layout;
  final bool openPodcast;
  final bool selectable;
  final bool externallyRefreshed;

  /// Count of animation items.
  final int initNum;

  const EpisodeGrid({
    super.key,
    required this.episodeIds,
    this.initNum = 12,
    this.preferEpisodeImage = false,
    this.layout = EpisodeGridLayout.small,
    this.openPodcast = false,
    this.selectable = true,
    this.externallyRefreshed = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = LiveOptions(
      delay: Duration.zero,
      showItemInterval: Duration(milliseconds: 20),
      showItemDuration: Duration(milliseconds: 50),
    );
    final scrollController = ScrollController();
    if (episodeIds.isNotEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        sliver: SliverGrid.builder(
          itemCount: episodeIds.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: layout.ratio,
            crossAxisCount: layout.getHorizontalCount(context.width),
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
          ),
          itemBuilder: (context, index) => InteractiveEpisodeCard(
            episodeIds[index],
            layout,
            openPodcast: openPodcast,
            preferEpisodeImage: preferEpisodeImage,
            selectable: selectable,
            index: index,
          ),
          // I couldn't make it stop animating after the initial batch
          // sliver: LiveSliverGrid.options(
          //   controller: scrollController,
          //   options: options,
          //   itemCount: episodeIds.length,
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //     childAspectRatio: layout.ratio,
          //     crossAxisCount: layout.getHorizontalCount(context.width),
          //     mainAxisSpacing: 10.0,
          //     crossAxisSpacing: 10.0,
          //   ),
          //   itemBuilder: (context, index, animation) {
          //     final child = InteractiveEpisodeCard(
          //       episodeIds[index],
          //       layout,
          //       openPodcast: openPodcast,
          //       preferEpisodeImage: preferEpisodeImage,
          //       showNumber: true,
          //       selectable: selectable,
          //       index: index,
          //     );
          //     return FadeTransition(
          //       opacity: Tween<double>(begin: index < initNum ? 0 : 1, end: 1)
          //           .animate(animation),
          //       child: child,
          //     );
          //   },
        ),
      );
    } else {
      return SliverToBoxAdapter();
    }
  }
}
