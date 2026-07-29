import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../type/podcastbrief.dart';
import '../type/podcastgroup.dart';
import '../type/tab_configuration.dart';
import '../type/theme_data.dart';
import '../util/extension_helper.dart';
import '../util/selection_controller.dart';
import 'action_bar_generic_widgets.dart';
import '../local_storage/sqflite_localpodcast.dart';
import 'custom_popupmenu.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';

/// Bar with buttons to sort, filter episodes and control view.
/// Returns the get episodes callback with the [onConfigurationChanged] callback.
/// Subwidgets can be chosen by passing [widgetsFirstRow] & [widgetsFirstRow]
/// Filters can be controlled from outside by passing them.
/// Configure colors with a [CardColorScheme] provided with a [ChangeNotifierProvider], defaults to the global theme
/// Select mode switch works when [SelectionController] if provided with a [ChangeNotifierProvider]
class ActionBar extends StatefulWidget {
  /// Callback to return the new configuration when the filters change.
  final ValueSetter<ActionBarConfiguration> onConfigurationChanged;

  /// Wheter to call [onConfigurationChanged] after construction.
  final bool sendInitialConfig;

  /// Callback to return the layout status
  final ValueChanged<EpisodeGridLayout>? onLayoutChanged;

  /// Items to show on the bar
  final List<ActionBarWidget> widgetsFirstRow;

  /// Items to show in custom popup menu
  final List<ActionBarWidget> widgetsSecondRow;

  /// Sorters to show in the sort by dropdown button
  final List<Sorter> sortByItems;

  /// Default second row
  final bool expandSecondRow;

  /// Pin sliver to top
  final bool pinned;

  /// Wheter to wrap the bar in a sliver
  final bool sliver;

  /// Width of the bar.
  final double? width;

  /// Default configuration.
  final ActionBarConfiguration configuration;

  const ActionBar({
    super.key,
    required this.onConfigurationChanged,
    this.sendInitialConfig = false,
    this.onLayoutChanged,
    this.widgetsFirstRow = const [
      ActionBarDropdownSortBy(0, 0),
      ActionBarSwitchSortOrder(0, 1),
      ActionBarSpacer(0, 2),
      ActionBarButtonSync(0, 3),
      ActionBarFilterPlayed(0, 4),
      ActionBarFilterDownloaded(0, 5),
      ActionBarSwitchLayout(0, 6),
      ActionBarSwitchSelectMode(0, 7),
      ActionBarSwitchSecondRow(0, 8),
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
      Sorter.downloadDate,
      Sorter.likedDate,
      Sorter.random,
    ],
    this.expandSecondRow = false,
    this.pinned = true,
    this.sliver = true,
    this.width,
    this.configuration = const ActionBarConfiguration(),
  });
  @override
  State<ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> with TickerProviderStateMixin {
  late AnimationController _switchSecondRowController;
  late AnimationController _buttonRefreshController;

  late ActionBarSharedState _sharedState;

  bool initialBuild = true;
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _switchSecondRowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _switchSecondRowController.dispose();
    _buttonRefreshController.dispose();
    _sharedState.dispose();
    _sharedState.disposed = true;
    super.dispose();
  }

  @override
  void didUpdateWidget(ActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onConfigurationChanged != widget.onConfigurationChanged) {
      _sharedState.onConfigurationChanged = widget.onConfigurationChanged;
    }
    if (oldWidget.onLayoutChanged != widget.onLayoutChanged) {
      _sharedState.onLayoutChanged = widget.onLayoutChanged;
    }
    if (oldWidget.widgetsFirstRow != widget.widgetsFirstRow) {
      _sharedState.widgetsFirstRow = widget.widgetsFirstRow;
    }
    if (oldWidget.widgetsSecondRow != widget.widgetsSecondRow) {
      _sharedState.widgetsSecondRow = widget.widgetsSecondRow;
    }
    if (oldWidget.sortByItems != widget.sortByItems) {
      _sharedState.sortByItems = widget.sortByItems;
    }
    if (oldWidget.expandSecondRow != widget.expandSecondRow) {
      _sharedState.expandSecondRow = widget.expandSecondRow;
    }
    if (oldWidget.width != widget.width) {
      _sharedState.width = widget.width;
    }
    if (oldWidget.configuration != widget.configuration) {
      if (oldWidget.configuration.groupId != widget.configuration.groupId) {
        _sharedState.groupId = widget.configuration.groupId;
      }
      if (oldWidget.configuration.podcastId != widget.configuration.podcastId) {
        _sharedState.podcastId = widget.configuration.podcastId;
      }
      if (oldWidget.configuration.sortBy != widget.configuration.sortBy) {
        _sharedState.sortBy = widget.configuration.sortBy;
      }
      if (oldWidget.configuration.filterNew != widget.configuration.filterNew) {
        _sharedState.filterNew = widget.configuration.filterNew;
      }
      if (oldWidget.configuration.filterLiked !=
          widget.configuration.filterLiked) {
        _sharedState.filterLiked = widget.configuration.filterLiked;
      }
      if (oldWidget.configuration.filterPlayed !=
          widget.configuration.filterPlayed) {
        _sharedState.filterPlayed = widget.configuration.filterPlayed;
      }
      if (oldWidget.configuration.filterDownloaded !=
          widget.configuration.filterDownloaded) {
        _sharedState.filterDownloaded = widget.configuration.filterDownloaded;
      }
      if (oldWidget.configuration.sortOrder != widget.configuration.sortOrder) {
        _sharedState.sortOrder = widget.configuration.sortOrder;
      }
      if (oldWidget.configuration.layout != widget.configuration.layout) {
        _sharedState.layout = widget.configuration.layout;
      }
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
      _sharedState = ActionBarSharedState(
        context,
        onConfigurationChanged: widget.onConfigurationChanged,
        sendInitialConfig: widget.sendInitialConfig,
        onLayoutChanged: widget.onLayoutChanged,
        widgetsFirstRow: widget.widgetsFirstRow,
        widgetsSecondRow: widget.widgetsSecondRow,
        sortByItems: widget.sortByItems,
        expandSecondRow: widget.expandSecondRow,
        width: widget.width,
        configuration: widget.configuration,
        switchSecondRowController: _switchSecondRowController,
        buttonSyncController: _buttonRefreshController,
      );
      SelectionController? selectionController =
          Provider.of<SelectionController?>(context, listen: false);
      if (selectionController != null) {
        selectionController.onGetEpisodesLimitless =
            selectionController.onGetEpisodesLimitless = () => context
                .episodeState
                .getEpisodesWithConfiguration(_sharedState.configuration, -1);
      }
    }
    CardColorScheme? cardColorScheme = Provider.of<CardColorScheme?>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ActionBarSharedState>.value(value: _sharedState),
        if (cardColorScheme == null)
          Provider<CardColorScheme>.value(
            value: Theme.of(context).extension<CardColorScheme>()!,
          ),
      ],
      builder: (context, child) => _ActionBarOuter(
        Row(children: widget.widgetsFirstRow),
        Row(children: widget.widgetsSecondRow),
        pinned: widget.pinned,
        surface: context.trueBlack
            ? context.surface
            : cardColorScheme?.colorScheme.surface,
        sliver: widget.sliver,
      ),
    );
  }
}

class _ActionBarOuter extends StatefulWidget {
  final Widget firstRow;
  final Widget secondRow;
  final bool pinned;
  final Color? surface;
  final bool sliver;
  const _ActionBarOuter(
    this.firstRow,
    this.secondRow, {
    required this.pinned,
    this.surface,
    required this.sliver,
  });

  @override
  __ActionBarOuterState createState() => __ActionBarOuterState();
}

class __ActionBarOuterState extends State<_ActionBarOuter>
    with TickerProviderStateMixin {
  double get totalHeight => Tween<double>(
    begin:
        10 +
        context.actionBarIconSize +
        context.actionBarIconPadding.vertical * 3 / 2,
    end:
        10 +
        context.actionBarIconSize * 2 +
        context.actionBarIconPadding.vertical * 3,
  ).evaluate(_switchSecondRowSlideAnimation);

  late Animation<double> _switchSecondRowAppearAnimation;
  late Animation<double> _switchSecondRowSlideAnimation;

  @override
  void initState() {
    super.initState();
    ActionBarSharedState actionBarSharedState =
        Provider.of<ActionBarSharedState>(context, listen: false);
    actionBarSharedState.switchSecondRowController.addListener(() {
      if (mounted) setState(() {});
    });
    _switchSecondRowSlideAnimation = CurvedAnimation(
      parent: actionBarSharedState.switchSecondRowController,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCirc,
    );
    _switchSecondRowAppearAnimation = CurvedAnimation(
      parent: _switchSecondRowSlideAnimation,
      curve: Interval(0.75, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
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
                bottom:
                    context.actionBarIconPadding.bottom /
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
                  top:
                      context.actionBarIconPadding.top /
                      2 *
                      _switchSecondRowAppearAnimation.value,
                  right: context.actionBarIconPadding.right / 2,
                  bottom:
                      context.actionBarIconPadding.bottom /
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
    );
    if (widget.sliver) {
      return SliverAppBar(
        pinned: widget.pinned,
        leading: Center(),
        toolbarHeight: totalHeight,
        backgroundColor: widget.surface ?? context.surface,
        scrolledUnderElevation: 0,
        flexibleSpace: child,
      );
    } else {
      return child;
    }
  }
}

/// State shared by action bar widgets.
class ActionBarSharedState extends ChangeNotifier {
  final BuildContext context;
  ValueSetter<ActionBarConfiguration> onConfigurationChanged;
  ValueChanged<EpisodeGridLayout>? onLayoutChanged;

  List<ActionBarWidget> _widgetsFirstRow;
  List<ActionBarWidget> get widgetsFirstRow => _widgetsFirstRow;
  set widgetsFirstRow(List<ActionBarWidget> value) {
    _widgetsFirstRow = value;
    notifyListeners();
  }

  List<ActionBarWidget> _widgetsSecondRow;
  List<ActionBarWidget> get widgetsSecondRow => _widgetsSecondRow;
  set widgetsSecondRow(List<ActionBarWidget> value) {
    _widgetsSecondRow = value;
    notifyListeners();
  }

  List<Sorter> _sortByItems;
  List<Sorter> get sortByItems => _sortByItems;
  set sortByItems(List<Sorter> value) {
    _sortByItems = value;
    notifyListeners();
  }

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

  double? width;

  String _groupId;
  String get groupId => _groupId;
  set groupId(String? podcastGroup) {
    _groupId = podcastGroup ?? allGroupId;
    notifyListeners();
  }

  String _podcastId;
  String get podcastId => _podcastId;
  set podcastId(String? podcastBrief) {
    _podcastId = podcastBrief ?? podcastAllId;
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
  final AnimationController buttonSyncController;

  ActionBarSharedState(
    this.context, {
    required this.onConfigurationChanged,
    required bool sendInitialConfig,
    required this.onLayoutChanged,
    required this._widgetsFirstRow,
    required this._widgetsSecondRow,
    required this._sortByItems,
    required this._expandSecondRow,
    this.width,
    required ActionBarConfiguration configuration,
    required this.switchSecondRowController,
    required this.buttonSyncController,
  }) : _groupId = configuration.groupId,
       _podcastId = configuration.podcastId,
       _sortBy = configuration.sortBy,
       _filterNew = configuration.filterNew,
       _filterLiked = configuration.filterLiked,
       _filterPlayed = configuration.filterPlayed,
       _filterDownloaded = configuration.filterDownloaded,
       _filterDisplayVersion = configuration.filterDisplayVersion,
       _sortOrder = configuration.sortOrder,
       _layout = configuration.layout {
    if (expandSecondRow) switchSecondRowController.forward();
    if (sendInitialConfig) {
      Future.microtask(() => onConfigurationChanged(configuration));
    }
  }

  ActionBarConfiguration get configuration => ActionBarConfiguration(
    groupId: groupId,
    podcastId: podcastId,
    sortBy: sortBy,
    filterNew: filterNew,
    filterLiked: filterLiked,
    filterPlayed: filterPlayed,
    filterDownloaded: filterDownloaded,
    filterDisplayVersion: filterDisplayVersion,
    sortOrder: sortOrder,
    layout: layout,
    searchTitleQuery: searchTitleQuery == "" ? null : searchTitleQuery,
  );

  bool _disposed = false;
  bool get disposed => _disposed;
  set disposed(bool a) {
    _disposed = true;
  }

  List<String> get groups => [allGroupId, ...context.podcastState.groupIds];
  double? maxGroupTitleWidth;

  Future<List<String>> get podcasts async => [
    podcastAllId,
    ...await context.podcastState.getPodcasts(),
  ];
  double? maxPodcastTitleWidth;

  String searchTitleQuery = "";

  List<int> episodeIds = [];

  late ExpansionController expansionControllerFirstRow = ExpansionController(
    maxWidth: maxWidth,
  );
  late ExpansionController expansionControllerSecondRow = ExpansionController(
    maxWidth: maxWidth,
  );

  List<ExpansionController> get expansionControllers => [
    expansionControllerFirstRow,
    expansionControllerSecondRow,
  ];
  late List<List<ActionBarWidget>> rows = [widgetsFirstRow, widgetsSecondRow];

  double maxWidth() =>
      (width ?? context.width) -
      (16 + context.actionBarIconPadding.horizontal / 2);
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, String>(
      selector: (_, sharedState) => sharedState.groupId,
      builder: (context, data, _) {
        if (sharedState.maxGroupTitleWidth == null) {
          double expandedWidth = context.actionBarButtonSizeHorizontal;
          for (var groupId in sharedState.groups) {
            final name = groupId == allGroupId
                ? context.s.all
                : context.podcastState.getGroupById(groupId).name;
            final groupNameTest = TextPainter(
              text: TextSpan(
                text: name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              textDirection: TextDirection.ltr,
            );
            groupNameTest.layout();
            expandedWidth =
                (groupNameTest.width + context.actionBarIconPadding.horizontal)
                    .clamp(expandedWidth, 200);
          }
          sharedState.maxGroupTitleWidth =
              expandedWidth; // It's tricky to update this after the fact.
        }
        return ActionBarDropdownButton<String>(
          selected: data,
          expansionController: sharedState.expansionControllers[rowIndex],
          expandedChild: Text(
            data == allGroupId
                ? context.s.all
                : context.podcastState.getGroupById(data).name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          itemBuilder: () => sharedState.groups.map((groupId) {
            final name = groupId == allGroupId
                ? context.s.all
                : context.podcastState.getGroupById(groupId).name;
            return MyPopupMenuItem(
              value: groupId,
              child: Tooltip(
                message: name,
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onSelected: (value) {
            sharedState.groupId = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
          },
          maxExpandedWidth: sharedState.maxGroupTitleWidth,
          tooltip: context.s.filterType(context.s.groups(1)),
          active: (value) => value != allGroupId,
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

  String titleOf(BuildContext context, String podcastId) =>
      podcastId == podcastAllId
      ? context.s.all
      : context.podcastState[podcastId].title;
  @override
  Widget build(BuildContext context) {
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, String>(
      selector: (_, sharedState) => sharedState.podcastId,
      builder: (context, data, _) {
        return FutureBuilder<List<String>>(
          future: sharedState.podcasts,
          initialData: [],
          builder: (context, snapshot) {
            double expandedWidth = context.actionBarButtonSizeHorizontal;
            for (var podcastId in snapshot.data!) {
              final podcastNameTest = TextPainter(
                text: TextSpan(
                  text: titleOf(context, podcastId),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                textDirection: TextDirection.ltr,
              );
              podcastNameTest.layout();
              expandedWidth =
                  (podcastNameTest.width +
                          context.actionBarIconPadding.horizontal)
                      .clamp(expandedWidth, 200);
            }
            sharedState.maxPodcastTitleWidth =
                expandedWidth; // It's tricky to update this after the fact.
            return ActionBarDropdownButton<String>(
              selected: data,
              expansionController: sharedState.expansionControllers[rowIndex],
              expandedChild: Text(
                titleOf(context, data),
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              itemBuilder: () => snapshot.data!.map((podcastId) {
                final title = titleOf(context, podcastId);
                return MyPopupMenuItem(
                  value: podcastId,
                  child: Tooltip(
                    message: title,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onSelected: (value) {
                sharedState.podcastId = value;
                sharedState.onConfigurationChanged(sharedState.configuration);
              },
              maxExpandedWidth: sharedState.maxPodcastTitleWidth,
              tooltip: context.s.filterType(context.s.podcast(1)),
              active: (value) => value != podcastAllId,
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, Sorter>(
      selector: (_, sharedState) => sharedState.sortBy,
      builder: (context, data, _) {
        return ActionBarDropdownButton<Sorter>(
          selected: data,
          expansionController: sharedState.expansionControllers[rowIndex],
          itemBuilder: () => _getSortBy(context, sharedState.sortByItems),
          onSelected: (value) {
            sharedState.sortBy = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
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

List<MyPopupMenuItem<Sorter>> _getSortBy(
  BuildContext context,
  List<Sorter> sortByItems,
) {
  List<MyPopupMenuItem<Sorter>> items = [];
  var s = context.s;
  for (var sorter in sortByItems) {
    switch (sorter) {
      case Sorter.pubDate:
        items.add(
          MyPopupMenuItem(
            value: Sorter.pubDate,
            child: Tooltip(
              message: s.publishDate,
              child: _getSorterIcon(context, sorter),
            ),
          ),
        );
        break;
      case Sorter.enclosureSize:
        items.add(
          MyPopupMenuItem(
            value: Sorter.enclosureSize,
            child: Tooltip(
              message: s.size,
              child: _getSorterIcon(context, sorter),
            ),
          ),
        );
        break;
      case Sorter.enclosureDuration:
        items.add(
          MyPopupMenuItem(
            value: Sorter.enclosureDuration,
            child: Tooltip(
              message: s.duration,
              child: _getSorterIcon(context, sorter),
            ),
          ),
        );
        break;
      case Sorter.downloadDate:
        items.add(
          MyPopupMenuItem(
            value: Sorter.downloadDate,
            child: Tooltip(
              message: s.downloadDate,
              child: _getSorterIcon(context, sorter),
            ),
          ),
        );
        break;
      case Sorter.likedDate:
        items.add(
          MyPopupMenuItem(
            value: Sorter.likedDate,
            child: Tooltip(
              message: s.likeDate,
              child: _getSorterIcon(context, sorter),
            ),
          ),
        );
        break;
      case Sorter.random:
        items.add(
          MyPopupMenuItem(
            value: Sorter.random,
            child: Tooltip(
              message: s.random,
              child: _getSorterIcon(context, sorter),
            ),
          ),
        );
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
      return Icon(
        Icons.download_for_offline_outlined,
        color: context.actionBarIconColor,
      );
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterNew,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterNew = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterLiked,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterLiked = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
          },
          tooltip: context.s.filterType(context.s.liked),
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: Icon(
              Icons.favorite_border,
              color: context.actionBarIconColor,
            ),
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterPlayed,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterPlayed = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterDownloaded,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterDownloaded = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, bool?>(
      selector: (_, sharedState) => sharedState.filterDisplayVersion,
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          state: data,
          buttonType: ActionBarButtonType.noneOnOff,
          onPressed: (value) {
            sharedState.filterDisplayVersion = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, (SortOrder, Sorter)>(
      selector: (_, sharedState) => (sharedState.sortOrder, sharedState.sortBy),
      builder: (context, data, _) {
        return ActionBarButton(
          expansionController: sharedState.expansionControllers[rowIndex],
          buttonType: ActionBarButtonType.single,
          onPressed: (value) {
            switch (data.$1) {
              case SortOrder.asc:
                sharedState.sortOrder = SortOrder.desc;
                break;
              case SortOrder.desc:
                sharedState.sortOrder = SortOrder.asc;
                break;
            }
            sharedState.onConfigurationChanged(sharedState.configuration);
          },
          tooltip: context.s.sortOrder,
          connectLeft: index != 0 && row[index - 1] is ActionBarSort,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarSort,
          child: SizedBox(
            height: context.actionBarButtonSizeVertical,
            width: context.actionBarButtonSizeHorizontal,
            child: Icon(
              data.$2 == Sorter.random
                  ? Icons.casino_outlined
                  : data.$1 == SortOrder.asc
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, EpisodeGridLayout>(
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
            sharedState.onConfigurationChanged(sharedState.configuration);
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
                    painter: LayoutPainter(
                      0,
                      context.actionBarIconColor,
                      stroke: 2,
                    ),
                  )
                : data == EpisodeGridLayout.medium
                ? CustomPaint(
                    painter: LayoutPainter(
                      1,
                      context.actionBarIconColor,
                      stroke: 2,
                    ),
                  )
                : CustomPaint(
                    painter: LayoutPainter(
                      4,
                      context.actionBarIconColor,
                      stroke: 2,
                    ),
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
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
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
              Provider.of<SelectionController>(
                context,
                listen: false,
              ).selectMode = value!;
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
                painter: MultiSelectPainter(color: context.actionBarIconColor),
              ),
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
              color: context.trueBlack
                  ? Colors.grey[800]!
                  : context.actionBarIconColor,
            ),
          ),
        ),
      );
    }
  }
}

class ActionBarSwitchSecondRow extends ActionBarControl {
  const ActionBarSwitchSecondRow(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, bool>(
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
                sharedState.expansionControllerSecondRow = ExpansionController(
                  maxWidth: sharedState.maxWidth,
                );
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
              status: data,
              color: context.actionBarIconColor,
            ),
          ),
        );
      },
    );
  }
}

class ActionBarButtonSync extends ActionBarControl {
  const ActionBarButtonSync(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return ActionBarButton(
      expansionController: sharedState.expansionControllers[rowIndex],
      buttonType: ActionBarButtonType.single,
      onPressed: (value) async {
        if (sharedState.buttonSyncController.value == 0) {
          final pState = context.podcastState;
          sharedState.buttonSyncController.forward();
          if (context.mounted) {
            Fluttertoast.showToast(
              msg: context.s.syncStarted,
              gravity: ToastGravity.BOTTOM,
            );
          }
          if (sharedState.podcastId != podcastAllId) {
            await pState.syncPodcast(sharedState.podcastId);
          } else if (sharedState.groupId != allGroupId) {
            final ids = pState.getGroupById(sharedState.groupId).podcastIds;
            Queue<Future<int?>> futures = Queue();
            for (var id in ids) {
              if (futures.length >= 8) await futures.removeFirst();
              futures.add(pState.syncPodcast(id));
            }
            await Future.wait(futures);
          } else {
            await pState.syncAllPodcasts();
          }
          if (context.mounted) {
            Fluttertoast.showToast(
              msg: context.s.syncFinished,
              gravity: ToastGravity.BOTTOM,
            );
          }
          sharedState.buttonSyncController.reverse();
        }
      },
      tooltip: context.s.refresh,
      animation: sharedState.buttonSyncController,
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

class ActionBarSearchTitle extends ActionBarFilter {
  const ActionBarSearchTitle(super.rowIndex, super.index, {super.key});
  @override
  Widget build(BuildContext context) {
    ActionBarSharedState sharedState = Provider.of<ActionBarSharedState>(
      context,
      listen: false,
    );
    final row = sharedState.rows[rowIndex];
    return Selector<ActionBarSharedState, String>(
      selector: (_, sharedState) => sharedState.searchTitleQuery,
      builder: (context, data, _) {
        return ActionBarExpandingSearchButton(
          query: data,
          expansionController: sharedState.expansionControllers[rowIndex],
          onQueryChanged: (value) async {
            sharedState.searchTitleQuery = value;
            sharedState.onConfigurationChanged(sharedState.configuration);
          },
          connectLeft: index != 0 && row[index - 1] is ActionBarFilter,
          connectRight:
              index != row.length - 1 && row[index + 1] is ActionBarFilter,
        );
      },
    );
  }
}
