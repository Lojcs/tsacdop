import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../state/episode_state.dart';
import '../state/podcast_group.dart';
import '../type/episodebrief.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/selection_controller.dart';
import 'action_bar.dart';
import 'custom_widget.dart';
import 'episode_card.dart';

enum EpisodeGridLayout { small, medium, large }

/// Integrates [EpisodeGrid] with an [ActionBar] and if provided with a provider,
/// a [SelectionController]. Implements pagination.
class InteractiveEpisodeGrid extends StatefulWidget {
  /// Widget to display when no episodes are returned from the database
  final Widget? noEpisodesWidget;

  /// Slivers to display in addition to the 3 included here
  final List<Widget> additionalSliversList;

  /// Indicies to insert included slivers at the [additionalSliversList]
  final ({
    int actionBarIndex,
    int loadingIndicatorIndex,
    int gridIndex
  }) sliverInsertIndicies;

  /// Prefer episode image over podcast image for card avatar image
  final bool preferEpisodeImage;

  /// Opens the podcast details if card avatar image is tapped
  final bool openPodcast;

  /// Enables selection if a [SelectionController] provider is in the tree
  final bool selectable;

  /// Count of animation items.
  final int initNum;

  /// Show or hide grid
  final bool showGrid;

  /// Items to show on the sction bar
  final List<ActionBarWidget> actionBarWidgetsFirstRow;

  /// Items to show in custom popup menu
  final List<ActionBarWidget> actionBarWidgetsSecondRow;

  /// Sorters to show in the second row of the action bar
  final List<Sorter> actionBarSortByItems;

  /// Default podcast group
  final PodcastGroup? actionBarGroup;

  /// Default podcast
  final PodcastLocal? actionBarPodcast;

  /// Default sorter
  final Sorter actionBarSortBy;

  /// Default filter new
  final bool? actionBarFilterNew;

  /// Default filter liked
  final bool? actionBarFilterLiked;

  /// Default filter played
  final bool? actionBarFilterPlayed;

  /// Default filter downloaded
  final bool? actionBarFilterDownloaded;

  /// Default filter display version
  final bool? actionBarFilterDisplayVersion;

  /// Default sort order
  final SortOrder actionBarSortOrder;

  /// Default layout
  final EpisodeGridLayout layout;

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
    this.showGrid = true,
    this.actionBarWidgetsFirstRow = const [
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
    this.actionBarWidgetsSecondRow = const [
      ActionBarDropdownPodcasts(1, 0),
      ActionBarSearchTitle(1, 1),
      ActionBarSpacer(1, 2),
      ActionBarFilterDownloaded(1, 3),
      ActionBarFilterLiked(1, 4),
      ActionBarSwitchLayout(1, 5),
      ActionBarButtonRefresh(1, 6),
    ],
    this.actionBarSortByItems = const [
      Sorter.pubDate,
      Sorter.enclosureSize,
      Sorter.enclosureDuration,
      Sorter.random
    ],
    this.actionBarGroup,
    this.actionBarPodcast,
    this.actionBarSortBy = Sorter.pubDate,
    this.actionBarFilterNew,
    this.actionBarFilterLiked,
    this.actionBarFilterPlayed,
    this.actionBarFilterDownloaded,
    this.actionBarFilterDisplayVersion = true,
    this.actionBarSortOrder = SortOrder.desc,
    this.layout = EpisodeGridLayout.small,
  });

  @override
  State<StatefulWidget> createState() => _InteractiveEpisodeGridState();
}

class _InteractiveEpisodeGridState extends State<InteractiveEpisodeGrid> {
  _InteractiveEpisodeGridState();

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

  /// Layout of the grid
  late EpisodeGridLayout _layout = widget.layout;

  /// Stop animating after first scroll
  bool _scroll = false;

  /// The grid
  Widget? _grid;

  @override
  void didUpdateWidget(covariant InteractiveEpisodeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layout != _layout) {
      _layout = widget.layout;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> slivers = widget.additionalSliversList.toList();
    slivers.insert(
      widget.sliverInsertIndicies.actionBarIndex,
      ActionBar(
        onGetEpisodesChanged: (getEpisodes) async {
          _getEpisodes = getEpisodes;
          _episodes = await _getEpisodes(_top);
          if (mounted && context.mounted) {
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null) {
              selectionController.setSelectableEpisodes(_episodes);
            }
            setState(() {});
          }
        },
        onLayoutChanged: (layout) {
          _layout = layout;
          if (mounted) setState(() {});
        },
        widgetsFirstRow: widget.actionBarWidgetsFirstRow,
        widgetsSecondRow: widget.actionBarWidgetsSecondRow,
        sortByItems: widget.actionBarSortByItems,
        group: widget.actionBarGroup,
        podcast: widget.actionBarPodcast,
        sortBy: widget.actionBarSortBy,
        filterNew: widget.actionBarFilterNew,
        filterLiked: widget.actionBarFilterLiked,
        filterPlayed: widget.actionBarFilterPlayed,
        filterDownloaded: widget.actionBarFilterDownloaded,
        filterDisplayVersion: widget.actionBarFilterDisplayVersion,
        sortOrder: widget.actionBarSortOrder,
        layout: _layout,
      ),
    );
    slivers.insert(
      widget.sliverInsertIndicies.loadingIndicatorIndex,
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
    );
    slivers.insert(
      widget.sliverInsertIndicies.gridIndex,
      widget.showGrid
          ? Selector<EpisodeState, bool>(
              selector: (_, episodeState) => episodeState.globalChange,
              builder: (context, value, _) => FutureBuilder(
                future: Future.microtask(() async {
                  _episodes = await _getEpisodes(_top);
                  if (context.mounted) {
                    SelectionController? selectionController =
                        Provider.of<SelectionController?>(context,
                            listen: false);
                    if (selectionController != null) {
                      selectionController.setSelectableEpisodes(_episodes);
                    }
                    _grid = null;
                  }
                }),
                builder: (context, snapshot) {
                  _grid ??= EpisodeGrid(
                    episodes: _episodes,
                    initNum: widget.initNum,
                    preferEpisodeImage: widget.preferEpisodeImage,
                    layout: _layout,
                    openPodcast: widget.openPodcast,
                    selectable: widget.selectable,
                    externallyRefreshed: true,
                  );
                  return _episodes.isNotEmpty
                      ? _grid!
                      : SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 150),
                            child: widget.noEpisodesWidget,
                          ),
                        );
                },
              ),
            )
          : SliverToBoxAdapter(),
    );
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - context.width &&
            _episodes.length == _top) {
          if (!_loadMore) {
            Future.microtask(() async {
              _episodes.addAll(await _getEpisodes(36, offset: _top));
              _top = _top + 36;
              if (mounted && context.mounted) {
                SelectionController? selectionController =
                    Provider.of<SelectionController?>(context, listen: false);
                if (selectionController != null) {
                  selectionController.setSelectableEpisodes(_episodes);
                }
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
        child: CustomScrollView(
          slivers: slivers,
        ),
      ),
    );
  }
}

/// Widget that displays [InteractiveEpisodeCard]s in a grid.
class EpisodeGrid extends StatelessWidget {
  final List<EpisodeBrief> episodes;
  final bool preferEpisodeImage;
  final EpisodeGridLayout layout;
  final bool openPodcast;
  final bool selectable;
  final bool externallyRefreshed;

  /// Count of animation items.
  final int initNum;

  const EpisodeGrid({
    super.key,
    required this.episodes,
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
      showItemInterval: Duration(milliseconds: 50),
      showItemDuration: Duration(milliseconds: 50),
    );
    final scrollController = ScrollController();
    if (episodes.isNotEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        sliver: LiveSliverGrid.options(
          controller: scrollController,
          options: options,
          itemCount: episodes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: layout == EpisodeGridLayout.small
                ? 1
                : layout == EpisodeGridLayout.medium
                    ? 1.5
                    : 4,
            crossAxisCount: layout == EpisodeGridLayout.small
                ? 3
                : layout == EpisodeGridLayout.medium
                    ? 2
                    : 1,
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
          ),
          itemBuilder: (context, index, animation) {
            return FadeTransition(
              opacity: Tween<double>(begin: index < initNum ? 0 : 1, end: 1)
                  .animate(animation),
              child: InteractiveEpisodeCard(
                context,
                episodes[index],
                layout,
                openPodcast: openPodcast,
                preferEpisodeImage: preferEpisodeImage,
                showNumber: true,
                selectable: selectable,
                index: index,
                externallyRefreshed: externallyRefreshed,
              ),
            );
          },
        ),
      );
    } else {
      return SliverToBoxAdapter();
    }
  }
}
