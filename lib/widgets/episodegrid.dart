import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../util/selection_controller.dart';
import 'package:tuple/tuple.dart';

import '../episodes/episode_detail.dart';
import '../home/audioplayer.dart';
import '../state/audio_state.dart';
import '../type/episodebrief.dart';
import '../util/extension_helper.dart';
import '../util/open_container.dart';
import 'episode_card.dart';

enum EpisodeGridLayout { small, medium, large }

class EpisodeGrid extends StatelessWidget {
  final List<EpisodeBrief> episodes;
  final bool showFavorite;
  final bool showDownload;
  final bool preferEpisodeImage;
  final EpisodeGridLayout layout;
  final bool openPodcast;

  /// Count of animation items.
  final int initNum;

  const EpisodeGrid({
    super.key,
    required this.episodes,
    this.initNum = 12,
    this.showDownload = false,
    this.showFavorite = false,
    this.preferEpisodeImage = false,
    this.layout = EpisodeGridLayout.small,
    this.openPodcast = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = LiveOptions(
      delay: Duration.zero,
      showItemInterval: Duration(milliseconds: 50),
      showItemDuration: Duration(milliseconds: 50),
    );
    final scrollController = ScrollController();
    late final SelectionController? selectionController =
        Provider.of<SelectionController?>(context);
    if (episodes.isNotEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        sliver: Selector<SelectionController?, Tuple2<List<int>?, bool>>(
          selector: (_, selectionController) => Tuple2(
              selectionController?.selectedIndicies,
              selectionController?.selectMode ?? false),
          builder: (_, data, __) => LiveSliverGrid.options(
            controller: scrollController,
            options: options,
            itemCount: episodes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: layout == EpisodeGridLayout.small
                  ? 1
                  : layout == EpisodeGridLayout.medium
                      ? 1.5
                      : 4,
              crossAxisCount: layout == EpisodeGridLayout.small
                  ? 3
                  : layout == EpisodeGridLayout.medium
                      ? 2
                      : 1,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
            ),
            itemBuilder: (context, index, animation) {
              bool selected = data.item1?.contains(index) ?? false;
              return FadeTransition(
                opacity: Tween<double>(begin: index < initNum ? 0 : 1, end: 1)
                    .animate(animation),
                child: InteractiveEpisodeCard(
                  context,
                  episodes[index],
                  layout,
                  openPodcast: openPodcast,
                  preferEpisodeImage: preferEpisodeImage,
                  showNumber: true,
                  selectMode: data.item2,
                  onSelect: selectionController != null
                      ? () {
                          selectionController.select(index);
                        }
                      : null,
                  selected: selected,
                ),
              );
            },
          ),
        ),
      );
    } else {
      return SliverToBoxAdapter();
    }
  }
}

class OpenContainerWrapper extends StatelessWidget {
  const OpenContainerWrapper(
      {super.key,
      required this.closedBuilder,
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
  final EpisodeGridLayout layout;
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
        flightWidgetBeginOffsetX: layout == EpisodeGridLayout.small ? 6 : 8,
        flightWidgetBeginOffsetY: layout == EpisodeGridLayout.small
            ? 7
            : layout == EpisodeGridLayout.medium
                ? 8
                : 15,
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
            : context.surface,
        openColor: context.surface,
        openElevation: 0,
        closedElevation: 0,
        openShape: RoundedRectangleBorder(borderRadius: context.radiusSmall),
        closedShape: RoundedRectangleBorder(
            borderRadius: layout == EpisodeGridLayout.small
                ? context.radiusSmall
                : layout == EpisodeGridLayout.medium
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
