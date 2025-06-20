import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/audio_state.dart';
import '../util/extension_helper.dart';

enum SlideDirection { up, down }

class AudioPanel extends StatefulWidget {
  final Widget miniPanel;
  final Widget? midiPanel;
  final Widget maxiPanel;
  final double minHeight;
  final double midHeight;
  final double? maxHeight;

  const AudioPanel(
      {required this.miniPanel,
      required this.maxiPanel,
      this.midiPanel,
      this.minHeight = 70,
      this.midHeight = 300,
      this.maxHeight,
      super.key});
  @override
  AudioPanelState createState() => AudioPanelState();
}

class AudioPanelState extends State<AudioPanel> with TickerProviderStateMixin {
  double? size;
  late double _startdy;
  bool _dragStarted = false;
  double _move = 0;
  late AnimationController _controller;
  late AnimationController _slowController;
  late Animation _animation;
  SlideDirection? _slideDirection;

  ScrollNotification? _lastScrollNotification;

  @override
  void initState() {
    super.initState();
    size = widget.minHeight;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 175))
          ..addListener(() {
            if (mounted) setState(() {});
          });
    _slowController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 350))
          ..addListener(() {
            if (mounted) setState(() {});
          });
    if (Provider.of<AudioPlayerNotifier>(context, listen: false)
        .playerInitialStart) {
      Provider.of<AudioPlayerNotifier>(context, listen: false)
          .playerInitialStart = false;
      _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
      _animatePanel(end: size, slow: true);
    } else {
      _animation = Tween<double>(begin: size, end: size).animate(_controller);
    }
    _slideDirection = SlideDirection.up;
  }

  @override
  void dispose() {
    _controller.dispose();
    _slowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          child: (_animation.value > widget.minHeight + 30)
              ? Positioned.fill(
                  child: GestureDetector(
                    onTap: backToMini,
                    child: Container(
                      color: context.surface.withValues(
                          alpha: 0.4 *
                              math.min(
                                  (_animation.value - widget.minHeight) /
                                      widget.midHeight,
                                  1)),
                    ),
                  ),
                )
              : Center(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (_lastScrollNotification != notification) {
                _lastScrollNotification = notification;
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null &&
                    notification.metrics.pixels ==
                        notification.metrics.minScrollExtent) {
                  _dragStarted = true;
                  _start(notification.dragDetails!);
                } else if (_dragStarted) {
                  if (notification is OverscrollNotification &&
                      notification.dragDetails != null) {
                    if (!_animation.isAnimating) {
                      _update(notification.dragDetails!);
                    }
                  } else if (notification is ScrollUpdateNotification &&
                      notification.dragDetails != null) {
                    if (!_animation.isAnimating) {
                      _update(notification.dragDetails!);
                    }
                  } else if (notification is ScrollEndNotification &&
                      !_animation.isAnimating &&
                      _animation.value != widget.maxHeight &&
                      _animation.value != widget.midHeight) {
                    _dragStarted = false;
                    if (notification.dragDetails != null) {
                      _end(notification.dragDetails!);
                    } else {
                      _end(DragEndDetails(
                          velocity: Velocity(pixelsPerSecond: Offset(0, -3001)),
                          primaryVelocity: -3001));
                    }
                  }
                }
              }
              return true;
            },
            child: GestureDetector(
              onVerticalDragStart: _start,
              onVerticalDragUpdate: _update,
              onVerticalDragEnd: _end,
              child: SizedBox(
                height: _animation.value < 0 ? 0 : _animation.value,
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Opacity(
                      opacity: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(context.width / 15),
                              topRight: Radius.circular(context.width / 15)),
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(0, -1),
                              blurRadius: 1,
                              color: context.brightness == Brightness.light
                                  ? Colors.grey[400]!.withValues(alpha: 0.5)
                                  : !context.realDark
                                      ? Colors.grey[900]!
                                      : Colors.grey[800]!,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                              height: math.max(
                                  widget.midHeight,
                                  math.min(
                                      _animation.value, widget.maxHeight!)),
                              child: widget.maxiPanel),
                        ),
                      ),
                    ),
                    if (widget.minHeight + 50 > _animation.value)
                      Opacity(
                        opacity:
                            ((widget.minHeight + 50 - _animation.value) / 50)
                                .clamp(0, 1),
                        child: widget.miniPanel,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void backToMini() {
    _animatePanel(end: widget.minHeight, slow: true);
  }

  void scrollToTop() {
    _animatePanel(end: widget.maxHeight, slow: true);
  }

  void _animatePanel(
      {required double? end, bool slow = false, bool bounce = false}) {
    AnimationController controller = slow ? _slowController : _controller;
    controller.reset();
    _animation = Tween<double>(begin: _animation.value, end: end).animate(
        CurvedAnimation(
            parent: controller,
            curve: bounce ? Curves.easeOutBack : Curves.easeOutQuad));
    size = end;
    controller.forward();
  }

  void _start(DragStartDetails event) {
    setState(() {
      _startdy = event.localPosition.dy;
      _animation = Tween<double>(begin: size, end: size).animate(_controller);
    });
  }

  void _update(DragUpdateDetails event) {
    setState(() {
      _move = _startdy - event.localPosition.dy;
      _animation = Tween<double>(begin: size! + _move, end: size! + _move)
          .animate(_controller);
      _slideDirection = _move > 0 ? SlideDirection.up : SlideDirection.down;
    });
  }

  void _end(DragEndDetails event) async {
    // Minimize / maximize on fast swipe
    if ((event.primaryVelocity ?? 0) > 3000) {
      _animatePanel(
          end: widget.minHeight, slow: size! > widget.midHeight ? true : false);
    } else if ((event.primaryVelocity ?? 0) < -3000) {
      _animatePanel(
          end: widget.maxHeight, slow: size! < widget.midHeight ? true : false);
    }
    // Return to position on small swipe
    else if (_move.abs() < 50) {
      _animatePanel(end: size, bounce: true);
    }
    // Move one step based on ongoing swipe, or total movement. Ignore small velocities to resist shaky hands
    else if ((event.primaryVelocity ?? 0) < -300 ||
        ((event.primaryVelocity ?? 0) <= 300 &&
            _slideDirection == SlideDirection.up)) {
      if (_animation.value > widget.midHeight) {
        _animatePanel(end: widget.maxHeight);
      } else {
        _animatePanel(end: widget.midHeight);
      }
    } else if ((event.primaryVelocity ?? 0) > 300 ||
        _slideDirection == SlideDirection.down) {
      if (_animation.value > widget.midHeight) {
        _animatePanel(end: widget.midHeight);
      } else {
        _animatePanel(end: widget.minHeight);
      }
    }
  }
}

class _AudioPanelRoute extends StatefulWidget {
  const _AudioPanelRoute({super.key});
  @override
  __AudioPanelRouteState createState() => __AudioPanelRouteState();
}

class __AudioPanelRouteState extends State<_AudioPanelRoute> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        body: Stack(children: <Widget>[
          Container(
            child: Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                // child:
                // Container(
                //   color: Theme.of(context)
                //       .background
                //       .withOpacity(0.8),
                //
                //),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: context.primaryColor,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -1),
                    blurRadius: 1,
                    color: context.brightness == Brightness.light
                        ? Colors.grey[400]!.withValues(alpha: 0.5)
                        : Colors.grey[800]!,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height: 300,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class AudioPanelInnerNotification extends Notification {
  ScrollController scrollController;
  AudioPanelInnerNotification(this.scrollController);
}
