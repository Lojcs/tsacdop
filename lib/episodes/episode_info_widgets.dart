import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../podcasts/podcast_detail.dart';
import '../state/episode_state.dart';
import '../util/extension_helper.dart';
import '../util/hide_player_route.dart';
import '../widgets/custom_dropdown.dart';

class EpisodeAvatar extends StatelessWidget {
  final int episodeId;
  final double radius;
  final bool preferEpisodeImage;
  final bool openPodcast;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  const EpisodeAvatar(this.episodeId,
      {required this.radius,
      required this.preferEpisodeImage,
      this.openPodcast = true,
      this.onTapDown,
      this.onTapUp,
      super.key});

  @override
  Widget build(BuildContext context) {
    final episode =
        Provider.of<EpisodeState>(context, listen: false)[episodeId];
    return SizedBox(
      height: radius,
      width: radius,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius / 2,
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
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      HidePlayerRoute(
                        PodcastDetail(podcastId: episode.podcastId),
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

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
                  color: widget.showPlayedAndDownloaded && value.downloaded
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
  final Animation<double>? nameAnimation;
  const EpisodeNumberAndPodcastName(this.episodeId,
      {this.showName = true, this.nameAnimation, this.textStyle, super.key});

  @override
  State<EpisodeNumberAndPodcastName> createState() =>
      EpisodeNumberAndPodcastNameState();
}

class EpisodeNumberAndPodcastNameState
    extends State<EpisodeNumberAndPodcastName>
    with SingleTickerProviderStateMixin {
  TextStyle get textStyle => widget.textStyle ?? context.textTheme.bodyLarge!;

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
            widget.nameAnimation == null
                ? widget.showName
                    ? Text(
                        "|${episode.podcastTitle}",
                        style: textStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: episode
                                .colorScheme(context)
                                .onSecondaryContainer),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Center()
                : AnimatedBuilder(
                    animation: widget.nameAnimation!,
                    builder: (context, child) =>
                        widget.nameAnimation!.value == 0
                            ? Center()
                            : Opacity(
                                opacity: widget.nameAnimation!.value,
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
      ),
    );
  }
}

/// Episode title widget.
class EpisodeTitle extends StatefulWidget {
  final int episodeId;
  final TextStyle textStyle;
  final int maxLines;
  const EpisodeTitle(this.episodeId,
      {required this.textStyle, this.maxLines = 3, super.key});

  @override
  State<EpisodeTitle> createState() => EpisodeTitleState();
}

class EpisodeTitleState extends State<EpisodeTitle> {
  TextStyle get textStyle => widget.textStyle;
  @override
  Widget build(BuildContext context) {
    final episode =
        Provider.of<EpisodeState>(context, listen: false)[widget.episodeId];
    return Text(
      episode.title,
      style: widget.textStyle.copyWith(
        height: 1.25,
        color: episode.colorScheme(context).onSurface,
      ),
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
