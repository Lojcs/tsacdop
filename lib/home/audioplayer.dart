import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import '../episodes/shownote.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../episodes/episode_detail.dart';
import '../playlists/playlist_home.dart';
import '../state/audio_state.dart';
import '../state/settings/setting_state.dart';
import '../type/chapter.dart';
import '../type/episodebrief.dart';
import '../type/playlist.dart';
import '../util/extension_helper.dart';
import '../util/pageroute.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_widget.dart';

const List<Duration> kMinsToSelect = [
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 10),
  Duration(minutes: 15),
  Duration(minutes: 20),
  Duration(minutes: 25),
  Duration(minutes: 30),
  Duration(minutes: 35),
  Duration(minutes: 40),
  Duration(minutes: 45),
  Duration(minutes: 50),
  Duration(minutes: 55),
  Duration(minutes: 60),
  Duration(minutes: 65),
  Duration(minutes: 70),
  Duration(minutes: 75),
  Duration(minutes: 80),
  Duration(minutes: 85),
  Duration(minutes: 90),
  Duration(minutes: 95),
  Duration(minutes: 100),
  Duration(minutes: 105),
  Duration(minutes: 110),
  Duration(minutes: 115),
  Duration(minutes: 120),
];

class PlayerWidget extends StatelessWidget {
  const PlayerWidget({super.key, this.playerKey, this.isPlayingPage = false});
  final GlobalKey<AudioPanelState>? playerKey;
  final bool isPlayingPage;

  @override
  Widget build(BuildContext context) {
    return Selector<AudioState, bool>(
      selector: (_, audio) => audio.playerRunning,
      builder: (context, value, __) {
        if (!value) {
          return Center();
        } else {
          final minHeight = 75.0;
          final maxHeight = math.min(325.0, context.height - 20);
          return AudioPanel(
            minHeight: minHeight,
            midHeight: maxHeight,
            maxHeight:
                context.height -
                context.originalPadding.top -
                context.originalPadding.bottom,
            key: playerKey, // TODO: is this necessary?
            miniPanel: _MiniPanel(),
            maxiPanel: ControlPanel(
              maxHeight: maxHeight,
              isPlayingPage: isPlayingPage,
              onExpand: () {
                playerKey!.currentState!.scrollToTop();
              },
              onClose: () {
                playerKey!.currentState!.backToMini();
              },
            ),
          );
        }
      },
    );
  }
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel();

  @override
  Widget build(BuildContext context) {
    final audio = context.audioState;
    final eState = context.episodeState;
    final s = context.s;
    final bgColor = context.cardColorSchemeCard;
    return Container(
      color: bgColor,
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Selector<AudioState, double>(
            selector: (_, audio) => audio.seekSliderValue,
            builder: (_, data, __) {
              return SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: data,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colorScheme.onSecondaryContainer,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: Selector<AudioState, String>(
                      selector: (_, audio) => eState[audio.episodeId!].title,
                      builder: (_, title, __) => Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Selector<AudioState, (bool, double, String?)>(
                      selector: (_, audio) => (
                        audio.buffering,
                        (audio.audioDuration - audio.audioPosition) / 1000,
                        audio.remoteErrorMessage,
                      ),
                      builder: (_, data, __) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: data.$3 != null
                              ? Text(
                                  data.$3!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF0000),
                                  ),
                                )
                              : data.$1
                              ? Text(
                                  s.buffering,
                                  style: TextStyle(color: context.primaryColor),
                                )
                              : Text(
                                  s.timeLeft((data.$2).toInt().toTime),
                                  maxLines: 2,
                                ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DiscSpinner(),
                        IconButton(
                          onPressed: () => audio.skipToNext(),
                          iconSize: 20.0,
                          icon: Icon(Icons.skip_next),
                          color: context.textColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioActions extends StatelessWidget {
  const AudioActions({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    var audio = Provider.of<AudioState>(context, listen: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Selector<AudioState, bool>(
            selector: (_, audio) => audio.skipSilence == true,
            builder: (_, data, __) => TextButton(
              style: TextButton.styleFrom(
                foregroundColor: data ? context.primaryColor : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                  side: BorderSide(
                    color: data
                        ? context.primaryColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
              ),
              onPressed: () => context.settingState.skipSilence.set(!data),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    size: 18,
                    color: data ? context.primaryColor : context.textColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    s.skipSilence,
                    style: TextStyle(
                      color: data ? context.primaryColor : context.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          Selector<AudioState, bool>(
            selector: (_, audio) => audio.volumeBoost == true,
            builder: (_, data, __) => TextButton(
              style: TextButton.styleFrom(
                foregroundColor: data ? context.primaryColor : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                  side: BorderSide(
                    color: data
                        ? context.primaryColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => context.settingState.volumeBoost.set(!data),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 18,
                    color: data ? context.primaryColor : context.textColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    s.boostVolume,
                    style: TextStyle(
                      color: data ? context.primaryColor : context.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          Selector<AudioState, int?>(
            selector: (_, audio) => audio.undoButtonPosition,
            builder: (_, data, __) {
              return data != null
                  ? TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.0),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      // highlightedBorderColor: Colors.green[700],
                      onPressed: audio.undoSeek,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(
                              painter: ListenedPainter(
                                context.textColor,
                                stroke: 2.0,
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            (data ~/ 1000).toTime,
                            style: TextStyle(color: context.textColor),
                          ),
                        ],
                      ),
                    )
                  : Center();
            },
          ),
          Selector<AudioState, bool>(
            selector: (_, audio) => audio.sleepTimerRunning,
            builder: (_, data, __) => data
                ? SizedBox(
                    height: 20,
                    width: 40,
                    child: Transform.rotate(
                      angle: math.pi * 0.7,
                      child: Icon(
                        Icons.brightness_2,
                        size: 18,
                        color: context.primaryColor,
                      ),
                    ),
                  )
                : Center(),
          ),
        ],
      ),
    );
  }
}

class PlaylistWidget extends StatefulWidget {
  const PlaylistWidget({super.key});

  @override
  State<PlaylistWidget> createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  final GlobalKey<AnimatedListState> miniPlaylistKey = GlobalKey();

  /// Map to hold ListView tiles between rebuilds due to playlist change.
  final Map<int, Widget> listItems = {};

  @override
  Widget build(BuildContext context) {
    var audio = context.audioState;
    var eState = context.episodeState;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Selector<AudioState, Playlist>(
            selector: (_, audio) => audio.playlist,
            builder: (_, playlist, __) => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: playlist.length,
              itemBuilder: (context, index) {
                int episodeId = playlist[index];
                if (!listItems.containsKey(episodeId)) {
                  listItems[episodeId] = Selector<AudioState, bool>(
                    selector: (_, audio) => index == audio.episodeIndex,
                    builder: (_, isPlaying, __) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (!isPlaying) {
                            audio.loadEpisodeFromCurrentPlaylist(index);
                          }
                        },
                        child: Container(
                          height: 50,
                          color: isPlaying
                              ? context.primaryColor
                              : Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundImage: eState[episodeId]
                                      .episodeOrPodcastImageProvider,
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    eState[episodeId].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (isPlaying)
                                Container(
                                  height: 20,
                                  width: 20,
                                  margin: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Selector<AudioState, bool>(
                                    selector: (_, audio) => audio.playing,
                                    builder: (_, playing, __) => WaveLoader(
                                      animate: playing,
                                      color: context.cardColorSchemeSaturated,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return listItems[episodeId];
              },
            ),
          ),
        ),
        SizedBox(
          height: 60.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                Selector<AudioState, Playlist>(
                  selector: (_, audio) => audio.playlist,
                  builder: (_, playlist, __) => Text(
                    playlist.name == 'Queue'
                        ? context.s.queue
                        : '${context.s.homeMenuPlaylist}${'-${playlist.name}'}',
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: context.boxShadowSmall(),
                    color: context.cardColorSchemeCard,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      onTap: () {
                        audio.skipToNext();
                        // miniPlaylistKey.currentState.removeItem(
                        //     0, (context, animation) => Container());
                        // miniPlaylistKey.currentState.insertItem(0);
                      },
                      child: SizedBox(
                        height: 30,
                        width: 60,
                        child: Icon(Icons.skip_next, size: 30),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: context.boxShadowSmall(),
                    color: context.cardColorSchemeCard,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15.0),
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideLeftRoute(page: PlaylistHome()),
                        );
                      },
                      child: SizedBox(
                        height: 30.0,
                        width: 30.0,
                        child: Transform.rotate(
                          angle: math.pi,
                          child: Icon(LineIcons.database, size: 20.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SleepMode extends StatefulWidget {
  const SleepMode({super.key});

  @override
  SleepModeState createState() => SleepModeState();
}

class SleepModeState extends State<SleepMode>
    with SingleTickerProviderStateMixin {
  bool _openClock = false;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Selector<AudioState, (bool, Duration)>(
                  selector: (_, audio) =>
                      (audio.sleepTimerRunning, audio.sleepInterval),
                  builder: (context, value, __) => AnimatedOpacity(
                    opacity: value.$1 ? 0 : 1,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOutQuad,
                    child: _openClock
                        ? SleepTimerPicker(
                            initialValue: TimeOfDay.fromDateTime(
                              DateTime.now().add(value.$2),
                            ),
                            onChange: (duration) => setState(
                              () => context.audioState.sleepInterval = duration,
                            ),
                          )
                        : Wrap(
                            direction: Axis.horizontal,
                            children: kMinsToSelect
                                .map(
                                  (e) => InkWell(
                                    onTap: () => setState(
                                      () =>
                                          context.audioState.sleepInterval = e,
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        color: (e == value.$2)
                                            ? context.cardColorSchemeSelected
                                            : context.cardColorSchemeCard,
                                        shape: BoxShape.circle,
                                        boxShadow: context.boxShadowSmall(),
                                      ),
                                      alignment: Alignment.center,
                                      height: 30,
                                      width: 30,
                                      child: Text(
                                        e.inMinutes.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (e == value.$2)
                                              ? Colors.white
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ),
              ),
            ),
            Selector<AudioState, bool>(
              selector: (_, audio) => audio.sleepTimerRunning,
              builder: (context, value, __) => value
                  ? Text(
                      context.s.goodNight,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: context.primaryColor,
                      ),
                    )
                  : Center(),
            ),
            Selector<AudioState, bool>(
              selector: (_, audio) => audio.sleepWaitEpisodeEnd,
              builder: (context, value, __) => Container(
                alignment: Alignment.center,
                height: 40,
                width: 120,
                decoration: BoxDecoration(
                  color: value
                      ? context.cardColorSchemeSaturated
                      : context.cardColorSchemeCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.boxShadowSmall(),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        context.audioState.sleepWaitEpisodeEnd = !value,
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 40,
                      width: 120,
                      child: Center(
                        child: Text(
                          context.s.endOfEpisode,
                          style: TextStyle(
                            color: value ? context.primaryColor : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Selector<AudioState, bool>(
              selector: (_, audio) => audio.sleepTimerRunning,
              builder: (context, value, __) => Container(
                height: 40,
                width: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value
                      ? context.cardColorSchemeSaturated
                      : context.cardColorSchemeCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.boxShadowSmall(),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => value
                        ? context.audioState.cancelSleepTimer()
                        : context.audioState.startSleepTimer(),
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 40,
                      width: 120,
                      child: Center(
                        child: Text(
                          value
                              ? context.s.sleepTimerCancel
                              : context.s.sleepTimerStart,
                          style: TextStyle(
                            color: value ? context.primaryColor : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Selector<AudioState, (bool, bool)>(
              selector: (_, audio) =>
                  (audio.sleepTimerRunning, audio.sleepWaitingForEpisodeEnd),
              builder: (context, value, __) => TickedSubtree(
                tick: value.$1,
                builder: (context) => Text(
                  value.$2
                      ? context.s.sleepTimerWait
                      : context.audioState.sleepTimerTimeLeft.toTime(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 60.0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      context.s.sleepTimer,
                      style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: context.cardColorSchemeCard,
                        boxShadow: context.boxShadowSmall(),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15.0),
                          onTap: () {
                            setState(() {
                              _openClock = !_openClock;
                            });
                          },
                          child: SizedBox(
                            height: 30.0,
                            width: 30.0,
                            child: Icon(
                              _openClock
                                  ? LineIcons.stopwatch
                                  : LineIcons.clock,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Selector<AudioState, bool>(
          selector: (_, audio) => audio.sleepTimerRunning,
          builder: (context, value, __) =>
              value ? CustomPaint(painter: StarSky()) : Center(),
        ),
        Selector<AudioState, bool>(
          selector: (_, audio) => audio.sleepTimerRunning,
          builder: (context, value, __) => value ? MeteorLoader() : Center(),
        ),
      ],
    );
  }
}

class ChaptersWidget extends StatefulWidget {
  const ChaptersWidget({super.key});

  @override
  _ChaptersWidgetState createState() => _ChaptersWidgetState();
}

class _ChaptersWidgetState extends State<ChaptersWidget> {
  late bool _showChapter;

  @override
  void initState() {
    super.initState();
    _showChapter = false;
  }

  Future<List<Chapters>?> _getChapters(EpisodeBrief episode) async {
    if (episode.chapterLink == '') {
      return [];
    }
    try {
      final file = await DefaultCacheManager().getSingleFile(
        episode.chapterLink,
      );
      final response = file.readAsStringSync();
      var chapterInfo = ChapterInfo.fromJson(jsonDecode(response));
      return chapterInfo.chapters;
    } catch (e) {
      developer.log('Download cahpter error', error: e);
      return [];
    }
  }

  Widget _chapterDetailWidget(Chapters chapters) {
    return Column(
      children: [
        SizedBox(
          // height: 60,
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ButtonTheme(
                  height: 28,
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                        side: BorderSide(color: context.primaryColor),
                      ),
                    ),
                    // highlightedBorderColor: Colors.green[700],
                    onPressed: () {
                      context.read<AudioState>().seekTo(
                        chapters.startTime! * 1000,
                      );
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(
                            painter: ListenedPainter(
                              context.textColor,
                              stroke: 2.0,
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(chapters.startTime!.toTime),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    Text(
                      chapters.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge,
                    ),
                    if (chapters.url != '')
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chapters.url!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.primaryColor),
                            ),
                          ),
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all<Color>(
                                context.primaryColor,
                              ),
                              overlayColor: WidgetStateProperty.all<Color>(
                                context.onPrimary.withValues(alpha: 0.3),
                              ),
                            ),
                            onPressed: () => chapters.url!.launchUrl,
                            child: Text('Visit'),
                          ),
                        ],
                      ),
                    if (chapters.img != '')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: _ChapterImage(chapters.img),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AudioState, EpisodeBrief>(
      selector: (_, audio) => audio.episodeBrief!,
      builder: (_, episode, __) => Scrollbar(
        child: Column(
          children: [
            Expanded(
              child: _showChapter
                  ? FutureBuilder<List<Chapters>?>(
                      future: _getChapters(episode),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final data = snapshot.data!;
                          return ListView.builder(
                            itemCount: data.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              return _chapterDetailWidget(data[index]);
                            },
                          );
                        }
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Platform.isIOS
                                ? CupertinoActivityIndicator()
                                : CircularProgressIndicator(),
                          ),
                        );
                      },
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        if (episode.episodeImageUrl != '' &&
                            episode.enclosureUrl.substring(0, 4) != "file")
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: CachedNetworkImage(
                              width: 100,
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.center,
                              imageUrl: episode.episodeImageUrl,
                              placeholderFadeInDuration: Duration.zero,
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) => Container(
                                    height: 50,
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 20,
                                      height: 2,
                                      child: LinearProgressIndicator(
                                        value: downloadProgress.progress,
                                      ),
                                    ),
                                  ),
                              errorWidget: (context, url, error) => Center(),
                            ),
                          ),
                        ShowNote(episodeId: episode.id),
                      ],
                    ),
            ),
            SizedBox(
              height: 60.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    Text(
                      context.s.homeToprightMenuAbout,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    SizedBox(width: 20),
                    if (episode.chapterLink != '')
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: context.boxShadowSmall(),
                          color: context.cardColorSchemeCard,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15.0),
                            onTap: () {
                              setState(() {
                                _showChapter = !_showChapter;
                              });
                            },
                            child: SizedBox(
                              height: 30.0,
                              width: 30.0,
                              child: !_showChapter
                                  ? Icon(
                                      Icons.bookmark_border_outlined,
                                      size: 18,
                                    )
                                  : Icon(
                                      Icons.chrome_reader_mode_outlined,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterImage extends StatefulWidget {
  final String? url;
  const _ChapterImage(this.url);

  @override
  __ChapterImageState createState() => __ChapterImageState();
}

class __ChapterImageState extends State<_ChapterImage> {
  late bool _openFullImage;
  @override
  void initState() {
    super.initState();
    _openFullImage = false;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _openFullImage = !_openFullImage),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CachedNetworkImage(
              width: double.infinity,
              height: _openFullImage ? null : 50,
              fit: BoxFit.fitWidth,
              alignment: Alignment.center,
              imageUrl: widget.url!,
              placeholderFadeInDuration: Duration.zero,
              progressIndicatorBuilder: (contlext, url, downloadProgress) =>
                  Container(
                    height: 50,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 20,
                      height: 2,
                      child: LinearProgressIndicator(
                        value: downloadProgress.progress,
                      ),
                    ),
                  ),
              errorWidget: (context, url, error) => Center(),
            ),
            if (!_openFullImage)
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      offset: Offset(0, -5),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ControlPanel extends StatefulWidget {
  const ControlPanel({
    this.onExpand,
    this.onClose,
    this.maxHeight,
    this.isPlayingPage = false,
    super.key,
  });
  final VoidCallback? onExpand;
  final VoidCallback? onClose;
  final double? maxHeight;
  final bool isPlayingPage;
  @override
  _ControlPanelState createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with TickerProviderStateMixin {
  double _setSpeed = 0;
  late AnimationController _controller;
  late AnimationController _playPauseController;
  late Animation<double> _playPauseAnimation;
  late AnimationController _rewindController;
  late AnimationController _fastForwardController;
  late Animation<double> _animation;
  TabController? _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3)
      ..addListener(() {
        setState(() => _tabIndex = _tabController!.index);
      });
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() => _setSpeed = _animation.value);
        }
      });
    _playPauseController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          });
    _rewindController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400))
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          });
    _fastForwardController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400))
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          });
    _playPauseAnimation = CurvedAnimation(
      parent: _playPauseController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _playPauseController.dispose();
    _rewindController.dispose();
    _fastForwardController.dispose();
    _tabController!.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final audio = Provider.of<AudioState>(context, listen: false);
    if (audio.playing && _playPauseController.value == 0) {
      _playPauseController.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioState>(context, listen: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Container(
          color: context.cardColorSchemeCard,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 16),
              Selector<
                AudioState,
                (double, int, int, AudioProcessingState, String?)
              >(
                selector: (context, audio) => (
                  audio.seekSliderValue,
                  audio.audioPosition,
                  audio.audioDuration,
                  audio.audioState,
                  audio.remoteErrorMessage,
                ),
                builder: (_, data, __) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: context.primaryColor.withAlpha(
                              70,
                            ),
                            inactiveTrackColor:
                                context.colorScheme.secondaryContainer,
                          ),
                          child: Slider(
                            value: data.$1,
                            onChanged: audio.seekbarVisualSeek,
                            onChangeEnd: audio.seekbarSeek,
                          ),
                        ),
                      ),
                      Container(
                        height: 20.0,
                        padding: EdgeInsets.symmetric(horizontal: 30.0),
                        child: Row(
                          children: <Widget>[
                            Text(
                              (data.$2 ~/ 1000).toTime,
                              style: TextStyle(fontSize: 10),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: data.$5 != null
                                    ? Text(
                                        data.$5!,
                                        style: const TextStyle(
                                          color: Color(0xFFFF0000),
                                        ),
                                      )
                                    : Text(
                                        data.$4 ==
                                                    AudioProcessingState
                                                        .buffering ||
                                                data.$4 ==
                                                    AudioProcessingState.loading
                                            ? context.s.buffering
                                            : '',
                                        style: TextStyle(
                                          color: context.primaryColor,
                                        ),
                                      ),
                              ),
                            ),
                            Text(
                              (data.$3 ~/ 1000).toTime,
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(
                height: 100,
                child: Selector<AudioState, bool>(
                  selector: (_, audio) => audio.playing,
                  builder: (_, playing, __) {
                    Color? greyColor = context.brightness == Brightness.light
                        ? Colors.grey[700]
                        : Colors.grey[350];
                    return Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100.0),
                                  side: BorderSide(color: Colors.transparent),
                                ),
                              ),
                            ),
                            onPressed: audio.rewind,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fast_rewind,
                                  size: 32,
                                  color: greyColor,
                                ),
                                SizedBox(width: 5),
                                Selector<SettingState, int>(
                                  selector: (_, settings) =>
                                      settings.rewindInterval.get().inSeconds,
                                  builder: (_, seconds, __) => Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      '$seconds s',
                                      style: GoogleFonts.teko(
                                        textBaseline: TextBaseline.ideographic,
                                        textStyle: TextStyle(
                                          color: greyColor,
                                          fontSize: 25,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 35),
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: context.trueBlack
                                      ? null
                                      : context.cardColorSchemeSaturated,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: context.boxShadowMedium(),
                                  border: Border.all(
                                    width: 1,
                                    color: context.trueBlack
                                        ? Color.lerp(
                                            context.primaryColor,
                                            Colors.black,
                                            0.5,
                                          )!
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 35),
                                height: 70,
                                width: 70,
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                    splashColor:
                                        context.colorScheme.secondaryContainer,
                                    onTap: playing
                                        ? () {
                                            audio.pauseAduio();
                                            _playPauseController.reverse();
                                          }
                                        : () {
                                            audio.resumeAudio();
                                            _playPauseController.forward();
                                          },
                                    child: Icon(
                                      playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 40 + 6,
                                      color: context.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100.0),
                                  side: BorderSide(color: Colors.transparent),
                                ),
                              ),
                            ),
                            onPressed: audio.fastForward,
                            child: Row(
                              children: [
                                Selector<SettingState, int>(
                                  selector: (_, settings) => settings
                                      .fastForwardInterval
                                      .get()
                                      .inSeconds,
                                  builder: (_, seconds, __) => Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      '$seconds s',
                                      style: GoogleFonts.teko(
                                        textStyle: TextStyle(
                                          color: greyColor,
                                          fontSize: 25,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.fast_forward,
                                  size: 32.0,
                                  color: greyColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 80.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(left: 50, right: 50),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) => true,
                          child: Selector<AudioState, String>(
                            selector: (_, audio) => audio.episodeBrief!.title,
                            builder: (_, title, __) => LayoutBuilder(
                              builder: (context, size) {
                                final span = TextSpan(
                                  text: title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  )..merge(DefaultTextStyle.of(context).style),
                                );
                                final tp = TextPainter(
                                  text: span,
                                  maxLines: 1,
                                  textDirection: TextDirection.ltr,
                                );
                                tp.layout(maxWidth: size.maxWidth);
                                if (tp.didExceedMaxLines) {
                                  return Marquee(
                                    text: title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    scrollAxis: Axis.horizontal,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    blankSpace: 30.0,
                                    velocity: 50.0,
                                    pauseAfterRound: Duration.zero,
                                    startPadding: 0,
                                    accelerationDuration: Duration(
                                      milliseconds: 100,
                                    ),
                                    accelerationCurve: Curves.linear,
                                    decelerationDuration: Duration(
                                      milliseconds: 100,
                                    ),
                                    decelerationCurve: Curves.linear,
                                  );
                                } else {
                                  return Text(
                                    title,
                                    maxLines: 1,
                                    style: context.textTheme.titleLarge!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (height <= widget.maxHeight! + 20)
                      Opacity(
                        opacity: ((widget.maxHeight! + 20 - height) / 20).clamp(
                          0,
                          1,
                        ),
                        child: AudioActions(),
                      ),
                  ],
                ),
              ),
              if (height > widget.maxHeight!)
                SizedBox(
                  height: height - widget.maxHeight!,
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height:
                          context.height -
                          context.originalPadding.top -
                          context.originalPadding.bottom -
                          widget.maxHeight!,
                      child: ScrollConfiguration(
                        behavior: NoGrowBehavior(),
                        child: TabBarView(
                          controller: _tabController,
                          children:
                              [PlaylistWidget(), SleepMode(), ChaptersWidget()]
                                  .map(
                                    (e) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 20.0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: context.radiusMedium,
                                        boxShadow: context.boxShadowMedium(),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Container(
                                        color: context.cardColorSchemeSaturated,
                                        foregroundDecoration: context.trueBlack
                                            ? BoxDecoration(
                                                borderRadius:
                                                    context.radiusMedium,
                                                border: Border.all(
                                                  width: 1,
                                                  color: Color.lerp(
                                                    context.primaryColor,
                                                    Colors.black,
                                                    0.5,
                                                  )!,
                                                ),
                                              )
                                            : null,
                                        child: e,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (height <= widget.maxHeight! + 25)
                      Opacity(
                        opacity: ((widget.maxHeight! + 25 - height) / 25).clamp(
                          0,
                          1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (_setSpeed == 0)
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      widget.onClose!();
                                      if (!widget.isPlayingPage) {
                                        Navigator.push(
                                          context,
                                          FadeRoute(
                                            page: EpisodeDetail(
                                              audio.episodeId!,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child:
                                        Selector<
                                          AudioState,
                                          (String, ImageProvider)
                                        >(
                                          selector: (_, audio) => (
                                            audio.episodeBrief!.title,
                                            audio
                                                .episodeBrief!
                                                .episodeOrPodcastImageProvider,
                                          ),
                                          builder: (_, data, __) => Row(
                                            children: [
                                              SizedBox(
                                                height: 30.0,
                                                width: 30.0,
                                                child: CircleAvatar(
                                                  backgroundImage: data.$2,
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              SizedBox(
                                                width: context.width - 130,
                                                child: Text(
                                                  data.$1,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  ),
                                ),
                              if (_setSpeed > 0)
                                Expanded(
                                  child: Opacity(
                                    opacity: _setSpeed,
                                    child: Selector<AudioState, double>(
                                      selector: (_, audio) => audio.visualSpeed,
                                      builder: (_, currentSpeed, __) =>
                                          SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                                  activeTrackColor: context
                                                      .primaryColor
                                                      .withAlpha(70),
                                                  inactiveTrackColor: context
                                                      .colorScheme
                                                      .secondaryContainer,
                                                ),
                                            child: Slider(
                                              min: 0.5,
                                              max: 5,
                                              divisions: 18,
                                              value: currentSpeed,
                                              onChanged: audio.setVisualSpeed,
                                              onChangeEnd: context
                                                  .settingState
                                                  .audioSpeedRatio
                                                  .set,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  if (_setSpeed == 0) {
                                    _controller.forward();
                                  } else {
                                    _controller.reverse();
                                  }
                                },
                                icon: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Transform.rotate(
                                      angle: math.pi * _setSpeed,
                                      child: Text('X'),
                                    ),
                                    Selector<AudioState, (double, bool)>(
                                      selector: (_, audio) => (
                                        audio.visualSpeed,
                                        audio.visualSpeed == audio.currentSpeed,
                                      ),
                                      builder: (context, speed, __) => Text(
                                        speed.$1.toStringAsFixed(2),
                                        style: context.textTheme.labelLarge!
                                            .copyWith(
                                              color: speed.$2
                                                  ? null
                                                  : context.primaryColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_setSpeed == 0)
                      Positioned(
                        bottom: 0,
                        child: InkWell(
                          onTap: widget.onExpand,
                          child: SizedBox(
                            height: 30,
                            width: 115,
                            child: Align(
                              alignment: Alignment.center,
                              child: CustomPaint(
                                size: Size(120, 5),
                                painter: TabIndicator(
                                  index: _tabIndex,
                                  indicatorSize: 10,
                                  fraction:
                                      (height - widget.maxHeight!) /
                                      (context.height -
                                          context.originalPadding.top -
                                          context.originalPadding.bottom -
                                          widget.maxHeight!),
                                  accentColor: context.primaryColor,
                                  color: context.textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_setSpeed == 0 && height > widget.maxHeight! - 20)
                      Opacity(
                        opacity:
                            ((50 -
                                        (context.height -
                                            height -
                                            context.originalPadding.top -
                                            context.originalPadding.bottom)) /
                                    50)
                                .clamp(0, 1),
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          padding: EdgeInsets.only(
                            bottom: 20,
                            left: context.width / 2 - 80,
                            right: context.width / 2 - 80,
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.label,
                            isScrollable: true,
                            labelColor: context.primaryColor,
                            unselectedLabelColor: context.textColor,
                            indicator: BoxDecoration(),
                            dividerHeight: 0,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Icon(Icons.playlist_play),
                              ),
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Transform.rotate(
                                  angle: math.pi * 0.7,
                                  child: Icon(Icons.brightness_2, size: 18),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Icon(Icons.library_books, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DiscSpinner extends StatefulWidget {
  const DiscSpinner({super.key});

  @override
  State<DiscSpinner> createState() => _DiscSpinnerState();
}

class _DiscSpinnerState extends State<DiscSpinner> {
  late final audioState = context.audioState;

  bool firstTime = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: 30,
      child: Selector<AudioState, (bool, bool, EpisodeBrief?)>(
        selector: (_, audio) =>
            (audio.buffering, audio.playing, audio.episodeBrief),
        builder: (_, data, __) => InkWell(
          onTap: !data.$1
              ? data.$2
                    ? audioState.pauseAduio
                    : audioState.resumeAudio
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Selector<AudioState, int>(
                selector: (context, audio) => audio.audioPosition,

                builder: (context, value, child) {
                  var firstRun = false;
                  if (firstTime) {
                    firstTime = false;
                    firstRun = true;
                  }
                  return AnimatedRotation(
                    // key: GlobalObjectKey("disc_spinner"),
                    turns: (firstRun ? 2 : 0) + value * 0.0004,
                    duration: Duration(seconds: 1),
                    curve: Curves.easeOut,
                    child: CircleAvatar(
                      backgroundColor: data.$3!.backgroudColor(context),
                      backgroundImage: data.$3!.episodeOrPodcastImageProvider,
                    ),
                  );
                },
              ),
              if (!data.$1 && !data.$2)
                Icon(Icons.play_arrow, color: Colors.white),
              if (!data.$1 && data.$2) Icon(Icons.pause, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
