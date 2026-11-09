import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/extension/extension_helper.dart';
import '../../../episode/grid/widget/episode_grid.dart';
import '../../../player/widget/audio_panel.dart';
import '../../../podcast/state/podcast_state.dart';
import '../../../settings/state/setting_state.dart';
import '../../card/widget/group_card.dart';
import '../../model/podcast_group.dart';

class GroupCarousel extends StatelessWidget {
  const GroupCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _groupCarouselHeight,
      child: Selector<PodcastState, int>(
        selector: (_, pState) => pState.groupCount,
        builder: (context, count, _) => _StackedCarousel(
          indexCount: count,
          getWidgetAt: (index) => Selector<PodcastState, String>(
            selector: (_, pState) => pState.getGroupIdAt(index),
            builder: (context, id, _) =>
                GroupCard(groupId: id, key: ValueKey(id)),
          ),
        ),
      ),
    );
  }
}

class _StackedCarousel extends StatefulWidget {
  final int indexCount;
  final int index;
  final Widget Function(int index) getWidgetAt;

  const _StackedCarousel({
    super.key,
    required this.indexCount,
    this.index = 0,
    required this.getWidgetAt,
  });
  @override
  State<_StackedCarousel> createState() => _StackedCarouselState();
}

const double _groupCardHeight = 300;
const double _groupCardHalfHeight = _groupCardHeight * 0.5;
const double _inverseGroupCardHeight = 1 / _groupCardHeight;
const double _groupCardPadding = 10;
const double _groupCarouselHeight = _groupCardHeight + _groupCardPadding * 2;
Matrix4Tween _cardLeaveTween = Matrix4Tween(
  begin: .identity(),
  end: .rotationX(math.pi * 0.5)
    ..translateByDouble(0, _groupCardHalfHeight, 0, 0),
);
Matrix4Tween _cardStackTween = Matrix4Tween(
  begin: .identity()..scaleByDouble(0.8, 0.8, 1, 1),
  end: .identity(),
);
Matrix4Tween _cardLeaveTweenReverse = Matrix4Tween(
  begin: _cardLeaveTween.end,
  end: _cardLeaveTween.begin,
);
Matrix4Tween _cardStackTweenReverse = Matrix4Tween(
  begin: _cardStackTween.end,
  end: _cardStackTween.begin,
);

enum _StackedCarouselTarget { next, prev }

class _StackedCarouselState extends State<_StackedCarousel>
    with SingleTickerProviderStateMixin {
  late int index = widget.index;

  late final snapshotController = SnapshotController();

  late final controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 300),
  );
  late final _animationNormal = CurvedAnimation(
    parent: controller,
    curve: Curves.easeInOut,
  );
  late final _animationBouncy = CurvedAnimation(
    parent: controller,
    curve: Curves.easeOutBack,
  );
  late Animation<double> animation = _animationNormal;
  late Matrix4Tween topCardTween = _cardLeaveTween;
  late Matrix4Tween bottomCardTween = _cardStackTween;

  double swipeStartY = 0;
  double effectiveSwipeStartY = 0;
  double swipeDistance = 0;

  Widget getChildAt(int index) => widget.getWidgetAt(index % widget.indexCount);

  GlobalKey bottomCardKey = GlobalKey();
  GlobalKey topCardKey = GlobalKey();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MatrixTransition(
          animation: animation,
          onTransform: bottomCardTween.transform,
          alignment: .bottomCenter,
          child: SnapshotWidget(
            key: bottomCardKey,
            controller: snapshotController,
            child: getChildAt(index + 1),
          ),
        ),
        MatrixTransition(
          animation: animation,
          onTransform: topCardTween.transform,
          alignment: .bottomCenter,
          child: SnapshotWidget(
            key: topCardKey,
            controller: snapshotController,
            child: getChildAt(index),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: prevIndex,
              icon: Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              onPressed: nextIndex,
              icon: Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
        Positioned.fill(
          child: GestureDetector(
            onVerticalDragStart: start,
            onVerticalDragUpdate: update,
            onVerticalDragEnd: end,
          ),
        ),
      ],
    );
  }

  void resetTweens() {
    bottomCardTween = _cardStackTween;
    topCardTween = _cardLeaveTween;
  }

  void animatePanel({
    required _StackedCarouselTarget target,
    bool bounce = false,
  }) {
    if (target == .prev) {
      controller.addStatusListener(finishAnimating);
      if (controller.value % 1 == 0) {
        snapshotController.clear();
        snapshotController.allowSnapshotting = true;
        index--;
        bottomCardTween = _cardLeaveTweenReverse;
        topCardTween = _cardLeaveTweenReverse;
      } else {
        bottomCardTween = Matrix4Tween(
          begin: bottomCardTween.transform(animation.value),
          end: _cardStackTween.begin,
        );
        topCardTween = Matrix4Tween(
          begin: topCardTween.transform(animation.value),
          end: _cardLeaveTween.begin,
        );
      }
    } else {
      controller.addStatusListener(autoIncrement);
      if (controller.value % 1 == 0) {
        snapshotController.clear();
        snapshotController.allowSnapshotting = true;
        resetTweens();
      } else {
        bottomCardTween = Matrix4Tween(
          begin: bottomCardTween.transform(animation.value),
          end: _cardStackTween.end,
        );
        topCardTween = Matrix4Tween(
          begin: topCardTween.transform(animation.value),
          end: _cardLeaveTween.end,
        );
      }
    }
    controller.value = 0;
    controller.forward();
    if (bounce) animation = _animationBouncy;
    setState(() {});
  }

  void finishAnimating(AnimationStatus status) {
    if (status.isCompleted) {
      resetTweens();
      controller.reset();
      snapshotController.allowSnapshotting = false;
      controller.removeStatusListener(finishAnimating);
      setState(() {});
    }
  }

  void autoDecrement(AnimationStatus status) {
    if (status.isCompleted) {
      print("Auto decremented.");
      index--;
      resetTweens();
      controller.reset();
      snapshotController.allowSnapshotting = false;
      controller.removeStatusListener(autoDecrement);
      setState(() {});
    }
  }

  void autoIncrement(AnimationStatus status) {
    if (status.isCompleted) {
      print("Auto incremented.");
      index++;
      resetTweens();
      controller.reset();
      snapshotController.allowSnapshotting = false;
      controller.removeStatusListener(autoIncrement);
      setState(() {});
    }
  }

  void prevIndex() => animatePanel(target: .prev);
  void nextIndex() => animatePanel(target: .next);

  void start(DragStartDetails event) {
    snapshotController.clear();
    snapshotController.allowSnapshotting = true;
    setState(() {
      swipeStartY = event.localPosition.dy;
      effectiveSwipeStartY = event.localPosition.dy;
      animation = _animationNormal;
    });
  }

  void update(DragUpdateDetails event) {
    setState(() {
      swipeDistance = event.localPosition.dy - swipeStartY;
      var value = swipeDistance * _inverseGroupCardHeight;
      if (value < 0) {
        print("Wrapped back");
        value++;
        bottomCardKey = topCardKey;
        topCardKey = GlobalKey();
        swipeStartY -= _groupCardHeight;
        index = (index - 1) % widget.indexCount;
      } else if (value > 1) {
        print("Wrapped forward");
        value--;
        topCardKey = bottomCardKey;
        bottomCardKey = GlobalKey();
        swipeStartY += _groupCardHeight;
        index = (index + 1) % widget.indexCount;
      }
      controller.value = value;
    });
  }

  void end(DragEndDetails event) async {
    if ((event.primaryVelocity ?? 0) < -300) {
      prevIndex();
    } else if ((event.primaryVelocity ?? 0) > 300) {
      nextIndex();
    } else if (swipeDistance < _groupCardHalfHeight) {
      print("Go back");
      prevIndex();
    } else if (swipeDistance >= _groupCardHalfHeight) {
      print("Complete");
      nextIndex();
    }
  }
}
