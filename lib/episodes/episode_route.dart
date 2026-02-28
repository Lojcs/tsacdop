import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/audio_state.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../util/predictive_back_page.dart';
import 'episode_card.dart';
import 'episode_detail.dart';
import '../util/extension_helper.dart';
import 'episode_info_widgets.dart';
import '../widgets/episodegrid.dart';

/// Helper class for storing hero data about episode info widgets.
class EpisodeHero<T extends State<StatefulWidget>> {
  final GlobalKey<T> key;

  EpisodeHero(this.key);

  Offset? initialOffset;
  Offset? finalOffset;
  late Tween<Offset> offsetTween;
  void setOffsetTween() => offsetTween =
      Tween(begin: initialOffset, end: finalOffset ?? initialOffset);

  Size? initialSize;
  Size? finalSize;
  late Tween<Size> sizeTween;
  void setSizeTween() =>
      sizeTween = Tween(begin: initialSize, end: finalSize ?? initialSize);

  void setInitial() {
    if (key.currentContext == null) return;
    final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    initialOffset = box.localToGlobal(Offset.zero);
    initialSize = box.size;
    setOffsetTween();
    setSizeTween();
  }

  void setFinal() {
    if (key.currentContext == null) return;
    final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    finalOffset = box.localToGlobal(Offset.zero);
    finalSize = box.size;
    setOffsetTween();
    setSizeTween();
  }
}

class NumberAndNameHero extends EpisodeHero<EpisodeNumberAndPodcastNameState> {
  NumberAndNameHero(super.key);

  TextStyle? initialStyle;
  TextStyle? finalStyle;
  late TextStyleTween styleTween;
  void setStyleTween() => styleTween =
      TextStyleTween(begin: initialStyle, end: finalStyle ?? initialStyle);

  bool? nameVisible;
  @override
  void setInitial() {
    if (key.currentContext == null) return;
    super.setInitial();
    initialStyle = key.currentState!.textStyle;
    setStyleTween();
    nameVisible = key.currentState!.widget.showName;
  }

  @override
  void setFinal() {
    if (key.currentContext == null) return;
    super.setFinal();
    finalStyle = key.currentState!.textStyle;
    setStyleTween();
  }
}

class TitleHero extends EpisodeHero<EpisodeTitleState> {
  TitleHero(super.key);

  TextStyle? initialStyle;
  TextStyle? finalStyle;
  late TextStyleTween styleTween;
  void setStyleTween() => styleTween =
      TextStyleTween(begin: initialStyle, end: finalStyle ?? initialStyle);

  @override
  void setInitial() {
    if (key.currentContext == null) return;
    super.setInitial();
    initialStyle = key.currentState!.textStyle;
    setStyleTween();
  }

  @override
  void setFinal() {
    if (key.currentContext == null) return;
    super.setFinal();
    finalStyle = key.currentState!.textStyle;
    setStyleTween();
  }
}

/// Route that animates an [EpisodeCard] into [EpisodeDetail].
class EpisodeCardDetailRoute extends ModalRoute {
  final int episodeId;
  final GlobalKey cardKey;
  final EpisodeGridLayout layout;
  final Widget card;
  final Widget cardLowerlay;

  final VoidCallback showCard;
  final VoidCallback hideCard;

  final RenderBox cardBox;

  final bool preferEpisodeImage;

  final GlobalKey avatarKey;
  final GlobalKey<EpisodeNumberAndPodcastNameState> numberAndNameKey;
  final GlobalKey<EpisodeTitleState> titleKey;
  final GlobalKey lengthAndSizeKey;
  final GlobalKey heartKey;

  final EpisodeHero cardHero;
  final EpisodeHero avatarHero;
  final NumberAndNameHero numberAndNameHero;
  final TitleHero titleHero;
  final EpisodeHero lengthAndSizeHero;
  final EpisodeHero heartHero;

  EpisodeCardDetailRoute(
    BuildContext context,
    this.episodeId, {
    required this.cardKey,
    required this.layout,
    required this.card,
    required this.cardLowerlay,
    required this.showCard,
    required this.hideCard,
    required this.preferEpisodeImage,
    required this.avatarKey,
    required this.numberAndNameKey,
    required this.titleKey,
    required this.lengthAndSizeKey,
    required this.heartKey,
  })  : cardBox = cardKey.currentContext!.findRenderObject() as RenderBox,
        cardHero = EpisodeHero(cardKey),
        avatarHero = EpisodeHero(avatarKey),
        numberAndNameHero = NumberAndNameHero(numberAndNameKey),
        titleHero = TitleHero(titleKey),
        lengthAndSizeHero = EpisodeHero(lengthAndSizeKey),
        heartHero = EpisodeHero(heartKey) {
    cardHero.setInitial();
    avatarHero.setInitial();
    numberAndNameHero.setInitial();
    titleHero.setInitial();
    lengthAndSizeHero.setInitial();
    heartHero.setInitial();

    hideCard();
  }

  @override
  void dispose() {
    done();
    super.dispose();
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  bool showHeroes = true;
  void done() {
    showCard();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        showHeroes = false;
      },
    );
  }

  EpisodeBrief? episode;

  ///
  late AudioPlayerNotifier audio;
  late double bottomSafeArea;

  /// Does the same thing as [offstage], but suitable for use in higher-level
  /// framework used here.
  bool fakeOffstage = true;

  void setFinals([bool force = false]) {
    if (force || animation!.isCompleted) {
      cardHero.setFinal();
      cardHero.finalSize = Size(
          cardHero.finalSize!.width,
          cardHero.finalSize!.height -
              (audio.playerRunning
                  ? audio.playerHeight!.height + bottomSafeArea
                  : 0));
      cardHero.setSizeTween();
    }
    avatarHero.setFinal();
    numberAndNameHero.setFinal();
    titleHero.setFinal();
    lengthAndSizeHero.setFinal();
    heartHero.setFinal();
    fakeOffstage = false;
    showHeroes = true;
  }

  @override
  bool didPop(result) {
    setFinals();
    return super.didPop(result);
  }

  @override
  void handleStartBackGesture({double progress = 0.0}) {
    assert(isCurrent);
    setFinals();
    super.controller?.value = 0.2 + 0.8 * progress;
    navigator?.didStartUserGesture();
  }

  @override
  void handleUpdateBackGestureProgress({required double progress}) {
    if (!isCurrent) {
      return;
    }
    super.controller?.value = 0.2 + 0.8 * progress;
  }

  @override
  void handleCancelBackGesture() {
    _handleDragEnd(animateForward: true);
  }

  @override
  void handleCommitBackGesture() {
    _handleDragEnd(animateForward: false);
  }

  /// The default implementation of this causes the animation to jump.
  void _handleDragEnd({required bool animateForward}) {
    if (isCurrent) {
      if (animateForward) {
        // Typically, handleUpdateBackGestureProgress will have already
        // completed the animation. If not, animate to completion.
        if (!super.controller!.isCompleted) {
          super.controller!.forward();
        }
      } else {
        // This route is destined to pop at this point. Reuse navigator's pop.

        // The popping may have finished inline if already at the target destination.
        if (super.controller?.isAnimating ?? false) {
          super.controller!.reverse(from: super.controller!.upperBound);
        }
        navigator?.pop();
      }
    }

    navigator?.didStopUserGesture();
  }

  int buildNumber = 0;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    audio = context.audioState;
    bottomSafeArea = context.originalPadding.bottom;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setFinals(true),
    );

    bool show = animation.isCompleted || fakeOffstage;
    Widget getChild() {
      buildNumber++;
      return EpisodeDetail(
        episodeId,
        cardKey: cardKey,
        avatarKey: avatarKey,
        numberAndNameKey: numberAndNameKey,
        titleKey: titleKey,
        lengthAndSizeKey: lengthAndSizeKey,
        heartKey: heartKey,
        hide: !show,
      );
    }

    Widget child = getChild();
    animation.addStatusListener(
      (status) {
        if (status.isDismissed) {
          done();
        }
      },
    );
    return PredictiveBackPage(
      route: this,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          if (show != animation.isCompleted || fakeOffstage) {
            show = animation.isCompleted || fakeOffstage;
            child = getChild();
          }
          return child;
        },
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    episode ??= context.episodeState[episodeId];
    final sizeAnimation =
        CurvedAnimation(parent: animation, curve: Curves.easeInOutCirc);
    final nameAnimation = numberAndNameHero.nameVisible!
        ? kAlwaysCompleteAnimation
        : sizeAnimation;
    final size = cardHero.sizeTween.evaluate(sizeAnimation);
    return Stack(
      children: [
        Transform.translate(
          offset: fakeOffstage
              ? Offset.zero
              : cardHero.offsetTween.evaluate(sizeAnimation),
          child: Container(
            decoration: episodeCardDecoration(context, episodeId, layout)
                .copyWith(
                    border: BoxBorder.all(width: 0, color: Colors.transparent),
                    color: episode!.isPlayed
                        ? episode!.progressIndicatorColor(context)
                        : null),
            clipBehavior: Clip.hardEdge,
            height: fakeOffstage || animation.isCompleted ? null : size.height,
            width: fakeOffstage || animation.isCompleted ? null : size.width,
            child: Offstage(
              offstage: fakeOffstage,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  fakeOffstage || animation.isCompleted
                      ? child
                      : FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            height: context.width * size.height / size.width,
                            width: context.width,
                            child: child,
                          ),
                        ),
                  if (!animation.isCompleted)
                    Opacity(
                      opacity: 1 - sizeAnimation.value,
                      child: ColoredBox(
                        color:
                            context.episodeState[episodeId].cardColor(context),
                      ),
                    ),
                  if (!animation.isCompleted)
                    Opacity(
                      opacity: 1 - sizeAnimation.value,
                      child: cardLowerlay,
                    ),
                  if (!animation.isCompleted)
                    Opacity(
                      opacity: 1 - sizeAnimation.value,
                      child: card,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showHeroes && !animation.isCompleted)
          Transform.translate(
            offset: numberAndNameHero.offsetTween.evaluate(sizeAnimation),
            child: EpisodeNumberAndPodcastName(
              episodeId,
              nameAnimation: nameAnimation,
              textStyle: numberAndNameHero.styleTween.evaluate(sizeAnimation),
            ),
          ),
        if (showHeroes && !animation.isCompleted)
          Transform.translate(
            offset: lengthAndSizeHero.offsetTween.evaluate(sizeAnimation),
            child: EpisodeLengthAndSize(
              episodeId,
              height:
                  lengthAndSizeHero.sizeTween.evaluate(sizeAnimation).height,
            ),
          ),
        if (showHeroes && !animation.isCompleted)
          Transform.translate(
            offset: titleHero.offsetTween.evaluate(sizeAnimation),
            child: SizedBox.fromSize(
              size: titleHero.sizeTween.evaluate(sizeAnimation),
              child: EpisodeTitle(
                episodeId,
                textStyle: titleHero.styleTween.evaluate(sizeAnimation),
              ),
            ),
          ),
        if (showHeroes &&
            !animation.isCompleted &&
            heartHero.initialOffset != null)
          Transform.translate(
            offset: heartHero.offsetTween.evaluate(sizeAnimation),
            child: SizedBox.fromSize(
              size: heartHero.sizeTween.evaluate(sizeAnimation),
              child: Icon(
                Icons.favorite,
                color: Colors.red,
                size: heartHero.sizeTween.evaluate(sizeAnimation).width,
              ),
            ),
          ),
        if (showHeroes && !animation.isCompleted)
          Transform.translate(
            offset: avatarHero.offsetTween.evaluate(sizeAnimation),
            child: SizedBox.fromSize(
              size: avatarHero.sizeTween.evaluate(sizeAnimation),
              child: CircleAvatar(
                radius: avatarHero.sizeTween.evaluate(sizeAnimation).width / 2,
                backgroundImage: preferEpisodeImage
                    ? episode!.episodeOrPodcastImageProvider
                    : episode!.podcastImageProvider,
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool get maintainState => false;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
}
