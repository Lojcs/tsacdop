import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../episodes/episode_detail.dart';
import '../state/episode_state.dart';
import '../state/setting_state.dart';
import '../type/episodebrief.dart';
import '../util/extension_helper.dart';
import '../util/hide_player_route.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../state/audio_state.dart';
import '../type/play_histroy.dart';
import '../type/podcastlocal.dart';
import '../util/helpers.dart';
import '../util/selection_controller.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';

/// [EpisodeCard] widget that responds to user interaction.
class InteractiveEpisodeCard extends StatefulWidget {
  /// Id of the episode the card is about
  final int episodeId;

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

  InteractiveEpisodeCard(
    this.episodeId,
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
  })  : assert(!selectable || index != null),
        super(key: Key(episodeId.toString()));

  @override
  State<InteractiveEpisodeCard> createState() => InteractiveEpisodeCardState();
}

class InteractiveEpisodeCardState extends State<InteractiveEpisodeCard>
    with TickerProviderStateMixin {
  final GlobalKey cardKey = GlobalKey();

  late AnimationController _controller;
  late AnimationController _shadowController;

  late SelectionController? selectionController =
      Provider.of<SelectionController?>(context, listen: false);
  late SettingState settings =
      Provider.of<SettingState>(context, listen: false);
  late EpisodeState eState = Provider.of<EpisodeState>(context, listen: false);

  bool get selectable =>
      widget.selectable && selectionController != null && mounted;
  late bool selected =
      selectionController?.selectedIndicies.contains(widget.index) ?? false;

  GlobalKey avatarKey = GlobalKey();

  bool avatarHasFocus = false;
  Future<void> waitForAvatar = Future(() {});

  bool hideCard = false;
  void _selectionListener() {
    if (mounted) {
      selected = selectionController!.selectedIndicies.contains(widget.index);
      if (selectable) {
        if (selected) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _shadowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    selectionController?.addListener(_selectionListener);
    if (selected && selectable) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    _shadowController.dispose();
    super.dispose();
  }

  Widget _cardBuilder(bool hideImage) => EpisodeCard(
        widget.episodeId,
        widget.layout,
        openPodcast: widget.openPodcast,
        showImage: widget.showImage,
        preferEpisodeImage: widget.preferEpisodeImage,
        showNumber: widget.showNumber,
        showLiked: widget.showLiked,
        showNew: widget.showNew,
        showLengthAndSize: widget.showLengthAndSize,
        showPlayedAndDownloaded: widget.showPlayedAndDownloaded,
        showDate: widget.showDate,
        decorate: false,
        avatarKey: avatarKey,
        onTapDown: () => avatarHasFocus = true,
        onTapUp: () => Future.delayed(
            Duration(milliseconds: 6), () => avatarHasFocus = false),
        hideImage: hideImage,
      );

  void openDetails(BuildContext context) => Navigator.push(
        context,
        EpisodeCardDetailRoute(
          context,
          widget.episodeId,
          cardKey: cardKey,
          layout: widget.layout,
          cardBuilder: _cardBuilder,
          preferEpisodeImage: widget.preferEpisodeImage,
          heroKey: avatarKey,
          showCard: () {
            setState(() => hideCard = false);
          },
          hideCard: () {
            setState(() => hideCard = true);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    List<FocusedMenuItem> menuItemList = [];
    if (hideCard) return Center();
    return Selector<AudioPlayerNotifier, (bool, bool, bool)>(
      key: cardKey,
      selector: (_, audio) => (
        audio.episodeId == widget.episodeId,
        audio.playlist.contains(widget.episodeId),
        audio.playerRunning,
      ),
      builder: (_, data, __) {
        return _FocusedMenuHolderWrapper(
          onTapStart: () async {
            waitForAvatar = Future.delayed(Duration(milliseconds: 1));
            await waitForAvatar;
            if (avatarHasFocus) return;
            if (selected) {
              _vibrateTapSelected();
            } else {
              _vibrateTapNormal();
            }
          },
          onTapEnd: () {
            if (avatarHasFocus) return;
            _vibrateEnd();
          },
          onTap: () async {
            await waitForAvatar;
            if (avatarHasFocus) return;
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
              if (context.mounted) openDetails(context);
            }
          },
          onShortTapHold: () {
            if (avatarHasFocus) return;
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
            if (avatarHasFocus) return;
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
            if (avatarHasFocus) return;
            _shadowController.forward();
            openDetails(context);
          },
          onAddSelect: () {
            if (avatarHasFocus) return;
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
            if (avatarHasFocus) return;
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
          episodeId: widget.episodeId,
          layout: widget.layout,
          menuItemList: () async {
            if (context.mounted) {
              final menulist = await _getEpisodeMenu();
              menuItemList = _menuItemList(context, widget.episodeId, data.$1,
                  data.$2, data.$3, menulist,
                  applyToAllSelected: widget.applyActionToAllSelected);
            }
            return menuItemList;
          },
          menuItemExtent: () async {
            final menulist = await _getEpisodeMenu();
            return widget.layout == EpisodeGridLayout.small
                ? 41.5
                : widget.layout == EpisodeGridLayout.medium
                    ? 42.5
                    : 100 / menulist.where((i) => i < 10).length;
          },
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
          childLowerlay: data.$1 && data.$3
              ? Selector<AudioPlayerNotifier, double>(
                  selector: (_, audio) => audio.seekSliderValue,
                  builder: (_, seekValue, __) => _ProgressLowerlay(
                    widget.episodeId,
                    seekValue,
                    widget.layout,
                    animator: _controller,
                  ),
                )
              : Selector<EpisodeState, bool>(
                  selector: (_, eState) => eState[widget.episodeId].isPlayed,
                  builder: (_, played, __) => played
                      ? _ProgressLowerlay(
                          widget.episodeId,
                          1,
                          widget.layout,
                          animator: _controller,
                        )
                      : FutureBuilder<PlayHistory>(
                          future: _getSavedPosition(),
                          // initialData: PlayHistory("", "", 0, 0),
                          builder: (context, snapshot) => _ProgressLowerlay(
                            widget.episodeId,
                            snapshot.hasData ? snapshot.data!.seekValue! : 0,
                            widget.layout,
                            animator: _controller,
                          ),
                        ),
                ),
          controller: _controller,
          shadowController: _shadowController,
          child: _cardBuilder(false),
        );
      },
    );
  }

  Future<void> _vibrateTapNormal() async {
    if (!(await Vibration.hasAmplitudeControl()) ||
        settings.hapticsStrength <= -100) {
      return;
    }
    Vibration.vibrate(
      pattern: [5, 145, 50, 50],
      intensities: [32, 0, 4, 0]
          .map((i) => (i * math.pow(2, settings.hapticsStrength / 2)).toInt())
          .toList(),
    );
  }

  Future<void> _vibrateTapSelected() async {
    if (!(await Vibration.hasAmplitudeControl()) ||
        settings.hapticsStrength <= -100) {
      return;
    }
    await Vibration.cancel();
    Vibration.vibrate(
        duration: 5,
        amplitude: (32 * math.pow(2, settings.hapticsStrength / 2).toInt()));
  }

  Future<void> _vibrateLongTap() async {
    if (!(await Vibration.hasAmplitudeControl()) ||
        settings.hapticsStrength <= -100) {
      return;
    }
    await Vibration.cancel();
    Vibration.vibrate(
        duration: 5,
        amplitude: (48 * math.pow(2, settings.hapticsStrength / 2).toInt()));
  }

  Future<void> _vibrateTapFinishedSelect() async {
    if (!(await Vibration.hasAmplitudeControl()) ||
        settings.hapticsStrength <= -100) {
      return;
    }
    await Vibration.cancel();
    Vibration.vibrate(
      pattern: [32, 4, 4],
      intensities: [4, 0, 32]
          .map((i) => (i * math.pow(2, settings.hapticsStrength / 2)).toInt())
          .toList(),
    );
  }

  Future<void> _vibrateTapFinishedRelease() async {
    if (!(await Vibration.hasAmplitudeControl()) ||
        settings.hapticsStrength <= -100) {
      return;
    }
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

  Future<PlayHistory> _getSavedPosition() {
    DBHelper dbHelper = DBHelper();
    return dbHelper.getPosition(eState[widget.episodeId]);
  }
}

class EpisodeCardDetailRoute extends ModalRoute {
  final int episodeId;
  final GlobalKey cardKey;
  final EpisodeGridLayout layout;
  final Widget Function(bool hideImage) cardBuilder;

  final VoidCallback showCard;
  final VoidCallback hideCard;
  final VoidCallback? onDispose;

  final RenderBox cardBox;

  final bool preferEpisodeImage;
  final GlobalKey heroKey;

  late final Offset initialHeroOffset;
  final Offset finalHeroOffset;

  late final Tween<Size> sizeTween;
  late final Tween<Offset> offsetTween;

  late final Tween<Offset> heroOffsetTween;
  late final Tween<double> heroSizeTween;

  EpisodeCardDetailRoute(BuildContext context, this.episodeId,
      {required this.cardKey,
      required this.layout,
      required this.cardBuilder,
      required this.showCard,
      required this.hideCard,
      required this.preferEpisodeImage,
      required this.heroKey,
      this.onDispose})
      : cardBox = cardKey.currentContext!.findRenderObject() as RenderBox,
        finalHeroOffset = Offset(
            10,
            context.audioState.playerRunning
                ? context.height -
                    context.audioState.playerHeight!.height -
                    40 -
                    context.originalPadding.bottom
                : context.height - 40 - context.originalPadding.bottom) {
    sizeTween = Tween(
        begin: cardBox.size,
        end: Size(
            context.width,
            context.height -
                (context.audioState.playerRunning
                    ? context.audioState.playerHeight!.height
                    : 0) -
                context.originalPadding.bottom));
    final cardOffset = cardBox.localToGlobal(Offset.zero);
    offsetTween = Tween(begin: cardOffset, end: Offset.zero);

    final RenderBox heroBox =
        heroKey.currentContext!.findRenderObject() as RenderBox;
    initialHeroOffset = heroBox.localToGlobal(Offset.zero);
    heroOffsetTween = Tween(begin: initialHeroOffset, end: finalHeroOffset);
    heroSizeTween = Tween(begin: heroBox.size.width, end: 30);
  }

  @override
  void dispose() {
    showCard();
    if (onDispose != null) onDispose!();
    super.dispose();
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    Future.microtask(hideCard);
    EpisodeState eState = Provider.of<EpisodeState>(context, listen: false);
    final sizeAnimation =
        CurvedAnimation(parent: animation, curve: Curves.easeInOutCirc);
    final cardFadeAnimation =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final detailFadeAnimation =
        CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final size = sizeTween.evaluate(sizeAnimation);
        final heroSize = heroSizeTween.evaluate(sizeAnimation);
        return Stack(
          children: [
            animation.isCompleted
                ? PopScope(
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) {
                        Future.delayed(Duration(milliseconds: 400), showCard);
                      }
                    },
                    child: EpisodeDetail(episodeId),
                  )
                : Transform.translate(
                    offset: offsetTween.evaluate(sizeAnimation),
                    child: Container(
                      decoration:
                          _cardDecoration(context, episodeId, layout).copyWith(
                        border:
                            BoxBorder.all(width: 0, color: Colors.transparent),
                      ),
                      clipBehavior: Clip.hardEdge,
                      height: size.height,
                      width: size.width,
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          Opacity(
                            opacity: 1 - cardFadeAnimation.value,
                            child: FittedBox(
                              alignment: Alignment.topCenter,
                              fit: BoxFit.fitWidth,
                              child: SizedBox(
                                height: cardBox.size.height,
                                width: cardBox.size.width,
                                child: cardBuilder(true),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: detailFadeAnimation.value,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                height:
                                    context.width * size.height / size.width,
                                width: context.width,
                                child: PopScope(
                                  onPopInvokedWithResult: (didPop, result) {
                                    if (didPop) {
                                      Future.delayed(
                                          Duration(milliseconds: 400),
                                          showCard);
                                    }
                                  },
                                  child: EpisodeDetail(
                                    episodeId,
                                    hide: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            Transform.translate(
              offset: heroOffsetTween.evaluate(sizeAnimation),
              child: animation.isCompleted
                  ? Center()
                  : SizedBox(
                      height: heroSize,
                      width: heroSize,
                      child: CircleAvatar(
                        backgroundImage: preferEpisodeImage
                            ? eState[episodeId].episodeOrPodcastImageProvider
                            : eState[episodeId].podcastImageProvider,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get maintainState => false;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
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

  final int episodeId;
  final EpisodeGridLayout layout;

  final Future<List<FocusedMenuItem>> Function() menuItemList;
  final Future<double> Function()? menuItemExtent;
  final BoxDecoration? menuBoxDecoration;
  final Widget? childLowerlay;

  final AnimationController controller;
  final AnimationController shadowController;

  final VoidCallback? beforeOpened;
  final Future? initData;
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
      required this.episodeId,
      required this.layout,
      required this.menuItemList,
      required this.menuItemExtent,
      required this.menuBoxDecoration,
      required this.childLowerlay,
      required this.controller,
      required this.shadowController,
      this.beforeOpened,
      this.initData});
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
    final child = FocusedMenuHolder(
      blurSize: 0,
      menuItemExtent: widget.menuItemExtent,
      enableMenuScroll: false,
      menuBoxDecoration: widget.menuBoxDecoration,
      childDecoration: _cardDecoration(context, widget.episodeId, widget.layout,
          controller: widget.controller,
          shadowController: widget.shadowController),
      openChildDecoration: _cardDecoration(
        context,
        widget.episodeId,
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
      beforeOpened: widget.beforeOpened,
      initData: widget.initData,
      child: widget.child,
    );
    return Transform.scale(
        scale: 1 -
            0.01 *
                CurvedAnimation(
                  parent: widget.controller,
                  curve: Curves.easeOutQuad,
                ).value,
        child: child);
  }
}

/// Widget to display information about an episode.
class EpisodeCard extends StatelessWidget {
  /// Id of the episode the card is about
  final int episodeId;

  /// General card layout
  final EpisodeGridLayout layout;

  /// Opens the podcast details if avatar image is tapped
  final bool openPodcast;

  /// Controls if the avatar image is shown at any time.
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

  /// Key for the avatar image
  final GlobalKey? avatarKey;

  /// Callback that disables card gesture callbacks
  final VoidCallback? onTapDown;

  /// Callback that reenables card gesture callbacks
  final VoidCallback? onTapUp;

  final bool hideImage;

  const EpisodeCard(
    this.episodeId,
    this.layout, {
    super.key,
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
    this.avatarKey,
    this.onTapDown,
    this.onTapUp,
    this.hideImage = false,
  });

  @override
  Widget build(BuildContext context) {
    /// EpisodeBrief for convenience, don't use for value that might change
    EpisodeBrief episode =
        Provider.of<EpisodeState>(context, listen: false)[episodeId];

    /// Episode title widget.
    Widget title() => Container(
          alignment: layout == EpisodeGridLayout.large
              ? Alignment.centerLeft
              : Alignment.topLeft,
          padding:
              EdgeInsets.only(top: layout == EpisodeGridLayout.large ? 0 : 2),
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
    Widget podcastTitle() => Container(
          alignment: layout == EpisodeGridLayout.large
              ? Alignment.centerLeft
              : Alignment.topLeft,
          padding:
              EdgeInsets.only(top: layout == EpisodeGridLayout.large ? 0 : 2),
          width: (context.width / layout.getHorizontalCount(context.width)) -
              layout.getRowHeight(context.width) * 2 -
              30,
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
    Widget circleImage(
      bool openPodcast,
      bool preferEpisodeImage, {
      required double radius,
    }) =>
        SizedBox(
          height: radius,
          width: radius,
          child: !hideImage
              ? Stack(
                  children: [
                    CircleAvatar(
                      key: avatarKey,
                      radius: radius,
                      backgroundColor: episode.colorScheme(context).primary,
                      backgroundImage: preferEpisodeImage
                          ? episode.episodeOrPodcastImageProvider
                          : episode.podcastImageProvider,
                    ),
                    if (openPodcast)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(radius),
                          onTapDown: (details) => onTapDown?.call(),
                          onTapUp: (details) => onTapUp?.call(),
                          onTap: () async {
                            DBHelper dbHelper = DBHelper();
                            PodcastBrief? podcast = await dbHelper
                                .getPodcastWithUrl(episode.enclosureUrl);
                            if (podcast != null && context.mounted) {
                              Navigator.push(
                                context,
                                HidePlayerRoute(
                                  PodcastDetail(podcastLocal: podcast),
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

    /// Widget that shows the length, size properties and optionally the
    /// played, downloaded status of the episode.
    Widget lengthAndSize(BuildContext context,
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
      return Selector<EpisodeState,
          ({int duration, int size, bool played, bool downloaded})>(
        selector: (_, episodeState) => (
          duration: episodeState[episodeId].enclosureDuration,
          size: episodeState[episodeId].enclosureSize,
          played: episodeState[episodeId].isPlayed,
          downloaded: episodeState[episodeId].isDownloaded,
        ),
        builder: (context, value, _) => Row(
          children: [
            if (value.duration != 0)
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(5),
                        right:
                            value.size == 0 ? Radius.circular(5) : Radius.zero),
                    border: Border.fromBorderSide(side),
                    color: showPlayedAndDownloaded && value.played
                        ? backgroundColor
                        : Colors.transparent),
                foregroundDecoration: context.realDark
                    ? BoxDecoration(
                        borderRadius: BorderRadius.horizontal(
                            right: value.size == 0
                                ? Radius.circular(5)
                                : Radius.zero),
                        border: value.size == 0 ||
                                (showPlayedAndDownloaded &&
                                    (value.played || value.downloaded))
                            ? null
                            : Border(right: innerSide),
                      )
                    : null,
                alignment: Alignment.center,
                child: Text(
                  value.duration.toTime,
                  style: (layout == EpisodeGridLayout.large
                          ? context.textTheme.labelMedium
                          : context.textTheme.labelSmall)!
                      .copyWith(
                          color: showPlayedAndDownloaded &&
                                  !context.realDark &&
                                  value.played
                              ? episode.colorScheme(context).secondaryContainer
                              : episode
                                  .colorScheme(context)
                                  .onSecondaryContainer),
                ),
              ),
            if (value.size != 0)
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(5),
                        left: value.duration == 0
                            ? Radius.circular(5)
                            : Radius.zero),
                    border: value.duration == 0
                        ? Border.fromBorderSide(side)
                        : Border(top: side, right: side, bottom: side),
                    color: showPlayedAndDownloaded && value.downloaded
                        ? backgroundColor
                        : Colors.transparent),
                alignment: Alignment.center,
                child: Text(
                  '${value.size ~/ 1000000}MB',
                  style: (layout == EpisodeGridLayout.large
                          ? context.textTheme.labelMedium
                          : context.textTheme.labelSmall)!
                      .copyWith(
                          color: showPlayedAndDownloaded &&
                                  !context.realDark &&
                                  value.downloaded
                              ? episode.colorScheme(context).secondaryContainer
                              : episode
                                  .colorScheme(context)
                                  .onSecondaryContainer),
                ),
              ),
          ],
        ),
      );
    }

    /// Liked indicator widget.
    Widget isLikedIndicator() => Align(
          alignment: Alignment.center,
          child: Selector<EpisodeState, bool>(
            selector: (_, episodeState) => episodeState[episodeId].isLiked,
            builder: (context, value, _) => value
                ? Icon(Icons.favorite,
                    color: Colors.red,
                    size: layout == EpisodeGridLayout.small
                        ? context.textTheme.bodySmall!.fontSize
                        : context.textTheme.bodyLarge!.fontSize)
                : Center(),
          ),
        );

    /// Count indicator widget.
    Widget numberIndicator() => Padding(
          padding: EdgeInsets.only(top: 0.5),
          child: Selector<EpisodeState, int>(
            selector: (_, episodeState) => episodeState[episodeId].number,
            builder: (context, value, _) => Text(
              value.toString() + (layout == EpisodeGridLayout.large ? "|" : ""),
              style: GoogleFonts.teko(
                  textStyle: layout == EpisodeGridLayout.small
                      ? context.textTheme.labelMedium
                      : layout == EpisodeGridLayout.medium
                          ? context.textTheme.bodyMedium
                          : context.textTheme.bodyLarge),
            ),
          ),
        );

    /// Pubdate widget
    Widget pubDate(bool showNew) => Selector<EpisodeState, bool>(
          selector: (_, episodeState) =>
              showNew && episodeState[episodeId].isNew,
          builder: (context, value, _) => Text(
            episode.pubDate.toDate(context),
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: (layout == EpisodeGridLayout.small
                    ? context.textTheme.labelSmall
                    : context.textTheme.labelMedium)!
                .copyWith(
                    fontStyle: FontStyle.italic,
                    color: value
                        ? Colors.red
                        : episode.colorScheme(context).onSecondaryContainer),
          ),
        );
    return Container(
      decoration: BoxDecoration(
          borderRadius:
              _cardDecoration(context, episodeId, layout).borderRadius),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          decorate
              ? Container(
                  decoration: _cardDecoration(context, episodeId, layout,
                      selected: selected))
              : Center(),
          decorate
              ? FutureBuilder<PlayHistory>(
                  future: DBHelper().getPosition(episode),
                  builder: (context, snapshot) => _ProgressLowerlay(episodeId,
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
                        circleImage(
                          openPodcast,
                          preferEpisodeImage,
                          radius: layout == EpisodeGridLayout.small
                              ? layout.getRowHeight(context.width) / 7
                              : layout.getRowHeight(context.width) / 5,
                        ),
                        SizedBox(
                            width: layout == EpisodeGridLayout.small ? 2 : 5),
                        if (showNumber) numberIndicator(),
                        Spacer(),
                        pubDate(showNew),
                      ],
                    ),
                  ),
                Expanded(
                  flex: layout == EpisodeGridLayout.small ? 10 : 7,
                  child: layout == EpisodeGridLayout.large
                      ? Row(
                          children: [
                            circleImage(
                              openPodcast,
                              preferEpisodeImage,
                              radius:
                                  layout.getRowHeight(context.width) * 4 / 5,
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
                                        if (showNumber) numberIndicator(),
                                        podcastTitle(),
                                        Spacer(),
                                        pubDate(showNew),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 5, child: title()),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: <Widget>[
                                        if (showLiked) isLikedIndicator(),
                                        Spacer(),
                                        if (showLengthAndSize)
                                          lengthAndSize(context,
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
                      : title(),
                ),
                if (layout != EpisodeGridLayout.large)
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: <Widget>[
                        if (showLiked) isLikedIndicator(),
                        Spacer(),
                        if (showLengthAndSize)
                          lengthAndSize(context,
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
  final int episodeId;
  final double seekValue;
  final EpisodeGridLayout layout;
  final bool hide;
  final AnimationController? animator;
  const _ProgressLowerlay(this.episodeId, this.seekValue, this.layout,
      {this.hide = false, this.animator});

  @override
  Widget build(BuildContext context) {
    EpisodeState eState = Provider.of<EpisodeState>(context, listen: false);
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
                : eState[episodeId].progressIndicatorColor(context),
            backgroundColor: Colors.transparent,
            value: seekValue),
      ),
    );
  }
}

BoxDecoration _cardDecoration(
  BuildContext context,
  int episodeId,
  EpisodeGridLayout layout, {
  bool selected = false,
  AnimationController? controller,
  AnimationController?
      shadowController, // Hide shadow during expanding transition
}) {
  EpisodeState eState = Provider.of<EpisodeState>(context, listen: false);
  EpisodeBrief episode = eState[episodeId];
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

List<FocusedMenuItem> _menuItemList(BuildContext context, int episodeId,
    bool playing, bool inPlaylist, bool playerRunning, List<int> menuList,
    {bool applyToAllSelected = false}) {
  var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
  var episodeState = Provider.of<EpisodeState>(context, listen: false);
  var s = context.s;
  EpisodeState eState = Provider.of<EpisodeState>(context, listen: false);
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
            List<int> episodeIds = [episodeId];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodeIds = selectionController.selectedEpisodes;
            }
            await audio.loadEpisodesToQueue(episodeIds);
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
            List<int> episodeIds = [episodeId];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodeIds = selectionController.selectedEpisodes;
            }
            if (!inPlaylist) {
              await audio.addToPlaylist(episodeIds);
              await Fluttertoast.showToast(
                msg: s.toastAddPlaylist,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              await audio.removeFromPlaylist(episodeIds);
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
          title: eState[episodeId].isLiked ? Text(s.unlike) : Text(s.like),
          trailing: Icon(LineIcons.heart, color: Colors.red, size: 21),
          onPressed: () async {
            List<int> episodes = [episodeId];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodes = selectionController.selectedEpisodes;
            }
            if (eState[episodeId].isLiked) {
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
          title: eState[episodeId].isPlayed
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
            List<int> episodes = [episodeId];
            SelectionController? selectionController =
                Provider.of<SelectionController?>(context, listen: false);
            if (selectionController != null && applyToAllSelected) {
              episodes = selectionController.selectedEpisodes;
            }
            if (eState[episodeId].isPlayed) {
              episodeState.unsetPlayed(episodes);
              Fluttertoast.showToast(
                msg: s.markNotListened,
                gravity: ToastGravity.BOTTOM,
              );
            } else {
              episodeState.setPlayed(episodes);
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
          title: eState[episodeId].isDownloaded
              ? Text(s.downloaded,
                  style: TextStyle(
                      color: context.textColor.withValues(alpha: 0.5)))
              : Text(s.download),
          trailing: Icon(LineIcons.download, color: Colors.green),
          onPressed: () async {
            if (!eState[episodeId].isDownloaded) {
              List<int> episodes = [episodeId];
              SelectionController? selectionController =
                  Provider.of<SelectionController?>(context, listen: false);
              if (selectionController != null && applyToAllSelected) {
                episodes = selectionController.selectedEpisodes;
              }
              List<EpisodeBrief> selectedEpisodes =
                  episodes.map((i) => eState[i]).toList();
              await requestDownload(selectedEpisodes, context);
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
          List<int> episodeIds = [episodeId];
          SelectionController? selectionController =
              Provider.of<SelectionController?>(context, listen: false);
          if (selectionController != null && applyToAllSelected) {
            episodeIds = selectionController.selectedEpisodes;
          }
          audio.addToPlaylist(episodeIds,
              index: audio.playlist.length > 0 ? 1 : 0);
          Fluttertoast.showToast(
            msg: s.playNextDes,
            gravity: ToastGravity.BOTTOM,
          );
        },
      ),
  ];
}

Future<List<int>> _getEpisodeMenu() async {
  final popupMenuStorage = KeyValueStorage(
      episodePopupMenuKey); // TODO: These should be obtainable from SettingState.
  final list = await popupMenuStorage.getMenu();
  return list;
}
