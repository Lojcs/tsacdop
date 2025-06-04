import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart' as tuple;

import '../home/audioplayer.dart';
import '../state/audio_state.dart';
import '../util/extension_helper.dart';

class HidePlayerRoute extends ModalRoute<void> {
  HidePlayerRoute(this.openPage, [this.transitionPage])
      : transitionDuration = const Duration(milliseconds: 300);
  final Widget openPage;
  final Widget? transitionPage;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    Key pageKey = GlobalKey();
    return Selector<AudioPlayerNotifier, tuple.Tuple2<bool, PlayerHeight?>>(
      selector: (_, audio) =>
          tuple.Tuple2(audio.playerRunning, audio.playerHeight),
      builder: (_, data, __) => Align(
        alignment: Alignment.topLeft,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            if (animation.isCompleted) {
              return KeyedSubtree(key: pageKey, child: openPage);
            }
            // final Animation<double> curvedAnimation = CurvedAnimation(
            //   parent: animation,
            //   curve: Curves.fastOutSlowIn,
            //   reverseCurve: Curves.fastOutSlowIn.flipped,
            // );
            final playerHeight = kMinPlayerHeight[data.item2!.index];
            final playerRunning = data.item1;
            return Transform.translate(
              offset: Offset(
                  context.width *
                      (1 - Curves.easeOut.transform(animation.value)),
                  0),
              child: Container(
                width: context.width,
                height: context.height -
                    (playerRunning
                        ? playerHeight + MediaQuery.of(context).padding.bottom
                        : 0),
                decoration: BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: context.width,
                    height: context.height,
                    child: KeyedSubtree(
                      key: pageKey,
                      child: transitionPage ?? openPage,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  final Duration transitionDuration;
}
