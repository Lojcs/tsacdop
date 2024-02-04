import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/episodes/episode_download.dart';
import 'package:tsacdop/state/download_state.dart';
import 'package:tsacdop/state/episode_state.dart';
import 'package:tsacdop/type/episodebrief.dart';
import 'package:tsacdop/util/extension_helper.dart';
import 'package:tuple/tuple.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../state/audio_state.dart';
import '../state/setting_state.dart';
import '../type/play_histroy.dart';
import '../util/helpers.dart';
import '../util/pageroute.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';
import 'general_dialog.dart';

/// [EpisodeCard] widget that responds to user interaction.
class InteractiveEpisodeCard extends StatefulWidget {
  final BuildContext context;
  final EpisodeBrief episode;

  /// General card layout
  final Layout layout;

  /// Opens the podcast details if avatar image is tapped
  final bool openPodcast;

  /// Controls the avatar image
  final bool showImage;

  /// Prefer episode image over podcast image for avatar (requires [showimage])
  final bool preferEpisodeImage;

  /// Episode number to be shown. Null for off
  final String? numberText;

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
      this.numberText,
      this.showLiked = true,
      this.showNew = true,
      this.showLengthAndSize = true,
      this.showPlayedAndDownloaded = true,
      this.showDate = false,
      this.selectMode = false,
      this.onSelect,
      this.selected = false}) {
    assert((!preferEpisodeImage &&
            episode.fields.contains(EpisodeField.podcastImage)) ||
        episode.fields.contains(EpisodeField.episodeImage) ||
        episode.fields.contains(EpisodeField.podcastImage));
    assert(!showLiked || episode.fields.contains(EpisodeField.isLiked));
    assert(!showNew || episode.fields.contains(EpisodeField.isNew));
    assert(!showLengthAndSize ||
        (episode.fields.contains(EpisodeField.enclosureDuration) &&
            episode.fields.contains(EpisodeField.enclosureSize)));
    assert(!showPlayedAndDownloaded ||
        !showLengthAndSize ||
        (episode.fields.contains(EpisodeField.isPlayed) &&
            episode.fields.contains(EpisodeField.isDownloaded)));
    assert(episode.fields.contains(EpisodeField.primaryColor));
  }
  @override
  _InteractiveEpisodeCardState createState() => _InteractiveEpisodeCardState();
}

class _InteractiveEpisodeCardState extends State<InteractiveEpisodeCard>
    with TickerProviderStateMixin {
  bool _firstBuild = true;
  late AnimationController _controller;
  late AnimationController _shadowController;
  bool selected = false;
  // Wheter the card has been selected internally
  bool liveSelect = false;
  late EpisodeBrief episode;
  @override
  void initState() {
    super.initState();
    episode = widget.episode;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _shadowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _shadowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    var episodeState = Provider.of<EpisodeState>(context, listen: false);
    var s = context.s;
    // Apply external selection
    if (widget.selected != selected && !liveSelect && widget.selectMode) {
      _firstBuild = false;
      selected = widget.selected;
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    // Unselect on selectMode exit
    if (!widget.selectMode && selected) {
      setState(() {
        selected = false;
        _controller.reverse();
      });
    }
    liveSelect = false;
    DBHelper dbHelper = DBHelper();

    return Selector2<AudioPlayerNotifier, EpisodeState,
            Tuple4<EpisodeBrief?, List<String>, bool?, bool>>(
        selector: (_, audio, episodeState) => Tuple4(
              audio.episode,
              audio.queue.episodes.map((e) => e!.enclosureUrl).toList(),
              episodeState.episodeChangeMap[episode.id],
              audio.playerRunning,
            ),
        builder: (_, data, __) => FutureBuilder<EpisodeBrief>(
            future: episode.copyWithFromDB(update: true),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                episode = snapshot.data!;
              }
              return OpenContainerWrapper(
                  layout: widget.layout,
                  avatarSize: widget.layout == Layout.small
                      ? context.width / 20
                      : widget.layout == Layout.medium
                          ? context.width / 15
                          : context.width / 6,
                  episode: episode,
                  preferEpisodeImage: widget.preferEpisodeImage,
                  onClosed: (() {
                    _shadowController.reverse();
                  }),
                  closedBuilder: (context, action, boo) => FutureBuilder<
                          Tuple2<bool, List<int>>>(
                      future: _initData(episode),
                      initialData: Tuple2(false, []),
                      builder: (context, snapshot) {
                        final tapToOpen = snapshot.data!.item1;
                        final menuList = snapshot.data!.item2;
                        int menuLength = 0;
                        for (int i = 0; i < 6; i++) {
                          if (menuList.contains(i)) menuLength++;
                        }
                        return FocusedMenuHolder(
                            blurSize: 0,
                            menuItemExtent: widget.layout == Layout.small
                                ? 41.5
                                : widget.layout == Layout.medium
                                    ? 42.5
                                    : 100 / menuLength,
                            enableMenuScroll: false,
                            menuBoxDecoration: BoxDecoration(
                              color: context.accentBackground,
                              border: Border.all(
                                color: context.accentColor,
                                width: 1.0,
                              ),
                              borderRadius: widget.layout == Layout.small
                                  ? context.radiusSmall
                                  : widget.layout == Layout.medium
                                      ? context.radiusMedium
                                      : context.radiusLarge,
                            ),
                            childDecoration: _cardDecoration(
                                context, episode, widget.layout,
                                selected: selected,
                                controller: _firstBuild ? null : _controller,
                                shadowController: _shadowController),
                            openChildDecoration: _cardDecoration(
                                context, episode, widget.layout,
                                selected: true,
                                shadowController: _shadowController),
                            childHighlightColor: context.brightness == Brightness.light
                                ? episode.colorSchemeDark.primary
                                : episode.colorSchemeLight
                                    .onSecondaryContainer, // TODO: Bug in flutter breaks the color. Need to update https://github.com/flutter/flutter/pull/110552
                            childLowerlay: audio.episode == episode
                                ? Selector<AudioPlayerNotifier, double>(
                                    selector: (_, audio) =>
                                        audio.seekSliderValue,
                                    builder: (_, seekValue, __) =>
                                        _progressLowerlay(
                                            context, seekValue, widget.layout,
                                            hide: selected),
                                  )
                                : FutureBuilder<PlayHistory>(
                                    future: dbHelper.getPosition(episode),
                                    builder: (context, snapshot) => _progressLowerlay(
                                        context, snapshot.hasData ? snapshot.data!.seekValue! : 0, widget.layout,
                                        hide: selected, animator: _controller)),
                            duration: Duration(milliseconds: 100),
                            openWithTap: tapToOpen,
                            animateMenuItems: false,
                            blurBackgroundColor: context.background,
                            bottomOffsetHeight: 10,
                            menuOffset: 10,
                            menuItems: <FocusedMenuItem>[
                              FocusedMenuItem(
                                  backgroundColor: Colors.transparent,
                                  highlightColor: context.brightness ==
                                          Brightness.light
                                      ? null
                                      : context.colorScheme.primaryContainer,
                                  title: Text(
                                    data.item1 != episode || !data.item4
                                        ? s.play
                                        : s.playing,
                                  ),
                                  trailing: Icon(
                                    LineIcons.playCircle,
                                    color: context.accentColor,
                                  ),
                                  onPressed: () {
                                    if (data.item1 != episode || !data.item4) {
                                      audio.episodeLoad(episode);
                                    }
                                  }),
                              if (menuList.contains(1))
                                FocusedMenuItem(
                                    backgroundColor: Colors.transparent,
                                    highlightColor: context.brightness ==
                                            Brightness.light
                                        ? null
                                        : context.colorScheme.primaryContainer,
                                    title: data.item2
                                            .contains(episode.enclosureUrl)
                                        ? Text(s.remove)
                                        : Text(s.later),
                                    trailing: Icon(
                                      LineIcons.clock,
                                      color: Colors.cyan,
                                    ),
                                    onPressed: () {
                                      if (!data.item2
                                          .contains(episode.enclosureUrl)) {
                                        audio.addToPlaylist(episode);
                                        Fluttertoast.showToast(
                                          msg: s.toastAddPlaylist,
                                          gravity: ToastGravity.BOTTOM,
                                        );
                                      } else {
                                        audio.delFromPlaylist(episode);
                                        Fluttertoast.showToast(
                                          msg: s.toastRemovePlaylist,
                                          gravity: ToastGravity.BOTTOM,
                                        );
                                      }
                                    }),
                              if (menuList.contains(2))
                                FocusedMenuItem(
                                    backgroundColor: Colors.transparent,
                                    highlightColor: context.brightness ==
                                            Brightness.light
                                        ? null
                                        : context.colorScheme.primaryContainer,
                                    title: episode.isLiked!
                                        ? Text(s.unlike)
                                        : Text(s.like),
                                    trailing: Icon(LineIcons.heart,
                                        color: Colors.red, size: 21),
                                    onPressed: () async {
                                      if (episode.isLiked!) {
                                        await episodeState.setUnliked(episode);
                                        Fluttertoast.showToast(
                                          msg: s.unlike,
                                          gravity: ToastGravity.BOTTOM,
                                        );
                                      } else {
                                        await episodeState.setLiked(episode);
                                        Fluttertoast.showToast(
                                          msg: s.liked,
                                          gravity: ToastGravity.BOTTOM,
                                        );
                                      }
                                    }),
                              if (menuList.contains(3))
                                FocusedMenuItem(
                                    backgroundColor: Colors.transparent,
                                    highlightColor: context.brightness ==
                                            Brightness.light
                                        ? null
                                        : context.colorScheme.primaryContainer,
                                    title: episode.isPlayed!
                                        ? Text(s.markNotListened,
                                            style: TextStyle(
                                                color: context.textColor
                                                    .withOpacity(0.5)))
                                        : Text(
                                            s.markListened,
                                            softWrap: true,
                                          ),
                                    trailing: SizedBox(
                                      width: 23,
                                      height: 23,
                                      child: CustomPaint(
                                          painter: ListenedAllPainter(
                                              Colors.blue,
                                              stroke: 1.5)),
                                    ),
                                    onPressed: () async {
                                      if (episode.isPlayed!) {
                                        episodeState.markNotListened(episode);
                                        Fluttertoast.showToast(
                                          msg: s.markNotListened,
                                          gravity: ToastGravity.BOTTOM,
                                        );
                                      } else {
                                        episodeState.markListened(episode);
                                        Fluttertoast.showToast(
                                          msg: s.markListened,
                                          gravity: ToastGravity.BOTTOM,
                                        );
                                      }
                                    }),
                              if (menuList.contains(4))
                                FocusedMenuItem(
                                    backgroundColor: Colors.transparent,
                                    highlightColor: context.brightness ==
                                            Brightness.light
                                        ? null
                                        : context.colorScheme.primaryContainer,
                                    title: episode.isDownloaded!
                                        ? Text(s.downloaded,
                                            style: TextStyle(
                                                color: context.textColor
                                                    .withOpacity(0.5)))
                                        : Text(s.download),
                                    trailing: Icon(LineIcons.download,
                                        color: Colors.green),
                                    onPressed: () async {
                                      if (!episode.isDownloaded!) {
                                        await requestDownload(
                                            [episode], context);
                                      }
                                    }),
                              if (menuList.contains(5))
                                FocusedMenuItem(
                                  backgroundColor: Colors.transparent,
                                  highlightColor: context.brightness ==
                                          Brightness.light
                                      ? null
                                      : context.colorScheme.primaryContainer,
                                  title: Text(s.playNext),
                                  trailing: Icon(
                                    LineIcons.lightningBolt,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () {
                                    audio.moveToTop(episode);
                                    Fluttertoast.showToast(
                                      msg: s.playNextDes,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  },
                                ),
                            ],
                            onPressed: widget.selectMode
                                ? () async {
                                    widget.onSelect!();
                                    // await Future.delayed(
                                    //     Duration(milliseconds: 100));
                                    // selected = !selected;
                                    // _controller.reset();
                                    // _controller.forward();
                                    if (mounted) {
                                      setState(() {
                                        if (selected)
                                          _controller.reverse();
                                        else
                                          _controller.forward();
                                        selected = !selected;
                                        liveSelect = true;
                                        if (_firstBuild) _firstBuild = false;
                                      });
                                    }
                                  }
                                : () async {
                                    _shadowController.forward();
                                    // await Future.delayed(
                                    //     Duration(milliseconds: 150));
                                    action();
                                  },
                            child: EpisodeCard(context, episode, widget.layout,
                                openPodcast: widget.openPodcast,
                                showImage: widget.showImage && !boo,
                                preferEpisodeImage: widget.preferEpisodeImage,
                                numberText: widget.numberText,
                                showLiked: widget.showLiked,
                                showNew: widget.showNew,
                                showLengthAndSize: widget.showLengthAndSize,
                                showPlayedAndDownloaded:
                                    widget.showPlayedAndDownloaded,
                                showDate: widget.showDate,
                                selected: selected,
                                decorate: false));
                      }));
            }));
  }
}

/// Widget to display information about an episode.
class EpisodeCard extends StatelessWidget {
  final BuildContext context;
  final EpisodeBrief episode;

  /// General card layout
  final Layout layout;

  /// Opens the podcast details if avatar image is tapped
  final bool openPodcast;

  /// Controls the avatar image
  final bool showImage;

  /// Prefer episode image over podcast image for avatar (requires [showimage])
  final bool preferEpisodeImage;

  /// Episode number to be shown. Null for off
  final String? numberText;

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
      this.numberText,
      this.showLiked = true,
      this.showNew = true,
      this.showLengthAndSize = true,
      this.showPlayedAndDownloaded = true,
      this.showDate = false,
      this.selected = false,
      this.decorate = true}) {
    assert((!preferEpisodeImage &&
            episode.fields.contains(EpisodeField.podcastImage)) ||
        episode.fields.contains(EpisodeField.episodeImage) ||
        episode.fields.contains(EpisodeField.podcastImage));
    assert(!showLiked || episode.fields.contains(EpisodeField.isLiked));
    assert(!showNew || episode.fields.contains(EpisodeField.isNew));
    assert(!showLengthAndSize ||
        (episode.fields.contains(EpisodeField.enclosureDuration) &&
            episode.fields.contains(EpisodeField.enclosureSize)));
    assert(!showPlayedAndDownloaded ||
        !showLengthAndSize ||
        (episode.fields.contains(EpisodeField.isPlayed) &&
            episode.fields.contains(EpisodeField.isDownloaded)));
    assert(episode.fields.contains(EpisodeField.primaryColor));
  }
  final DBHelper dbHelper = DBHelper();

  @override
  Widget build(BuildContext context) {
    if (false) {
      return _layoutOneCard(context, episode, layout, preferEpisodeImage,
          numberText: numberText ?? "",
          openPodcast: openPodcast,
          showDownload: showPlayedAndDownloaded,
          showFavorite: showLiked,
          showNumber: numberText != null,
          boo: showImage);
    } else {
      return Container(
        decoration: BoxDecoration(
            borderRadius:
                _cardDecoration(context, episode, layout).borderRadius),
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
                    builder: (context, snapshot) => _progressLowerlay(
                        context,
                        snapshot.hasData ? snapshot.data!.seekValue! : 0,
                        layout,
                        hide: selected))
                : Center(),
            Padding(
              padding: EdgeInsets.all(layout == Layout.small ? 6 : 8)
                  .copyWith(bottom: layout == Layout.small ? 8 : 8),
              child: Column(
                children: <Widget>[
                  if (layout != Layout.large)
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: <Widget>[
                          if (showImage)
                            _circleImage(
                              context,
                              openPodcast,
                              preferEpisodeImage,
                              radius: layout == Layout.small
                                  ? context.width / 20
                                  : context.width / 15,
                              episode: episode,
                              color: episode.getColorScheme(context).primary,
                            ),
                          SizedBox(
                            width: 5,
                          ),
                          if (numberText != null)
                            _numberIndicator(context, numberText!, layout),
                          Spacer(),
                          _pubDate(context, episode, layout, showNew),
                        ],
                      ),
                    ),
                  Expanded(
                    flex: layout == Layout.small ? 10 : 7,
                    child: layout == Layout.large
                        ? Row(
                            children: [
                              _circleImage(
                                context,
                                openPodcast,
                                preferEpisodeImage,
                                radius: context.width / 6,
                                episode: episode,
                                color: episode.getColorScheme(context).primary,
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
                                          if (numberText != null)
                                            _numberIndicator(
                                                context, numberText!, layout),
                                          if (numberText != null)
                                            Text("|",
                                                style: GoogleFonts.teko(
                                                    textStyle: context
                                                        .textTheme.bodyLarge)),
                                          _podcastTitle(
                                              episode, context, layout),
                                          Spacer(),
                                          _pubDate(context, episode, layout,
                                              showNew),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                        flex: 5,
                                        child:
                                            _title(episode, context, layout)),
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
                  if (layout != Layout.large)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          if (showLiked)
                            _isLikedIndicator(episode, context, layout),
                          Spacer(),
                          if (showLengthAndSize)
                            _lengthAndSize(context, layout, episode,
                                showPlayedAndDownloaded:
                                    showPlayedAndDownloaded),
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
}

Widget _progressLowerlay(BuildContext context, double seekValue, Layout layout,
    {bool hide = false, AnimationController? animator}) {
  return Opacity(
    opacity: animator == null
        ? hide
            ? 0
            : 1
        : 1 - animator.value,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout == Layout.small
            ? 12
            : layout == Layout.medium
                ? 16
                : 20),
      ),
      clipBehavior: Clip.hardEdge,
      height: double.infinity,
      child: LinearProgressIndicator(
          color: context.realDark
              ? context.background.withOpacity(0.7)
              : context.brightness == Brightness.light
                  ? context.background.withOpacity(0.7)
                  : context.background.withOpacity(0.6),
          backgroundColor: Colors.transparent,
          value: seekValue),
    ),
  );
}

BoxDecoration _cardDecoration(
    BuildContext context, EpisodeBrief episode, Layout layout,
    {bool selected = false,
    AnimationController? controller,
    AnimationController? shadowController}) {
  return BoxDecoration(
      color: context.realDark
          ? controller == null
              ? selected
                  ? Color.lerp(context.background,
                      episode.getColorScheme(context).primary, 0.25)
                  : context.background
              : selected
                  ? ColorTween(
                          begin: context.background,
                          end: Color.lerp(context.background,
                              episode.getColorScheme(context).primary, 0.25))
                      .animate(controller)
                      .value!
                  : context.background
          : controller == null
              ? selected
                  ? Color.lerp(
                      episode.getColorScheme(context).secondaryContainer,
                      episode.getColorScheme(context).primary,
                      0.15)
                  : episode.getColorScheme(context).secondaryContainer
              : selected
                  ? ColorTween(
                          begin: episode
                              .getColorScheme(context)
                              .secondaryContainer,
                          end: Color.lerp(
                              episode
                                  .getColorScheme(context)
                                  .secondaryContainer,
                              episode.getColorScheme(context).primary,
                              0.15))
                      .animate(controller)
                      .value!
                  : episode.getColorScheme(context).secondaryContainer,
      borderRadius: BorderRadius.circular(layout == Layout.small
          ? 12
          : layout == Layout.medium
              ? 16
              : 20),
      border: Border.all(
        color: context.realDark
            ? controller == null
                ? selected
                    ? Color.lerp(episode.getColorScheme(context).primary,
                        Colors.white, 0.5)!
                    : episode.getColorScheme(context).primary
                : ColorTween(
                        begin: episode.getColorScheme(context).primary,
                        end: Color.lerp(episode.getColorScheme(context).primary,
                            Colors.white, 0.5)!)
                    .animate(controller)
                    .value!
            : controller == null
                ? selected
                    ? episode.getColorScheme(context).primary
                    : Colors.transparent
                : ColorTween(
                        begin: Colors.transparent,
                        end: episode.getColorScheme(context).primary)
                    .animate(controller)
                    .value!,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowController == null
              ? episode.getColorScheme(context).primary
              : ColorTween(
                      begin: episode.getColorScheme(context).primary,
                      end: Colors.transparent)
                  .animate(shadowController)
                  .value!,
          blurRadius: controller == null
              ? selected
                  ? 8
                  : 5
              : Tween<double>(begin: 5, end: 8).animate(controller).value,
          spreadRadius: controller == null
              ? selected
                  ? 2
                  : -1
              : Tween<double>(begin: -1, end: 2).animate(controller).value,
          offset: Offset.fromDirection(0, 0),
        )
      ]);
}

Widget _layoutOneCard(BuildContext context, EpisodeBrief episode, Layout layout,
    bool preferEpisodeImage,
    {String? numberText,
    required bool openPodcast,
    required bool showFavorite,
    required bool showDownload,
    required bool showNumber,
    required bool boo}) {
  var width = context.width;
  return Container(
    decoration: BoxDecoration(
      color: episode.getColorScheme(context).secondaryContainer,
      borderRadius: BorderRadius.circular(15.0),
    ),
    clipBehavior: Clip.hardEdge,
    child: Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        if (episode.isPlayed!)
          Container(
            height: 4,
            color: context.accentColor,
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: _circleImage(context, openPodcast, preferEpisodeImage,
                      radius: context.width / 8,
                      episode: episode,
                      color: episode.getColorScheme(context).primary),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Text(episode.podcastTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: episode
                                        .getColorScheme(context)
                                        .primary)),
                          ),
                          _isNewIndicator(episode, context, layout),
                          _downloadIndicator(context, layout, showDownload,
                              isDownloaded: episode.isDownloaded),
                          _numberIndicator(context, numberText ?? "", layout)
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: _title(episode, context, layout))),
                    Expanded(
                      flex: 1,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            if (episode.enclosureDuration != 0)
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  episode.enclosureDuration!.toTime,
                                  style: TextStyle(fontSize: width / 35),
                                ),
                              ),
                            if (episode.enclosureDuration != 0 &&
                                episode.enclosureSize != null &&
                                episode.enclosureSize != 0 &&
                                layout != Layout.small)
                              Text(
                                '|',
                                style: TextStyle(
                                  fontSize: width / 35,
                                ),
                              ),
                            if (episode.enclosureSize != null &&
                                episode.enclosureSize != 0)
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '${episode.enclosureSize! ~/ 1000000}MB',
                                  style: TextStyle(fontSize: width / 35),
                                ),
                              ),
                            SizedBox(width: 4),
                            if (episode.isLiked!)
                              Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: width / 35,
                              ),
                            Spacer(),
                            _pubDate(context, episode, layout, false),
                          ]),
                    )
                  ],
                ),
              ),
              SizedBox(width: 8)
            ],
          ),
        ),
      ],
    ),
  );
}

/// Episode title widget.
Widget _title(EpisodeBrief episode, BuildContext context, Layout layout) =>
    Container(
      alignment:
          layout == Layout.large ? Alignment.centerLeft : Alignment.topLeft,
      padding: EdgeInsets.only(top: layout == Layout.large ? 0 : 2),
      child: Text(
        episode.title,
        style: (layout == Layout.small
                ? context.textTheme.bodySmall
                : layout == Layout.medium
                    ? context.textTheme.bodyMedium
                    : context.textTheme.bodyLarge)!
            .copyWith(height: 1.25),
        maxLines: layout == Layout.small
            ? 4
            : layout == Layout.medium
                ? 3
                : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

/// Episode title widget.
Widget _podcastTitle(
        EpisodeBrief episode, BuildContext context, Layout layout) =>
    Container(
      alignment:
          layout == Layout.large ? Alignment.centerLeft : Alignment.topLeft,
      padding: EdgeInsets.only(top: layout == Layout.large ? 0 : 2),
      width: context.width / 2.25,
      child: Text(
        episode.podcastTitle,
        style: (layout == Layout.small
                ? context.textTheme.bodySmall
                : layout == Layout.medium
                    ? context.textTheme.bodyMedium
                    : context.textTheme.bodyLarge)!
            .copyWith(
                fontWeight: FontWeight.bold,
                color: episode.getColorScheme(context).primary),
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
              backgroundImage: preferEpisodeImage && episode.episodeImage != ''
                  ? episode.episodeImageProvider
                  : episode.podcastImageProvider),
          if (openPodcast)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: () async {
                  DBHelper dbHelper = DBHelper();
                  Navigator.push(
                    context,
                    SlideLeftRoute(
                        page: PodcastDetail(
                      podcastLocal: await dbHelper
                          .getPodcastWithUrl(episode.enclosureUrl),
                    )),
                  );
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
Widget _lengthAndSize(BuildContext context, Layout layout, EpisodeBrief episode,
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
                            : episode
                                .getColorScheme(context)
                                .onSecondaryContainer,
                        width: 1),
                    color: showPlayedAndDownloaded && episode.isPlayed!
                        ? context.realDark
                            ? episode.getColorScheme(context).secondaryContainer
                            : episode
                                .getColorScheme(context)
                                .onSecondaryContainer
                        : Colors.transparent),
                alignment: Alignment.center,
                child: Text(
                  episode.enclosureDuration!.toTime,
                  style: (layout == Layout.large
                          ? context.textTheme.labelMedium
                          : context.textTheme.labelSmall)!
                      .copyWith(
                          color: context.realDark
                              ? episode
                                  .getColorScheme(context)
                                  .onSecondaryContainer
                              : showPlayedAndDownloaded && episode.isPlayed!
                                  ? episode
                                      .getColorScheme(context)
                                      .secondaryContainer
                                  : episode
                                      .getColorScheme(context)
                                      .onSecondaryContainer),
                ),
              ),
              Container(
                  width: 1,
                  height: (layout == Layout.large
                          ? context.textTheme.bodyMedium
                          : context.textTheme.bodySmall)!
                      .fontSize,
                  color: context.realDark &&
                          (!showPlayedAndDownloaded ||
                              !episode.isDownloaded! && !episode.isPlayed!) &&
                          episode.enclosureSize != 0
                      ? episode.getColorScheme(context).onSecondaryContainer
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
                          : episode
                              .getColorScheme(context)
                              .onSecondaryContainer,
                      width: 1),
                  color: showPlayedAndDownloaded && episode.isDownloaded!
                      ? context.realDark
                          ? episode.getColorScheme(context).secondaryContainer
                          : episode.getColorScheme(context).onSecondaryContainer
                      : Colors.transparent),
              alignment: Alignment.center,
              child: Text(
                '${episode.enclosureSize! ~/ 1000000}MB',
                style: (layout == Layout.large
                        ? context.textTheme.labelMedium
                        : context.textTheme.labelSmall)!
                    .copyWith(
                        color: context.realDark
                            ? episode
                                .getColorScheme(context)
                                .onSecondaryContainer
                            : showPlayedAndDownloaded && episode.isDownloaded!
                                ? episode
                                    .getColorScheme(context)
                                    .secondaryContainer
                                : episode
                                    .getColorScheme(context)
                                    .onSecondaryContainer),
              ),
            ),
            Container(
                width: 1,
                height: (layout == Layout.large
                        ? context.textTheme.bodyMedium
                        : context.textTheme.bodySmall)!
                    .fontSize,
                color: context.realDark &&
                        (!showPlayedAndDownloaded ||
                            !episode.isDownloaded! && !episode.isPlayed!) &&
                        episode.enclosureDuration != 0
                    ? episode.getColorScheme(context).onSecondaryContainer
                    : Colors.transparent)
          ]),
      ],
    );

Widget _downloadIndicator(
        BuildContext context, Layout layout, bool showDownload,
        {bool? isDownloaded}) =>
    showDownload && layout != Layout.small
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
        EpisodeBrief episode, BuildContext context, Layout layout) =>
    episode.isNew!
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('New',
                style: (layout == Layout.large
                        ? context.textTheme.labelMedium
                        : context.textTheme.labelSmall)!
                    .copyWith(color: Colors.red, fontStyle: FontStyle.italic)),
          )
        : Center();

/// Liked indicator widget.
Widget _isLikedIndicator(
        EpisodeBrief episode, BuildContext context, Layout layout) =>
    Container(
      alignment: Alignment.center,
      child: episode.isLiked!
          ? Icon(Icons.favorite,
              color: Colors.red,
              size: layout == Layout.small
                  ? context.textTheme.bodySmall!.fontSize
                  : context.textTheme.bodyLarge!.fontSize)
          : Center(),
    );

/// Count indicator widget.
Widget _numberIndicator(
        BuildContext context, String numberText, Layout layout) =>
    Text(
      numberText,
      style: GoogleFonts.teko(
          textStyle: layout == Layout.small
              ? context.textTheme.bodySmall
              : layout == Layout.medium
                  ? context.textTheme.bodyMedium
                  : context.textTheme.bodyLarge),
    );

/// Pubdate widget
Widget _pubDate(BuildContext context, EpisodeBrief episode, Layout layout,
        bool showNew) =>
    Text(
      episode.pubDate.toDate(context),
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: (layout == Layout.small
              ? context.textTheme.labelSmall
              : layout == Layout.medium
                  ? context.textTheme.labelMedium
                  : context.textTheme.labelLarge)!
          .copyWith(
              fontStyle: FontStyle.italic,
              color: episode.isNew!
                  ? Colors.red
                  : episode.getColorScheme(context).onSecondaryContainer),
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
