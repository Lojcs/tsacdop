import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'episode_detail.dart';
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
import '../util/selection_controller.dart';
import '../widgets/custom_widget.dart';
import 'episode_info_widgets.dart';
import '../widgets/episodegrid.dart';
import 'episode_route.dart';

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

  late final avatarKey = GlobalKey();
  late final numberAndNameKey = GlobalKey<EpisodeNumberAndPodcastNameState>();
  late final titleKey = GlobalKey<EpisodeTitleState>();
  late final lengthAndSizeKey = GlobalKey();
  late final heartKey = GlobalKey();

  late Widget progressLowerlay =
      Selector2<AudioPlayerNotifier, EpisodeState, (bool, double)>(
    selector: (_, audio, eState) {
      if (audio.episodeId == widget.episodeId && audio.playerRunning) {
        return (false, audio.seekSliderValue);
      } else if (eState[widget.episodeId].isPlayed) {
        return (false, 1);
      } else {
        return (true, 0);
      }
    },
    builder: (_, data, __) => FutureBuilder<double>(
      future: Future(
        () async => data.$1 ? (await _getSavedPosition()).seekValue! : data.$2,
      ),
      // initialData: PlayHistory("", "", 0, 0),
      builder: (context, snapshot) => ProgressLowerlay(
        widget.episodeId,
        snapshot.hasData ? snapshot.data! : 0,
        widget.layout,
        animator: _controller,
      ),
    ),
  );

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
        showLiked: widget.showLiked,
        showNew: widget.showNew,
        showLengthAndSize: widget.showLengthAndSize,
        showPlayedAndDownloaded: widget.showPlayedAndDownloaded,
        showDate: widget.showDate,
        decorate: false,
        avatarKey: avatarKey,
        numberAndNameKey: numberAndNameKey,
        titleKey: titleKey,
        lengthAndSizeKey: lengthAndSizeKey,
        heartKey: heartKey,
        onTapDown: () => avatarHasFocus = true,
        onTapUp: () => Future.delayed(
            Duration(milliseconds: 6), () => avatarHasFocus = false),
        hide: hideImage,
        key: hideImage ? null : cardKey,
      );

  void openDetails(BuildContext context) => Navigator.push(
        context,
        EpisodeCardDetailRoute(
          context,
          widget.episodeId,
          cardKey: cardKey,
          layout: widget.layout,
          card: _cardBuilder(true),
          cardLowerlay: progressLowerlay,
          preferEpisodeImage: widget.preferEpisodeImage,
          avatarKey: avatarKey,
          numberAndNameKey: numberAndNameKey,
          titleKey: titleKey,
          lengthAndSizeKey: lengthAndSizeKey,
          heartKey: heartKey,
          showCard: () {
            // _shadowController.reverse();
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
    // if (hideCard) return Center();
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
          // _shadowController.forward();
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
        // _shadowController.forward();
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
          final audio = context.audioState;
          menuItemList = _menuItemList(
              context,
              widget.episodeId,
              audio.episodeId == widget.episodeId,
              audio.playlist.contains(widget.episodeId),
              audio.playerRunning,
              await _getEpisodeMenu(),
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
      childLowerlay: progressLowerlay,
      controller: _controller,
      shadowController: _shadowController,
      child: hideCard ? Center() : _cardBuilder(false),
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
      pattern: [32, 20, 4],
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
      this.initData,
      super.key});
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
      childDecoration: episodeCardDecoration(
          context, widget.episodeId, widget.layout,
          controller: widget.controller,
          shadowController: widget.shadowController),
      openChildDecoration: episodeCardDecoration(
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

  /// Key for the EpisodeNumberAndPodcastName widget
  final GlobalKey? numberAndNameKey;

  /// Key for the EpisodeTitle widget
  final GlobalKey? titleKey;

  /// Key for the EpisodeLengthAndSize widget
  final GlobalKey? lengthAndSizeKey;

  /// Key for the isLiked indicator
  final GlobalKey? heartKey;

  /// Callback that disables card gesture callbacks
  final VoidCallback? onTapDown;

  /// Callback that reenables card gesture callbacks
  final VoidCallback? onTapUp;

  final bool hide;

  const EpisodeCard(
    this.episodeId,
    this.layout, {
    super.key,
    this.openPodcast = false,
    this.showImage = true,
    this.preferEpisodeImage = false,
    this.showLiked = true,
    this.showNew = true,
    this.showLengthAndSize = true,
    this.showPlayedAndDownloaded = true,
    this.showDate = false,
    this.selected = false,
    this.decorate = true,
    this.avatarKey,
    this.numberAndNameKey,
    this.titleKey,
    this.lengthAndSizeKey,
    this.heartKey,
    this.onTapDown,
    this.onTapUp,
    this.hide = false,
  });

  @override
  Widget build(BuildContext context) {
    /// EpisodeBrief for convenience, don't use for value that might change
    EpisodeBrief episode =
        Provider.of<EpisodeState>(context, listen: false)[episodeId];

    /// Episode title widget.
    Widget title() => hide
        ? Center()
        : Container(
            alignment: layout == EpisodeGridLayout.large
                ? Alignment.centerLeft
                : Alignment.topLeft,
            child: EpisodeTitle(
              episodeId,
              textStyle: (layout == EpisodeGridLayout.small
                  ? context.textTheme.bodySmall
                  : context.textTheme.bodyMedium)!,
              maxLines: layout == EpisodeGridLayout.small
                  ? 4
                  : layout == EpisodeGridLayout.medium
                      ? 3
                      : 2,
              key: titleKey,
            ),
          );

    /// Circle avatar widget.
    Widget circleImage(
      bool openPodcast,
      bool preferEpisodeImage, {
      required double radius,
    }) =>
        hide
            ? SizedBox(width: radius)
            : EpisodeAvatar(
                episodeId,
                radius: radius,
                preferEpisodeImage: preferEpisodeImage,
                openPodcast: openPodcast,
                onTapDown: onTapDown,
                onTapUp: onTapUp,
                key: avatarKey,
              );

    /// Liked indicator widget.
    Widget isLikedIndicator() => Align(
          alignment: Alignment.center,
          child: Selector<EpisodeState, bool>(
            selector: (_, episodeState) => episodeState[episodeId].isLiked,
            builder: (context, value, _) => value && !hide
                ? Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: layout == EpisodeGridLayout.small
                        ? context.textTheme.bodySmall!.fontSize
                        : context.textTheme.bodyLarge!.fontSize,
                    key: heartKey,
                  )
                : Center(),
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
              episodeCardDecoration(context, episodeId, layout).borderRadius),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          decorate
              ? Container(
                  decoration: episodeCardDecoration(context, episodeId, layout,
                      selected: selected))
              : Center(),
          decorate
              ? FutureBuilder<PlayHistory>(
                  future: DBHelper().getPosition(episode),
                  builder: (context, snapshot) => ProgressLowerlay(episodeId,
                      snapshot.hasData ? snapshot.data!.seekValue! : 0, layout,
                      hide: selected))
              : Center(),
          Padding(
            padding: EdgeInsets.all(layout == EpisodeGridLayout.small ? 6 : 8)
                .copyWith(bottom: layout == EpisodeGridLayout.small ? 8 : 8),
            child: Row(
              children: [
                if (layout == EpisodeGridLayout.large)
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 5),
                    child: circleImage(
                      openPodcast,
                      preferEpisodeImage,
                      radius: layout.getRowHeight(context.width) * 4 / 5,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: layout != EpisodeGridLayout.large ? 30 : 16,
                        // width: context.width -
                        //     layout.getRowHeight(context.width) * 4 / 5 -
                        //     120,
                        child: Stack(
                          children: [
                            Row(
                              children: <Widget>[
                                if (layout != EpisodeGridLayout.large)
                                  circleImage(
                                    openPodcast,
                                    preferEpisodeImage,
                                    radius: layout == EpisodeGridLayout.small
                                        ? layout.getRowHeight(context.width) / 7
                                        : layout.getRowHeight(context.width) /
                                            5,
                                  ),
                                if (layout != EpisodeGridLayout.large)
                                  SizedBox(
                                      width: layout == EpisodeGridLayout.small
                                          ? 2
                                          : 5),
                                if (!hide)
                                  EpisodeNumberAndPodcastName(
                                    episodeId,
                                    showName: layout == EpisodeGridLayout.large,
                                    key: numberAndNameKey,
                                  ),
                              ],
                            ),
                            Align(
                              alignment: AlignmentGeometry.centerRight,
                              child: pubDate(showNew),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: title(),
                      ),
                      SizedBox(
                        height: 24,
                        child: Row(
                          children: <Widget>[
                            if (showLiked) isLikedIndicator(),
                            Spacer(),
                            if (showLengthAndSize && !hide)
                              EpisodeLengthAndSize(
                                episodeId,
                                showPlayedAndDownloaded:
                                    showPlayedAndDownloaded,
                                key: lengthAndSizeKey,
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressLowerlay extends StatelessWidget {
  final int episodeId;
  final double seekValue;
  final EpisodeGridLayout layout;
  final bool hide;
  final AnimationController? animator;
  const ProgressLowerlay(this.episodeId, this.seekValue, this.layout,
      {super.key, this.hide = false, this.animator});

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

BoxDecoration episodeCardDecoration(
  BuildContext context,
  int episodeId,
  EpisodeGridLayout layout, {
  bool selected = false,
  AnimationController? controller,
  AnimationController?
      shadowController, // Hide shadow during expanding transition
}) {
  EpisodeBrief episode = context.episodeState[episodeId];
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
              List<int> episodeIds = [episodeId];
              SelectionController? selectionController =
                  Provider.of<SelectionController?>(context, listen: false);
              if (selectionController != null && applyToAllSelected) {
                episodeIds = selectionController.selectedEpisodes;
              }
              await context.downloadState.requestDownload(context, episodeIds);
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
