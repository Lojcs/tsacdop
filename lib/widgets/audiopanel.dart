import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/state/audio_state.dart';

import '../util/extension_helper.dart';

enum SlideDirection { up, down }

class AudioPanel extends StatefulWidget {
  final Widget miniPanel;
  final Widget? midiPanel;
  final Widget maxiPanel;
  final double minHeight;
  final double midHeight;
  final double? maxHeight;

  AudioPanel(
      {required this.miniPanel,
      required this.maxiPanel,
      this.midiPanel,
      this.minHeight = 70,
      this.midHeight = 300,
      this.maxHeight,
      Key? key})
      : super(key: key);
  @override
  AudioPanelState createState() => AudioPanelState();
}

class AudioPanelState extends State<AudioPanel> with TickerProviderStateMixin {
  double? initSize;
  late double _startdy;
  double _move = 0;
  late AnimationController _controller;
  late AnimationController _slowController;
  late Animation _animation;
  SlideDirection? _slideDirection;

  @override
  void initState() {
    initSize = widget.minHeight;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() {
            if (mounted) setState(() {});
          });
    _slowController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..addListener(() {
            if (mounted) setState(() {});
          });
    if (Provider.of<AudioPlayerNotifier>(context, listen: false)
        .playerInitialStart) {
      _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
      _animatePanel(end: initSize, slow: true);
    } else {
      _animation =
          Tween<double>(begin: initSize, end: initSize).animate(_controller);
    }
    _slideDirection = SlideDirection.up;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _slowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Container(
        child: (_animation.value > widget.minHeight + 30)
            ? Positioned.fill(
                child: GestureDetector(
                  onTap: backToMini,
                  child: Container(
                    color: context.background.withOpacity(0.9 *
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
        child: GestureDetector(
          onVerticalDragStart: _start,
          onVerticalDragUpdate: _update,
          onVerticalDragEnd: _end,
          child: Container(
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
                              ? Colors.grey[400]!.withOpacity(0.5)
                              : Colors.grey[800]!,
                        ),
                        BoxShadow(
                          offset: Offset(-1, 0),
                          blurRadius: 1,
                          color: context.brightness == Brightness.light
                              ? Colors.grey[400]!.withOpacity(0.5)
                              : Colors.grey[800]!,
                        ),
                        BoxShadow(
                          offset: Offset(1, 0),
                          blurRadius: 1,
                          color: context.brightness == Brightness.light
                              ? Colors.grey[400]!.withOpacity(0.5)
                              : Colors.grey[800]!,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        height: math.max(widget.midHeight,
                            math.min(_animation.value, widget.maxHeight!)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(child: widget.maxiPanel),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.minHeight + 50 > _animation.value)
                  Opacity(
                    opacity: math.min(
                        1,
                        math.max(0,
                            (widget.minHeight + 50 - _animation.value) / 50)),
                    child: widget.miniPanel,
                  ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  backToMini() {
    _animatePanel(end: widget.minHeight, slow: true);
  }

  scrollToTop() {
    _animatePanel(end: widget.maxHeight, slow: true);
  }

  _animatePanel(
      {required double? end, bool slow = false, bool bounce = false}) {
    AnimationController controller = slow ? _slowController : _controller;
    controller.reset();
    _animation = Tween<double>(begin: _animation.value, end: end).animate(
        CurvedAnimation(
            parent: controller,
            curve: bounce ? Curves.easeOutBack : Curves.easeOutExpo));
    initSize = end;
    controller.forward();
  }

  _start(DragStartDetails event) {
    setState(() {
      _startdy = event.localPosition.dy;
      _animation =
          Tween<double>(begin: initSize, end: initSize).animate(_controller);
    });
  }

  _update(DragUpdateDetails event) {
    setState(() {
      _move = _startdy - event.localPosition.dy;
      _animation =
          Tween<double>(begin: initSize! + _move, end: initSize! + _move)
              .animate(_controller);
      _slideDirection = _move > 0 ? SlideDirection.up : SlideDirection.down;
    });
  }

  _end(DragEndDetails event) async {
    // Minimize / maximize on fast swipe
    if ((event.primaryVelocity ?? 0) > 3000) {
      _animatePanel(
          end: widget.minHeight,
          slow: initSize! > widget.midHeight ? true : false);
    } else if ((event.primaryVelocity ?? 0) < -3000) {
      _animatePanel(
          end: widget.maxHeight,
          slow: initSize! < widget.midHeight ? true : false);
    }
    // Return to position on small swipe
    else if (_move.abs() < 50) {
      _animatePanel(end: initSize, bounce: true);
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
  _AudioPanelRoute({this.expandPanel, this.height, Key? key}) : super(key: key);
  final Widget? expandPanel;
  final double? height;
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
              height: widget.height,
              decoration: BoxDecoration(
                color: context.primaryColor,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -1),
                    blurRadius: 1,
                    color: context.brightness == Brightness.light
                        ? Colors.grey[400]!.withOpacity(0.5)
                        : Colors.grey[800]!,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height: 300,
                  child: widget.expandPanel,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
