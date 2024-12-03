import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/state/podcast_group.dart';
import 'package:tsacdop/type/episodebrief.dart';
import 'package:tsacdop/type/podcastlocal.dart';
import 'package:tsacdop/util/extension_helper.dart';
import 'package:tsacdop/util/selection_controller.dart';
import 'package:tsacdop/widgets/action_bar_generic_widgets.dart';
import 'package:tuple/tuple.dart';
import 'package:webfeed/domain/media/group.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/episode_state.dart';
import '../state/refresh_podcast.dart';
import 'custom_dropdown.dart';
import 'custom_popupmenu.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';

enum ActionBarEntry {
  dropdownGroups,
  dropdownPodcasts,
  dropdownSortBy,
  filterNew,
  filterLiked,
  filterPlayed,
  filterDownloaded,
  switchSortOrder,
  switchLayout,
  switchSelectMode,
  switchSecondRow,
  buttonRefresh,
  buttonRemoveNewMark,
  searchTitle,
  spacer,
}

/// Action bar to use with episodegrid
class ActionBar extends StatefulWidget {
  /// Callback to return the episode list based on filters
  final ValueSetter<ValueGetter<Future<List<EpisodeBrief>>>>
      onGetEpisodesChanged;

  /// Callback to return the layout status
  final ValueChanged<Layout>? onLayoutChanged;

  /// Callback to return the select mode status
  final ValueChanged<double>? onHeightChanged;

  /// Wheter to show integrated multiselect bar on select mode
  final bool showMultiSelectBar;

  /// Items to show on the bar
  final List<ActionBarEntry> itemsFirstRow;

  /// Items to show in custom popup menu
  final List<ActionBarEntry> itemsSecondRow;

  /// Sorters to show in the sort by dropdown button
  final List<Sorter> sortByItems;

  /// Accent color to use
  final Color? color;

  /// For late animation start
  final bool hide;

  /// Limit of episode list size
  final int limit;

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

  /// Default sort order
  final SortOrder sortOrder;

  /// Default layout (overrides general default)
  final Layout layout;

  /// Controller for select mode. Necessary for the button to be enabled
  final SelectionController? selectionController;

  /// Default second row
  final bool secondRow;

  const ActionBar({
    required this.onGetEpisodesChanged,
    this.onLayoutChanged,
    this.onHeightChanged,
    this.showMultiSelectBar = true,
    this.itemsFirstRow = const [
      ActionBarEntry.dropdownSortBy,
      ActionBarEntry.switchSortOrder,
      ActionBarEntry.spacer,
      ActionBarEntry.buttonRefresh,
      ActionBarEntry.buttonRemoveNewMark,
      ActionBarEntry.filterPlayed,
      ActionBarEntry.filterDownloaded,
      ActionBarEntry.switchLayout,
      ActionBarEntry.switchSelectMode,
      ActionBarEntry.switchSecondRow,
    ],
    this.itemsSecondRow = const [
      // ActionBarEntry.dropdownGroups,
      // ActionBarEntry.dropdownPodcasts,
      ActionBarEntry.searchTitle,
      ActionBarEntry.spacer,
      ActionBarEntry.filterNew,
      ActionBarEntry.filterLiked,
    ],
    this.sortByItems = const [
      Sorter.pubDate,
      Sorter.enclosureSize,
      Sorter.enclosureDuration,
      Sorter.random
    ],
    this.color,
    this.hide = false,
    this.limit = 100,
    this.group,
    this.podcast,
    this.sortBy = Sorter.pubDate,
    this.filterNew,
    this.filterLiked,
    this.filterPlayed,
    this.filterDownloaded,
    this.sortOrder = SortOrder.DESC,
    this.layout = Layout.large,
    this.selectionController,
    this.secondRow = false,
  });
  @override
  _ActionBarState createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> with TickerProviderStateMixin {
  /// Accent color to use
  late final Color color = widget.color ?? context.accentColor;
  late final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: color,
    brightness: Brightness.dark,
  );
  late Color activeColor = context.realDark
      ? colorScheme.secondaryContainer
      : color.toStrongBackround(context);

  late PodcastGroup group;
  late final PodcastGroup _groupAll;
  late final List<PodcastGroup?> groups;

  late PodcastLocal podcast;
  late final PodcastLocal _podcastAll;
  late List<PodcastLocal> podcasts;

  late Sorter sortBy = widget.sortBy;
  late bool? filterNew = widget.filterNew;
  late bool? filterLiked = widget.filterLiked;
  late bool? filterPlayed = widget.filterPlayed;
  late bool? filterDownloaded = widget.filterDownloaded;
  late SortOrder sortOrder = widget.sortOrder;
  late Layout layout = widget.layout;
  late final SelectionController? selectionController =
      widget.selectionController;
  late bool selectMode =
      selectionController != null ? selectionController!.selectMode : false;
  late bool secondRow = widget.secondRow;

  double get totalHeight => Tween<double>(
          begin: 10 + context.iconSize + context.iconPadding.vertical * 3 / 2,
          end: 10 + context.iconSize * 2 + context.iconPadding.vertical * 3)
      .evaluate(_switchSecondRowSlideAnimation);
  String searchTitleQuery = "";

  late ExpansionController _expansionControllerFirstRow =
      ExpansionController(maxWidth: () => context.width);
  late ExpansionController _expansionControllerSecondRow =
      ExpansionController(maxWidth: () => context.width);

  List<ActionBarEntry> entryList(int rowIndex) =>
      [widget.itemsFirstRow, widget.itemsSecondRow][rowIndex];
  ExpansionController expansionController(int rowIndex) =>
      [_expansionControllerFirstRow, _expansionControllerSecondRow][rowIndex];

  List<EpisodeBrief> episodes = [];

  bool initialBuild = true;
  late DBHelper _dbHelper;

  final Duration _durationShort = const Duration(milliseconds: 300);
  final Duration _durationMedium = const Duration(milliseconds: 500);

  late AnimationController _switchSelectModeController;
  late AnimationController _switchSecondRowController;
  late Animation<double> _switchSecondRowAppearAnimation;
  late Animation<double> _switchSecondRowSlideAnimation;
  late AnimationController _buttonRefreshController;
  late AnimationController _buttonRemoveNewMarkController;

  Set<ActionBarEntry> filterEntries = {
    ActionBarEntry.dropdownGroups,
    ActionBarEntry.dropdownPodcasts,
    ActionBarEntry.filterNew,
    ActionBarEntry.filterLiked,
    ActionBarEntry.filterPlayed,
    ActionBarEntry.filterDownloaded,
    ActionBarEntry.searchTitle,
  };

  Set<ActionBarEntry> controlEntriesWithoutRemoveNewMark = {
    ActionBarEntry.switchLayout,
    ActionBarEntry.switchSelectMode,
    ActionBarEntry.switchSecondRow,
    ActionBarEntry.buttonRefresh,
  };
  Set<ActionBarEntry> controlEntriesWithRemoveNewMark = {
    ActionBarEntry.switchLayout,
    ActionBarEntry.switchSelectMode,
    ActionBarEntry.switchSecondRow,
    ActionBarEntry.buttonRefresh,
    ActionBarEntry.buttonRemoveNewMark,
  };

  @override
  void initState() {
    super.initState();
    if (selectionController != null) {
      selectionController!.addListener(() {
        if (selectMode != selectionController!.selectMode) {
          if (selectionController!.selectMode) {
            _switchSelectModeController.forward();
          } else {
            _switchSelectModeController.reverse();
          }
          if (mounted) {
            setState(() => selectMode = selectionController!.selectMode);
          }
        }
      });
      selectionController!.onGetEpisodesLimitless = () => _dbHelper.getEpisodes(
            feedIds: podcast != _podcastAll
                ? group.podcastList.isEmpty ||
                        group.podcastList.contains(podcast.id)
                    ? [podcast.id]
                    : []
                : group.podcastList,
            likeEpisodeTitles:
                searchTitleQuery == "" ? null : [searchTitleQuery],
            optionalFields: [
              EpisodeField.description,
              EpisodeField.number,
              EpisodeField.enclosureDuration,
              EpisodeField.enclosureSize,
              EpisodeField.isDownloaded,
              EpisodeField.episodeImage,
              EpisodeField.podcastImage,
              EpisodeField.primaryColor,
              EpisodeField.isLiked,
              EpisodeField.isNew,
              EpisodeField.isPlayed,
              EpisodeField.versionInfo
            ],
            sortBy: sortBy,
            sortOrder: sortOrder,
            filterVersions: 1,
            filterNew: filterNew,
            filterLiked: filterLiked,
            filterPlayed: filterPlayed,
            filterDownloaded: filterDownloaded,
          );
    }
    _dbHelper = DBHelper();
    _initAnimations();
  }

  void _initAnimations() {
    _switchSelectModeController =
        AnimationController(vsync: this, duration: _durationShort)
          ..addListener(_animationListener);
    _switchSecondRowController =
        AnimationController(vsync: this, duration: _durationMedium)
          ..addListener(() {
            if (mounted) setState(() {});
            if (widget.onHeightChanged != null) {
              widget.onHeightChanged!(totalHeight);
            }
          });
    _buttonRefreshController =
        AnimationController(vsync: this, duration: _durationShort)
          ..addListener(_animationListener);
    _buttonRemoveNewMarkController =
        AnimationController(vsync: this, duration: _durationShort)
          ..addListener(_animationListener);

    _switchSecondRowSlideAnimation = CurvedAnimation(
      parent: _switchSecondRowController,
      curve: Curves.easeInOutExpo,
    );
    _switchSecondRowAppearAnimation = CurvedAnimation(
        parent: _switchSecondRowSlideAnimation, curve: Interval(0.75, 1));

    if (selectMode) _switchSelectModeController.forward();
    if (secondRow) _switchSecondRowController.forward();
  }

  void _animationListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _switchSelectModeController.dispose();
    _switchSecondRowController.dispose();
    _buttonRefreshController.dispose();
    _buttonRemoveNewMarkController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.limit != widget.limit) {
      widget.onGetEpisodesChanged(_getGetEpisodes());
    }
    if (oldWidget.layout != widget.layout) {
      layout = widget.layout;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (initialBuild) {
      _groupAll = PodcastGroup(context.s.all, podcastList: []);
      groups = [_groupAll]
        ..addAll(Provider.of<GroupList>(context, listen: false).groups);
      _podcastAll =
          PodcastLocal(context.s.all, '', '', '', '', '', '', '', '', []);
      podcasts = [_podcastAll];
      group = widget.group ?? _groupAll;
      podcast = widget.podcast ?? _podcastAll;
      widget.onGetEpisodesChanged(_getGetEpisodes(getPodcasts: true));
      initialBuild = false;
      _expansionControllerSecondRow
          .addWidth(16 + context.iconPadding.horizontal / 2);
    }
    return SizedBox(
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
                left: context.iconPadding.left / 2,
                top: context.iconPadding.top / 2,
                right: context.iconPadding.right / 2,
                bottom: context.iconPadding.bottom /
                    2 *
                    _switchSecondRowAppearAnimation.value,
              ),
              child: Row(
                children: getRowWidgets(0),
              ),
            ),
            if (_switchSecondRowAppearAnimation.value >
                0) // This still clips 10.5 pixels if the padding isn't animated
              Container(
                padding: EdgeInsets.only(
                  // left: iconPadding.left / 2,
                  top: context.iconPadding.top /
                      2 *
                      _switchSecondRowAppearAnimation.value,
                  right: context.iconPadding.right / 2,
                  bottom: context.iconPadding.bottom /
                      2 *
                      _switchSecondRowAppearAnimation.value,
                ),
                child: FadeTransition(
                  opacity: _switchSecondRowAppearAnimation,
                  child: Row(
                    children: getRowWidgets(1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> getRowWidgets(int rowIndex) {
    List<Widget> widgets = [];
    expansionController(rowIndex).resetWidth();
    expansionController(rowIndex)
        .addWidth(16 + context.iconPadding.horizontal / 2);
    for (int i = 0; i < entryList(rowIndex).length; i++) {
      Widget newWidget = _getWidget(rowIndex, i);
      widgets.add(newWidget);
    }
    return widgets;
  }

  Widget _getWidget(int rowIndex, int index) {
    bool connectLeft = false;
    bool connectRight = false;
    switch (entryList(rowIndex)[index]) {
      case ActionBarEntry.dropdownGroups:
        if (index - 1 >= 0 &&
            filterEntries.contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            filterEntries.contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _dropdownGroups(
            expansionController: expansionController(rowIndex),
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.dropdownPodcasts:
        if (index - 1 >= 0 &&
            filterEntries.contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            filterEntries.contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _dropdownPodcasts(
            expansionController: expansionController(rowIndex),
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.dropdownSortBy:
        if (index - 1 >= 0 &&
            entryList(rowIndex)[index - 1] == ActionBarEntry.switchSortOrder) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            entryList(rowIndex)[index + 1] == ActionBarEntry.switchSortOrder) {
          connectRight = true;
        }
        return _dropDownSortBy(
          rowIndex: rowIndex,
          connectLeft: connectLeft,
          connectRight: connectRight,
        );

      case ActionBarEntry.filterNew:
        if (index - 1 >= 0 &&
            filterEntries.contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            filterEntries.contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _filterNew(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.filterLiked:
        if (index - 1 >= 0 &&
            filterEntries.contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            filterEntries.contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _filterLiked(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.filterPlayed:
        if (index - 1 >= 0 &&
            filterEntries.contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            filterEntries.contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _filterPlayed(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.filterDownloaded:
        if (index - 1 >= 0 &&
            filterEntries.contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            filterEntries.contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _filterDownloaded(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.switchSortOrder:
        if (index - 1 >= 0 &&
            entryList(rowIndex)[index - 1] == ActionBarEntry.dropdownSortBy) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            entryList(rowIndex)[index + 1] == ActionBarEntry.dropdownSortBy) {
          connectRight = true;
        }
        return _switchSortOrder(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.switchLayout:
        if (index - 1 >= 0 &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _switchLayout(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.switchSelectMode:
        if (index - 1 >= 0 &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _switchSelectMode(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.switchSecondRow:
        if (index - 1 >= 0 &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _switchSecondRow(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.buttonRefresh:
        if (index - 1 >= 0 &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _buttonRefresh(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.buttonRemoveNewMark:
        if (index - 1 >= 0 &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            controlEntriesWithRemoveNewMark
                .contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _buttonRemoveNewMark(
            rowIndex: rowIndex,
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.searchTitle:
        if (index - 1 >= 0 &&
            filterEntries.contains(entryList(rowIndex)[index - 1])) {
          connectLeft = true;
        }
        if (index + 1 < entryList(rowIndex).length &&
            filterEntries.contains(entryList(rowIndex)[index + 1])) {
          connectRight = true;
        }
        return _searchTitle(
            expansionController: expansionController(rowIndex),
            connectLeft: connectLeft,
            connectRight: connectRight);

      case ActionBarEntry.spacer:
        return Spacer();
    }
  }

  Widget _dropdownGroups({
    required ExpansionController expansionController,
    bool connectLeft = false,
    bool connectRight = false,
  }) {
    double expandedWidth = context.iconButtonSizeHorizontal;
    for (var group in groups) {
      if (group != null) {
        final groupNameTest = TextPainter(
            text: TextSpan(
              text: group.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            textDirection: TextDirection.ltr);
        groupNameTest.layout();
        expandedWidth = (groupNameTest.width + context.iconPadding.horizontal)
            .clamp(expandedWidth, 200);
      }
    }
    expansionController.addWidth(
        (!connectLeft ? context.iconPadding.left / 2 : 0) +
            (!connectRight ? context.iconPadding.right / 2 : 0));
    return ActionBarDropdownButton<PodcastGroup>(
        child: Icon(Icons.all_out),
        selected: group,
        expansionController: expansionController,
        expandedChild: Text(
          group.name!,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        itemBuilder: _getGroups,
        onSelected: (value) {
          if (mounted) setState(() => group = value);
          widget.onGetEpisodesChanged(_getGetEpisodes());
        },
        maxExpandedWidth: expandedWidth,
        color: color,
        activeColor: activeColor,
        tooltip: context.s.filterType(context.s.groups(1)),
        active: (value) => value != _groupAll,
        connectLeft: connectLeft,
        connectRight: connectRight);
  }

  List<PopupMenuEntry<PodcastGroup>> _getGroups() {
    List<PopupMenuEntry<PodcastGroup>> items = [];
    for (final group in groups) {
      if (group != null) {
        items.add(PopupMenuItem(
          child: Tooltip(
            child: Text(
              group.name!,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            message: group.name,
          ),
          value: group,
        ));
      }
    }
    return items;
  }

  Widget _dropdownPodcasts({
    required ExpansionController expansionController,
    bool connectLeft = false,
    bool connectRight = false,
  }) {
    double expandedWidth = context.iconButtonSizeHorizontal;
    for (var podcast in podcasts) {
      final podcastNameTest = TextPainter(
          text: TextSpan(
            text: podcast.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          textDirection: TextDirection.ltr);
      podcastNameTest.layout();
      expandedWidth = (podcastNameTest.width + context.iconPadding.horizontal)
          .clamp(expandedWidth, 200);
    }
    expansionController.addWidth(
        (!connectLeft ? context.iconPadding.left / 2 : 0) +
            (!connectRight ? context.iconPadding.right / 2 : 0));
    return ActionBarDropdownButton<PodcastLocal>(
        child: Icon(Icons.podcasts),
        selected: podcast,
        expansionController: expansionController,
        expandedChild: Text(
          podcast.title!,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        itemBuilder: _getPodcasts,
        onSelected: (value) {
          if (mounted) setState(() => podcast = value);
          widget.onGetEpisodesChanged(_getGetEpisodes());
        },
        maxExpandedWidth: expandedWidth,
        color: color,
        activeColor: activeColor,
        tooltip: context.s.filterType(context.s.podcast(1)),
        active: (value) => value != _podcastAll,
        connectLeft: connectLeft,
        connectRight: connectRight);
  }

  List<PopupMenuEntry<PodcastLocal>> _getPodcasts() {
    List<PopupMenuEntry<PodcastLocal>> items = [];
    for (final podcast in podcasts) {
      items.add(PopupMenuItem(
        padding: context.iconPadding,
        height: context.iconButtonSizeVertical,
        child: Tooltip(
          child: Text(
            podcast.title!,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          message: podcast.title,
        ),
        value: podcast,
      ));
    }
    return items;
  }

  Widget _dropDownSortBy(
      {required int rowIndex,
      bool connectLeft = false,
      bool connectRight = false}) {
    expansionController(rowIndex).addWidth(
        (!connectLeft ? context.iconPadding.left / 2 : 0) +
            (!connectRight ? context.iconPadding.right / 2 : 0));
    return ActionBarDropdownButton<Sorter>(
      child: _getSorterIcon(sortBy),
      selected: sortBy,
      itemBuilder: _getSortBy,
      onSelected: (value) {
        if (mounted) setState(() => sortBy = value);
        widget.onGetEpisodesChanged(_getGetEpisodes());
      },
      color: color,
      activeColor: activeColor,
      tooltip: context.s.sortBy,
      active: (_) => true,
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  List<PopupMenuEntry<Sorter>> _getSortBy() {
    List<PopupMenuEntry<Sorter>> items = [];
    var s = context.s;
    for (final sorter in widget.sortByItems) {
      switch (sorter) {
        case Sorter.pubDate:
          items.add(PopupMenuItem(
            padding: context.iconPadding,
            height: context.iconButtonSizeVertical,
            child: Tooltip(
              child: _getSorterIcon(sorter),
              message: s.publishDate,
            ),
            value: Sorter.pubDate,
          ));
          break;
        case Sorter.enclosureSize:
          items.add(PopupMenuItem(
            padding: context.iconPadding,
            height: context.iconButtonSizeVertical,
            child: Tooltip(
              child: _getSorterIcon(sorter),
              message: s.size,
            ),
            value: Sorter.enclosureSize,
          ));
          break;
        case Sorter.enclosureDuration:
          items.add(PopupMenuItem(
            padding: context.iconPadding,
            height: context.iconButtonSizeVertical,
            child: Tooltip(
              child: _getSorterIcon(sorter),
              message: s.duration,
            ),
            value: Sorter.enclosureDuration,
          ));
          break;
        case Sorter.downloadDate:
          items.add(PopupMenuItem(
            padding: context.iconPadding,
            height: context.iconButtonSizeVertical,
            child: Tooltip(
              child: _getSorterIcon(sorter),
              message: s.downloadDate,
            ),
            value: Sorter.downloadDate,
          ));
          break;
        case Sorter.likedDate:
          items.add(PopupMenuItem(
            padding: context.iconPadding,
            height: context.iconButtonSizeVertical,
            child: Tooltip(
              child: _getSorterIcon(sorter),
              message: s.likeDate,
            ),
            value: Sorter.likedDate,
          ));
          break;
        case Sorter.random:
          items.add(PopupMenuItem(
            padding: context.iconPadding,
            height: context.iconButtonSizeVertical,
            child: Tooltip(
              child: _getSorterIcon(sorter),
              message: s.random,
            ),
            value: Sorter.random,
          ));
          break;
      }
    }
    return items;
  }

  Icon _getSorterIcon(Sorter sorter) {
    switch (sorter) {
      case Sorter.pubDate:
        return Icon(Icons.date_range);
      case Sorter.enclosureSize:
        return Icon(Icons.data_usage);
      case Sorter.enclosureDuration:
        return Icon(Icons.timer_outlined);
      case Sorter.downloadDate:
        return Icon(Icons.download);
      case Sorter.likedDate:
        return Icon(Icons.favorite_border);
      case Sorter.random:
        return Icon(Icons.question_mark);
    }
  }

  Widget _filterNew({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) =>
      _button(
        rowIndex: rowIndex,
        child: Icon(Icons.new_releases_outlined),
        state: filterNew,
        buttonType: ActionBarButtonType.noneOnOff,
        onPressed: (value) {
          if (mounted) setState(() => filterNew = value);
          widget.onGetEpisodesChanged(_getGetEpisodes());
        },
        tooltip: context.s.filterType(context.s.newPlain),
        connectLeft: connectLeft,
        connectRight: connectRight,
      );

  Widget _filterLiked({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) =>
      _button(
        rowIndex: rowIndex,
        child: Icon(Icons.favorite_border),
        state: filterLiked,
        buttonType: ActionBarButtonType.noneOnOff,
        onPressed: (value) {
          if (mounted) setState(() => filterLiked = value);
          widget.onGetEpisodesChanged(_getGetEpisodes());
        },
        tooltip: context.s.filterType(context.s.liked),
        connectLeft: connectLeft,
        connectRight: connectRight,
      );

  Widget _filterPlayed({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) =>
      _button(
        rowIndex: rowIndex,
        child:
            CustomPaint(painter: ListenedPainter(context.textColor, stroke: 2)),
        state: filterPlayed,
        buttonType: ActionBarButtonType.noneOnOff,
        onPressed: (value) {
          if (mounted) setState(() => filterPlayed = value);
          widget.onGetEpisodesChanged(_getGetEpisodes());
        },
        tooltip: context.s.filterType(context.s.listened),
        connectLeft: connectLeft,
        connectRight: connectRight,
      );

  Widget _filterDownloaded({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) =>
      _button(
        rowIndex: rowIndex,
        child: CustomPaint(
          painter: DownloadPainter(
            color: context.textColor,
            fraction: 0,
            progressColor: context.textColor,
            progress: 0,
            stroke: 2,
          ),
        ),
        state: filterDownloaded,
        buttonType: ActionBarButtonType.noneOnOff,
        onPressed: (value) {
          if (mounted) setState(() => filterDownloaded = value);
          widget.onGetEpisodesChanged(_getGetEpisodes());
        },
        tooltip: context.s.filterType(context.s.downloaded),
        connectLeft: connectLeft,
        connectRight: connectRight,
      );

  Widget _switchSortOrder({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) =>
      _button(
        rowIndex: rowIndex,
        child: Icon(
          sortOrder == SortOrder.ASC
              ? LineIcons.sortAmountUp
              : LineIcons.sortAmountDown,
        ),
        buttonType: ActionBarButtonType.single,
        onPressed: (value) {
          if (mounted) {
            setState(() {
              switch (sortOrder) {
                case SortOrder.ASC:
                  sortOrder = SortOrder.DESC;
                  break;
                case SortOrder.DESC:
                  sortOrder = SortOrder.ASC;
                  break;
              }
            });
          }
          widget.onGetEpisodesChanged(_getGetEpisodes());
        },
        connectLeft: connectLeft,
        connectRight: connectRight,
      );

  Widget _switchLayout({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) {
    double height = 10;
    double width = 30;
    return _button(
      rowIndex: rowIndex,
      child: layout == Layout.small
          ? SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: LayoutPainter(0, context.textColor, stroke: 2),
              ),
            )
          : layout == Layout.medium
              ? SizedBox(
                  height: height,
                  width: width,
                  child: CustomPaint(
                    painter: LayoutPainter(1, context.textColor, stroke: 2),
                  ),
                )
              : SizedBox(
                  height: height,
                  width: width,
                  child: CustomPaint(
                    painter: LayoutPainter(4, context.textColor, stroke: 2),
                  ),
                ),
      buttonType: ActionBarButtonType.single,
      onPressed: (value) {
        if (mounted) {
          setState(() {
            switch (layout) {
              case Layout.small:
                layout = Layout.large;
                break;
              case Layout.medium:
                layout = Layout.small;
                break;
              case Layout.large:
                layout = Layout.medium;
                break;
            }
          });
        }
        if (widget.onLayoutChanged != null) {
          widget.onLayoutChanged!(layout);
        }
      },
      width: width + context.iconPadding.horizontal,
      innerPadding: EdgeInsets.only(
        left: context.iconPadding.left,
        top: (context.iconButtonSizeVertical - height) / 2,
        right: context.iconPadding.right,
        bottom: (context.iconButtonSizeVertical - height) / 2,
      ),
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  Widget _switchSelectMode({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) {
    double height = 10;
    double width = 20;
    return _button(
      rowIndex: rowIndex,
      child: SizedBox(
        width: height,
        height: width,
        child: CustomPaint(painter: MultiSelectPainter(color: color)),
      ),
      state: selectMode,
      buttonType: ActionBarButtonType.onOff,
      onPressed: (value) {
        selectionController!.selectMode = value!;
      },
      innerPadding: EdgeInsets.only(
        left: context.iconPadding.left,
        top: (context.iconButtonSizeVertical - height) / 2,
        right: context.iconPadding.right,
        bottom: (context.iconButtonSizeVertical - height) / 2,
      ),
      enabled: selectionController != null,
      animation: _switchSelectModeController,
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  Widget _switchSecondRow({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) =>
      _button(
        rowIndex: rowIndex,
        child: UpDownIndicator(
          status: secondRow,
          color: context.textColor,
        ),
        state: secondRow,
        buttonType: ActionBarButtonType.onOff,
        onPressed: (value) {
          if (mounted) setState(() => secondRow = value!);
          switch (value!) {
            case false:
              _switchSecondRowController.reverse();
              break;
            case true:
              _switchSecondRowController.forward();
              _expansionControllerSecondRow =
                  ExpansionController(maxWidth: () => context.width);
              break;
          }
        },
        animation: _switchSecondRowController,
        connectLeft: connectLeft,
        connectRight: connectRight,
      );

  Widget _buttonRefresh({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) {
    return _button(
      rowIndex: rowIndex,
      child: Icon(Icons.refresh),
      buttonType: ActionBarButtonType.single,
      onPressed: (value) async {
        if (_buttonRefreshController.value == 0) {
          final refreshWorker = context.read<RefreshWorker>();
          Future refreshFuture;
          if (podcast != _podcastAll) {
            refreshFuture = refreshWorker.start([podcast.id]);
          } else if (group != _podcastAll) {
            refreshFuture = refreshWorker.start(group.podcastList);
          } else {
            refreshFuture = refreshWorker.start([]);
          }
          _buttonRefreshController.forward();
          Fluttertoast.showToast(
            msg: context.s.refreshStarted,
            gravity: ToastGravity.BOTTOM,
          );
          await refreshFuture;
          _buttonRefreshController.reverse();
          // Fluttertoast.cancel();
          // Fluttertoast.showToast(
          //   msg: context.s.refreshFinished,
          //   gravity: ToastGravity.BOTTOM,
          // ); // TODO: Toast on refresh finish
          widget.onGetEpisodesChanged(_getGetEpisodes());
        }
      },
      animation: _buttonRefreshController,
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  Widget _buttonRemoveNewMark({
    required int rowIndex,
    bool connectLeft = false,
    bool connectRight = false,
  }) {
    bool enabled = episodes.any((episode) => episode.isNew == true);
    return _button(
      rowIndex: rowIndex,
      child: CustomPaint(
          painter: RemoveNewFlagPainter(
              !enabled && context.realDark
                  ? Colors.grey[800]
                  : context.textColor,
              enabled
                  ? Colors.red
                  : context.realDark
                      ? Colors.grey[800]!
                      : context.textColor,
              stroke: 2)),
      buttonType: ActionBarButtonType.single,
      onPressed: (value) async {
        if (_buttonRemoveNewMarkController.value == 0) {
          _buttonRemoveNewMarkController.forward();
          Future removeFuture;
          if (podcast != _podcastAll) {
            removeFuture = _dbHelper.removeGroupNewMark([podcast.id]);
          } else if (group != _groupAll) {
            removeFuture = _dbHelper.removeGroupNewMark(group.podcastList);
          } else {
            removeFuture = _dbHelper.removeAllNewMark();
          }
          await Future.wait(
              [removeFuture, Future.delayed(Duration(seconds: 1))]);
          widget.onGetEpisodesChanged(_getGetEpisodes());
        }
      },
      enabled: enabled,
      animation: _buttonRefreshController,
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  Widget _button({
    required int rowIndex,
    required Widget child,
    bool? state,
    ActionBarButtonType? buttonType,
    required void Function(bool?) onPressed,
    double? width,
    double? height,
    EdgeInsets? innerPadding,
    String? tooltip,
    bool enabled = true,
    Animation<double>? animation,
    bool connectLeft = false,
    bool connectRight = false,
  }) {
    expansionController(rowIndex).addWidth(
        (width ?? context.iconButtonSizeHorizontal) +
            (!connectLeft ? context.iconPadding.left / 2 : 0) +
            (!connectRight ? context.iconPadding.right / 2 : 0));
    return ActionBarButton(
      child: child,
      state: state,
      buttonType: buttonType ?? ActionBarButtonType.single,
      onPressed: onPressed,
      width: width,
      height: height,
      innerPadding: innerPadding,
      color: color,
      activeColor: activeColor,
      tooltip: tooltip,
      enabled: enabled,
      animation: animation,
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  Widget _searchTitle(
      {required ExpansionController expansionController,
      bool connectLeft = false,
      bool connectRight = false}) {
    expansionController.addWidth(
        (!connectLeft ? context.iconPadding.left / 2 : 0) +
            (!connectRight ? context.iconPadding.right / 2 : 0));
    return ActionBarExpandingSearchButton(
      expansionController: expansionController,
      onQueryChanged: (value) async {
        if (mounted) setState(() => searchTitleQuery = value);
        widget.onGetEpisodesChanged(_getGetEpisodes());
      },
      color: color,
      activeColor: activeColor,
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  ValueGetter<Future<List<EpisodeBrief>>> _getGetEpisodes(
          {bool getPodcasts = false}) =>
      () async {
        if (getPodcasts) {
          podcasts.addAll(await _dbHelper.getPodcastLocalAll());
        }
        episodes = await _dbHelper.getEpisodes(
            feedIds: podcast != _podcastAll
                ? group.podcastList.isEmpty ||
                        group.podcastList.contains(podcast.id)
                    ? [podcast.id]
                    : []
                : group.podcastList,
            likeEpisodeTitles:
                searchTitleQuery == "" ? null : [searchTitleQuery],
            optionalFields: [
              EpisodeField.description,
              EpisodeField.number,
              EpisodeField.enclosureDuration,
              EpisodeField.enclosureSize,
              EpisodeField.isDownloaded,
              EpisodeField.episodeImage,
              EpisodeField.podcastImage,
              EpisodeField.primaryColor,
              EpisodeField.isLiked,
              EpisodeField.isNew,
              EpisodeField.isPlayed,
              EpisodeField.versionInfo
            ],
            sortBy: sortBy,
            sortOrder: sortOrder,
            limit: widget.limit,
            filterVersions: 1, // TODO: Make version button
            filterNew: filterNew,
            filterLiked: filterLiked,
            filterPlayed: filterPlayed,
            filterDownloaded: filterDownloaded,
            episodeState: mounted
                ? Provider.of<EpisodeState>(context, listen: false)
                : null);
        return episodes;
      };
}

Future<Tuple2<Layout, bool>> getDefaults() async {
  final layoutStorage = KeyValueStorage(podcastLayoutKey);
  final index = await layoutStorage.getInt(defaultValue: 1);
  Layout layout = Layout.values[index];
  final hideListenedStorage = KeyValueStorage(hideListenedKey);
  bool hideListened = await hideListenedStorage.getBool(defaultValue: false);
  return Tuple2(layout, hideListened);
}
