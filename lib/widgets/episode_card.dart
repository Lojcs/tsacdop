import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/state/episode_state.dart';
import 'package:tsacdop/type/episodebrief.dart';
import 'package:tsacdop/util/extension_helper.dart';
import 'package:tuple/tuple.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../state/audio_state.dart';
import '../type/play_histroy.dart';
import '../type/podcastlocal.dart';
import '../util/helpers.dart';
import '../util/pageroute.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';

/// [EpisodeCard] widget that responds to user interaction.
class InteractiveEpisodeCard extends StatefulWidget {
  final BuildContext context;
  final EpisodeBrief episode;

  /// General card layout
  final EpisodeGridLayout layout;

  /// Opens the podcast details if avatar image is tapped
  final bool openPodcast;

  /// Controls the avatar image
  final bool showImage;

  /// Prefer episode image over podcast image for avatar (requires [showimage])
  final bool preferEpisodeImage;

  /// Episode number to be shown. Null for off
  final bool showNumber;

  /// Controls the favourite indicator
  final bool showLiked;

  /// Controls the new indicator
  final bool showNew;

  /// Controls the length and size idnicators
  final bool showLengthAndSize;

  /// Controls the played and downloaded indicators (requires [showLengthAndSize])
  final bool showPlayedAndDownloaded;

  /// Controls the date indicator
  final bool showDate;

  /// Sets the primary action to highlight instead of open
  final bool selectMode;

  /// Callback to call when [selectMode] is on and the card is selected
  final VoidCallback? onSelect;

  /// Wheter the episode is selected
  final bool selected;
  InteractiveEpisodeCard(this.context, this.episode, this.layout,
      {this.openPodcast = true,
      this.showImage = true,
      this.preferEpisodeImage = false,
      this.showNumber = false,
      this.showLiked = true,
      this.showNew = true,
      this.showLengthAndSize = true,
      this.showPlayedAndDownloaded = true,
      this.showDate = false,
      this.selectMode = false,
      this.onSelect,
      this.selected = false})
      : assert((!preferEpisodeImage &&
                episode.fields.contains(EpisodeField.podcastImage)) ||
            episode.fields.contains(EpisodeField.episodeImage) ||
            episode.fields.contains(EpisodeField.podcastImage)),
        assert(!showNumber || episode.fields.contains(EpisodeField.number)),
        assert(!showLiked || episode.fields.contains(EpisodeField.isLiked)),
        assert(!showNew || episode.fields.contains(EpisodeField.isNew)),
        assert(!showLengthAndSize ||
            (episode.fields.contains(EpisodeField.enclosureDuration) &&
                episode.fields.contains(EpisodeField.enclosureSize))),
        assert(!showPlayedAndDownloaded ||
            !showLengthAndSize ||
            (episode.fields.contains(EpisodeField.isPlayed) &&
                episode.fields.contains(EpisodeField.isDownloaded))),
        assert(episode.fields.contains(EpisodeField.primaryColor)),
        super(key: Key(episode.id.toString()));

  @override
  _InteractiveEpisodeCardState createState() => _InteractiveEpisodeCardState();
}

class _InteractiveEpisodeCardState extends State<InteractiveEpisodeCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shadowController;
  bool selected = false;
  // Wheter the card has been selected internally
  bool liveSelect = false;
  late EpisodeBrief episode;
  PlayHistory? savedPosition;

  bool _initialBuild = true;
  late bool? episodeChange;
  late Widget _body = _getBody();
  @override
  void initState() {
    super.initState();
    episode = widget.episode;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _shadowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _controller.dispose();
    _shadowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveEpisodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Apply external selection
    if (widget.selected != selected && !liveSelect && widget.selectMode) {
      selected = widget.selected;
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    if (widget.layout != oldWidget.layout) {
      _body = _getBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialBuild) {
      _initialBuild = false;
      episodeChange =
          Provider.of<EpisodeState>(context).episodeChangeMap[episode.id];
    }
    // Unselect on selectMode exit
    if (!widget.selectMode && selected) {
      setState(() {
        selected = false;
        _controller.reverse();
      });
    }
    liveSelect = false;
    return _body; // This is to avoid rebuild when selecting or enabling select mode.
  }

  Widget _getBody() {
    return Selector<EpisodeState, bool?>(
      selector: (_, episodeState) => episodeState.episodeChangeMap[episode.id],
      builder: (_, data, ___) => FutureBuilder<EpisodeBrief?>(
        future: () async {
          if (data != episodeChange) {
            // Prevents unnecessary database calls when the card is rebuilt for other reasons
            episodeChange = data;
            return widget.episode
                .copyWithFromDB(update: true); // It needs to be widget.episode
          } else {
            return null;
          }
        }(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            episode = snapshot.data!;
          }
          return OpenContainerWrapper(
            layout: widget.layout,
            avatarSize: widget.layout == EpisodeGridLayout.small
                ? context.width / 20
                : widget.layout == EpisodeGridLayout.medium
                    ? context.width / 15
                    : context.width / 6,
            episode: episode,
            preferEpisodeImage: widget.preferEpisodeImage,
            onClosed: (() {
              _shadowController.reverse();
            }),
            closedBuilder: (context, action, boo) =>
                FutureBuilder<Tuple2<bool, List<int>>>(
              future: _initData(episode),
              initialData: Tuple2(false, []),
              builder: (context, snapshot) {
                final tapToOpen = snapshot.data!.item1;
                final menuList = snapshot.data!.item2;
                return Selector<AudioPlayerNotifier, Tuple3<bool, bool, bool>>(
                  selector: (_, audio) => Tuple3(audio.episode == episode,
                      audio.playlist.contains(episode), audio.playerRunning),
                  builder: (_, data, __) {
                    if (data.item1) savedPosition = null;
                    List<FocusedMenuItem> menuItemList = _menuItemList(context,
                        episode, data.item1, data.item2, data.item3, menuList);
                    return _FocusedMenuHolderWrapper(
                      child: EpisodeCard(context, episode, widget.layout,
                          openPodcast: widget.openPodcast,
                          showImage: widget.showImage && !boo,
                          preferEpisodeImage: widget.preferEpisodeImage,
                          showNumber: widget.showNumber,
                          showLiked: widget.showLiked,
                          showNew: widget.showNew,
                          showLengthAndSize: widget.showLengthAndSize,
                          showPlayedAndDownloaded:
                              widget.showPlayedAndDownloaded,
                          showDate: widget.showDate,
                          decorate: false),
                      onPressed: () async {
                        if (widget.selectMode) {
                          widget.onSelect!();
                          if (mounted) {
                            setState(() {
                              if (selected) {
                                _controller.reverse();
                              } else {
                                _controller.forward();
                              }
                              selected = !selected;
                              liveSelect = true;
                            });
                          }
                        } else {
                          _shadowController.forward();
                          action();
                        }
                      },
                      episode: episode,
                      layout: widget.layout,
                      tapToOpen: tapToOpen,
                      menuItemList: menuItemList,
                      menuItemExtent: widget.layout == EpisodeGridLayout.small
                          ? 41.5
                          : widget.layout == EpisodeGridLayout.medium
                              ? 42.5
                              : 100 / menuItemList.length,
                      menuBoxDecoration: BoxDecoration(
                        color: context.accentBackground,
                        border: Border.all(
                          color: context.accentColor,
                          width: 1.0,
                        ),
                        borderRadius: widget.layout == EpisodeGridLayout.small
                            ? context.radiusSmall
                            : widget.layout == EpisodeGridLayout.medium
                                ? context.radiusMedium
                                : context.radiusLarge,
                      ),
                      childLowerlay: data.item1
                          ? Selector<AudioPlayerNotifier, double>(
                              selector: (_, audio) => audio.seekSliderValue,
                              builder: (_, seekValue, __) => _ProgressLowerlay(
                                episode,
                                seekValue,
                                widget.layout,
                                animator: _controller,
                              ),
                            )
                          : FutureBuilder<PlayHistory>(
                              future: _getSavedPosition(),
                              // initialData: PlayHistory("", "", 0, 0),
                              builder: (context, snapshot) => _ProgressLowerlay(
                                episode,
                                snapshot.hasData
                                    ? snapshot.data!.seekValue!
                                    : 0,
                                widget.layout,
                                animator: _controller,
                              ),
                            ),
                      controller: _controller,
                      shadowController: _shadowController,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<PlayHistory> _getSavedPosition() async {
    if (savedPosition == null) {
      DBHelper dbHelper = DBHelper();
      savedPosition = await dbHelper.getPosition(widget.episode);
    }
    return savedPosition!;
  }
}

class _FocusedMenuHolderWrapper extends StatefulWidget {
  final Widget child;
  final Function onPressed;
  final EpisodeBrief episode;
  final EpisodeGridLayout layout;

  final bool tapToOpen;
  final List<FocusedMenuItem> menuItemList;
  final double? menuItemExtent;
  final BoxDecoration? menuBoxDecoration;
  final Widget? childLowerlay;

  final AnimationController controller;
  final AnimationController shadowController;
  const _FocusedMenuHolderWrapper(
      {required this.child,
      required this.onPressed,
      required this.episode,
      required this.layout,
      required this.tapToOpen,
      required this.menuItemList,
      required this.menuItemExtent,
      required this.menuBoxDecoration,
      required this.childLowerlay,
      required this.controller,
      required this.shadowController});
  @override
  _FocusedMenuHolderWrapperState createState() =>
      _FocusedMenuHolderWrapperState();
}

class _FocusedMenuHolderWrapperState extends State<_FocusedMenuHolderWrapper> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    widget.shadowController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusedMenuHolder(
      blurSize: 0,
      menuItemExtent: widget.menuItemExtent,
      enableMenuScroll: false,
      menuBoxDecoration: widget.menuBoxDecoration,
      childDecoration: _cardDecoration(context, widget.episode, widget.layout,
          controller: widget.controller,
          shadowController: widget.shadowController),
      openChildDecoration: _cardDecoration(
        context,
        widget.episode,
        widget.layout,
        selected: true,
      ),
      childLowerlay: widget.childLowerlay,
      duration: const Duration(milliseconds: 100),
      openWithTap: widget.tapToOpen,
      animateMenuItems: false,
      blurBackgroundColor: context.surface,
      bottomOffsetHeight: 10,
      menuOffset: 10,
      menuItems: widget.menuItemList,
      onPressed: widget.onPressed,
      child: widget.child,
    );
  }
}

/// Widget to display information about an episode.
class EpisodeCard extends StatelessWidget {
  final BuildContext context;
  final EpisodeBrief episode;

  /// General card layout
  final EpisodeGridLayout layout;

  /// Opens the podcast details if avatar image is tapped
  final bool openPodcast;

  /// Controls the avatar image
  final bool showImage;

  /// Prefer episode image over podcast image for avatar (requires [showimage])
  final bool preferEpisodeImage;

  /// Episode number to be shown. Null for off
  final bool showNumber;

  /// Controls the favourite indicator
  final bool showLiked;

  /// Controls the new indicator
  final bool showNew;

  /// Controls the length and size idnicators
  final bool showLengthAndSize;

  /// Controls the played and downloaded indicators (requires [showLengthAndSize])
  final bool showPlayedAndDownloaded;

  /// Controls the date indicator
  final bool showDate;

  /// Controls the select indicator
  final bool selected;

  /// Applies card decorations
  final bool decorate;
  EpisodeCard(this.context, this.episode, this.layout,
      {this.openPodcast = false,
      this.showImage = true,
      this.preferEpisodeImage = false,
      this.showNumber = false,
      this.showLiked = true,
      this.showNew = true,
      this.showLengthAndSize = true,
      this.showPlayedAndDownloaded = true,
      this.showDate = false,
      this.selected = false,
      this.decorate = true})
      : assert((!preferEpisodeImage &&
                episode.fields.contains(EpisodeField.podcastImage)) ||
            episode.fields.contains(EpisodeField.episodeImage) ||
            episode.fields.contains(EpisodeField.podcastImage)),
        assert(!showNumber || episode.fields.contains(EpisodeField.number)),
        assert(!showLiked || episode.fields.contains(EpisodeField.isLiked)),
        assert(!showNew || episode.fields.contains(EpisodeField.isNew)),
        assert(!showLengthAndSize ||
            (episode.fields.contains(EpisodeField.enclosureDuration) &&
                episode.fields.contains(EpisodeField.enclosureSize))),
        assert(!showPlayedAndDownloaded ||
            !showLengthAndSize ||
            (episode.fields.contains(EpisodeField.isPlayed) &&
                episode.fields.contains(EpisodeField.isDownloaded))),
        assert(episode.fields.contains(EpisodeField.primaryColor));

  @override
  Widget build(BuildContext context) {
    final DBHelper dbHelper = DBHelper();
    return Container(
      decoration: BoxDecoration(
          borderRadius: _cardDecoration(context, episode, layout).borderRadius),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          decorate
              ? Container(
                  decoration: _cardDecoration(context, episode, layout,
                      selected: selected))
              : Center(),
          decorate
              ? FutureBuilder<PlayHistory>(
                  future: dbHelper.getPosition(episode),
                  builder: (context, snapshot) => _ProgressLowerlay(episode,
                      snapshot.hasData ? snapshot.data!.seekValue! : 0, layout,
                      hide: selected))
              : Center(),
          Padding(
            padding: EdgeInsets.all(layout == EpisodeGridLayout.small ? 6 : 8)
                .copyWith(bottom: layout == EpisodeGridLayout.small ? 8 : 8),
            child: Column(
              children: <Widget>[
                if (layout != EpisodeGridLayout.large)
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: <Widget>[
                        showImage
                            ? _circleImage(
                                context,
                                openPodcast,
                                preferEpisodeImage,
                                radius: layout == EpisodeGridLayout.small
                                    ? context.width / 20
                                    : context.width / 15,
                                episode: episode,
                                color: episode.colorScheme(context).primary,
                              )
                            : SizedBox(
                                width: layout == EpisodeGridLayout.small
                                    ? context.width / 20
                                    : context.width / 15,
                              ),
                        SizedBox(
                          width: 5,
                        ),
                        if (showNumber)
                          _numberIndicator(
                              context, episode.number!.toString(), layout),
                        Spacer(),
                        _pubDate(context, episode, layout, showNew),
                      ],
                    ),
                  ),
                Expanded(
                  flex: layout == EpisodeGridLayout.small ? 10 : 7,
                  child: layout == EpisodeGridLayout.large
                      ? Row(
                          children: [
                            _circleImage(
                              context,
                              openPodcast,
                              preferEpisodeImage,
                              radius: context.width / 6,
                              episode: episode,
                              color: episode.colorScheme(context).primary,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: <Widget>[
                                        if (showNumber)
                                          _numberIndicator(
                                              context,
                                              episode.number!.toString(),
                                              layout),
                                        if (showNumber)
                                          Text("|",
                                              style: GoogleFonts.teko(
                                                  textStyle: context
                                                      .textTheme.bodyLarge)),
                                        _podcastTitle(episode, context, layout),
                                        Spacer(),
                                        _pubDate(
                                            context, episode, layout, showNew),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                      flex: 5,
                                      child: _title(episode, context, layout)),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: <Widget>[
                                        if (showLiked)
                                          _isLikedIndicator(
                                              episode, context, layout),
                                        Spacer(),
                                        if (showLengthAndSize)
                                          _lengthAndSize(
                                              context, layout, episode,
                                              showPlayedAndDownloaded:
                                                  showPlayedAndDownloaded)
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                      : _title(episode, context, layout),
                ),
                if (layout != EpisodeGridLayout.large)
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: <Widget>[
                        if (showLiked)
                          _isLikedIndicator(episode, context, layout),
                        Spacer(),
                        if (showLengthAndSize)
                          _lengthAndSize(context, layout, episode,
                              showPlayedAndDownloaded: showPlayedAndDownloaded),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLowerlay extends StatelessWidget {
  final EpisodeBrief episode;
  final double seekValue;
  final EpisodeGridLayout layout;
  final bool hide;
  final AnimationController? animator;
  _ProgressLowerlay(this.episode, this.seekValue, this.layout,
      {this.hide = false, this.animator});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animator == null
          ? hide
              ? AlwaysStoppedAnimation(0)
              : const AlwaysStoppedAnimation(1)
          : ReverseAnimation(animator!),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(layout == EpisodeGridLayout.small
              ? 12
              : layout == EpisodeGridLayout.medium
                  ? 16
                  : 20),
        ),
        clipBehavior: Clip.hardEdge,
        height: double.infinity,
        child: LinearProgressIndicator(
            color: context.realDark
                ? context.surface
                : episode.progressIndicatorColor(context),
            backgroundColor: Colors.transparent,
            value: seekValue),
      ),
    );
  }
}

BoxDecoration _cardDecoration(
  BuildContext context,
  EpisodeBrief episode,
  EpisodeGridLayout layout, {
  bool selected = false,
  AnimationController? controller,
  AnimationController?
      shadowController, // Hide shadow during expanding transition
}) {
  Color shownShadowColor = controller == null
      ? episode.cardShadowColor(context)
      : ColorTween(
              begin: episode.cardShadowColor(context),
              end: Color.lerp(episode.cardColor(context), Colors.white, 0))
          .evaluate(controller)!;
  return BoxDecoration(
      color: controller == null
          ? selected
              ? episode.selectedCardColor(context)
              : episode.cardColor(context)
          : ColorTween(
                  begin: episode.cardColor(context),
                  end: episode.selectedCardColor(context))
              .evaluate(controller)!,
      borderRadius: BorderRadius.circular(layout == EpisodeGridLayout.small
          ? 12
          : layout == EpisodeGridLayout.medium
              ? 16
              : 20),
      border: Border.all(
        color: context.realDark
            ? controller == null
                ? selected
                    ? episode.realDarkBorderColorSelected
                    : episode.realDarkBorderColor
                : ColorTween(
                        begin: episode.realDarkBorderColor,
                        end: episode.realDarkBorderColorSelected)
                    .evaluate(controller)!
            : Colors.transparent,
        width: 1.0,
      ),
      boxShadow: [
        // Difference between the values with and without controller is intentional
        BoxShadow(
          color: shadowController == null
              ? shownShadowColor
              : ColorTween(begin: shownShadowColor, end: Colors.transparent)
                  .evaluate(shadowController)!,
          blurRadius: 5,
          spreadRadius: controller == null
              ? selected
                  ? -2
                  : -3
              : Tween<double>(
                      begin: context.brightness == Brightness.light ? -2 : 1,
                      end: -3)
                  .evaluate(controller),
          offset: Offset.fromDirection(0, 0),
        )
      ]);
}

List<FocusedMenuItem> _menuItemList(BuildContext context, EpisodeBrief episode,
    bool playing, bool inPlaylist, bool playerRunning, List<int> menuList) {
  var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
  var episodeState = Provider.of<EpisodeState>(context, listen: false);
  var s = context.s;
  return <FocusedMenuItem>[
    FocusedMenuItem(
        backgroundColor: Color.fromARGB(0, 5, 4, 4),
        highlightColor: context.brightness == Brightness.light
            ? null
            : context.colorScheme.primaryContainer,
        title: Text(
          !playing || !playerRunning ? s.play : s.playing,
        ),
        trailing: Icon(
          LineIcons.playCircle,
          color: context.accentColor,
        ),
        onPressed: () async {
          if (!playing || !playerRunning) {
            await audio.loadEpisodeToQueue(episode);
          }
        }),
    if (menuList.contains(1))
      FocusedMenuItem(
          backgroundColor: Colors.transparent,
          highlightColor: context.brightness == Brightness.light
              ? null
              : context.colorScheme.primaryContainer,
          title: inPlaylist ? Text(s.remove) : Text(s.later),
          trailing: Icon(
            LineIcons.clock,
            color: Colors.cyan,
          ),
          onPressed: () async {
            if (!inPlaylist) {
              await audio.addToPlaylist([episode]);
              await Fluttertoast.showToast(
                msg: s.toastAddPlaylist,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              await audio.removeFromPlaylist([episode]);
              await Fluttertoast.showToast(
                msg: s.toastRemovePlaylist,
                gravity: ToastGravity.BOTTOM,
              );
            }
          }),
    if (menuList.contains(2))
      FocusedMenuItem(
          backgroundColor: Colors.transparent,
          highlightColor: context.brightness == Brightness.light
              ? null
              : context.colorScheme.primaryContainer,
          title: episode.isLiked! ? Text(s.unlike) : Text(s.like),
          trailing: Icon(LineIcons.heart, color: Colors.red, size: 21),
          onPressed: () async {
            if (episode.isLiked!) {
              await episodeState.unsetLiked([episode]);
              Fluttertoast.showToast(
                msg: s.unlike,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              await episodeState.setLiked([episode]);
              Fluttertoast.showToast(
                msg: s.liked,
                gravity: ToastGravity.BOTTOM,
              );
            }
          }),
    if (menuList.contains(3))
      FocusedMenuItem(
          backgroundColor: Colors.transparent,
          highlightColor: context.brightness == Brightness.light
              ? null
              : context.colorScheme.primaryContainer,
          title: episode.isPlayed!
              ? Text(s.markNotListened,
                  style: TextStyle(color: context.textColor.withOpacity(0.5)))
              : Text(
                  s.markListened,
                  softWrap: true,
                ),
          trailing: SizedBox(
            width: 23,
            height: 23,
            child: CustomPaint(
                painter: ListenedAllPainter(Colors.blue, stroke: 1.5)),
          ),
          onPressed: () async {
            if (episode.isPlayed!) {
              episodeState.unsetListened([episode]);
              Fluttertoast.showToast(
                msg: s.markNotListened,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              episodeState.setListened([episode]);
              Fluttertoast.showToast(
                msg: s.markListened,
                gravity: ToastGravity.BOTTOM,
              );
            }
          }),
    if (menuList.contains(4))
      FocusedMenuItem(
          backgroundColor: Colors.transparent,
          highlightColor: context.brightness == Brightness.light
              ? null
              : context.colorScheme.primaryContainer,
          title: episode.isDownloaded!
              ? Text(s.downloaded,
                  style: TextStyle(color: context.textColor.withOpacity(0.5)))
              : Text(s.download),
          trailing: Icon(LineIcons.download, color: Colors.green),
          onPressed: () async {
            if (!episode.isDownloaded!) {
              await requestDownload([episode], context);
            }
          }),
    if (menuList.contains(5))
      FocusedMenuItem(
        backgroundColor: Colors.transparent,
        highlightColor: context.brightness == Brightness.light
            ? null
            : context.colorScheme.primaryContainer,
        title: Text(s.playNext),
        trailing: Icon(
          LineIcons.lightningBolt,
          color: Colors.amber,
        ),
        onPressed: () {
          audio.addToPlaylist([episode],
              index: audio.playlist.length > 0 ? 1 : 0);
          Fluttertoast.showToast(
            msg: s.playNextDes,
            gravity: ToastGravity.BOTTOM,
          );
        },
      ),
  ];
}

/// Episode title widget.
Widget _title(
        EpisodeBrief episode, BuildContext context, EpisodeGridLayout layout) =>
    Container(
      alignment: layout == EpisodeGridLayout.large
          ? Alignment.centerLeft
          : Alignment.topLeft,
      padding: EdgeInsets.only(top: layout == EpisodeGridLayout.large ? 0 : 2),
      child: Text(
        episode.title,
        style: (layout == EpisodeGridLayout.small
                ? context.textTheme.bodySmall
                : context.textTheme.bodyMedium)!
            .copyWith(height: 1.25),
        maxLines: layout == EpisodeGridLayout.small
            ? 4
            : layout == EpisodeGridLayout.medium
                ? 3
                : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

/// Episode title widget.
Widget _podcastTitle(
        EpisodeBrief episode, BuildContext context, EpisodeGridLayout layout) =>
    Container(
      alignment: layout == EpisodeGridLayout.large
          ? Alignment.centerLeft
          : Alignment.topLeft,
      padding: EdgeInsets.only(top: layout == EpisodeGridLayout.large ? 0 : 2),
      width: context.width / 2.25,
      child: Text(
        episode.podcastTitle,
        style: (layout == EpisodeGridLayout.small
                ? context.textTheme.bodySmall
                : layout == EpisodeGridLayout.medium
                    ? context.textTheme.bodyMedium
                    : context.textTheme.bodyLarge)!
            .copyWith(
                fontWeight: FontWeight.bold,
                color: episode.colorScheme(context).primary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

/// Circle avatar widget.
Widget _circleImage(
  BuildContext context,
  bool openPodcast,
  bool preferEpisodeImage, {
  required double radius,
  required EpisodeBrief episode,
  required Color color,
}) =>
    Container(
      height: radius,
      width: radius,
      child: Stack(
        children: [
          CircleAvatar(
              radius: radius,
              backgroundColor: color.withOpacity(0.5),
              backgroundImage: preferEpisodeImage
                  ? episode.episodeOrPodcastImageProvider
                  : episode.podcastImageProvider),
          if (openPodcast)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: () async {
                  DBHelper dbHelper = DBHelper();
                  PodcastLocal? podcast =
                      await dbHelper.getPodcastWithUrl(episode.enclosureUrl);
                  if (podcast != null) {
                    Navigator.push(
                      context,
                      SlideLeftRoute(
                        page: PodcastDetail(podcastLocal: podcast),
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );

// There's a gap between the two widgets if you look closely. I couldn't fix it
// https://stackoverflow.com/questions/68230022/how-to-remove-space-between-widgets-in-column-or-row-in-flutter
// ListView's initial animation is too distracting to use.
// Custom paint perhaps?
Widget _lengthAndSize(
        BuildContext context, EpisodeGridLayout layout, EpisodeBrief episode,
        {bool showPlayedAndDownloaded = false}) =>
    Row(
      children: [
        if (episode.enclosureDuration != 0)
          Stack(
            alignment: AlignmentDirectional.centerEnd,
            children: [
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(5),
                        right: episode.enclosureSize == 0
                            ? Radius.circular(5)
                            : Radius.zero),
                    border: Border.all(
                        color: context.realDark
                            ? Colors.transparent
                            : episode.colorScheme(context).onSecondaryContainer,
                        width: 1),
                    color: showPlayedAndDownloaded && episode.isPlayed!
                        ? context.realDark
                            ? episode.colorScheme(context).secondaryContainer
                            : episode.colorScheme(context).onSecondaryContainer
                        : Colors.transparent),
                alignment: Alignment.center,
                child: Text(
                  episode.enclosureDuration!.toTime,
                  style: (layout == EpisodeGridLayout.large
                          ? context.textTheme.labelMedium
                          : context.textTheme.labelSmall)!
                      .copyWith(
                          color: context.realDark
                              ? episode
                                  .colorScheme(context)
                                  .onSecondaryContainer
                              : showPlayedAndDownloaded && episode.isPlayed!
                                  ? episode
                                      .colorScheme(context)
                                      .secondaryContainer
                                  : episode
                                      .colorScheme(context)
                                      .onSecondaryContainer),
                ),
              ),
              Container(
                  width: 1,
                  height: (layout == EpisodeGridLayout.large
                          ? context.textTheme.bodyMedium
                          : context.textTheme.bodySmall)!
                      .fontSize,
                  color: context.realDark &&
                          (!showPlayedAndDownloaded ||
                              !episode.isDownloaded! && !episode.isPlayed!) &&
                          episode.enclosureSize != 0
                      ? episode.colorScheme(context).onSecondaryContainer
                      : Colors.transparent)
            ],
          ),
        if (episode.enclosureSize != 0)
          Stack(alignment: AlignmentDirectional.centerStart, children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(5),
                      left: episode.enclosureDuration == 0
                          ? Radius.circular(5)
                          : Radius.zero),
                  // border: episode.enclosureDuration == 0
                  //     ? Border.all(
                  //         color: episode
                  //             .getColorScheme(context)
                  //             .onSecondaryContainer,
                  //       )
                  //     : Border(
                  //         right: BorderSide(
                  //             color: episode
                  //                 .getColorScheme(context)
                  //                 .onSecondaryContainer),
                  //         top: BorderSide(
                  //             color: episode
                  //                 .getColorScheme(context)
                  //                 .onSecondaryContainer),
                  //         bottom: BorderSide(
                  //             color: episode
                  //                 .getColorScheme(context)
                  //                 .onSecondaryContainer),
                  // ),
                  // This doesn't work currently due to flutter barf https://github.com/flutter/flutter/issues/12583
                  // TODO: Find workaround (solid color overlay with stack doesn't work as background is transparent and might mismatch if the episode is half played)
                  border: Border.all(
                      color: context.realDark
                          ? Colors.transparent
                          : episode.colorScheme(context).onSecondaryContainer,
                      width: 1),
                  color: showPlayedAndDownloaded && episode.isDownloaded!
                      ? context.realDark
                          ? episode.colorScheme(context).secondaryContainer
                          : episode.colorScheme(context).onSecondaryContainer
                      : Colors.transparent),
              alignment: Alignment.center,
              child: Text(
                '${episode.enclosureSize! ~/ 1000000}MB',
                style: (layout == EpisodeGridLayout.large
                        ? context.textTheme.labelMedium
                        : context.textTheme.labelSmall)!
                    .copyWith(
                        color: context.realDark
                            ? episode.colorScheme(context).onSecondaryContainer
                            : showPlayedAndDownloaded && episode.isDownloaded!
                                ? episode
                                    .colorScheme(context)
                                    .secondaryContainer
                                : episode
                                    .colorScheme(context)
                                    .onSecondaryContainer),
              ),
            ),
            Container(
                width: 1,
                height: (layout == EpisodeGridLayout.large
                        ? context.textTheme.bodyMedium
                        : context.textTheme.bodySmall)!
                    .fontSize,
                color: context.realDark &&
                        (!showPlayedAndDownloaded ||
                            !episode.isDownloaded! && !episode.isPlayed!) &&
                        episode.enclosureDuration != 0
                    ? episode.colorScheme(context).onSecondaryContainer
                    : Colors.transparent)
          ]),
      ],
    );

Widget _downloadIndicator(
        BuildContext context, EpisodeGridLayout layout, bool showDownload,
        {bool? isDownloaded}) =>
    showDownload && layout != EpisodeGridLayout.small
        ? isDownloaded!
            ? Container(
                height: 20,
                width: 20,
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 5),
                padding: EdgeInsets.fromLTRB(2, 2, 2, 3),
                decoration: BoxDecoration(
                  color: context.accentColor,
                  shape: BoxShape.circle,
                ),
                child: CustomPaint(
                  size: Size(12, 12),
                  painter: DownloadPainter(
                    stroke: 1.0,
                    color: context.accentColor,
                    fraction: 1,
                    progressColor: Colors.white,
                    progress: 1,
                  ),
                ),
              )
            : Center()
        : Center();

/// New indicator widget.
Widget _isNewIndicator(
        EpisodeBrief episode, BuildContext context, EpisodeGridLayout layout) =>
    episode.isNew!
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('New',
                style: (layout == EpisodeGridLayout.large
                        ? context.textTheme.labelMedium
                        : context.textTheme.labelSmall)!
                    .copyWith(color: Colors.red, fontStyle: FontStyle.italic)),
          )
        : Center();

/// Liked indicator widget.
Widget _isLikedIndicator(
        EpisodeBrief episode, BuildContext context, EpisodeGridLayout layout) =>
    Container(
      alignment: Alignment.center,
      child: episode.isLiked!
          ? Icon(Icons.favorite,
              color: Colors.red,
              size: layout == EpisodeGridLayout.small
                  ? context.textTheme.bodySmall!.fontSize
                  : context.textTheme.bodyLarge!.fontSize)
          : Center(),
    );

/// Count indicator widget.
Widget _numberIndicator(
        BuildContext context, String numberText, EpisodeGridLayout layout) =>
    Text(
      numberText,
      style: GoogleFonts.teko(
          textStyle: layout == EpisodeGridLayout.small
              ? context.textTheme.bodySmall
              : layout == EpisodeGridLayout.medium
                  ? context.textTheme.bodyMedium
                  : context.textTheme.bodyLarge),
    );

/// Pubdate widget
Widget _pubDate(BuildContext context, EpisodeBrief episode,
        EpisodeGridLayout layout, bool showNew) =>
    Text(
      episode.pubDate.toDate(context),
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: (layout == EpisodeGridLayout.small
              ? context.textTheme.labelSmall
              : context.textTheme.labelMedium)!
          .copyWith(
              fontStyle: FontStyle.italic,
              color: episode.isNew!
                  ? Colors.red
                  : episode.colorScheme(context).onSecondaryContainer),
    );

Future<Tuple2<bool, List<int>>> _initData(EpisodeBrief episode) async {
  final menuList = await _getEpisodeMenu();
  final tapToOpen = await _getTapToOpenPopupMenu();
  return Tuple2(tapToOpen, menuList);
}

Future<List<int>> _getEpisodeMenu() async {
  final popupMenuStorage = KeyValueStorage(
      episodePopupMenuKey); // TODO: These should be obtainable from SettingState.
  final list = await popupMenuStorage.getMenu();
  return list;
}

Future<bool> _getTapToOpenPopupMenu() async {
  final tapToOpenPopupMenuStorage = KeyValueStorage(tapToOpenPopupMenuKey);
  final boo = await tapToOpenPopupMenuStorage.getBool(defaultValue: false);
  return boo;
}
