import 'dart:ui';

import 'package:auto_animated/auto_animated.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../episodes/episode_detail.dart';
import '../home/audioplayer.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../state/setting_state.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/open_container.dart';
import '../util/pageroute.dart';
import 'custom_widget.dart';
import 'episode_card.dart';
import 'general_dialog.dart';

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
  final List<EpisodeBrief>? selectedList;

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
      this.selectedList})
      : super(key: key);

  List<EpisodeBrief>? _selectedList = [];
  final _dbHelper = DBHelper();

  Future<PodcastLocal?> _getPodcast(String url) async {
    var podcasts = await _dbHelper.getPodcastWithUrl(url);
    return podcasts;
  }

  @override
  Widget build(BuildContext context) {
    var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    final settings = Provider.of<SettingState>(context, listen: false);
    final options = LiveOptions(
      delay: Duration.zero,
      showItemInterval: Duration(milliseconds: 50),
      showItemDuration: Duration(milliseconds: 50),
    );
    final scrollController = ScrollController();
    final s = context.s;
    return SliverPadding(
      padding: const EdgeInsets.only(
          top: 10.0, bottom: 5.0, left: 10.0, right: 10.0),
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
          final c = episodes![index].backgroudColor(context);
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
                  if (!selectedList!.contains(episodes![index])) {
                    _selectedList = selectedList;
                    _selectedList!.add(episodes![index]);
                  } else {
                    _selectedList = selectedList;
                    _selectedList!.remove(episodes![index]);
                  }
                  onSelect!(_selectedList);
                },
                selected: selectedList!.contains(episodes![index]),
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
      required this.layout});

  final OpenContainerBuilder closedBuilder;
  final EpisodeBrief episode;
  final bool? playerRunning;
  final double? avatarSize;
  final bool preferEpisodeImage;
  final Layout layout;

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerNotifier, Tuple2<bool, PlayerHeight?>>(
      selector: (_, audio) => Tuple2(audio.playerRunning, audio.playerHeight),
      builder: (_, data, __) => OpenContainer(
        playerRunning: data.item1,
        playerHeight: kMinPlayerHeight[data.item2!.index],
        flightWidget: CircleAvatar(
            backgroundImage: preferEpisodeImage && episode.episodeImage != ''
                ? episode.episodeImageProvider
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
                64 -
                MediaQuery.of(context).padding.bottom
            : context.height - 64 - MediaQuery.of(context).padding.bottom,
        transitionDuration: Duration(milliseconds: 400),
        beginColor: Theme.of(context).primaryColor,
        endColor: Theme.of(context).primaryColor,
        closedColor: Theme.of(context).brightness == Brightness.light
            ? context.primaryColor
            : context.background,
        openColor: context.background,
        openElevation: 0,
        closedElevation: 0,
        openShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        closedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (context, _, boo) {
          return EpisodeDetail(
            episodeItem: episode,
            hide: boo,
          );
        },
        tappable: true,
        closedBuilder: closedBuilder,
      ),
    );
  }
}
