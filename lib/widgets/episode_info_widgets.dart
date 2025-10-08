import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/episode_state.dart';
import '../util/extension_helper.dart';
import 'custom_dropdown.dart';
import 'episodegrid.dart';

/// Widget that shows the length, size properties and optionally the
/// played, downloaded status of the episode.
/// Sized itself based on height and width.
class EpisodeLengthAndSize extends StatefulWidget {
  final int episodeId;
  final bool showPlayedAndDownloaded;
  final double? height;
  final double? width;
  final bool fill;
  const EpisodeLengthAndSize(this.episodeId,
      {this.showPlayedAndDownloaded = true,
      this.height,
      this.width,
      this.fill = false,
      super.key});

  @override
  State<EpisodeLengthAndSize> createState() => _EpisodeLengthAndSizeState();
}

class _EpisodeLengthAndSizeState extends State<EpisodeLengthAndSize> {
  final double defaultHeight = 24;
  final double defaultWidth = 72;
  final double defaultCornerRadius = 7.2;
  late double scale;
  late double textScale;
  late double targetHeight;
  late double targetWidth;
  late double targetCornerRadius;

  void calculateScales() {
    scale = switch ((widget.height, widget.width)) {
      (null, null) => 1,
      (null, var width!) => width / defaultWidth,
      (var height!, null) => height / defaultHeight,
      (var height!, var width!) =>
        math.min(height / defaultHeight, width / defaultWidth)
    };
    textScale = math.sqrt(scale);
    targetHeight = defaultHeight * scale;
    targetWidth = defaultWidth * scale;
    targetCornerRadius = defaultCornerRadius * scale;
  }

  @override
  void initState() {
    super.initState();
    calculateScales();
  }

  @override
  void didUpdateWidget(covariant EpisodeLengthAndSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height || oldWidget.width != widget.width) {
      calculateScales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final episode =
        Provider.of<EpisodeState>(context, listen: false)[widget.episodeId];
    final colorScheme = episode.colorScheme(context);
    final cardColorScheme = episode.cardColorScheme(context);
    BorderSide side = BorderSide(
        color: context.realDark
            ? Colors.transparent
            : colorScheme.onSecondaryContainer,
        width: 1);
    BorderSide innerSide =
        BorderSide(color: colorScheme.onSecondaryContainer, width: 1);
    Color backgroundColor = context.realDark
        ? colorScheme.secondaryContainer
        : colorScheme.onSecondaryContainer;
    return Selector<EpisodeState,
        ({int duration, int size, bool played, bool downloaded})>(
      selector: (_, episodeState) => (
        duration: episodeState[widget.episodeId].enclosureDuration,
        size: episodeState[widget.episodeId].enclosureSize,
        played: episodeState[widget.episodeId].isPlayed,
        downloaded: episodeState[widget.episodeId].isDownloaded,
      ),
      builder: (context, value, _) => Row(
        children: [
          if (value.duration != 0)
            Container(
              height: targetHeight,
              width: targetWidth / 2,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(targetCornerRadius),
                      right: value.size == 0
                          ? Radius.circular(targetCornerRadius)
                          : Radius.zero),
                  border: Border.fromBorderSide(side),
                  color: widget.showPlayedAndDownloaded && value.played
                      ? backgroundColor
                      : widget.fill
                          ? cardColorScheme.card
                          : Colors.transparent),
              foregroundDecoration: context.realDark
                  ? BoxDecoration(
                      borderRadius: BorderRadius.horizontal(
                          right: value.size == 0
                              ? Radius.circular(targetCornerRadius)
                              : Radius.zero),
                      border: value.size == 0 ||
                              (widget.showPlayedAndDownloaded &&
                                  (value.played || value.downloaded))
                          ? null
                          : Border(right: innerSide),
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                value.duration.toTime,
                textScaler: TextScaler.linear(textScale),
                style: context.textTheme.labelSmall!.copyWith(
                    color: widget.showPlayedAndDownloaded &&
                            !context.realDark &&
                            value.played
                        ? colorScheme.secondaryContainer
                        : colorScheme.onSecondaryContainer),
              ),
            ),
          if (value.size != 0)
            Container(
              height: targetHeight,
              width: targetWidth / 2,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(targetCornerRadius),
                      left: value.duration == 0
                          ? Radius.circular(targetCornerRadius)
                          : Radius.zero),
                  border: value.duration == 0
                      ? Border.fromBorderSide(side)
                      : Border(top: side, right: side, bottom: side),
                  color: widget.showPlayedAndDownloaded && value.played
                      ? backgroundColor
                      : widget.fill
                          ? cardColorScheme.card
                          : Colors.transparent),
              alignment: Alignment.center,
              child: Text(
                '${value.size ~/ 1000000}MB',
                textScaler: TextScaler.linear(textScale),
                style: context.textTheme.labelSmall!.copyWith(
                    color: widget.showPlayedAndDownloaded &&
                            !context.realDark &&
                            value.downloaded
                        ? colorScheme.secondaryContainer
                        : colorScheme.onSecondaryContainer),
              ),
            ),
        ],
      ),
    );
  }
}

class EpisodeNumberAndPodcastName extends StatefulWidget {
  final int episodeId;
  final bool showName;
  final TextStyle? textStyle;
  const EpisodeNumberAndPodcastName(this.episodeId,
      {this.showName = true, this.textStyle, super.key});

  @override
  State<EpisodeNumberAndPodcastName> createState() =>
      EpisodeNumberAndPodcastNameState();
}

class EpisodeNumberAndPodcastNameState
    extends State<EpisodeNumberAndPodcastName>
    with SingleTickerProviderStateMixin {
  TextStyle get textStyle => widget.textStyle ?? context.textTheme.bodyLarge!;

  late final nameAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
      value: widget.showName ? 1 : 0);
  late final nameAnimation = CurvedAnimation(
      parent: nameAnimationController,
      curve: Curves.easeInCirc,
      reverseCurve: Curves.easeInCirc);
  @override
  void didUpdateWidget(covariant EpisodeNumberAndPodcastName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showName) {
      nameAnimationController.forward();
    } else {
      nameAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    nameAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final episode =
        Provider.of<EpisodeState>(context, listen: false)[widget.episodeId];
    return ScrollConfiguration(
        behavior: NoOverscrollScrollBehavior(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: NeverScrollableScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: textStyle.fontSize! / 10), // Teko baseline fix
                child: Text(
                  episode.number.toString(),
                  style: GoogleFonts.teko(textStyle: textStyle),
                ),
              ),
              AnimatedBuilder(
                animation: nameAnimation,
                builder: (context, child) => nameAnimation.value == 0
                    ? Center()
                    : Opacity(
                        opacity: nameAnimation.value,
                        child: Text(
                          "|${episode.podcastTitle}",
                          style: textStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: episode
                                  .colorScheme(context)
                                  .onSecondaryContainer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ],
          ),
        ));
  }
}

/// Episode title widget.
// class EpisodeTitle extends StatelessWidget {
//   const EpisodeTitle({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       alignment: layout == EpisodeGridLayout.large
//           ? Alignment.centerLeft
//           : Alignment.topLeft,
//       padding: EdgeInsets.only(top: layout == EpisodeGridLayout.large ? 0 : 2),
//       child: Text(
//         episode.title,
//         style: (layout == EpisodeGridLayout.small
//                 ? context.textTheme.bodySmall
//                 : context.textTheme.bodyMedium)!
//             .copyWith(
//           height: 1.25,
//           color: episode.colorScheme(context).onSurface,
//         ),
//         maxLines: layout == EpisodeGridLayout.small
//             ? 4
//             : layout == EpisodeGridLayout.medium
//                 ? 3
//                 : 2,
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
//   }
// }
