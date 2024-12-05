import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/util/selection_controller.dart';
import 'package:tuple/tuple.dart';

import '../home/audioplayer.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../type/playlist.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import 'action_bar_generic_widgets.dart';
import 'custom_widget.dart';

/// Integrates [MultiSelectPanel] with [EpisodeState]
/// and places it above the [PlayerWidget]
class MultiSelectPanelIntegration extends StatefulWidget {
  final SelectionController selectionController;
  final bool expanded;
  final Color? color;
  final ValueGetter<Future<List<EpisodeBrief>>> getEpisodes;
  const MultiSelectPanelIntegration({
    required this.selectionController,
    this.expanded = true,
    this.color,
    required this.getEpisodes,
    Key? key,
  });

  @override
  _MultiSelectPanelIntegrationState createState() =>
      _MultiSelectPanelIntegrationState();
}

class _MultiSelectPanelIntegrationState
    extends State<MultiSelectPanelIntegration> with TickerProviderStateMixin {
  late bool episodeStateGlobalChange;
  bool initialBuild = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (initialBuild) {
      initialBuild = false;
      episodeStateGlobalChange =
          Provider.of<EpisodeState>(context).globalChange;
    }
    return Selector<AudioPlayerNotifier, Tuple2<bool, PlayerHeight?>>(
      selector: (_, audio) => Tuple2(audio.playerRunning, audio.playerHeight),
      builder: (_, data, __) {
        var height = kMinPlayerHeight[data.item2!.index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Selector<EpisodeState, bool>(
              selector: (_, episodeState) => episodeState.globalChange,
              builder: (_, data, ___) => FutureBuilder<List<EpisodeBrief>?>(
                future: () async {
                  if (data != episodeStateGlobalChange) {
                    // Prevents unnecessary database calls when the bar is rebuilt for other reasons
                    episodeStateGlobalChange = data;
                    return _getUpdatedEpisodes(context);
                  } else {
                    return null;
                  }
                }(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    widget.selectionController.updateEpisodes(snapshot.data!);
                  }
                  return MultiSelectPanel(
                    selectionController: widget.selectionController,
                    expanded: widget.expanded,
                    color: widget.color,
                    getEpisodes: widget.getEpisodes,
                    key: widget.key,
                  );
                },
              ),
            ),
            SizedBox(
              height: data.item1 ? height : 0,
            ),
          ],
        );
      },
    );
  }

  Future<List<EpisodeBrief>> _getUpdatedEpisodes(BuildContext context) async {
    var dbHelper = DBHelper();
    List<int> episodeIds = [];
    EpisodeState episodeState = Provider.of<EpisodeState>(context);
    Set<int> episodesInSelectionController = widget
            .selectionController.hasAllSelectableEpisodes
        ? widget.selectionController.selectableEpisodes.map((e) => e.id).toSet()
        : widget.selectionController.selectableEpisodes.map((e) => e.id).toSet()
      ..addAll(
          widget.selectionController.selectedEpisodes.map((e) => e.id).toSet());
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

/// Multi select panel to use with a [SelectionController].
/// Allows advanced selection options and batch actions on selected episodes.
class MultiSelectPanel extends StatefulWidget {
  final SelectionController selectionController;
  final bool expanded;
  final Color? color;
  final ValueGetter<Future<List<EpisodeBrief>>> getEpisodes;
  const MultiSelectPanel({
    required this.selectionController,
    this.expanded = true,
    this.color,
    required this.getEpisodes,
    Key? key,
  }) : super(key: key);

  @override
  _MultiSelectPanelState createState() => _MultiSelectPanelState();
}

class _MultiSelectPanelState extends State<MultiSelectPanel>
    with TickerProviderStateMixin {
  Color get color => widget.color ?? context.accentColor;
  late final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: color,
    brightness: Brightness.dark,
  );
  late Color activeColor = context.realDark
      ? colorScheme.secondaryContainer
      : color.toStrongBackround(context);

  late final SelectionController selectionController =
      widget.selectionController;

  late bool selectMode = selectionController.selectMode;

  bool get secondRow => _secondRowController.value != 0;
  set secondRow(bool boo) =>
      boo ? _secondRowController.forward() : _secondRowController.reverse();
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late AnimationController _secondRowController;
  late Animation<double> _secondRowSlideAnimation;
  late Animation<double> _secondRowAppearAnimation;

  double iconButtonSize = 36;
  EdgeInsets get iconPadding => EdgeInsets.all((iconButtonSize - 24) / 2);
  Radius iconRadius = Radius.circular(16);

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
    _secondRowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _secondRowSlideAnimation = CurvedAnimation(
        parent: _secondRowController, curve: Curves.easeInOutExpo);
    _secondRowAppearAnimation = CurvedAnimation(
        parent: _secondRowSlideAnimation, curve: Interval(0.75, 1));
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
    _secondRowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MultiSelectPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.expanded
          ? (Tween<double>(
                          begin: 10 + iconButtonSize * 2 + iconPadding.vertical,
                          end: 10 +
                              iconButtonSize * 3 +
                              iconPadding.vertical * 3 / 2)
                      .evaluate(_secondRowSlideAnimation) +
                  8) *
              _slideAnimation.value.clamp(0, 2)
          : Tween<double>(
                  begin: 10 + iconButtonSize + iconPadding.vertical / 2,
                  end: 10 + iconButtonSize * 2 + iconPadding.vertical)
              .evaluate(_secondRowSlideAnimation),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: context.radiusMedium,
            border: Border.all(
              color: context.realDark ? color : Colors.transparent,
              width: 1,
            ),
            boxShadow:
                context.boxShadowMedium(color: context.realDark ? color : null),
          ),
          clipBehavior: Clip.hardEdge,
          margin: EdgeInsets.only(
            left: 8,
            right: 8,
          ),
          padding: EdgeInsets.only(
            left: 8,
            top: 5,
            right: 8,
            bottom: 5,
          ),
          height: Tween<double>(
                  begin: 10 + iconButtonSize * 2 + iconPadding.vertical,
                  end: 10 + iconButtonSize * 3 + iconPadding.vertical * 3 / 2)
              .evaluate(_secondRowSlideAnimation),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.expanded)
                SizedBox(
                  height: 40,
                  child: _SelectionOptions(
                    color: color,
                    activeColor: activeColor,
                  ),
                ),
              SizedBox(
                height: Tween<double>(
                        begin: 0,
                        end: iconButtonSize + iconPadding.vertical / 2)
                    .evaluate(_secondRowSlideAnimation),
                child: _secondRowAppearAnimation.value != 0
                    ? FadeTransition(
                        opacity: _secondRowAppearAnimation,
                        child: _PlaylistList(
                          selectionController: selectionController,
                          color: color,
                        ),
                      )
                    : Center(),
              ),
              SizedBox(
                height: 40,
                child: _MultiselectActionBar(
                  onSwitchSecondRow: (value) {
                    secondRow = value;
                  },
                  selectionController: selectionController,
                  color: color,
                  activeColor: activeColor,
                  expanded: widget.expanded,
                  iconButtonSize: iconButtonSize,
                  iconPadding: iconPadding,
                  iconRadius: iconRadius,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar with options to extend batch selection
class _SelectionOptions extends StatelessWidget {
  final Color color;
  final Color activeColor;
  _SelectionOptions({
    required this.color,
    required this.activeColor,
  });
  @override
  Widget build(BuildContext context) {
    SelectionController selectionController =
        Provider.of<SelectionController>(context, listen: false);
    ExpansionController expansionController =
        ExpansionController(maxWidth: () => context.width);
    expansionController.addWidth(
        128 + 16 + 16 + context.actionBarIconPadding.horizontal * 3 / 2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          alignment: AlignmentDirectional.centerStart,
          height: 40,
          width: 128,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.actionBarIconPadding.horizontal / 2),
            child: Text(
              context.s.selected(
                  "${Provider.of<SelectionController>(context).selectedEpisodes.length}" +
                      (selectionController.selectionTentative ? "+" : "")),
              style: context.textTheme.titleLarge!.copyWith(color: color),
            ),
          ),
        ),
        Spacer(),
        ActionBarButton(
          child: Center(
            child: Text(
              context.s.before,
              style: context.textTheme.titleMedium,
            ),
          ),
          expansionController: expansionController,
          shrunkChild: Center(
            child: Icon(
              Icons.first_page,
              color: context.actionBarIconColor,
            ),
          ),
          buttonType: ActionBarButtonType.onOff,
          onPressed: (value) {
            selectionController.selectBefore = value!;
          },
          width: 80,
          shrunkWidth: context.actionBarSizeHorizontal,
          color: color,
          activeColor: activeColor,
          tooltip: context.s.before,
          enabled: selectionController.explicitlySelectedCount >= 1,
          connectRight: true,
        ),
        ActionBarButton(
          child: Center(
            child: Text(
              context.s.between,
              style: context.textTheme.titleMedium,
            ),
          ),
          expansionController: expansionController,
          shrunkChild: Center(
            child: Icon(
              Icons.more_horiz,
              color: context.actionBarIconColor,
            ),
          ),
          buttonType: ActionBarButtonType.onOff,
          onPressed: (value) {
            selectionController.selectBetween = value!;
          },
          width: 80,
          shrunkWidth: context.actionBarSizeHorizontal,
          color: color,
          activeColor: activeColor,
          tooltip: context.s.between,
          enabled: selectionController.explicitlySelectedCount >= 2,
          connectLeft: true,
          connectRight: true,
        ),
        ActionBarButton(
          child: Center(
            child: Text(
              context.s.after,
              style: context.textTheme.titleMedium,
            ),
          ),
          expansionController: expansionController,
          shrunkChild: Center(
            child: Icon(
              Icons.last_page,
              color: context.actionBarIconColor,
            ),
          ),
          buttonType: ActionBarButtonType.onOff,
          onPressed: (value) {
            selectionController.selectAfter = value!;
          },
          width: 80,
          shrunkWidth: context.actionBarSizeHorizontal,
          color: color,
          activeColor: activeColor,
          tooltip: context.s.after,
          enabled: selectionController.explicitlySelectedCount >= 1,
          connectLeft: true,
          connectRight: true,
        ),
        ActionBarButton(
          child: Center(
            child: Text(
              context.s.all,
              style: context.textTheme.titleMedium,
            ),
          ),
          expansionController: expansionController,
          shrunkChild: Center(
            child: Icon(
              Icons.select_all,
              color: context.actionBarIconColor,
            ),
          ),
          buttonType: ActionBarButtonType.onOff,
          onPressed: (value) {
            selectionController.selectAll = value!;
          },
          width: 80,
          shrunkWidth: context.actionBarSizeHorizontal,
          color: color,
          activeColor: activeColor,
          tooltip: context.s.all,
          connectLeft: true,
        ),
      ],
    );
  }
}

class _NewPlaylist extends StatefulWidget {
  final List<EpisodeBrief> episodes;
  final Color? color;
  _NewPlaylist(this.episodes, {this.color, Key? key}) : super(key: key);

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
                setState(() => _error = 1);
              } else {
                final episodesList =
                    widget.episodes.map((e) => e.enclosureUrl).toList();
                final playlist = Playlist(_playlistName,
                    episodeUrlList: episodesList, episodes: widget.episodes);
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
  final SelectionController selectionController;
  final Color color;

  const _PlaylistList({
    required this.selectionController,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Selector<AudioPlayerNotifier, List<Playlist>>(
        selector: (_, audio) => audio.playlists,
        builder: (_, data, child) {
          return Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (var p in data)
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
                              pageBuilder:
                                  (context, animaiton, secondaryAnimation) =>
                                      _NewPlaylist(
                                          selectionController.selectedEpisodes,
                                          color: color));
                        },
                      )
                    else
                      _buttonOnMenu(
                        child: Row(
                          children: [
                            Container(
                              height: 30,
                              width: 30,
                              color: color.toHighlightBackround(context),
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
                          await selectionController.getEpisodesLimitless();
                          await context
                              .read<AudioPlayerNotifier>()
                              .addToPlaylist(
                                  selectionController.selectedEpisodes,
                                  playlist: p);
                        },
                      )
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
  final ValueChanged onSwitchSecondRow;
  final SelectionController selectionController;
  final Color color;
  final Color activeColor;
  final bool expanded;
  final double iconButtonSize;
  final EdgeInsets iconPadding;
  final Radius iconRadius;

  const _MultiselectActionBar({
    required this.onSwitchSecondRow,
    required this.selectionController,
    required this.color,
    required this.activeColor,
    required this.expanded,
    required this.iconButtonSize,
    required this.iconPadding,
    required this.iconRadius,
  });
  @override
  _MultiselectActionBarState createState() => _MultiselectActionBarState();
}

class _MultiselectActionBarState extends State<_MultiselectActionBar> {
  bool? liked;
  bool? played;
  bool? downloaded;
  bool? inPlaylist;

  late int selectedEpisodesLength =
      widget.selectionController.selectedEpisodes.length;

  late bool episodesUpdated = widget.selectionController.episodesUpdated;

  List<EpisodeBrief> get selectedEpisodes =>
      widget.selectionController.selectedEpisodes;

  SelectionController get selectionController => widget.selectionController;

  @override
  void initState() {
    super.initState();
    _initProperties();
    selectionController.addListener(() {
      if (mounted) {
        setState(() {
          if (selectedEpisodesLength !=
              selectionController.selectedEpisodes.length) {
            selectedEpisodesLength =
                selectionController.selectedEpisodes.length;
            _initProperties();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MultiselectActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (episodesUpdated != widget.selectionController.episodesUpdated) {
      episodesUpdated = widget.selectionController.episodesUpdated;
      _initProperties();
    }
  }

  void _initProperties() {
    if (widget.selectionController.selectionTentative) {
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
    return Row(
      children: [
        _likeButton(context),
        _playedButton(context),
        _downloadButton(context),
        // Spacer(),
        _playlistButton(context),
        _morePlaylistButton(context),
        Spacer(),
        if (!widget.expanded)
          SizedBox(
            height: 40,
            child: Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                      context.s.selected("${selectedEpisodes.length}" +
                          (selectionController.selectionTentative ? "+" : "")),
                      style: context.textTheme.titleLarge!
                          .copyWith(color: widget.color))),
            ),
          ),
        _closeButton(),
      ],
    );
  }

  Widget _button({
    required Widget child,
    Widget? falseChild,
    Widget? partialChild,
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
    return ActionBarButton(
      child: child,
      falseChild: falseChild,
      partialChild: partialChild,
      state: state,
      buttonType: buttonType ?? ActionBarButtonType.single,
      onPressed: onPressed,
      width: width ?? widget.iconButtonSize,
      height: height ?? widget.iconButtonSize,
      innerPadding: innerPadding,
      color: widget.color,
      activeColor: widget.activeColor,
      tooltip: tooltip,
      enabled: enabled,
      animation: animation,
      connectLeft: connectLeft,
      connectRight: connectRight,
    );
  }

  Widget _likeButton(BuildContext context) => _button(
        child: Icon(Icons.favorite, color: Colors.red),
        falseChild:
            Icon(Icons.favorite_border, color: context.actionBarIconColor),
        state: liked,
        buttonType: ActionBarButtonType.partialOnOff,
        onPressed: (value) async {
          if (selectedEpisodes.isNotEmpty) {
            EpisodeState episodeState =
                Provider.of<EpisodeState>(context, listen: false);
            await selectionController.getEpisodesLimitless();
            liked = value;
            if (value!) {
              await episodeState.setLiked(selectedEpisodes);
              Fluttertoast.showToast(
                msg: context.s.liked,
                gravity: ToastGravity.BOTTOM,
              );
              OverlayEntry _overlayEntry;
              _overlayEntry = createOverlayEntry(context);
              Overlay.of(context)!.insert(_overlayEntry);
              await Future.delayed(Duration(seconds: 2));
              _overlayEntry.remove();
            } else {
              await episodeState.unsetLiked(selectedEpisodes);
              Fluttertoast.showToast(
                msg: context.s.unlike,
                gravity: ToastGravity.BOTTOM,
              );
            }
          }
        },
        connectRight: true,
      );

  Widget _playedButton(BuildContext context) => _button(
        child: CustomPaint(
          size: Size(25, 25),
          painter: ListenedAllPainter(widget.color, stroke: 2.0),
        ),
        falseChild: CustomPaint(
          size: Size(25, 25),
          painter: MarkListenedPainter(context.actionBarIconColor, stroke: 2.0),
        ),
        state: played,
        buttonType: ActionBarButtonType.partialOnOff,
        onPressed: (value) async {
          if (selectedEpisodes.isNotEmpty) {
            EpisodeState episodeState =
                Provider.of<EpisodeState>(context, listen: false);
            await selectionController.getEpisodesLimitless();
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
        connectLeft: true,
        connectRight: true,
      );
  Widget _downloadButton(BuildContext context) => _button(
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CustomPaint(
              painter: DownloadPainter(
                  color: widget.color,
                  fraction: 1,
                  progressColor: context.accentColor,
                  progress: 1),
            ),
          ),
        ),
        falseChild: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CustomPaint(
              painter: DownloadPainter(
                color: context.actionBarIconColor,
                fraction: 0,
                progressColor: widget.color,
              ),
            ),
          ),
        ),
        state: downloaded,
        buttonType: ActionBarButtonType.partialOnOff,
        onPressed: (value) async {
          if (selectedEpisodes.isNotEmpty) {
            await selectionController.getEpisodesLimitless();
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
                futures.add(Provider.of<DownloadState>(context, listen: false)
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
        connectLeft: true,
        connectRight: false,
      );

  Widget _playlistButton(BuildContext context) {
    var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return _button(
      child: Icon(Icons.playlist_add_check, color: widget.color),
      falseChild: Icon(
        Icons.playlist_add,
        color: context.actionBarIconColor,
      ),
      state: inPlaylist,
      buttonType: ActionBarButtonType.partialOnOff,
      onPressed: (value) async {
        if (selectedEpisodes.isNotEmpty) {
          await selectionController.getEpisodesLimitless();
          inPlaylist = value;
          if (value!) {
            await audio.addToPlaylist(selectedEpisodes);
            await Fluttertoast.showToast(
              msg: context.s.toastAddPlaylist,
              gravity: ToastGravity.BOTTOM,
            );
          } else {
            await audio.removeFromPlaylist(selectedEpisodes);
            await Fluttertoast.showToast(
              msg: context.s.toastRemovePlaylist,
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
      },
      connectLeft: false,
      connectRight: true,
    );
  }

  Widget _morePlaylistButton(BuildContext context) => _button(
        child: Icon(
          Icons.add_box_outlined,
          color: context.actionBarIconColor,
        ),
        buttonType: ActionBarButtonType.onOff,
        onPressed: (value) {
          widget.onSwitchSecondRow(value);
        },
        connectLeft: true,
      );
  Widget _closeButton() => _button(
      child: Icon(Icons.close),
      onPressed: (value) {
        selectionController.selectMode = false;
      });
}
