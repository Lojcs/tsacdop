import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../episodes/episode_detail.dart';
import '../home/audioplayer.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../type/episodebrief.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/open_container.dart';
import 'episode_card.dart';

enum Layout { small, medium, large }

// ignore: must_be_immutable
class EpisodeGrid extends StatelessWidget {
  final List<EpisodeBrief>? episodes;
  final bool showFavorite;
  final bool showDownload;
  final bool preferEpisodeImage;
  final int? episodeCount;
  final Layout? layout;
  final SortOrder? sortOrder;
  final bool? multiSelect;
  final ValueChanged<List<EpisodeBrief>?>? onSelect;
  final bool openPodcast;
  List<EpisodeBrief> selectedList;

  /// Count of animation items.
  final int initNum;

  EpisodeGrid(
      {Key? key,
      required this.episodes,
      this.initNum = 12,
      this.showDownload = false,
      this.showFavorite = false,
      this.preferEpisodeImage = false,
      this.episodeCount,
      this.layout = Layout.small,
      this.sortOrder,
      this.openPodcast = false,
      this.multiSelect = false,
      this.onSelect,
      this.selectedList = const <EpisodeBrief>[]})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final options = LiveOptions(
      delay: Duration.zero,
      showItemInterval: Duration(milliseconds: 50),
      showItemDuration: Duration(milliseconds: 50),
    );
    final scrollController = ScrollController();
    return SliverPadding(
      padding:
          const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 10.0, right: 10.0),
      sliver: LiveSliverGrid.options(
        controller: scrollController,
        options: options,
        itemCount: episodes!.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: layout == Layout.small
              ? 1
              : layout == Layout.medium
                  ? 1.5
                  : 4,
          crossAxisCount: layout == Layout.small
              ? 3
              : layout == Layout.medium
                  ? 2
                  : 1,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
        ),
        itemBuilder: (context, index, animation) {
          scrollController.addListener(() {});

          return FadeTransition(
              opacity: Tween<double>(begin: index < initNum ? 0 : 1, end: 1)
                  .animate(animation),
              child: InteractiveEpisodeCard(
                context,
                episodes![index],
                layout!,
                openPodcast: openPodcast,
                preferEpisodeImage: preferEpisodeImage,
                numberText: episodeCount != null
                    ? (sortOrder == SortOrder.ASC
                        ? (index + 1).toString()
                        : (episodeCount! - index).toString())
                    : null,
                selectMode: multiSelect!,
                onSelect: () {
                  if (!selectedList.contains(episodes![index])) {
                    selectedList.add(episodes![index]);
                  } else {
                    selectedList.remove(episodes![index]);
                  }
                  onSelect!(selectedList);
                },
                selected: selectedList.contains(episodes![index]),
              ));
        },
      ),
    );
  }
}

class OpenContainerWrapper extends StatelessWidget {
  const OpenContainerWrapper(
      {required this.closedBuilder,
      required this.episode,
      this.playerRunning,
      this.avatarSize,
      required this.preferEpisodeImage,
      required this.layout,
      this.onClosed});

  final OpenContainerBuilder closedBuilder;
  final EpisodeBrief episode;
  final bool? playerRunning;
  final double? avatarSize;
  final bool preferEpisodeImage;
  final Layout layout;
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
        flightWidgetBeginSize: avatarSize,
        flightWidgetEndSize: 30,
        flightWidgetBeginOffsetX: layout == Layout.small ? 6 : 8,
        flightWidgetBeginOffsetY: layout == Layout.small
            ? 6
            : layout == Layout.medium
                ? 8
                : 14,
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
            : context.background,
        openColor: context.background,
        openElevation: 0,
        closedElevation: 0,
        openShape: RoundedRectangleBorder(borderRadius: context.radiusSmall),
        closedShape: RoundedRectangleBorder(
            borderRadius: layout == Layout.small
                ? context.radiusSmall
                : layout == Layout.medium
                    ? context.radiusMedium
                    : context.radiusLarge),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (context, _, boo) {
          return EpisodeDetail(
            episodeItem: episode,
            hide: boo,
          );
        },
        tappable: true,
        closedBuilder: closedBuilder,
        onDispose: onClosed,
      ),
    );
  }
}
