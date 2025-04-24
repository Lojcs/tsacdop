import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../episodes/episode_detail.dart';
import '../home/audioplayer.dart';
import '../state/episode_state.dart';
import '../state/setting_state.dart';
import '../type/episodebrief.dart';
import '../util/extension_helper.dart';
import '../util/hide_player_route.dart';
import 'package:tuple/tuple.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../state/audio_state.dart';
import '../type/play_histroy.dart';
import '../type/podcastlocal.dart';
import '../util/helpers.dart';
import '../util/open_container.dart';
import '../util/selection_controller.dart';
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

  /// Enables selection if a [SelectionController] provider is in the tree.
  final bool selectable;

  /// Index to control with selectionController
  final int? index;

  /// If true and this episode is selected, context menu actions are applied
  /// to [SelectionController.selectedEpisodes].
  final bool applyActionToAllSelected;

  /// Disables the card listening to [EpisodeState] to refresh itself.
  /// [EpisodeState] is still checked to prevent unnecessary rebuilds.
  final bool externallyRefreshed;

  InteractiveEpisodeCard(
    this.context,
    this.episode,
    this.layout, {
    this.openPodcast = true,
    this.showImage = true,
    this.preferEpisodeImage = false,
    this.showNumber = false,
    this.showLiked = true,
    this.showNew = true,
    this.showLengthAndSize = true,
    this.showPlayedAndDownloaded = true,
    this.showDate = false,
    this.selectable = false,
    this.index,
    this.applyActionToAllSelected = true,
    this.externallyRefreshed = false,
  })  : assert((!preferEpisodeImage &&
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
        assert(!selectable || index != null),
        super(key: Key(episode.id.toString()));

  @override
  _InteractiveEpisodeCardState createState() => _InteractiveEpisodeCardState();
}

class _InteractiveEpisodeCardState extends State<InteractiveEpisodeCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shadowController;

  late EpisodeBrief episode;
  PlayHistory? savedPosition;

  late SelectionController? selectionController =
      Provider.of<SelectionController?>(context, listen: false);
  late SettingState settings =
      Provider.of<SettingState>(context, listen: false);

  bool get selectable => widget.selectable && selectionController != null;
  late bool selected =
      selectionController?.selectedIndicies.contains(widget.index) ?? false;

  bool _initialBuild = true;
  late bool? episodeChange;

  double avatarSize = 0;

  late Widget _body;

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
  Widget build(BuildContext context) {
    if (_initialBuild) {
      _initialBuild = false;
      episodeChange =
          Provider.of<EpisodeState>(context).episodeChangeMap[episode.id];
      _body = _getBody();
    }
    if (widget.externallyRefreshed) {
      bool? changeValue =
          Provider.of<EpisodeState>(context).episodeChangeMap[episode.id];
      if (changeValue != null && changeValue != episodeChange) {
        episode = widget.episode;
        episodeChange = changeValue;
        _body = _getBody();
      }
      return _body;
    } else {
      return Selector<EpisodeState, bool?>(
        selector: (_, episodeState) =>
            episodeState.episodeChangeMap[episode.id],
        builder: (_, data, ___) => FutureBuilder<EpisodeBrief?>(
          future: () async {
            if (data != episodeChange) {
              // Prevents unnecessary database calls when the card is rebuilt for other reasons
              episodeChange = data;
              return widget.episode.copyWithFromDB(
                  update: true); // It needs to be widget.episode
            } else {
              return null;
            }
          }(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              episode = snapshot.data!;
            }
            _body = _getBody();
            return _body;
          },
        ),
      );
    }
  }

  Future<void> _vibrateTapNormal() async {
    if (!(await Vibration.hasAmplitudeControl())) return;
    Vibration.vibrate(
      pattern: [5, 145, 50, 50],
      intensities: [32, 0, 4, 0]
          .map((i) => (i * math.pow(2, settings.hapticsStrength / 2)).toInt())
          .toList(),
    );
  }

  Future<void> _vibrateTapSelected() async {
    if (!(await Vibration.hasAmplitudeControl())) return;
    await Vibration.cancel();
    Vibration.vibrate(
        duration: 5,
        amplitude: (32 * math.pow(2, settings.hapticsStrength / 2).toInt()));
  }

  Future<void> _vibrateLongTap() async {
    if (!(await Vibration.hasAmplitudeControl())) return;
    await Vibration.cancel();
    Vibration.vibrate(
        duration: 5,
        amplitude: (48 * math.pow(2, settings.hapticsStrength / 2).toInt()));
  }

  Future<void> _vibrateTapFinishedSelect() async {
    if (!(await Vibration.hasAmplitudeControl())) return;
    await Vibration.cancel();
    Vibration.vibrate(
      pattern: [32, 4, 4],
      intensities: [4, 0, 32]
          .map((i) => (i * math.pow(2, settings.hapticsStrength / 2)).toInt())
          .toList(),
    );
  }

  Future<void> _vibrateTapFinishedRelease() async {
    if (!(await Vibration.hasAmplitudeControl())) return;
    await Vibration.cancel();
    Vibration.vibrate(
      pattern: [4, 12, 16, 12, 6],
      intensities: [32, 0, 8, 6, 4]
          .map((i) => (i * math.pow(2, settings.hapticsStrength / 2)).toInt())
          .toList(),
    );
  }

  Future<void> _vibrateEnd() async {
    await Vibration.cancel();
  }

  Widget _getBody() {
    return OpenContainerWrapper(
      layout: widget.layout,
      getAvatarSize: () => avatarSize,
      episode: episode,
      preferEpisodeImage: widget.preferEpisodeImage,
      onClosed: (() {
        _shadowController.reverse();
      }),
      closedBuilder: (context, action, boo) => FutureBuilder<List<int>>(
        future: _getEpisodeMenu(),
        initialData: [],
        builder: (context, snapshot) {
          final menuList = snapshot.data!;
          return Selector2<AudioPlayerNotifier, SelectionController?,
              Tuple4<bool, bool, bool, bool>>(
            selector: (_, audio, select) => Tuple4(
                audio.episode == episode,
                audio.playlist.contains(episode),
                audio.playerRunning,
                select?.selectedIndicies.contains(widget.index) ?? false),
            builder: (_, data, __) {
              selected = data.item4;
              if (selected) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
              if (data.item1) savedPosition = null;
              List<FocusedMenuItem> menuItemList = _menuItemList(context,
                  episode, data.item1, data.item2, data.item3, menuList,
                  applyToAllSelected: widget.applyActionToAllSelected);
              return _FocusedMenuHolderWrapper(
                onTapStart: () {
                  if (selected) {
                    _vibrateTapSelected();
                  } else {
                    _vibrateTapNormal();
                  }
                },
                onTapEnd: () {
                  _vibrateEnd();
                },
                onTap: () async {
                  if (selectable && selectionController!.selectMode) {
                    selected = selectionController!.select(widget.index!);
                    if (selected) {
                      _vibrateTapFinishedSelect();
                      _controller.forward();
                    } else {
                      _vibrateTapFinishedRelease();
                      _controller.reverse();
                    }
                  } else {
                    _shadowController.forward();
                    action();
                  }
                },
                onShortTapHold: () {
                  if (selectable && !selected) {
                    _vibrateLongTap();
                    if (!selectionController!.selectMode) {
                      selectionController!.selectMode = true;
                      selectionController!.temporarySelect = true;
                    }
                    selected = selectionController!.select(widget.index!);

                    _controller.forward();
                  }
                },
                onPrimaryClick: () {
                  if (selectable) {
                    if (selectionController!.selectMode) {
                      selected = selectionController!.select(widget.index!);
                    } else {
                      selectionController!.deselectAll();
                      selected = selectionController!.select(widget.index!);
                    }
                    if (selected) {
                      _controller.forward();
                    } else {
                      _controller.reverse();
                    }
                  }
                },
                onDoubleClick: () {
                  _shadowController.forward();
                  action();
                },
                onAddSelect: () {
                  if (selectable) {
                    if (!selectionController!.selectMode) {
                      selectionController!.selectMode = true;
                      selectionController!.temporarySelect = true;
                    }
                    selected = selectionController!.select(widget.index!);
                    if (selected) {
                      _controller.forward();
                    } else {
                      _controller.reverse();
                    }
                  }
                },
                onRangeSelect: () {
                  if (selectable) {
                    if (!selectionController!.selectMode) {
                      selectionController!.selectMode = true;
                      selectionController!.temporarySelect = true;
                    }
                    selectionController!.batchSelect = BatchSelect.none;
                    if (!selected) {
                      selected = selectionController!.select(widget.index!);
                    }
                    selectionController!.batchSelect = BatchSelect.between;
                    if (selected) {
                      _controller.forward();
                    } else {
                      _controller.reverse();
                    }
                  }
                },
                onTapDrag: () {},
                episode: episode,
                layout: widget.layout,
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
                childLowerlay: data.item1 && data.item3
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
                          snapshot.hasData ? snapshot.data!.seekValue! : 0,
                          widget.layout,
                          animator: _controller,
                        ),
                      ),
                controller: _controller,
                shadowController: _shadowController,
                child: EpisodeCard(
                  context,
                  episode,
                  widget.layout,
                  openPodcast: widget.openPodcast,
                  showImage: widget.showImage && !boo,
                  preferEpisodeImage: widget.preferEpisodeImage,
                  showNumber: widget.showNumber,
                  showLiked: widget.showLiked,
                  showNew: widget.showNew,
                  showLengthAndSize: widget.showLengthAndSize,
                  showPlayedAndDownloaded: widget.showPlayedAndDownloaded,
                  showDate: widget.showDate,
                  decorate: false,
                  avatarSizeCallback: (size) {
                    avatarSize = size;
                  },
                ),
              );
            },
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

class OpenContainerWrapper extends StatelessWidget {
  const OpenContainerWrapper(
      {super.key,
      required this.closedBuilder,
      required this.episode,
      this.playerRunning,
      this.getAvatarSize,
      required this.preferEpisodeImage,
      required this.layout,
      this.onClosed});

  final OpenContainerBuilder closedBuilder;
  final EpisodeBrief episode;
  final bool? playerRunning;
  final double? Function()? getAvatarSize;
  final bool preferEpisodeImage;
  final EpisodeGridLayout layout;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerNotifier, Tuple2<bool, PlayerHeight?>>(
      selector: (_, audio) => Tuple2(audio.playerRunning, audio.playerHeight),
      builder: (_, data, __) => OpenContainer(
        playerRunning: data.item1,
        playerHeight: kMinPlayerHeight[data.item2!.index],
        flightWidget: CircleAvatar(
            backgroundImage: preferEpisodeImage
                ? episode.episodeOrPodcastImageProvider
                : episode.podcastImageProvider),
        getFlightWidgetBeginSize: getAvatarSize,
        flightWidgetEndSize: 30,
        flightWidgetBeginOffsetX: layout == EpisodeGridLayout.small ? 6 : 8,
        flightWidgetBeginOffsetY: layout == EpisodeGridLayout.small
            ? 7
            : layout == EpisodeGridLayout.medium
                ? 8
                : 15,
        flightWidgetEndOffsetX: 10,
        flightWidgetEndOffsetY: data.item1
            ? context.height -
                kMinPlayerHeight[data.item2!.index]! -
                40 -
                context.originalPadding.bottom
            : context.height - 40 - context.originalPadding.bottom,
        transitionDuration: Duration(milliseconds: 400),
        beginColor: Theme.of(context).primaryColor,
        endColor: Theme.of(context).primaryColor,
        closedColor: Theme.of(context).brightness == Brightness.light
            ? context.primaryColor
            : context.surface,
        openColor: context.surface,
        openElevation: 0,
        closedElevation: 0,
        openShape: RoundedRectangleBorder(borderRadius: context.radiusSmall),
        closedShape: RoundedRectangleBorder(
            borderRadius: layout == EpisodeGridLayout.small
                ? context.radiusSmall
                : layout == EpisodeGridLayout.medium
                    ? context.radiusMedium
                    : context.radiusLarge),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (context, _, boo) {
          return EpisodeDetail(
            episodeItem: episode,
            hide: boo,
          );
        },
        tappable: false,
        closedBuilder: closedBuilder,
        onDispose: onClosed,
      ),
    );
  }
}

class _FocusedMenuHolderWrapper extends StatefulWidget {
  final Widget child;

  /// Wheter to show menu on medium tap hold.
  final VoidCallback? onTapStart;
  final VoidCallback? onTapEnd;
  final VoidCallback? onTap;
  final VoidCallback? onShortTapHold;
  final VoidCallback? onLongTapHold;
  final VoidCallback? onPrimaryClick;
  final VoidCallback? onDoubleClick;
  final VoidCallback? onAddSelect;
  final VoidCallback? onRangeSelect;
  final VoidCallback? onTapDrag;
  final VoidCallback? onPrimaryDrag;
  final VoidCallback? onDragOver;

  final EpisodeBrief episode;
  final EpisodeGridLayout layout;

  final List<FocusedMenuItem> menuItemList;
  final double? menuItemExtent;
  final BoxDecoration? menuBoxDecoration;
  final Widget? childLowerlay;

  final AnimationController controller;
  final AnimationController shadowController;
  const _FocusedMenuHolderWrapper(
      {required this.child,
      this.onTapStart,
      this.onTapEnd,
      this.onTap,
      this.onShortTapHold,
      this.onLongTapHold,
      this.onPrimaryClick,
      this.onDoubleClick,
      this.onAddSelect,
      this.onRangeSelect,
      this.onTapDrag,
      this.onPrimaryDrag,
      this.onDragOver,
      required this.episode,
      required this.layout,
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
    return Transform.scale(
      scale: 1 -
          0.01 *
              CurvedAnimation(
                parent: widget.controller,
                curve: Curves.easeOutQuad,
              ).value,
      child: FocusedMenuHolder(
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
        animateMenuItems: false,
        blurBackgroundColor: context.surface,
        bottomOffsetHeight: 10,
        menuOffset: 10,
        menuItems: widget.menuItemList,
        showMenuOnMediumHold: false,
        onTapStart: widget.onTapStart,
        onTapEnd: widget.onTapEnd,
        onTap: widget.onTap,
        onShortTapHold: widget.onShortTapHold,
        onLongTapHold: widget.onLongTapHold,
        onPrimaryClick: widget.onPrimaryClick,
        onDoubleClick: widget.onDoubleClick,
        onAddSelect: widget.onAddSelect,
        onRangeSelect: widget.onRangeSelect,
        onTapDrag: widget.onTapDrag,
        onPrimaryDrag: widget.onPrimaryDrag,
        onDragOver: widget.onDragOver,
        child: widget.child,
      ),
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

  /// Episode number to be shown.
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

  /// Callback that sends back the actual size of the avatar.
  final void Function(double)? avatarSizeCallback;
  EpisodeCard(this.context, this.episode, this.layout,
      {super.key,
      this.openPodcast = false,
      this.showImage = true,
      this.preferEpisodeImage = false,
      this.showNumber = false,
      this.showLiked = true,
      this.showNew = true,
      this.showLengthAndSize = true,
      this.showPlayedAndDownloaded = true,
      this.showDate = false,
      this.selected = false,
      this.decorate = true,
      this.avatarSizeCallback})
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
                        _circleImage(
                          context,
                          openPodcast,
                          preferEpisodeImage,
                          radius: layout == EpisodeGridLayout.small
                              ? context.width / 20
                              : context.width / 15,
                          episode: episode,
                          color: episode.colorScheme(context).primary,
                          actualSizeCallback: avatarSizeCallback,
                          showImage: showImage,
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
                              actualSizeCallback: avatarSizeCallback,
                              showImage: showImage,
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
  const _ProgressLowerlay(this.episode, this.seekValue, this.layout,
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
              : Tween<double>(begin: -2, end: -3).evaluate(controller),
          offset: Offset.fromDirection(0, 0),
        )
      ]);
}

List<FocusedMenuItem> _menuItemList(BuildContext context, EpisodeBrief episode,
    bool playing, bool inPlaylist, bool playerRunning, List<int> menuList,
    {bool applyToAllSelected = false}) {
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
            List<EpisodeBrief> episodes = [episode];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodes = selectionController.selectedEpisodes;
            }
            await audio.loadEpisodesToQueue(episodes);
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
            List<EpisodeBrief> episodes = [episode];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodes = selectionController.selectedEpisodes;
            }
            if (!inPlaylist) {
              await audio.addToPlaylist(episodes);
              await Fluttertoast.showToast(
                msg: s.toastAddPlaylist,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              await audio.removeFromPlaylist(episodes);
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
            List<EpisodeBrief> episodes = [episode];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodes = selectionController.selectedEpisodes;
            }
            if (episode.isLiked!) {
              await episodeState.unsetLiked(episodes);
              Fluttertoast.showToast(
                msg: s.unlike,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              await episodeState.setLiked(episodes);
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
                  style: TextStyle(
                      color: context.textColor.withValues(alpha: 0.5)))
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
            List<EpisodeBrief> episodes = [episode];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodes = selectionController.selectedEpisodes;
            }
            if (episode.isPlayed!) {
              episodeState.unsetListened(episodes);
              Fluttertoast.showToast(
                msg: s.markNotListened,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              episodeState.setListened(episodes);
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
                  style: TextStyle(
                      color: context.textColor.withValues(alpha: 0.5)))
              : Text(s.download),
          trailing: Icon(LineIcons.download, color: Colors.green),
          onPressed: () async {
            if (!episode.isDownloaded!) {
              List<EpisodeBrief> episodes = [episode];
              SelectionController? selectionController =
                  Provider.of<SelectionController?>(context, listen: false);
              if (selectionController != null && applyToAllSelected) {
                episodes = selectionController.selectedEpisodes;
              }
              await requestDownload(episodes, context);
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
          List<EpisodeBrief> episodes = [episode];
          SelectionController? selectionController =
              Provider.of<SelectionController?>(context, listen: false);
          if (selectionController != null && applyToAllSelected) {
            episodes = selectionController.selectedEpisodes;
          }
          audio.addToPlaylist(episodes,
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
            .copyWith(
          height: 1.25,
          color: episode.colorScheme(context).onSurface,
        ),
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
                color: episode.colorScheme(context).onSecondaryContainer),
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
  void Function(double)? actualSizeCallback,
  bool showImage = true,
}) =>
    LayoutBuilder(
      builder: (context, constraints) {
        double actualSize = math.min(
            math.min(radius, constraints.maxHeight), constraints.maxWidth);
        actualSizeCallback?.call(
          math.min(
              math.min(radius, constraints.maxHeight), constraints.maxWidth),
        );
        return SizedBox(
          height: actualSize,
          width: actualSize,
          child: showImage
              ? Stack(
                  children: [
                    CircleAvatar(
                      radius: actualSize,
                      backgroundColor: color.withValues(alpha: 0.5),
                      backgroundImage: preferEpisodeImage
                          ? episode.episodeOrPodcastImageProvider
                          : episode.podcastImageProvider,
                    ),
                    if (openPodcast)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(actualSize),
                          onTap: () async {
                            DBHelper dbHelper = DBHelper();
                            PodcastLocal? podcast = await dbHelper
                                .getPodcastWithUrl(episode.enclosureUrl);
                            if (podcast != null) {
                              Navigator.push(
                                context,
                                HidePlayerRoute(
                                  PodcastDetail(podcastLocal: podcast),
                                  PodcastDetail(
                                      podcastLocal: podcast, hide: true),
                                  duration: Duration(milliseconds: 300),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                )
              : Center(),
        );
      },
    );

Widget _lengthAndSize(
    BuildContext context, EpisodeGridLayout layout, EpisodeBrief episode,
    {bool showPlayedAndDownloaded = false}) {
  BorderSide side = BorderSide(
      color: context.realDark
          ? Colors.transparent
          : episode.colorScheme(context).onSecondaryContainer,
      width: 1);
  BorderSide innerSide = BorderSide(
      color: episode.colorScheme(context).onSecondaryContainer, width: 1);
  Color backgroundColor = context.realDark
      ? episode.colorScheme(context).secondaryContainer
      : episode.colorScheme(context).onSecondaryContainer;
  return Row(
    children: [
      if (episode.enclosureDuration != 0)
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(5),
                  right: episode.enclosureSize == 0
                      ? Radius.circular(5)
                      : Radius.zero),
              border: Border.fromBorderSide(side),
              color: showPlayedAndDownloaded && episode.isPlayed!
                  ? backgroundColor
                  : Colors.transparent),
          foregroundDecoration: context.realDark
              ? BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                      right: episode.enclosureSize == 0
                          ? Radius.circular(5)
                          : Radius.zero),
                  border: episode.enclosureSize == 0 ||
                          (showPlayedAndDownloaded &&
                              (episode.isPlayed! || episode.isDownloaded!))
                      ? null
                      : Border(right: innerSide),
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            episode.enclosureDuration!.toTime,
            style: (layout == EpisodeGridLayout.large
                    ? context.textTheme.labelMedium
                    : context.textTheme.labelSmall)!
                .copyWith(
                    color: showPlayedAndDownloaded &&
                            !context.realDark &&
                            episode.isPlayed!
                        ? episode.colorScheme(context).secondaryContainer
                        : episode.colorScheme(context).onSecondaryContainer),
          ),
        ),
      if (episode.enclosureSize != 0)
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(5),
                  left: episode.enclosureDuration == 0
                      ? Radius.circular(5)
                      : Radius.zero),
              border: episode.enclosureDuration == 0
                  ? Border.fromBorderSide(side)
                  : Border(top: side, right: side, bottom: side),
              color: showPlayedAndDownloaded && episode.isDownloaded!
                  ? backgroundColor
                  : Colors.transparent),
          alignment: Alignment.center,
          child: Text(
            '${episode.enclosureSize! ~/ 1000000}MB',
            style: (layout == EpisodeGridLayout.large
                    ? context.textTheme.labelMedium
                    : context.textTheme.labelSmall)!
                .copyWith(
                    color: showPlayedAndDownloaded &&
                            !context.realDark &&
                            episode.isDownloaded!
                        ? episode.colorScheme(context).secondaryContainer
                        : episode.colorScheme(context).onSecondaryContainer),
          ),
        ),
    ],
  );
}

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
    Padding(
      padding: EdgeInsets.only(top: 0.5),
      child: Text(
        numberText + (layout == EpisodeGridLayout.large ? "|" : ""),
        style: GoogleFonts.teko(
            textStyle: layout == EpisodeGridLayout.small
                ? context.textTheme.bodySmall
                : layout == EpisodeGridLayout.medium
                    ? context.textTheme.bodyMedium
                    : context.textTheme.bodyLarge),
      ),
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

Future<List<int>> _getEpisodeMenu() async {
  final popupMenuStorage = KeyValueStorage(
      episodePopupMenuKey); // TODO: These should be obtainable from SettingState.
  final list = await popupMenuStorage.getMenu();
  return list;
}
