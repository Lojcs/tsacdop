import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../util/selection_controller.dart';
import 'package:tuple/tuple.dart';

import '../home/audioplayer.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../type/playlist.dart';
import '../type/theme_data.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import 'action_bar_generic_widgets.dart';
import 'custom_dropdown.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';

/// Integrates [MultiSelectPanel] with [EpisodeState]
/// and places it above the [PlayerWidget]
/// [SelectionController] needs to be provided with a [ChangeNotifierProvider]
/// Uses the [CardColorScheme] provided with a [Provider], or defaults to the global theme
class MultiSelectPanelIntegration extends StatefulWidget {
  const MultiSelectPanelIntegration({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _MultiSelectPanelIntegrationState();
}

class _MultiSelectPanelIntegrationState
    extends State<MultiSelectPanelIntegration>
    with SingleTickerProviderStateMixin {
  late bool selectMode;

  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  double get iconButtonSize => context.actionBarButtonSizeVertical;
  EdgeInsets get iconPadding => context.actionBarIconPadding;
  Radius get iconRadius => context.actionBarIconRadius;

  late bool episodeStateGlobalChange;
  bool initialBuild = true;

  late double previewHeight = iconButtonSize + 8;
  late double multiSelectHeight =
      iconButtonSize * 2 + iconPadding.vertical * 3 / 2;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCirc,
      reverseCurve: Curves.easeInOutCirc,
    );
    SelectionController selectionController =
        Provider.of<SelectionController>(context, listen: false);
    selectMode = selectionController.selectMode;
    selectionController.addListener(() {
      if (selectMode != selectionController.selectMode) {
        selectMode = selectionController.selectMode;
        if (selectionController.selectMode) {
          _slideController.forward();
        } else {
          _slideController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialBuild) {
      initialBuild = false;
      episodeStateGlobalChange =
          Provider.of<EpisodeState>(context).globalChange;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          alignment: Alignment.bottomCenter,
          constraints: BoxConstraints.loose(Size(context.width, 400)),
          height: (previewHeight + multiSelectHeight + 8) *
              _slideAnimation.value.clamp(0, 1),
          child: ScrollConfiguration(
            behavior: const NoOverscrollScrollBehavior(),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              hitTestBehavior: HitTestBehavior.deferToChild,
              child: Column(
                children: [
                  SelectionPreview(
                    onHeightChanged: (height) {
                      if (mounted) setState(() => previewHeight = height);
                    },
                  ),
                  Selector<EpisodeState, bool>(
                    selector: (_, episodeState) => episodeState.globalChange,
                    builder: (_, data, ___) => FutureBuilder<void>(
                      future: () async {
                        if (data != episodeStateGlobalChange) {
                          // Prevents unnecessary database calls when the bar is rebuilt for other reasons
                          episodeStateGlobalChange = data;
                          List<EpisodeBrief> updatedEpisodes =
                              await _getUpdatedEpisodes(context);
                          Provider.of<SelectionController>(context,
                                  listen: false)
                              .updateEpisodes(updatedEpisodes);
                        }
                      }(),
                      builder: (context, _) {
                        return MultiSelectPanel(
                          onHeightChanged: (height) {
                            if (mounted) {
                              setState(() => multiSelectHeight = height);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Selector<AudioPlayerNotifier, Tuple2<bool, PlayerHeight?>>(
          selector: (_, audio) =>
              Tuple2(audio.playerRunning, audio.playerHeight),
          builder: (_, data, __) {
            var height = kMinPlayerHeight[data.item2!.index];
            return SizedBox(height: data.item1 ? height : 0);
          },
        ),
      ],
    );
  }

  Future<List<EpisodeBrief>> _getUpdatedEpisodes(BuildContext context) async {
    var dbHelper = DBHelper();
    List<int> episodeIds = [];
    EpisodeState episodeState =
        Provider.of<EpisodeState>(context, listen: false);
    SelectionController selectionController =
        Provider.of<SelectionController>(context);
    Set<int> episodesInSelectionController = selectionController
            .hasAllSelectableEpisodes
        ? selectionController.selectableEpisodes.map((e) => e.id).toSet()
        : selectionController.selectableEpisodes.map((e) => e.id).toSet()
      ..addAll(selectionController.selectedEpisodes.map((e) => e.id).toSet());
    for (var id in episodeState.changedIds) {
      if (episodesInSelectionController.contains(id)) {
        episodeIds.add(id);
      }
    }
    var episodes =
        await dbHelper.getEpisodes(episodeIds: episodeIds, optionalFields: [
      EpisodeField.isDownloaded,
      EpisodeField.isLiked,
      EpisodeField.isNew,
      EpisodeField.isPlayed,
      EpisodeField.episodeImage,
    ]);
    return episodes;
  }
}

/// Handle with selection stats and panel to preview selection contents
class SelectionPreview extends StatefulWidget {
  final void Function(double height) onHeightChanged;
  const SelectionPreview({required this.onHeightChanged, super.key});

  @override
  State<StatefulWidget> createState() => _SelectionPreviewState();
}

class _SelectionPreviewState extends State<SelectionPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  double get iconButtonSize => context.actionBarButtonSizeVertical;
  EdgeInsets get iconPadding => context.actionBarIconPadding;
  Radius get iconRadius => context.actionBarIconRadius;

  late bool selectMode;
  bool expanded = false;
  double maxBodyHeight = 200;
  double get bodyHeight => maxBodyHeight * _expandAnimation.value;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 175))
      ..addListener(() {
        widget.onHeightChanged(bodyHeight + iconButtonSize + 8);
        if (mounted) setState(() {});
      });
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutQuad,
    );
    SelectionController selectionController =
        Provider.of<SelectionController>(context, listen: false);
    selectMode = selectionController.selectMode;
    selectionController.addListener(() {
      if (selectMode != selectionController.selectMode) {
        selectMode = selectionController.selectMode;
        if (!selectionController.selectMode) {
          expanded = false;
          _expandController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SizedBox(
      height: bodyHeight + iconButtonSize + 8,
      child: Selector<CardColorScheme, Tuple3<Color, Color, Color>>(
        selector: (_, cardColorScheme) => Tuple3(
          cardColorScheme.shadow,
          cardColorScheme.colorScheme.surface,
          cardColorScheme.colorScheme.primary,
        ),
        builder: (context, colors, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          verticalDirection: VerticalDirection.up,
          children: [
            Container(
              height: bodyHeight,
              decoration: BoxDecoration(
                color: context.realDark ? context.surface : colors.item2,
                borderRadius:
                    BorderRadius.only(topRight: context.radiusMedium.topRight),
                boxShadow: _expandAnimation.value == 0
                    ? null
                    : context.boxShadowMedium(
                        color: context.realDark ? colors.item1 : null),
              ),
              width: context.width - 48,
              margin: EdgeInsets.symmetric(horizontal: 24),
              clipBehavior: Clip.hardEdge,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 8,
                    ),
                  ),
                  Selector<SelectionController,
                      Tuple2<List<EpisodeBrief>, int>>(
                    selector: (_, selectionController) => Tuple2(
                      selectionController.selectedEpisodes,
                      selectionController.selectedEpisodes.length,
                    ),
                    builder: (context, data, _) =>
                        FutureBuilder<List<EpisodeBrief>>(
                      future:
                          Future.wait(data.item1.map((e) => e.copyWithFromDB(
                                keepExisting: true,
                                newFields: [
                                  EpisodeField.number,
                                  EpisodeField.enclosureDuration,
                                  EpisodeField.enclosureSize,
                                  EpisodeField.episodeImage,
                                  EpisodeField.podcastImage,
                                  EpisodeField.primaryColor,
                                ],
                              ))),
                      initialData: [],
                      builder: (context, snapshot) => EpisodeGrid(
                        episodes: snapshot.data!,
                        layout: EpisodeGridLayout.medium,
                        openPodcast: true,
                        selectable: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.only(left: 8, top: 8, right: 8),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(),
              child: GestureDetector(
                onTap: () {
                  if (expanded) {
                    expanded = false;
                    _expandController.reverse();
                  } else {
                    expanded = true;
                    _expandController.forward();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: context.realDark ? context.surface : colors.item2,
                    borderRadius: BorderRadius.vertical(
                        top: context.radiusMedium.topLeft),
                    boxShadow: context.boxShadowMedium(
                        color: context.realDark ? colors.item1 : null),
                  ),
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.only(
                    left: iconPadding.left,
                    top: iconPadding.top / 2,
                    right: iconPadding.right,
                    bottom: iconPadding.bottom / 2,
                  ),
                  height: iconButtonSize,
                  width: 260,
                  child: Row(
                    children: [
                      UpDownIndicator(
                        status: !expanded,
                        color: context.actionBarIconColor,
                      ),
                      Selector<SelectionController, Tuple2<int, bool>>(
                        selector: (context, selectionController) => Tuple2(
                          selectionController.selectedEpisodes.length,
                          selectionController.selectionTentative,
                        ),
                        builder: (context, data, _) => Text(
                          context.s.selected(
                              "${data.item1}${data.item2 ? "+" : ""}"),
                          style: context.textTheme.titleLarge!
                              .copyWith(color: colors.item3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: context.actionBarIconPadding.vertical / 2),
                        child: Selector<SelectionController,
                            Tuple2<List<EpisodeBrief>, int>>(
                          selector: (context, selectionController) => Tuple2(
                            selectionController.selectedEpisodes,
                            selectionController.selectedEpisodes.length,
                          ),
                          builder: (context, data, _) {
                            int size = data.item1.fold(
                                0,
                                (size, episode) =>
                                    size + (episode.enclosureSize ?? 0));
                            int duration = data.item1.fold(
                                0,
                                (duration, episode) =>
                                    duration +
                                    (episode.enclosureDuration ?? 0));
                            return Text(
                              "  ${size ~/ 1000000}MB  ${duration.toTime}",
                              style: GoogleFonts.teko(
                                  textStyle: context.textTheme.titleSmall!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    CardColorScheme? cardColorScheme = Provider.of<CardColorScheme?>(context);
    if (cardColorScheme == null) {
      return MultiProvider(
        providers: [
          Provider<CardColorScheme>.value(
              value: Theme.of(context).extension<CardColorScheme>()!),
        ],
        child: child,
      );
    } else {
      return child;
    }
  }
}

/// Multi select panel to use with a [SelectionController].
/// Allows advanced selection options and batch actions on selected episodes.
/// [SelectionController] needs to be provided with a [ChangeNotifierProvider]
/// Uses the [CardColorScheme] provided with a [Provider], or defaults to the global theme
class MultiSelectPanel extends StatefulWidget {
  final void Function(double height) onHeightChanged;
  const MultiSelectPanel({required this.onHeightChanged, super.key});

  @override
  State<StatefulWidget> createState() => _MultiSelectPanelState();
}

class _MultiSelectPanelState extends State<MultiSelectPanel>
    with TickerProviderStateMixin {
  late bool selectMode;

  late AnimationController _secondRowController;
  late Animation<double> _secondRowSlideAnimation;
  late Animation<double> _secondRowAppearAnimation;

  double get iconButtonSize => context.actionBarButtonSizeVertical;
  EdgeInsets get iconPadding => context.actionBarIconPadding;
  Radius get iconRadius => context.actionBarIconRadius;

  late Widget _selectionOptions = _SelectionOptions();
  late Widget _playlistList = _PlaylistList();
  late Widget _actionBar = _MultiselectActionBar(
    secondRowController: _secondRowController,
  );

  double get height => Tween<double>(
          begin: iconButtonSize * 2 + iconPadding.vertical * 3 / 2,
          end: iconButtonSize * 3 + iconPadding.vertical * 2)
      .evaluate(_secondRowSlideAnimation);

  @override
  void initState() {
    super.initState();
    _secondRowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        widget.onHeightChanged(height);
        if (mounted) setState(() {});
      });
    _secondRowSlideAnimation = CurvedAnimation(
      parent: _secondRowController,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCirc,
    );
    _secondRowAppearAnimation = CurvedAnimation(
        parent: _secondRowSlideAnimation, curve: Interval(0.75, 1));
    SelectionController selectionController =
        Provider.of<SelectionController>(context, listen: false);
    selectMode = selectionController.selectMode;
    selectionController.addListener(() {
      if (selectMode != selectionController.selectMode) {
        selectMode = selectionController.selectMode;
        if (!selectionController.selectMode) {
          _secondRowController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _secondRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Selector<CardColorScheme, Tuple2<Color, Color>>(
      selector: (_, cardColorScheme) =>
          Tuple2(cardColorScheme.shadow, cardColorScheme.colorScheme.surface),
      builder: (context, data, _) => Container(
        decoration: BoxDecoration(
          color: context.realDark ? context.surface : data.item2,
          borderRadius: context.radiusMedium,
          boxShadow: context.boxShadowMedium(
              color: context.realDark ? data.item1 : null),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        padding: EdgeInsets.only(
          left: iconPadding.left,
          top: iconPadding.top / 2,
          right: iconPadding.right,
          bottom: iconPadding.bottom / 2,
        ),
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBar,
            SizedBox(
              height: Tween<double>(
                      begin: 0, end: iconButtonSize + iconPadding.vertical / 2)
                  .evaluate(_secondRowSlideAnimation),
              child: _secondRowAppearAnimation.value != 0
                  ? FadeTransition(
                      opacity: _secondRowAppearAnimation,
                      child: _playlistList,
                    )
                  : Center(),
            ),
            _selectionOptions,
          ],
        ),
      ),
    );
    CardColorScheme? cardColorScheme = Provider.of<CardColorScheme?>(context);
    if (cardColorScheme == null) {
      return MultiProvider(
        providers: [
          Provider<CardColorScheme>.value(
              value: Theme.of(context).extension<CardColorScheme>()!),
        ],
        child: child,
      );
    } else {
      return child;
    }
  }
}

/// Bar with options to extend batch selection
class _SelectionOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SelectionController selectionController =
        Provider.of<SelectionController>(context, listen: false);
    ExpansionController expansionController = ExpansionController(
        maxWidth: () =>
            context.width -
            (16 + context.actionBarIconPadding.horizontal * 3 / 2));
    expansionController.addWidth(160);
    return Padding(
      padding: EdgeInsets.only(
        top: context.actionBarIconPadding.top / 2,
        bottom: context.actionBarIconPadding.bottom / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Selector<SelectionController, Tuple2<bool, bool>>(
            selector: (context, selectionController) => Tuple2(
                selectionController.batchSelect == BatchSelect.before,
                selectionController.canSetBatchSelect(BatchSelect.before)),
            builder: (context, data, _) {
              return ActionBarButton(
                expansionController: expansionController,
                shrunkChild: Center(
                  child: Icon(
                    Icons.first_page,
                    color: !data.item2 && context.realDark
                        ? Colors.grey[800]
                        : context.actionBarIconColor,
                  ),
                ),
                state: data.item1,
                buttonType: ActionBarButtonType.onOff,
                onPressed: (value) {
                  selectionController.batchSelect = BatchSelect.before;
                },
                width: 80,
                shrunkWidth: context.actionBarButtonSizeHorizontal,
                tooltip: context.s.before,
                enabled: data.item2,
                connectRight: true,
                child: Center(
                  child: Text(
                    context.s.before,
                    style: context.textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
          Selector<SelectionController, Tuple2<bool, bool>>(
            selector: (context, selectionController) => Tuple2(
                selectionController.batchSelect == BatchSelect.between,
                selectionController.canSetBatchSelect(BatchSelect.between)),
            builder: (context, data, _) {
              return ActionBarButton(
                expansionController: expansionController,
                shrunkChild: Center(
                  child: Icon(
                    Icons.more_horiz,
                    color: !data.item2 && context.realDark
                        ? Colors.grey[800]
                        : context.actionBarIconColor,
                  ),
                ),
                state: data.item1,
                buttonType: ActionBarButtonType.onOff,
                onPressed: (value) {
                  selectionController.batchSelect = BatchSelect.between;
                },
                width: 80,
                shrunkWidth: context.actionBarButtonSizeHorizontal,
                tooltip: context.s.between,
                enabled: data.item2,
                connectLeft: true,
                connectRight: true,
                child: Center(
                  child: Text(
                    context.s.between,
                    style: context.textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
          Selector<SelectionController, Tuple2<bool, bool>>(
            selector: (context, selectionController) => Tuple2(
              selectionController.batchSelect == BatchSelect.after,
              selectionController.canSetBatchSelect(BatchSelect.after),
            ),
            builder: (context, data, _) {
              return ActionBarButton(
                expansionController: expansionController,
                shrunkChild: Center(
                  child: Icon(
                    Icons.last_page,
                    color: !data.item2 && context.realDark
                        ? Colors.grey[800]
                        : context.actionBarIconColor,
                  ),
                ),
                state: data.item1,
                buttonType: ActionBarButtonType.onOff,
                onPressed: (value) {
                  selectionController.batchSelect = BatchSelect.after;
                },
                width: 80,
                shrunkWidth: context.actionBarButtonSizeHorizontal,
                tooltip: context.s.after,
                enabled: data.item2,
                connectLeft: true,
                connectRight: true,
                child: Center(
                  child: Text(
                    context.s.after,
                    style: context.textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
          Selector<SelectionController, bool>(
            selector: (context, selectionController) =>
                selectionController.batchSelect == BatchSelect.all,
            builder: (context, state, _) => ActionBarButton(
              expansionController: expansionController,
              shrunkChild: Center(
                child: Icon(
                  Icons.select_all,
                  color: context.actionBarIconColor,
                ),
              ),
              state: state,
              buttonType: ActionBarButtonType.onOff,
              onPressed: (value) {
                selectionController.batchSelect = BatchSelect.all;
              },
              width: 80,
              shrunkWidth: context.actionBarButtonSizeHorizontal,
              tooltip: context.s.all,
              connectLeft: true,
              child: Center(
                child: Text(
                  context.s.all,
                  style: context.textTheme.titleMedium,
                ),
              ),
            ),
          ),
          Spacer(),
          ActionBarButton(
            onPressed: (value) {
              Provider.of<SelectionController>(context, listen: false)
                  .selectMode = false;
            },
            child: Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _NewPlaylist extends StatefulWidget {
  final List<EpisodeBrief> episodes;
  final Color? color;
  const _NewPlaylist(this.episodes, {this.color});

  @override
  __NewPlaylistState createState() => __NewPlaylistState();
}

class __NewPlaylistState extends State<_NewPlaylist> {
  String? _playlistName;
  int? _error;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor:
            Theme.of(context).brightness == Brightness.light
                ? Color.fromRGBO(113, 113, 113, 1)
                : Color.fromRGBO(5, 5, 5, 1),
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        backgroundColor: widget.color?.toWeakBackround(context) ??
            context.accentBackgroundWeak,
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        titlePadding: EdgeInsets.all(20),
        actionsPadding: EdgeInsets.zero,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              s.cancel,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (context
                  .read<AudioPlayerNotifier>()
                  .playlistExists(_playlistName)) {
                if (mounted) setState(() => _error = 1);
              } else {
                final episodesList =
                    widget.episodes.map((e) => e.enclosureUrl).toList();
                final playlist =
                    Playlist(_playlistName, episodeUrlList: episodesList);
                context.read<AudioPlayerNotifier>().addPlaylist(playlist);
                Navigator.of(context).pop();
              }
            },
            child: Text(s.confirm,
                style: TextStyle(color: widget.color ?? context.accentColor)),
          )
        ],
        title:
            SizedBox(width: context.width - 160, child: Text('New playlist')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                hintText: 'New playlist',
                hintStyle: TextStyle(fontSize: 18),
                filled: true,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.color ?? context.accentColor, width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.color ?? context.accentColor, width: 2.0),
                ),
              ),
              cursorRadius: Radius.circular(2),
              autofocus: true,
              maxLines: 1,
              onChanged: (value) {
                _playlistName = value;
              },
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: (_error == 1)
                  ? Text(
                      'Playlist existed',
                      style: TextStyle(color: Colors.red[400]),
                    )
                  : Center(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar of the list of playlists to choose which playlist to batch add to
class _PlaylistList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(
        top: context.actionBarIconPadding.top / 2,
        bottom: context.actionBarIconPadding.bottom / 2,
      ),
      child: Selector<AudioPlayerNotifier, Tuple2<List<Playlist>, int>>(
        selector: (_, audio) => Tuple2(audio.playlists,
            audio.playlists.length), // Length is needed for selector
        builder: (_, data, child) {
          return Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (var p in data.item1)
                    if (p.name == 'Queue')
                      _buttonOnMenu(
                        child: Row(
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 5),
                            Text('New')
                          ],
                        ),
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: MaterialLocalizations.of(context)
                                .modalBarrierDismissLabel,
                            barrierColor: Colors.black54,
                            transitionDuration:
                                const Duration(milliseconds: 200),
                            pageBuilder: (_, animaiton, secondaryAnimation) =>
                                _NewPlaylist(
                                    Provider.of<SelectionController>(context,
                                            listen: false)
                                        .selectedEpisodes,
                                    color: Provider.of<CardColorScheme>(context,
                                            listen: false)
                                        .colorScheme
                                        .primary),
                          );
                        },
                      )
                    else
                      _buttonOnMenu(
                        child: Row(
                          children: [
                            Container(
                              height: 30,
                              width: 30,
                              color: Provider.of<CardColorScheme>(context,
                                      listen: false)
                                  .colorScheme
                                  .primary
                                  .toHighlightBackround(context),
                              child: FutureBuilder<EpisodeBrief?>(
                                future: () async {
                                  await p.getPlaylist();
                                  return p.episodes.first;
                                }(),
                                builder: (_, snapshot) {
                                  if (snapshot.data != null) {
                                    return SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Image(
                                            image: snapshot.data!.avatarImage));
                                  }
                                  return Center();
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(p.name!),
                          ],
                        ),
                        onTap: () async {
                          SelectionController selectionController =
                              Provider.of<SelectionController>(context,
                                  listen: false);
                          await selectionController.getEpisodesLimitless();
                          await context
                              .read<AudioPlayerNotifier>()
                              .addToPlaylist(
                                  selectionController.selectedEpisodes,
                                  playlist: p);
                        },
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buttonOnMenu({Widget? child, VoidCallback? onTap}) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0), child: child),
          ),
        ),
      );
}

/// Action bar for batch actions
class _MultiselectActionBar extends StatefulWidget {
  final AnimationController secondRowController;

  const _MultiselectActionBar({
    required this.secondRowController,
  });
  @override
  _MultiselectActionBarState createState() => _MultiselectActionBarState();
}

class _MultiselectActionBarState extends State<_MultiselectActionBar> {
  bool? liked;
  bool? played;
  bool? downloaded;
  bool? inPlaylist;

  List<EpisodeBrief> selectedEpisodes = [];

  bool get secondRow => widget.secondRowController.value != 0;
  set secondRow(bool boo) => boo
      ? widget.secondRowController.forward()
      : widget.secondRowController.reverse();

  @override
  void initState() {
    super.initState();
    _initProperties(Provider.of<SelectionController>(context, listen: false)
        .selectionTentative);
    widget.secondRowController.addStatusListener(
      (status) {
        if (mounted && status == AnimationStatus.dismissed) setState(() {});
      },
    );
  }

  void _initProperties(bool selectionTentative) {
    if (selectionTentative) {
      liked = null;
      played = null;
      downloaded = null;
      inPlaylist = null;
    } else {
      bool likedSet = false;
      bool playedSet = false;
      bool downloadedSet = false;
      bool inPlaylistSet = false;
      liked = false;
      played = false;
      downloaded = false;
      inPlaylist = false;
      var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
      for (var episode in selectedEpisodes) {
        if (!likedSet) {
          liked = episode.isLiked!;
          likedSet = true;
        } else if (episode.isLiked! != liked) {
          liked = null;
        }
        if (!playedSet) {
          played = episode.isPlayed!;
          playedSet = true;
        } else if (episode.isPlayed! != played) {
          played = null;
        }
        if (!downloadedSet) {
          downloaded = episode.isDownloaded!;
          downloadedSet = true;
        } else if (episode.isDownloaded! != downloaded) {
          downloaded = null;
        }
        if (!inPlaylistSet) {
          inPlaylist = audio.playlist.contains(episode);
          inPlaylistSet = true;
        } else if (audio.playlist.contains(episode) != inPlaylist) {
          inPlaylist = null;
        }
        if (liked == null &&
            played == null &&
            downloaded == null &&
            inPlaylist == null) {
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: context.actionBarIconPadding.top / 2,
        bottom: context.actionBarIconPadding.bottom / 2,
      ),
      child: Selector<SelectionController,
          Tuple4<List<EpisodeBrief>, int, bool, bool>>(
        selector: (_, selectionController) => Tuple4(
            selectionController.selectedEpisodes,
            selectionController.selectedEpisodes.length,
            selectionController.episodesUpdated,
            selectionController.selectionTentative),
        builder: (context, data, _) {
          // Only item 1 & 2 is used, other items just communicate change.
          selectedEpisodes = data.item1;
          _initProperties(data.item4);
          return Row(
            children: [
              ActionBarButton(
                falseChild: Icon(Icons.favorite_border,
                    color: data.item2 == 0 && context.realDark
                        ? Colors.grey[800]
                        : context.actionBarIconColor),
                state: liked,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  if (selectedEpisodes.isNotEmpty) {
                    EpisodeState episodeState =
                        Provider.of<EpisodeState>(context, listen: false);
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodes = selectionController.selectedEpisodes;
                    liked = value;
                    if (value!) {
                      await episodeState.setLiked(selectedEpisodes);
                      Fluttertoast.showToast(
                        msg: context.s.liked,
                        gravity: ToastGravity.BOTTOM,
                      );
                      OverlayEntry overlayEntry;
                      overlayEntry = createOverlayEntry(context);
                      Overlay.of(context).insert(overlayEntry);
                      await Future.delayed(Duration(seconds: 2));
                      overlayEntry.remove();
                    } else {
                      await episodeState.unsetLiked(selectedEpisodes);
                      Fluttertoast.showToast(
                        msg: context.s.unlike,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                },
                enabled: data.item2 >= 1,
                connectRight: true,
                child: Icon(Icons.favorite, color: Colors.red),
              ),
              ActionBarButton(
                falseChild: CustomPaint(
                  size: Size(25, 25),
                  painter: MarkListenedPainter(
                      data.item2 == 0 && context.realDark
                          ? Colors.grey[800]!
                          : context.actionBarIconColor,
                      stroke: 2.0),
                ),
                state: played,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  if (selectedEpisodes.isNotEmpty) {
                    EpisodeState episodeState =
                        Provider.of<EpisodeState>(context, listen: false);
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodes = selectionController.selectedEpisodes;
                    played = value;
                    if (value!) {
                      await episodeState.setListened(selectedEpisodes);
                      Fluttertoast.showToast(
                        msg: context.s.markListened,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      await episodeState.unsetListened(selectedEpisodes);
                      Fluttertoast.showToast(
                        msg: context.s.markNotListened,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                },
                enabled: data.item2 >= 1,
                connectLeft: true,
                connectRight: true,
                child: Selector<CardColorScheme, Color>(
                  selector: (context, cardColorScheme) =>
                      cardColorScheme.colorScheme.primary,
                  builder: (context, color, _) => CustomPaint(
                    size: Size(25, 25),
                    painter: ListenedAllPainter(color, stroke: 2.0),
                  ),
                ),
              ),
              ActionBarButton(
                falseChild: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CustomPaint(
                      painter: DownloadPainter(
                        color: data.item2 == 0 && context.realDark
                            ? Colors.grey[800]
                            : context.actionBarIconColor,
                        fraction: 0,
                        progressColor: data.item2 == 0 && context.realDark
                            ? Colors.grey[800]
                            : context.actionBarIconColor,
                      ),
                    ),
                  ),
                ),
                state: downloaded,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  if (selectedEpisodes.isNotEmpty) {
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodes = selectionController.selectedEpisodes;
                    downloaded = value;
                    if (value!) {
                      await requestDownload(
                        selectedEpisodes,
                        context,
                        onSuccess: () {
                          // TODO: Make the icon reflect this
                          Fluttertoast.showToast(
                            msg: context.s.downloaded,
                            gravity: ToastGravity.BOTTOM,
                          );
                        },
                      );
                    } else {
                      List<Future<void>> futures = [];
                      for (var episode in selectedEpisodes) {
                        futures.add(
                            Provider.of<DownloadState>(context, listen: false)
                                .delTask(episode));
                      }
                      Future.wait(futures);
                      Fluttertoast.showToast(
                        msg: context.s.downloadRemovedToast,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                },
                enabled: data.item2 >= 1,
                connectLeft: true,
                connectRight: false,
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: Selector<CardColorScheme, Color>(
                      selector: (context, cardColorScheme) =>
                          cardColorScheme.colorScheme.primary,
                      builder: (context, color, _) => CustomPaint(
                        painter: DownloadPainter(
                            color: color,
                            fraction: 1,
                            progressColor: color,
                            progress: 1),
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(),
              ActionBarButton(
                state: secondRow,
                buttonType: ActionBarButtonType.onOff,
                onPressed: (value) {
                  secondRow = value!;
                },
                connectLeft: false,
                connectRight: true,
                child: Icon(
                  Icons.add_box_outlined,
                  color: context.actionBarIconColor,
                ),
              ),
              ActionBarButton(
                state: inPlaylist,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  if (selectedEpisodes.isNotEmpty) {
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodes = selectionController.selectedEpisodes;
                    inPlaylist = value;
                    if (value!) {
                      await Provider.of<AudioPlayerNotifier>(context,
                              listen: false)
                          .addToPlaylist(selectedEpisodes);
                      await Fluttertoast.showToast(
                        msg: context.s.toastAddPlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      await Provider.of<AudioPlayerNotifier>(context,
                              listen: false)
                          .removeFromPlaylist(selectedEpisodes);
                      await Fluttertoast.showToast(
                        msg: context.s.toastRemovePlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                },
                enabled: data.item2 >= 1,
                connectLeft: true,
                connectRight: true,
                falseChild: Icon(
                  Icons.playlist_add,
                  color: data.item2 == 0 && context.realDark
                      ? Colors.grey[800]
                      : context.actionBarIconColor,
                ),
                child: Selector<CardColorScheme, Color>(
                  selector: (context, cardColorScheme) =>
                      cardColorScheme.colorScheme.primary,
                  builder: (context, color, _) =>
                      Icon(Icons.playlist_add_check, color: color),
                ),
              ),
              ActionBarButton(
                state: inPlaylist,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  if (selectedEpisodes.isNotEmpty) {
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodes = selectionController.selectedEpisodes;
                    inPlaylist = value;
                    if (value!) {
                      AudioPlayerNotifier audio =
                          Provider.of<AudioPlayerNotifier>(context,
                              listen: false);
                      await audio.addToPlaylist(selectedEpisodes,
                          index: audio.playlist.length > 0 ? 1 : 0);
                      await Fluttertoast.showToast(
                        msg: context.s.toastAddPlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      await Provider.of<AudioPlayerNotifier>(context,
                              listen: false)
                          .removeFromPlaylist(selectedEpisodes);
                      await Fluttertoast.showToast(
                        msg: context.s.toastRemovePlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                },
                enabled: data.item2 >= 1,
                connectLeft: true,
                connectRight: true,
                falseChild: Icon(
                  LineIcons.lightningBolt,
                  color: data.item2 == 0 && context.realDark
                      ? Colors.grey[800]
                      : context.actionBarIconColor,
                ),
                child: Selector<CardColorScheme, Color>(
                  selector: (context, cardColorScheme) =>
                      cardColorScheme.colorScheme.primary,
                  builder: (context, color, _) => Stack(
                    children: [
                      Icon(LineIcons.lightningBolt, color: color),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.check,
                          color: color,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Selector<AudioPlayerNotifier, bool>(
                selector: (context, audio) => audio.playerRunning,
                builder: (context, playerRunning, _) => ActionBarButton(
                  state: playerRunning ? inPlaylist : false,
                  buttonType: ActionBarButtonType.partialOnOff,
                  onPressed: (value) async {
                    if (selectedEpisodes.isNotEmpty) {
                      SelectionController selectionController =
                          Provider.of<SelectionController>(context,
                              listen: false);
                      await selectionController.getEpisodesLimitless();
                      selectedEpisodes = selectionController.selectedEpisodes;
                      inPlaylist = value;
                      if (value!) {
                        await Provider.of<AudioPlayerNotifier>(context,
                                listen: false)
                            .loadEpisodesToQueue(selectedEpisodes);
                        await Fluttertoast.showToast(
                          msg: context.s.toastAddPlaylist,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    }
                  },
                  enabled: data.item2 >= 1,
                  connectLeft: true,
                  connectRight: false,
                  falseChild: Icon(
                    Icons.play_arrow,
                    color: data.item2 == 0 && context.realDark
                        ? Colors.grey[800]
                        : context.actionBarIconColor,
                  ),
                  child: Selector<CardColorScheme, Color>(
                    selector: (context, cardColorScheme) =>
                        cardColorScheme.colorScheme.primary,
                    builder: (context, color, _) => SizedBox(
                      width: 20,
                      height: 15,
                      child: WaveLoader(color: context.accentColor),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
