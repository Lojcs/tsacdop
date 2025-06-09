import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../util/selection_controller.dart';
import 'package:tuple/tuple.dart';

import '../home/audioplayer.dart';
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
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
                  MultiSelectPanel(
                    onHeightChanged: (height) {
                      if (mounted) {
                        setState(() => multiSelectHeight = height);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Selector<AudioPlayerNotifier, (bool, PlayerHeight?)>(
          selector: (_, audio) => (audio.playerRunning, audio.playerHeight),
          builder: (_, data, __) {
            var height = kMinPlayerHeight[data.$2?.index ?? 0];
            return SizedBox(height: data.$1 ? height : 0);
          },
        ),
      ],
    );
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
      if (mounted && selectMode != selectionController.selectMode) {
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
      width: context.width,
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
            if (bodyHeight != 0)
              Container(
                height: bodyHeight,
                decoration: BoxDecoration(
                  color: context.realDark ? context.surface : colors.item2,
                  borderRadius: BorderRadius.only(
                      topRight: context.radiusMedium.topRight),
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
                    Selector<SelectionController, (List<int>, int)>(
                      selector: (_, selectionController) => (
                        selectionController.selectedEpisodes,
                        selectionController.selectedEpisodes.length,
                      ),
                      builder: (context, data, _) {
                        return EpisodeGrid(
                          episodeIds: data.$1,
                          layout: EpisodeGridLayout.medium,
                          openPodcast: true,
                          selectable: false,
                          initNum: 0,
                        );
                      },
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.only(left: 24, top: 8, right: 24),
              clipBehavior: Clip.antiAlias, // Clip the shadow on the bottom
              decoration: BoxDecoration(),
              child: Container(
                decoration: BoxDecoration(
                  color: context.realDark ? context.surface : colors.item2,
                  borderRadius:
                      BorderRadius.vertical(top: context.radiusMedium.topLeft),
                  boxShadow: context.boxShadowMedium(
                      color: context.realDark ? colors.item1 : null),
                ),
                clipBehavior: Clip.hardEdge,
                height: iconButtonSize,
                width: 260,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (expanded) {
                        expanded = false;
                        _expandController.reverse();
                      } else {
                        expanded = true;
                        _expandController.forward();
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: iconPadding.left,
                        top: iconPadding.top / 2,
                        right: iconPadding.right,
                        bottom: iconPadding.bottom / 2,
                      ),
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
                            child:
                                Selector<SelectionController, (List<int>, int)>(
                              selector: (context, selectionController) => (
                                selectionController.selectedEpisodes,
                                selectionController.selectedEpisodes.length,
                              ),
                              builder: (context, data, _) {
                                var eState = Provider.of<EpisodeState>(context,
                                    listen: false);
                                int size = data.$1.fold(
                                    0,
                                    (size, id) =>
                                        size + eState[id].enclosureSize);
                                int duration = data.$1.fold(
                                    0,
                                    (duration, id) =>
                                        duration +
                                        eState[id].enclosureDuration);
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
              ),
            ),
          ],
        ),
      ),
    );
    CardColorScheme? cardColorScheme =
        Provider.of<CardColorScheme?>(context, listen: false);
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

  late Playlist _playlist =
      Provider.of<AudioPlayerNotifier>(context, listen: false).playlist;
  set playlist(Playlist p) {
    _playlist = p;
    _playlistList = _PlaylistList(
        playlist: _playlist, onPlaylistChanged: (p) => playlist = p);
    _actionBar = _MultiselectActionBar(
      secondRowController: _secondRowController,
      playlist: _playlist,
      onSecondRowOpen: () {
        playlist =
            Provider.of<AudioPlayerNotifier>(context, listen: false).playlist;
      },
    );
    setState(() {});
  }

  late final Widget _selectionOptions = _SelectionOptions();
  late Widget _playlistList = _PlaylistList(
      playlist: _playlist, onPlaylistChanged: (p) => playlist = p);
  late Widget _actionBar = _MultiselectActionBar(
    secondRowController: _secondRowController,
    onSecondRowOpen: () {
      playlist =
          Provider.of<AudioPlayerNotifier>(context, listen: false).playlist;
    },
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
      if (mounted && selectMode != selectionController.selectMode) {
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
    CardColorScheme? cardColorScheme =
        Provider.of<CardColorScheme?>(context, listen: false);
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
          Selector<SelectionController, bool>(
            selector: (context, selectionController) =>
                selectionController.selectionTentative,
            builder: (context, data, _) {
              return ActionBarButton(
                expansionController: expansionController,
                state: data,
                buttonType: ActionBarButtonType.onOff,
                onPressed: (value) async {
                  SelectionController selectionController =
                      Provider.of<SelectionController>(context, listen: false);
                  await selectionController.getEpisodesLimitless();
                },
                tooltip: context.s.loadAllSelected,
                enabled: data,
                connectRight: true,
                child: Icon(
                  Icons.all_inclusive,
                  color: !data && context.realDark
                      ? Colors.grey[800]
                      : context.actionBarIconColor,
                ),
              );
            },
          ),
          Selector<SelectionController, bool>(
            selector: (context, selectionController) =>
                selectionController.selectedEpisodes.isNotEmpty,
            builder: (context, enable, _) => ActionBarButton(
              expansionController: expansionController,
              buttonType: ActionBarButtonType.single,
              onPressed: (value) {
                selectionController.deselectAll();
              },
              width: context.actionBarButtonSizeHorizontal,
              tooltip: context.s.deselectAll,
              enabled: enable,
              connectLeft: true,
              connectRight: true,
              child: Center(
                child: Icon(
                  Icons.check_box_outline_blank,
                  color: context.actionBarIconColor,
                ),
              ),
            ),
          ),
          ActionBarButton(
            expansionController: expansionController,
            onPressed: (value) {
              Provider.of<SelectionController>(context, listen: false)
                  .selectMode = false;
            },
            tooltip: context.s.close,
            connectLeft: true,
            child: Icon(Icons.close, color: context.actionBarIconColor),
          ),
        ],
      ),
    );
  }
}

class _NewPlaylist extends StatefulWidget {
  final List<int> episodeIds;
  final Color? color;
  const _NewPlaylist(this.episodeIds, {this.color});

  @override
  __NewPlaylistState createState() => __NewPlaylistState();
}

class __NewPlaylistState extends State<_NewPlaylist> {
  String _playlistName = "";
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
                final playlist =
                    Playlist(_playlistName, episodeIds: widget.episodeIds);
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
  /// Default playlist to use with playlist actions
  final Playlist playlist;

  /// Communicates that the playlist to use with playlist actions has changed
  final void Function(Playlist playlist) onPlaylistChanged;
  const _PlaylistList({
    required this.playlist,
    required this.onPlaylistChanged,
  });

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
                  _buttonOnMenu(
                    context,
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
                        transitionDuration: const Duration(milliseconds: 200),
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
                  ),
                  ...data.item1.map<Widget>(
                    (p) => _buttonOnMenu(
                      context,
                      child: Row(
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              color: Provider.of<CardColorScheme>(context,
                                      listen: false)
                                  .colorScheme
                                  .primary
                                  .toHighlightBackround(context),
                              borderRadius: context.radiusSmall,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                FutureBuilder<ImageProvider?>(
                                  future: () async {
                                    if (p.isEmpty) return null;
                                    EpisodeState eState = context.episodeState;
                                    await p.cachePlaylist(eState);
                                    return eState[p.episodeIds.first]
                                        .podcastImageProvider;
                                  }(),
                                  builder: (_, snapshot) => snapshot.data !=
                                          null
                                      ? SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: Image(image: snapshot.data!),
                                        )
                                      : Center(),
                                ),
                                if (p == playlist)
                                  Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 30,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(p.name),
                        ],
                      ),
                      onTap: () => onPlaylistChanged(p),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buttonOnMenu(
    BuildContext context, {
    Widget? child,
    VoidCallback? onTap,
  }) =>
      Material(
        borderRadius: context.radiusSmall,
        clipBehavior: Clip.antiAlias,
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
  final Playlist? playlist;

  final VoidCallback onSecondRowOpen;

  const _MultiselectActionBar({
    required this.secondRowController,
    this.playlist,
    required this.onSecondRowOpen,
  });
  @override
  _MultiselectActionBarState createState() => _MultiselectActionBarState();
}

class _MultiselectActionBarState extends State<_MultiselectActionBar> {
  bool? liked;
  bool? played;
  bool? downloaded;
  bool? inPlaylist;

  late Playlist playlist;

  List<int> selectedEpisodeIds = [];
  bool _secondRow = false;
  bool get secondRow => _secondRow;
  set secondRow(bool boo) {
    _secondRow = boo;
    if (boo) {
      widget.onSecondRowOpen();
      widget.secondRowController.forward();
    } else {
      widget.secondRowController.reverse();
    }
  }

  bool actionLock = false;

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

  @override
  void didUpdateWidget(_MultiselectActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playlist != null) {
      playlist = widget.playlist!;
    }
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
      if (widget.playlist == null) {
        playlist =
            Provider.of<AudioPlayerNotifier>(context, listen: false).playlist;
      }
      for (var id in selectedEpisodeIds) {
        var episode = Provider.of<EpisodeState>(context, listen: false)[id];
        if (!likedSet) {
          liked = episode.isLiked;
          likedSet = true;
        } else if (episode.isLiked != liked) {
          liked = null;
        }
        if (!playedSet) {
          played = episode.isPlayed;
          playedSet = true;
        } else if (episode.isPlayed != played) {
          played = null;
        }
        if (!downloadedSet) {
          downloaded = episode.isDownloaded;
          downloadedSet = true;
        } else if (episode.isDownloaded != downloaded) {
          downloaded = null;
        }
        if (!inPlaylistSet) {
          inPlaylist = playlist.contains(id);
          inPlaylistSet = true;
        } else if (playlist.contains(id) != inPlaylist) {
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
      child: Selector2<SelectionController, EpisodeState,
          (List<int>, int, bool, bool)>(
        selector: (_, selectionController, episodeState) => (
          selectionController.selectedEpisodes,
          selectionController.selectedEpisodes.length,
          selectionController.selectionTentative,
          episodeState.globalChange,
        ),
        builder: (context, data, _) {
          selectedEpisodeIds = data.$1;
          _initProperties(data.$3);
          return Row(
            children: [
              ActionBarButton(
                falseChild: Icon(Icons.favorite_border,
                    color: data.$2 == 0 && context.realDark
                        ? Colors.grey[800]
                        : context.actionBarIconColor),
                state: liked,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  setState(() => actionLock = true);
                  if (selectedEpisodeIds.isNotEmpty) {
                    EpisodeState episodeState =
                        Provider.of<EpisodeState>(context, listen: false);
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodeIds = selectionController.selectedEpisodes;
                    liked = value;
                    if (value!) {
                      await episodeState.setLiked(selectedEpisodeIds);
                      setState(() => actionLock = false);
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
                      await episodeState.unsetLiked(selectedEpisodeIds);
                      setState(() => actionLock = false);
                      Fluttertoast.showToast(
                        msg: context.s.unlike,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                },
                tooltip: liked != false ? context.s.like : context.s.unlike,
                enabled: !actionLock && data.$2 >= 1,
                connectRight: true,
                child: Icon(Icons.favorite, color: Colors.red),
              ),
              ActionBarButton(
                falseChild: CustomPaint(
                  size: Size(25, 25),
                  painter: MarkListenedPainter(
                      data.$2 == 0 && context.realDark
                          ? Colors.grey[800]!
                          : context.actionBarIconColor,
                      stroke: 2.0),
                ),
                state: played,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  setState(() => actionLock = true);
                  if (selectedEpisodeIds.isNotEmpty) {
                    EpisodeState episodeState =
                        Provider.of<EpisodeState>(context, listen: false);
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodeIds = selectionController.selectedEpisodes;
                    played = value;
                    if (value!) {
                      await episodeState.setPlayed(selectedEpisodeIds);
                      Fluttertoast.showToast(
                        msg: context.s.markListened,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      await episodeState.unsetPlayed(selectedEpisodeIds);
                      Fluttertoast.showToast(
                        msg: context.s.markNotListened,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                  setState(() => actionLock = false);
                },
                tooltip: played != false
                    ? context.s.markListened
                    : context.s.markNotListened,
                enabled: !actionLock && data.$2 >= 1,
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
                        color: data.$2 == 0 && context.realDark
                            ? Colors.grey[800]
                            : context.actionBarIconColor,
                        fraction: 0,
                        progressColor: data.$2 == 0 && context.realDark
                            ? Colors.grey[800]
                            : context.actionBarIconColor,
                      ),
                    ),
                  ),
                ),
                state: downloaded,
                buttonType: ActionBarButtonType.partialOnOff,
                onPressed: (value) async {
                  setState(() => actionLock = true);
                  if (selectedEpisodeIds.isNotEmpty) {
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodeIds = selectionController.selectedEpisodes;
                    downloaded = value;
                    List<EpisodeBrief> selectedEpisodes = selectedEpisodeIds
                        .map((i) => Provider.of<EpisodeState>(context,
                            listen: false)[i])
                        .toList();
                    if (value!) {
                      await requestDownload(
                        selectedEpisodes,
                        context,
                        onSuccess: () {
                          // TODO: Make the icon reflect this
                          Fluttertoast.showToast(
                            msg: context.s.downloading,
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
                  setState(() => actionLock = false);
                },
                tooltip: downloaded != false
                    ? context.s.download
                    : context.s.removeDownload,
                enabled: !actionLock && data.$2 >= 1,
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
                tooltip: context.s.playlists,
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
                  setState(() => actionLock = true);
                  if (selectedEpisodeIds.isNotEmpty) {
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    AudioPlayerNotifier audio =
                        Provider.of<AudioPlayerNotifier>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodeIds = selectionController.selectedEpisodes;
                    inPlaylist = value;
                    if (value!) {
                      await audio.addToPlaylist(selectedEpisodeIds,
                          playlist: playlist);
                      await Fluttertoast.showToast(
                        msg: context.s.toastAddPlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      await audio.removeFromPlaylist(selectedEpisodeIds,
                          playlist: playlist);
                      await Fluttertoast.showToast(
                        msg: context.s.toastRemovePlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }
                  setState(() => actionLock = false);
                },
                tooltip: context.s.later,
                enabled: !actionLock && data.$2 >= 1,
                connectLeft: true,
                connectRight: true,
                falseChild: Icon(
                  Icons.playlist_add,
                  color: data.$2 == 0 && context.realDark
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
                  setState(() => actionLock = true);
                  if (selectedEpisodeIds.isNotEmpty) {
                    SelectionController selectionController =
                        Provider.of<SelectionController>(context,
                            listen: false);
                    AudioPlayerNotifier audio =
                        Provider.of<AudioPlayerNotifier>(context,
                            listen: false);
                    await selectionController.getEpisodesLimitless();
                    selectedEpisodeIds = selectionController.selectedEpisodes;
                    inPlaylist = value;
                    if (value!) {
                      await audio.addToPlaylist(selectedEpisodeIds,
                          index: audio.playlist.length > 0 ? 1 : 0,
                          playlist: playlist);
                      await Fluttertoast.showToast(
                        msg: context.s.toastAddPlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      await audio.removeFromPlaylist(selectedEpisodeIds,
                          playlist: playlist);
                      await Fluttertoast.showToast(
                        msg: context.s.toastRemovePlaylist,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  }

                  setState(() => actionLock = false);
                },
                tooltip: context.s.playNext,
                enabled: !actionLock && data.$2 >= 1,
                connectLeft: true,
                connectRight: true,
                falseChild: Icon(
                  LineIcons.lightningBolt,
                  color: data.$2 == 0 && context.realDark
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
                    setState(() => actionLock = true);
                    if (selectedEpisodeIds.isNotEmpty) {
                      SelectionController selectionController =
                          Provider.of<SelectionController>(context,
                              listen: false);
                      await selectionController.getEpisodesLimitless();
                      selectedEpisodeIds = selectionController.selectedEpisodes;
                      inPlaylist = value;
                      if (value!) {
                        await Provider.of<AudioPlayerNotifier>(context,
                                listen: false)
                            .loadEpisodesToQueue(selectedEpisodeIds);
                        await Fluttertoast.showToast(
                          msg: context.s.toastAddPlaylist,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    }
                    setState(() => actionLock = false);
                  },
                  tooltip: context.s.play,
                  enabled: !actionLock && data.$2 >= 1,
                  connectLeft: true,
                  connectRight: false,
                  falseChild: Icon(
                    Icons.play_arrow,
                    color: data.$2 == 0 && context.realDark
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
