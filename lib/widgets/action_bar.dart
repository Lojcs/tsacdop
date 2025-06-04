import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../state/podcast_group.dart';
import '../type/podcastlocal.dart';
import '../type/theme_data.dart';
import '../util/extension_helper.dart';
import '../util/selection_controller.dart';
import 'action_bar_generic_widgets.dart';
import 'package:tuple/tuple.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/episode_state.dart';
import '../state/refresh_podcast.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';

/// Bar with buttons to sort, filter episodes and control view.
/// Returns the get episodes callback with the [onGetEpisodeIdsChanged] callback.
/// Subwidgets can be chosen by passing [widgetsFirstRow] & [widgetsFirstRow]
/// Filters can be controlled from outside by passing them.
/// Configure colors with a [CardColorScheme] provided with a [ChangeNotifierProvider], defaults to the global theme
/// Select mode switch works when [SelectionController] if provided with a [ChangeNotifierProvider]
class ActionBar extends StatefulWidget {
  /// Callback to return the episode list based on filters
  final ValueSetter<Future<List<int>> Function(int count, {int offset})>
      onGetEpisodeIdsChanged;

  /// Callback to return the layout status
  final ValueChanged<EpisodeGridLayout>? onLayoutChanged;

  /// Items to show on the bar
  final List<ActionBarWidget> widgetsFirstRow;

  /// Items to show in custom popup menu
  final List<ActionBarWidget> widgetsSecondRow;

  /// Sorters to show in the sort by dropdown button
  final List<Sorter> sortByItems;

  /// Wheter to show integrated multiselect bar on select mode
  final bool showMultiSelectBar;

  /// Default second row
  final bool expandSecondRow;

  /// Pin sliver to top
  final bool pinned;

  /// Default podcast group
  final PodcastGroup? group;

  /// Default podcast
  final PodcastLocal? podcast;

  /// Default sorter
  final Sorter sortBy;

  /// Default filter new
  final bool? filterNew;

  /// Default filter liked
  final bool? filterLiked;

  /// Default filter played
  final bool? filterPlayed;

  /// Default filter downloaded
  final bool? filterDownloaded;

  /// Default filter display version
  final bool? filterDisplayVersion;

  /// Default sort order
  final SortOrder sortOrder;

  /// Default layout
  final EpisodeGridLayout layout;

  const ActionBar({
    super.key,
    required this.onGetEpisodeIdsChanged,
    this.onLayoutChanged,
    this.widgetsFirstRow = const [
      ActionBarDropdownSortBy(0, 0),
      ActionBarSwitchSortOrder(0, 1),
      ActionBarSpacer(0, 2),
      ActionBarButtonRefresh(0, 3),
      ActionBarButtonRemoveNewMark(0, 4),
      ActionBarFilterPlayed(0, 5),
      ActionBarFilterDownloaded(0, 6),
      ActionBarSwitchLayout(0, 7),
      ActionBarSwitchSelectMode(0, 8),
      ActionBarSwitchSecondRow(0, 9),
    ],
    this.widgetsSecondRow = const [
      ActionBarDropdownGroups(1, 0),
      ActionBarDropdownPodcasts(1, 1),
      ActionBarSearchTitle(1, 2),
      ActionBarSpacer(1, 3),
      ActionBarFilterNew(1, 4),
      ActionBarFilterLiked(1, 5),
    ],
    this.sortByItems = const [
      Sorter.pubDate,
      Sorter.enclosureSize,
      Sorter.enclosureDuration,
      Sorter.random
    ],
    this.showMultiSelectBar = false,
    this.expandSecondRow = false,
    this.pinned = true,
    this.group,
    this.podcast,
    this.sortBy = Sorter.pubDate,
    this.filterNew,
    this.filterLiked,
    this.filterPlayed,
    this.filterDownloaded,
    this.filterDisplayVersion,
    this.sortOrder = SortOrder.desc,
    this.layout = EpisodeGridLayout.large,
  });
  @override
  _ActionBarState createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> with TickerProviderStateMixin {
  late AnimationController _switchSecondRowController;
  late AnimationController _buttonRefreshController;
  late AnimationController _buttonRemoveNewMarkController;

  late _ActionBarSharedState _sharedState;

  bool initialBuild = true;
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _switchSecondRowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _buttonRefreshController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _buttonRemoveNewMarkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _switchSecondRowController.dispose();
    _buttonRefreshController.dispose();
    _buttonRemoveNewMarkController.dispose();
    _sharedState.dispose();
    _sharedState.disposed = true;
    super.dispose();
  }

  @override
  void didUpdateWidget(ActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expandSecondRow != widget.expandSecondRow) {
      _sharedState.expandSecondRow = widget.expandSecondRow;
    }
    if (oldWidget.group != widget.group) {
      _sharedState.group = widget.group;
    }
    if (oldWidget.podcast != widget.podcast) {
      _sharedState.podcast = widget.podcast;
    }
    if (oldWidget.sortBy != widget.sortBy) {
      _sharedState.sortBy = widget.sortBy;
    }
    if (oldWidget.filterNew != widget.filterNew) {
      _sharedState.filterNew = widget.filterNew;
    }
    if (oldWidget.filterLiked != widget.filterLiked) {
      _sharedState.filterLiked = widget.filterLiked;
    }
    if (oldWidget.filterPlayed != widget.filterPlayed) {
      _sharedState.filterPlayed = widget.filterPlayed;
    }
    if (oldWidget.filterDownloaded != widget.filterDownloaded) {
      _sharedState.filterDownloaded = widget.filterDownloaded;
    }
    if (oldWidget.sortOrder != widget.sortOrder) {
      _sharedState.sortOrder = widget.sortOrder;
    }
    if (oldWidget.layout != widget.layout) {
      _sharedState.layout = widget.layout;
    }
    if (oldWidget.expandSecondRow != widget.expandSecondRow) {
      if (widget.expandSecondRow) {
        _switchSecondRowController.forward();
      } else {
        _switchSecondRowController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (initialBuild) {
      initialBuild = false;
      _sharedState = _ActionBarSharedState(
        context,
        onGetEpisodeIdsChanged: widget.onGetEpisodeIdsChanged,
        onLayoutChanged: widget.onLayoutChanged,
        widgetsFirstRow: widget.widgetsFirstRow,
        widgetsSecondRow: widget.widgetsSecondRow,
        sortByItems: widget.sortByItems,
        expandSecondRow: widget.expandSecondRow,
        group: widget.group,
        podcast: widget.podcast,
        sortBy: widget.sortBy,
        filterNew: widget.filterNew,
        filterLiked: widget.filterLiked,
        filterPlayed: widget.filterPlayed,
        filterDownloaded: widget.filterDownloaded,
        filterDisplayVersion: widget.filterDisplayVersion,
        sortOrder: widget.sortOrder,
        layout: widget.layout,
        switchSecondRowController: _switchSecondRowController,
        buttonRefreshController: _buttonRefreshController,
        buttonRemoveNewMarkController: _buttonRemoveNewMarkController,
      );
      SelectionController? selectionController =
          Provider.of<SelectionController?>(context, listen: false);
      if (selectionController != null) {
        selectionController.onGetEpisodesLimitless = selectionController
            .onGetEpisodesLimitless = () => _sharedState.getGetEpisodes()(-1);
      }
    }
    CardColorScheme? cardColorScheme = Provider.of<CardColorScheme?>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<_ActionBarSharedState>.value(
            value: _sharedState),
        if (cardColorScheme == null)
          Provider<CardColorScheme>.value(
              value: Theme.of(context).extension<CardColorScheme>()!),
      ],
      builder: (context, child) => _ActionBarOuter(
        Row(children: widget.widgetsFirstRow),
        Row(children: widget.widgetsSecondRow),
        pinned: widget.pinned,
        surface: context.realDark
            ? context.surface
            : cardColorScheme?.colorScheme.surface,
      ),
    );
  }
}

class _ActionBarOuter extends StatefulWidget {
  final Widget firstRow;
  final Widget secondRow;
  final bool pinned;
  final Color? surface;
  const _ActionBarOuter(this.firstRow, this.secondRow,
      {required this.pinned, this.surface});

  @override
  __ActionBarOuterState createState() => __ActionBarOuterState();
}

class __ActionBarOuterState extends State<_ActionBarOuter>
    with TickerProviderStateMixin {
  double get totalHeight => Tween<double>(
          begin: 10 +
              context.actionBarIconSize +
              context.actionBarIconPadding.vertical * 3 / 2,
          end: 10 +
              context.actionBarIconSize * 2 +
              context.actionBarIconPadding.vertical * 3)
      .evaluate(_switchSecondRowSlideAnimation);

  late Animation<double> _switchSecondRowAppearAnimation;
  late Animation<double> _switchSecondRowSlideAnimation;

  @override
  void initState() {
    super.initState();
    _ActionBarSharedState actionBarSharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    actionBarSharedState.switchSecondRowController.addListener(() {
      if (mounted) setState(() {});
    });
    _switchSecondRowSlideAnimation = CurvedAnimation(
      parent: actionBarSharedState.switchSecondRowController,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCirc,
    );
    _switchSecondRowAppearAnimation = CurvedAnimation(
        parent: _switchSecondRowSlideAnimation, curve: Interval(0.75, 1));
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: widget.pinned,
      leading: Center(),
      toolbarHeight: totalHeight,
      backgroundColor: widget.surface ?? context.surface,
      scrolledUnderElevation: 0,
      flexibleSpace: SizedBox(
        height: totalHeight,
        child: Padding(
          padding: EdgeInsets.only(
            left: 8,
            top: 5,
            right: 8,
            bottom: 5 * _switchSecondRowAppearAnimation.value,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: context.actionBarIconPadding.left / 2,
                  top: context.actionBarIconPadding.top / 2,
                  right: context.actionBarIconPadding.right / 2,
                  bottom: context.actionBarIconPadding.bottom /
                      2 *
                      _switchSecondRowAppearAnimation.value,
                ),
                child: widget.firstRow,
              ),
              if (_switchSecondRowAppearAnimation.value >
                  0) // This still clips 10.5 pixels if the padding isn't animated
                Container(
                  padding: EdgeInsets.only(
                    left: context.actionBarIconPadding.left / 2,
                    top: context.actionBarIconPadding.top /
                        2 *
                        _switchSecondRowAppearAnimation.value,
                    right: context.actionBarIconPadding.right / 2,
                    bottom: context.actionBarIconPadding.bottom /
                        2 *
                        _switchSecondRowAppearAnimation.value,
                  ),
                  child: FadeTransition(
                    opacity: _switchSecondRowAppearAnimation,
                    child: widget.secondRow,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBarSharedState extends ChangeNotifier {
  final BuildContext context;
  final ValueSetter<Future<List<int>> Function(int count, {int offset})>
      onGetEpisodeIdsChanged;
  final ValueChanged<EpisodeGridLayout>? onLayoutChanged;

  final List<ActionBarWidget> widgetsFirstRow;
  final List<ActionBarWidget> widgetsSecondRow;
  final List<Sorter> sortByItems;

  bool _expandSecondRow;
  bool get expandSecondRow => _expandSecondRow;
  set expandSecondRow(bool boo) {
    if (_expandSecondRow != boo) {
      _expandSecondRow = boo;
      if (boo) {
        switchSecondRowController.forward();
      } else {
        switchSecondRowController.reverse();
      }
      notifyListeners();
    }
  }

  PodcastGroup _group;
  PodcastGroup get group => _group;
  set group(PodcastGroup? podcastGroup) {
    _group = podcastGroup ?? groupAll;
    notifyListeners();
  }

  PodcastLocal _podcast;
  PodcastLocal get podcast => _podcast;
  set podcast(PodcastLocal? podcastLocal) {
    _podcast = podcastLocal ?? podcastAll;
    notifyListeners();
  }

  Sorter _sortBy;
  Sorter get sortBy => _sortBy;
  set sortBy(Sorter sorter) {
    _sortBy = sorter;
    notifyListeners();
  }

  bool? _filterNew;
  bool? get filterNew => _filterNew;
  set filterNew(bool? boo) {
    _filterNew = boo;
    notifyListeners();
  }

  bool? _filterLiked;
  bool? get filterLiked => _filterLiked;
  set filterLiked(bool? boo) {
    _filterLiked = boo;
    notifyListeners();
  }

  bool? _filterPlayed;
  bool? get filterPlayed => _filterPlayed;
  set filterPlayed(bool? boo) {
    _filterPlayed = boo;
    notifyListeners();
  }

  bool? _filterDownloaded;
  bool? get filterDownloaded => _filterDownloaded;
  set filterDownloaded(bool? boo) {
    _filterDownloaded = boo;
    notifyListeners();
  }

  bool? _filterDisplayVersion;
  bool? get filterDisplayVersion => _filterDisplayVersion;
  set filterDisplayVersion(bool? boo) {
    _filterDisplayVersion = boo;
    notifyListeners();
  }

  SortOrder _sortOrder;
  SortOrder get sortOrder => _sortOrder;
  set sortOrder(SortOrder sortOrder) {
    _sortOrder = sortOrder;
    notifyListeners();
  }

  EpisodeGridLayout _layout;
  EpisodeGridLayout get layout => _layout;
  set layout(EpisodeGridLayout layout) {
    _layout = layout;
    notifyListeners();
  }

  final AnimationController switchSecondRowController;
  final AnimationController buttonRefreshController;
  final AnimationController buttonRemoveNewMarkController;

  _ActionBarSharedState(
    this.context, {
    required this.onGetEpisodeIdsChanged,
    required this.onLayoutChanged,
    required this.widgetsFirstRow,
    required this.widgetsSecondRow,
    required this.sortByItems,
    required bool expandSecondRow,
    required PodcastGroup? group,
    required PodcastLocal? podcast,
    required Sorter sortBy,
    required bool? filterNew,
    required bool? filterLiked,
    required bool? filterPlayed,
    required bool? filterDownloaded,
    required bool? filterDisplayVersion,
    required SortOrder sortOrder,
    required EpisodeGridLayout layout,
    required this.switchSecondRowController,
    required this.buttonRefreshController,
    required this.buttonRemoveNewMarkController,
  })  : _expandSecondRow = expandSecondRow,
        _group =
            group ?? PodcastGroup(context.s.all, podcastList: [], id: "All"),
        _podcast = podcast ??
            PodcastLocal(context.s.all, '', '', '', '', 'All', '', '', '', []),
        _sortBy = sortBy,
        _filterNew = filterNew,
        _filterLiked = filterLiked,
        _filterPlayed = filterPlayed,
        _filterDownloaded = filterDownloaded,
        _filterDisplayVersion = filterDisplayVersion,
        _sortOrder = sortOrder,
        _layout = layout {
    if (expandSecondRow) switchSecondRowController.forward();
    Future.microtask(() => onGetEpisodeIdsChanged(getGetEpisodes()));
  }

  bool _disposed = false;
  bool get disposed => _disposed;
  set disposed(bool a) {
    _disposed = true;
  }

  late final PodcastGroup groupAll =
      PodcastGroup(context.s.all, podcastList: [], id: "All");
  List<PodcastGroup> get groups => [
        groupAll,
        ...Provider.of<GroupList>(context, listen: false).groups.nonNulls
      ];
  double? maxGroupTitleWidth;

  late final PodcastLocal podcastAll =
      PodcastLocal(context.s.all, '', '', '', '', 'All', '', '', '', []);
  Future<List<PodcastLocal>> get podcasts async =>
      [podcastAll, ...await DBHelper().getPodcastLocalAll()];
  double? maxPodcastTitleWidth;

  String searchTitleQuery = "";

  List<int> episodeIds = [];
  List<int> get newEpisodeIds => episodeIds
      .where((e) => Provider.of<EpisodeState>(context, listen: false)[e].isNew)
      .toList();

  late ExpansionController expansionControllerFirstRow =
      ExpansionController(maxWidth: maxWidth);
  late ExpansionController expansionControllerSecondRow =
      ExpansionController(maxWidth: maxWidth);

  List<ExpansionController> get expansionControllers =>
      [expansionControllerFirstRow, expansionControllerSecondRow];
  late List<List<ActionBarWidget>> rows = [widgetsFirstRow, widgetsSecondRow];

  double maxWidth() =>
      context.width - (16 + context.actionBarIconPadding.horizontal / 2);

  Future<List<int>> Function(int count, {int offset}) getGetEpisodes() {
    return (int count, {int offset = -1}) async {
      episodeIds = await Provider.of<EpisodeState>(context, listen: false)
          .getEpisodes(
              feedIds: podcast != podcastAll
                  ? group.podcastList.isEmpty ||
                          group.podcastList.contains(podcast.id)
                      ? [podcast.id]
                      : []
                  : group.podcastList,
              likeEpisodeTitles:
                  searchTitleQuery == "" ? null : [searchTitleQuery],
              sortBy: sortBy,
              sortOrder: sortOrder,
              limit: count,
              offset: offset,
              filterNew: filterNew,
              filterLiked: filterLiked,
              filterPlayed: filterPlayed,
              filterDownloaded: filterDownloaded,
              filterDisplayVersion: filterDisplayVersion);
      return episodeIds;
    };
  }
}

abstract class ActionBarWidget extends StatelessWidget {
  final int rowIndex;
  final int index;
  const ActionBarWidget(this.rowIndex, this.index, {super.key});
}

class ActionBarSpacer extends ActionBarWidget {
  const ActionBarSpacer(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    return Spacer();
  }
}

sealed class ActionBarFilter extends ActionBarWidget {
  const ActionBarFilter(super.rowIndex, super.index, {super.key});
}

sealed class ActionBarSort extends ActionBarWidget {
  const ActionBarSort(super.rowIndex, super.index, {super.key});
}

sealed class ActionBarControl extends ActionBarWidget {
  const ActionBarControl(super.rowIndex, super.index, {super.key});
}

class ActionBarDropdownGroups extends ActionBarFilter {
  const ActionBarDropdownGroups(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, PodcastGroup>(
      selector: (_, sharedState) => sharedState.group,
      builder: (context, data, _) {
        if (sharedState.maxGroupTitleWidth == null) {
          double expandedWidth = context.actionBarButtonSizeHorizontal;
          for (var group in sharedState.groups) {
            final groupNameTest = TextPainter(
                text: TextSpan(
                  text: group.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                textDirection: TextDirection.ltr);
            groupNameTest.layout();
            expandedWidth =
                (groupNameTest.width + context.actionBarIconPadding.horizontal)
                    .clamp(expandedWidth, 200);
          }
          sharedState.maxGroupTitleWidth =
              expandedWidth; // It's tricky to update this after the fact.
        }
        return ActionBarDropdownButton<PodcastGroup>(
          selected: data,
          expansionController: sharedState.expansionControllers[rowIndex],
          expandedChild: Text(
            data.name!,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          itemBuilder: () => sharedState.groups
              .map<PopupMenuItem<PodcastGroup>>(
                (podcastGroup) => PopupMenuItem(
                  padding: context.actionBarIconPadding,
                  height: context.actionBarButtonSizeVertical,
                  value: podcastGroup,
                  child: Tooltip(
                    message: podcastGroup.name,
                    child: Text(
                      podcastGroup.name!,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
              .toList(),
          onSelected: (value) {
            sharedState.group = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          maxExpandedWidth: sharedState.maxGroupTitleWidth,
          tooltip: context.s.filterType(context.s.groups(1)),
          active: (value) => value != sharedState.groupAll,
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
          child: Icon(Icons.all_out, color: context.actionBarIconColor),
        );
      },
    );
  }
}

class ActionBarDropdownPodcasts extends ActionBarFilter {
  const ActionBarDropdownPodcasts(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, PodcastLocal>(
      selector: (_, sharedState) => sharedState.podcast,
      builder: (context, data, _) {
        return FutureBuilder<List<PodcastLocal>>(
          future: sharedState.podcasts,
          initialData: [],
          builder: (context, snapshot) {
            double expandedWidth = context.actionBarButtonSizeHorizontal;
            for (var podcast in snapshot.data!) {
              final podcastNameTest = TextPainter(
                  text: TextSpan(
                    text: podcast.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  textDirection: TextDirection.ltr);
              podcastNameTest.layout();
              expandedWidth = (podcastNameTest.width +
                      context.actionBarIconPadding.horizontal)
                  .clamp(expandedWidth, 200);
            }
            sharedState.maxPodcastTitleWidth =
                expandedWidth; // It's tricky to update this after the fact.
            return ActionBarDropdownButton<PodcastLocal>(
              selected: data,
              expansionController: sharedState.expansionControllers[rowIndex],
              expandedChild: Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              itemBuilder: () => snapshot.data!
                  .map<PopupMenuItem<PodcastLocal>>(
                    (podcast) => PopupMenuItem(
                      padding: context.actionBarIconPadding,
                      height: context.actionBarButtonSizeVertical,
                      value: podcast,
                      child: Tooltip(
                        message: podcast.title,
                        child: Text(
                          podcast.title!,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onSelected: (value) {
                sharedState.podcast = value;
                sharedState
                    .onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
              },
              maxExpandedWidth: sharedState.maxPodcastTitleWidth,
              tooltip: context.s.filterType(context.s.podcast(1)),
              active: (value) => value != sharedState.podcastAll,
              connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
              connectRight:
                  index != row.length - 1 && row[index + 1] is ActionBarFilter,
              child: Icon(Icons.podcasts, color: context.actionBarIconColor),
            );
          },
        );
      },
    );
  }
}

class ActionBarDropdownSortBy extends ActionBarSort {
  const ActionBarDropdownSortBy(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, Sorter>(
      selector: (_, sharedState) => sharedState.sortBy,
      builder: (context, data, _) {
        return ActionBarDropdownButton<Sorter>(
          selected: data,
          expansionController: sharedState.expansionControllers[rowIndex],
          itemBuilder: () => _getSortBy(context, sharedState.sortByItems),
          onSelected: (value) {
            sharedState.sortBy = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          tooltip: context.s.sortBy,
          active: (_) => true,
          connectLeft: index != 0 && row[index - 1] is ActionBarSort,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarSort,
          child: _getSorterIcon(context, sharedState.sortBy),
        );
      },
    );
  }
}

List<PopupMenuEntry<Sorter>> _getSortBy(
    BuildContext context, List<Sorter> sortByItems) {
  List<PopupMenuEntry<Sorter>> items = [];
  var s = context.s;
  for (final sorter in sortByItems) {
    switch (sorter) {
      case Sorter.pubDate:
        items.add(PopupMenuItem(
          padding: context.actionBarIconPadding,
          height: context.actionBarButtonSizeVertical,
          value: Sorter.pubDate,
          child: Tooltip(
            message: s.publishDate,
            child: _getSorterIcon(context, sorter),
          ),
        ));
        break;
      case Sorter.enclosureSize:
        items.add(PopupMenuItem(
          padding: context.actionBarIconPadding,
          height: context.actionBarButtonSizeVertical,
          value: Sorter.enclosureSize,
          child: Tooltip(
            message: s.size,
            child: _getSorterIcon(context, sorter),
          ),
        ));
        break;
      case Sorter.enclosureDuration:
        items.add(PopupMenuItem(
          padding: context.actionBarIconPadding,
          height: context.actionBarButtonSizeVertical,
          value: Sorter.enclosureDuration,
          child: Tooltip(
            message: s.duration,
            child: _getSorterIcon(context, sorter),
          ),
        ));
        break;
      case Sorter.downloadDate:
        items.add(PopupMenuItem(
          padding: context.actionBarIconPadding,
          height: context.actionBarButtonSizeVertical,
          value: Sorter.downloadDate,
          child: Tooltip(
            message: s.downloadDate,
            child: _getSorterIcon(context, sorter),
          ),
        ));
        break;
      case Sorter.likedDate:
        items.add(PopupMenuItem(
          padding: context.actionBarIconPadding,
          height: context.actionBarButtonSizeVertical,
          value: Sorter.likedDate,
          child: Tooltip(
            message: s.likeDate,
            child: _getSorterIcon(context, sorter),
          ),
        ));
        break;
      case Sorter.random:
        items.add(PopupMenuItem(
          padding: context.actionBarIconPadding,
          height: context.actionBarButtonSizeVertical,
          value: Sorter.random,
          child: Tooltip(
            message: s.random,
            child: _getSorterIcon(context, sorter),
          ),
        ));
        break;
    }
  }
  return items;
}

Icon _getSorterIcon(BuildContext context, Sorter sorter) {
  switch (sorter) {
    case Sorter.pubDate:
      return Icon(Icons.date_range, color: context.actionBarIconColor);
    case Sorter.enclosureSize:
      return Icon(Icons.data_usage, color: context.actionBarIconColor);
    case Sorter.enclosureDuration:
      return Icon(Icons.timer_outlined, color: context.actionBarIconColor);
    // downloadDate and likedDate could have better icons
    case Sorter.downloadDate:
      return Icon(Icons.download_for_offline_outlined,
          color: context.actionBarIconColor);
    case Sorter.likedDate:
      return Icon(Icons.favorite_border, color: context.actionBarIconColor);
    case Sorter.random:
      return Icon(Icons.question_mark, color: context.actionBarIconColor);
  }
}

class ActionBarFilterNew extends ActionBarFilter {
  const ActionBarFilterNew(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterNew,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterNew = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          tooltip: context.s.filterType(context.s.newPlain),
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: Icon(
              Icons.new_releases_outlined,
              color: context.actionBarIconColor,
            ),
          ),
        );
      },
    );
  }
}

class ActionBarFilterLiked extends ActionBarFilter {
  const ActionBarFilterLiked(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterLiked,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterLiked = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          tooltip: context.s.filterType(context.s.liked),
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child:
                Icon(Icons.favorite_border, color: context.actionBarIconColor),
          ),
        );
      },
    );
  }
}

class ActionBarFilterPlayed extends ActionBarFilter {
  const ActionBarFilterPlayed(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterPlayed,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterPlayed = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          tooltip: context.s.filterType(context.s.listened),
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: CustomPaint(
              painter: ListenedPainter(context.actionBarIconColor, stroke: 2),
            ),
          ),
        );
      },
    );
  }
}

class ActionBarFilterDownloaded extends ActionBarFilter {
  const ActionBarFilterDownloaded(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterDownloaded,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterDownloaded = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          tooltip: context.s.filterType(context.s.downloaded),
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: CustomPaint(
              painter: DownloadPainter(
                color: context.actionBarIconColor,
                fraction: 0,
                progressColor: context.actionBarIconColor,
                progress: 0,
                stroke: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ActionBarFilterDisplayVersion extends ActionBarFilter {
  const ActionBarFilterDisplayVersion(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterDisplayVersion,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterDisplayVersion = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          tooltip: context.s.filterType(context.s.displayVersion),
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: Icon(
              Icons.difference_outlined,
              color: context.actionBarIconColor,
            ),
          ),
        );
      },
    );
  }
}

class ActionBarSwitchSortOrder extends ActionBarSort {
  const ActionBarSwitchSortOrder(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, Tuple2<SortOrder, Sorter>>(
      selector: (_, sharedState) =>
          Tuple2(sharedState.sortOrder, sharedState.sortBy),
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          buttonType: ActionBarButtonType.single,
          onPressed: (value) {
            switch (data.item1) {
              case SortOrder.asc:
                sharedState.sortOrder = SortOrder.desc;
                break;
              case SortOrder.desc:
                sharedState.sortOrder = SortOrder.asc;
                break;
            }
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          tooltip: context.s.sortOrder,
          connectLeft: index != 0 && row[index - 1] is ActionBarSort,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarSort,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: Icon(
              data.item2 == Sorter.random
                  ? Icons.casino_outlined
                  : data.item1 == SortOrder.asc
                      ? LineIcons.sortAmountUp
                      : LineIcons.sortAmountDown,
              color: context.actionBarIconColor,
            ),
          ),
        );
      },
    );
  }
}

class ActionBarSwitchLayout extends ActionBarControl {
  const ActionBarSwitchLayout(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    double height = 10;
    double width = 30;
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, EpisodeGridLayout>(
      selector: (_, sharedState) => sharedState.layout,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          buttonType: ActionBarButtonType.single,
          onPressed: (value) {
            switch (data) {
              case EpisodeGridLayout.small:
                sharedState.layout = EpisodeGridLayout.large;
                break;
              case EpisodeGridLayout.medium:
                sharedState.layout = EpisodeGridLayout.small;
                break;
              case EpisodeGridLayout.large:
                sharedState.layout = EpisodeGridLayout.medium;
                break;
            }
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
            if (sharedState.onLayoutChanged != null) {
              sharedState.onLayoutChanged!(sharedState.layout);
            }
          },
          width: width + context.actionBarIconPadding.horizontal,
          innerPadding: EdgeInsets.only(
            left: context.actionBarIconPadding.left,
            top: (context.actionBarButtonSizeVertical - height) / 2,
            right: context.actionBarIconPadding.right,
            bottom: (context.actionBarButtonSizeVertical - height) / 2,
          ),
          tooltip: context.s.changeLayout,
          connectLeft: index != 0 && row[index - 1] is ActionBarControl,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarControl,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: data == EpisodeGridLayout.small
                ? CustomPaint(
                    painter:
                        LayoutPainter(0, context.actionBarIconColor, stroke: 2),
                  )
                : data == EpisodeGridLayout.medium
                    ? CustomPaint(
                        painter: LayoutPainter(1, context.actionBarIconColor,
                            stroke: 2),
                      )
                    : CustomPaint(
                        painter: LayoutPainter(4, context.actionBarIconColor,
                            stroke: 2),
                      ),
          ),
        );
      },
    );
  }
}

class ActionBarSwitchSelectMode extends ActionBarControl {
  const ActionBarSwitchSelectMode(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    double height = 10;
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    if (Provider.of<SelectionController?>(context, listen: false) != null) {
      return Selector<SelectionController, bool>(
        selector: (_, selectionController) => selectionController.selectMode,
        builder: (context, data, _) {
          return ActionBarButton(
            expansionController: sharedState.expansionControllers[rowIndex],
            state: data,
            buttonType: ActionBarButtonType.onOff,
            onPressed: (value) {
              Provider.of<SelectionController>(context, listen: false)
                  .selectMode = value!;
            },
            innerPadding: EdgeInsets.only(
              left: context.actionBarIconPadding.left,
              top: (context.actionBarButtonSizeVertical - height) / 2,
              right: context.actionBarIconPadding.right,
              bottom: (context.actionBarButtonSizeVertical - height) / 2,
            ),
            tooltip: context.s.selectMode,
            enabled: true,
            connectLeft: index != 0 && row[index - 1] is ActionBarControl,
            connectRight:
                index != row.length - 1 && row[index + 1] is ActionBarControl,
            child: SizedBox(
              height: context.actionBarButtonSizeVertical,
              width: context.actionBarButtonSizeHorizontal,
              child: CustomPaint(
                  painter:
                      MultiSelectPainter(color: context.actionBarIconColor)),
            ),
          );
        },
      );
    } else {
      return ActionBarButton(
        expansionController: sharedState.expansionControllers[rowIndex],
        state: false,
        buttonType: ActionBarButtonType.onOff,
        onPressed: (value) {
          Provider.of<SelectionController>(context, listen: false).selectMode =
              value!;
        },
        innerPadding: EdgeInsets.only(
          left: context.actionBarIconPadding.left,
          top: (context.actionBarButtonSizeVertical - height) / 2,
          right: context.actionBarIconPadding.right,
          bottom: (context.actionBarButtonSizeVertical - height) / 2,
        ),
        tooltip: context.s.selectMode,
        enabled: false,
        connectLeft: index != 0 && row[index - 1] is ActionBarControl,
        connectRight:
            index != row.length - 1 && row[index + 1] is ActionBarControl,
        child: SizedBox(
          height: context.actionBarButtonSizeVertical,
          width: context.actionBarButtonSizeHorizontal,
          child: CustomPaint(
              painter: MultiSelectPainter(
                  color: context.realDark
                      ? Colors.grey[800]!
                      : context.actionBarIconColor)),
        ),
      );
    }
  }
}

class ActionBarSwitchSecondRow extends ActionBarControl {
  const ActionBarSwitchSecondRow(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, bool>(
      selector: (_, sharedState) => sharedState.expandSecondRow,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.onOff,
          onPressed: (value) {
            sharedState.expandSecondRow = value!;
            switch (value) {
              case false:
                sharedState.switchSecondRowController.reverse();
                break;
              case true:
                sharedState.switchSecondRowController.forward();
                sharedState.expansionControllerSecondRow =
                    ExpansionController(maxWidth: sharedState.maxWidth);
                break;
            }
          },
          tooltip: context.s.moreOptions,
          animation: sharedState.switchSecondRowController,
          connectLeft: index != 0 && row[index - 1] is ActionBarControl,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarControl,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: UpDownIndicator(
                status: data, color: context.actionBarIconColor),
          ),
        );
      },
    );
  }
}

class ActionBarButtonRefresh extends ActionBarControl {
  const ActionBarButtonRefresh(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return ActionBarButton(
      expansionController: sharedState.expansionControllers[rowIndex],
      buttonType: ActionBarButtonType.single,
      onPressed: (value) async {
        if (sharedState.buttonRefreshController.value == 0) {
          final refreshWorker = context.read<RefreshWorker>();
          if (sharedState.podcast != sharedState.podcastAll) {
            refreshWorker.start([sharedState.podcast.id]);
          } else if (sharedState.group != sharedState.podcastAll) {
            refreshWorker.start(sharedState.group.podcastList);
          } else {
            refreshWorker.start([]);
          }
          sharedState.buttonRefreshController.forward();
          Fluttertoast.showToast(
            msg: context.s.refreshStarted,
            gravity: ToastGravity.BOTTOM,
          );
          String refreshFinished = context.s.refreshFinished;
          refreshWorker.addListener(() {
            if (refreshWorker.complete) {
              Fluttertoast.cancel();
              Fluttertoast.showToast(
                msg: refreshFinished,
                gravity: ToastGravity.BOTTOM,
              );
              if (!sharedState.disposed) {
                sharedState.buttonRefreshController.reverse();
                // Calling this in the listener messes up provider.
                Future.microtask(() => sharedState
                    .onGetEpisodeIdsChanged(sharedState.getGetEpisodes()));
              }
            }
          });
        }
      },
      tooltip: context.s.refresh,
      animation: sharedState.buttonRefreshController,
      connectLeft: index != 0 && row[index - 1] is ActionBarControl,
      connectRight:
          index != row.length - 1 && row[index + 1] is ActionBarControl,
      child: SizedBox(
        height: context.actionBarButtonSizeVertical,
        width: context.actionBarButtonSizeHorizontal,
        child: Icon(Icons.refresh, color: context.actionBarIconColor),
      ),
    );
  }
}

class ActionBarButtonRemoveNewMark extends ActionBarControl {
  const ActionBarButtonRemoveNewMark(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, (bool, List<int>)>(
      selector: (_, sharedState) {
        List<int> newEpisodes = sharedState.newEpisodeIds;
        return (newEpisodes.isNotEmpty, newEpisodes);
      },
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          buttonType: ActionBarButtonType.single,
          onPressed: (value) async {
            if (sharedState.buttonRemoveNewMarkController.value == 0) {
              sharedState.buttonRemoveNewMarkController.forward();
              await Provider.of<EpisodeState>(context, listen: false)
                  .unsetNew(data.$2);
              await Future.delayed(Duration(seconds: 1));
              sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
              sharedState.buttonRemoveNewMarkController.reverse();
              // It's supposed to disable immediately but it doesn't so at least turn off the selection
            }
          },
          tooltip: context.s.removeNewMark,
          enabled: data.$1,
          animation: sharedState.buttonRemoveNewMarkController,
          connectLeft: index != 0 && row[index - 1] is ActionBarControl,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarControl,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: CustomPaint(
              painter: RemoveNewFlagPainter(
                  !data.$1 && context.realDark
                      ? Colors.grey[800]
                      : context.actionBarIconColor,
                  data.$1
                      ? Colors.red
                      : context.realDark
                          ? Colors.grey[800]!
                          : context.actionBarIconColor,
                  stroke: 2),
            ),
          ),
        );
      },
    );
  }
}

class ActionBarSearchTitle extends ActionBarFilter {
  const ActionBarSearchTitle(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    _ActionBarSharedState sharedState =
        Provider.of<_ActionBarSharedState>(context, listen: false);
    final row = sharedState.rows[rowIndex];
    return Selector<_ActionBarSharedState, String>(
      selector: (_, sharedState) => sharedState.searchTitleQuery,
      builder: (context, data, _) {
        return ActionBarExpandingSearchButton(
          query: data,
          expansionController: sharedState.expansionControllers[rowIndex],
          onQueryChanged: (value) async {
            sharedState.searchTitleQuery = value;
            sharedState.onGetEpisodeIdsChanged(sharedState.getGetEpisodes());
          },
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
        );
      },
    );
  }
}

Future<(EpisodeGridLayout, bool?)> getLayoutAndShowListened(
    {String layoutKey = podcastLayoutKey}) async {
  final layoutStorage = KeyValueStorage(layoutKey);
  final index = await layoutStorage.getInt(defaultValue: 1);
  EpisodeGridLayout layout = EpisodeGridLayout.values[index];
  final hideListenedStorage = KeyValueStorage(hideListenedKey);
  bool hideListened = await hideListenedStorage.getBool(defaultValue: false);
  return (layout, hideListened ? false : null);
}
