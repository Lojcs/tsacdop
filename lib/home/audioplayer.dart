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
import 'package:tsacdop/episodes/shownote.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../episodes/episode_detail.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../playlists/playlist_home.dart';
import '../state/audio_state.dart';
import '../type/chapter.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/playlist.dart';
import '../util/extension_helper.dart';
import '../util/pageroute.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_slider.dart';
import '../widgets/custom_widget.dart';

List<BoxShadow> _playContainerShadow(BuildContext context,
    {required AnimationController controller}) {
  CurvedAnimation curvedAnimation =
      CurvedAnimation(parent: controller, curve: Curves.easeInCubic);
  return [
    BoxShadow(
        blurRadius:
            Tween<double>(begin: 30, end: 60).animate(curvedAnimation).value,
        spreadRadius:
            Tween<double>(begin: -16, end: -5).animate(curvedAnimation).value,
        offset: Tween<Offset>(
                begin: const Offset(-15, -15), end: const Offset(0, 0))
            .animate(curvedAnimation)
            .value,
        color: context.brightness == Brightness.light
            ? Colors.white
            : Colors.white),
    BoxShadow(
        blurRadius:
            Tween<double>(begin: 30, end: 30).animate(curvedAnimation).value,
        spreadRadius:
            Tween<double>(begin: -16, end: -10).animate(curvedAnimation).value,
        offset:
            Tween<Offset>(begin: const Offset(15, 15), end: const Offset(0, 0))
                .animate(curvedAnimation)
                .value,
        color: context.brightness == Brightness.light
            ? Colors.black
            : Colors.black),
  ];
}

List<BoxShadow> _playBackgroundShadow(BuildContext context,
    {required AnimationController controller}) {
  CurvedAnimation curvedAnimation =
      CurvedAnimation(parent: controller, curve: Curves.easeInCubic);
  return [
    BoxShadow(
        blurRadius:
            Tween<double>(begin: 30, end: 100).animate(curvedAnimation).value,
        spreadRadius:
            Tween<double>(begin: -16, end: 0).animate(curvedAnimation).value,
        offset: Tween<Offset>(
                begin: const Offset(-15, -15), end: const Offset(0, 0))
            .animate(curvedAnimation)
            .value,
        color: context.brightness == Brightness.light
            ? Colors.black
            : Colors.white),
    BoxShadow(
        blurRadius:
            Tween<double>(begin: 30, end: 50).animate(curvedAnimation).value,
        spreadRadius:
            Tween<double>(begin: -16, end: -4).animate(curvedAnimation).value,
        offset:
            Tween<Offset>(begin: const Offset(15, 15), end: const Offset(0, 0))
                .animate(curvedAnimation)
                .value,
        color: (context.brightness == Brightness.light
                ? Colors.black12
                : ColorTween(begin: Colors.white, end: Colors.white)
                    .animate(curvedAnimation)
                    .value!)
            .withOpacity(1)),
  ];
}

List<BoxShadow> _playIconShadow(BuildContext context,
    {required AnimationController controller}) {
  CurvedAnimation curvedAnimation =
      CurvedAnimation(parent: controller, curve: Curves.easeInCubic);
  return [
    BoxShadow(
        blurRadius:
            Tween<double>(begin: 15, end: 30).animate(curvedAnimation).value,
        color: context.brightness == Brightness.light
            ? Colors.black12
            : ColorTween(begin: Colors.white, end: Colors.white)
                .animate(curvedAnimation)
                .value!),
  ];
}

const List kMinsToSelect = [10, 15, 20, 25, 30, 45, 60, 70, 80, 90, 99];
const List kMinPlayerHeight = <double>[70.0, 75.0, 80.0];
const List kMaxPlayerHeight = <double>[300.0, 325.0, 350.0];

class PlayerWidget extends StatelessWidget {
  PlayerWidget({this.playerKey, this.isPlayingPage = false});
  final GlobalKey<AudioPanelState>? playerKey;
  final bool isPlayingPage;

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerNotifier, Tuple2<bool, PlayerHeight?>>(
      selector: (_, audio) => Tuple2(audio.playerRunning, audio.playerHeight),
      builder: (_, data, __) {
        if (!data.item1) {
          return Center();
        } else {
          final minHeight = kMinPlayerHeight[data.item2!.index];
          final maxHeight = math.min(
              kMaxPlayerHeight[data.item2!.index] as double,
              context.height - 20);
          return AudioPanel(
            minHeight: minHeight,
            midHeight: maxHeight,
            maxHeight: context.height -
                context.originalPadding.top -
                context.originalPadding.bottom,
            key: playerKey,
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
  const _MiniPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    final s = context.s;
    final bgColor = context.accentBackgroundSoft;
    return Container(
      color: bgColor,
      height: 60,
      child:
          Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Selector<AudioPlayerNotifier, double>(
          selector: (_, audio) => audio.seekSliderValue,
          builder: (_, data, __) {
            return SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: data,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.colorScheme.onSecondaryContainer),
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
                  child: Selector<AudioPlayerNotifier, String?>(
                    selector: (_, audio) => audio.episode?.title,
                    builder: (_, title, __) {
                      return Text(
                        title!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Selector<AudioPlayerNotifier,
                      Tuple3<bool, double, String?>>(
                    selector: (_, audio) => Tuple3(
                        audio.buffering,
                        (audio.audioDuration - audio.audioPosition) / 1000,
                        audio.remoteErrorMessage),
                    builder: (_, data, __) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: data.item3 != null
                            ? Text(data.item3!,
                                style:
                                    const TextStyle(color: Color(0xFFFF0000)))
                            : data.item1
                                ? Text(
                                    s.buffering,
                                    style:
                                        TextStyle(color: context.accentColor),
                                  )
                                : Text(
                                    s.timeLeft((data.item2).toInt().toTime),
                                    maxLines: 2,
                                  ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Selector<AudioPlayerNotifier,
                      Tuple3<bool, bool, EpisodeBrief?>>(
                    selector: (_, audio) =>
                        Tuple3(audio.buffering, audio.playing, audio.episode),
                    builder: (_, data, __) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          data.item1
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: SizedBox(
                                          height: 30.0,
                                          width: 30.0,
                                          child: CircleAvatar(
                                            backgroundColor: data.item3!
                                                .backgroudColor(context),
                                            backgroundImage: data.item3!
                                                .episodeOrPodcastImageProvider,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black),
                                      ),
                                    ])
                              : data.item2
                                  ? InkWell(
                                      onTap: data.item2
                                          ? () => audio.pauseAduio()
                                          : null,
                                      child:
                                          ImageRotate(episodeItem: data.item3),
                                    )
                                  : InkWell(
                                      onTap: data.item2
                                          ? null
                                          : () => audio.resumeAudio(),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10.0),
                                            child: SizedBox(
                                              height: 30.0,
                                              width: 30.0,
                                              child: CircleAvatar(
                                                backgroundColor: data.item3!
                                                    .backgroudColor(context),
                                                backgroundImage: data.item3!
                                                    .episodeOrPodcastImageProvider,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 40.0,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black),
                                          ),
                                          if (!data.item1)
                                            Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                            )
                                        ],
                                      ),
                                    ),
                          IconButton(
                              onPressed: () => audio.skipToNext(),
                              iconSize: 20.0,
                              icon: Icon(Icons.skip_next),
                              color: context.textColor)
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class LastPosition extends StatelessWidget {
  LastPosition({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return Selector<AudioPlayerNotifier, EpisodeBrief?>(
      selector: (_, audio) => audio.episode,
      builder: (context, episode, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Selector<AudioPlayerNotifier, bool?>(
                  selector: (_, audio) => audio.skipSilence,
                  builder: (_, data, __) => TextButton(
                      child: Row(
                        children: [
                          Icon(Icons.flash_on,
                              size: 18,
                              color: data!
                                  ? context.accentColor
                                  : context.textColor),
                          SizedBox(width: 5),
                          Text(
                            s.skipSilence,
                            style: TextStyle(
                                color: data
                                    ? context.accentColor
                                    : context.textColor),
                          ),
                        ],
                      ),
                      style: TextButton.styleFrom(
                        primary:
                            data ? context.accentColor : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.0),
                            side: BorderSide(
                                color: data
                                    ? context.accentColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.12))),
                      ),
                      onPressed: () =>
                          audio.setSkipSilence(skipSilence: !data))),
              SizedBox(width: 10),
              Selector<AudioPlayerNotifier, bool?>(
                  selector: (_, audio) => audio.boostVolume,
                  builder: (_, data, __) => TextButton(
                      child: Row(
                        children: [
                          Icon(Icons.volume_up,
                              size: 18,
                              color: data!
                                  ? context.accentColor
                                  : context.textColor),
                          SizedBox(width: 5),
                          Text(
                            s.boostVolume,
                            style: TextStyle(
                                color: data
                                    ? context.accentColor
                                    : context.textColor),
                          ),
                        ],
                      ),
                      style: TextButton.styleFrom(
                        primary:
                            data ? context.accentColor : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.0),
                            side: BorderSide(
                                color: data
                                    ? context.accentColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.12))),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () =>
                          audio.setBoostVolume(boostVolume: !data))),
              SizedBox(width: 10),
              Selector<AudioPlayerNotifier, int?>(
                  selector: (_, audio) => audio.undoButtonPosition,
                  builder: (_, data, __) {
                    return data != null
                        ? TextButton(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100.0),
                                  side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.12))),
                            ),
                            // highlightedBorderColor: Colors.green[700],
                            onPressed: () => audio.undoSeek(),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CustomPaint(
                                    painter: ListenedPainter(context.textColor,
                                        stroke: 2.0),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  data.toTime,
                                  style: TextStyle(color: context.textColor),
                                ),
                              ],
                            ),
                          )
                        : Center();
                  }),
              Selector<AudioPlayerNotifier, double>(
                selector: (_, audio) => audio.switchValue,
                builder: (_, data, __) => data == 1
                    ? Container(
                        height: 20,
                        width: 40,
                        child: Transform.rotate(
                            angle: math.pi * 0.7,
                            child: Icon(Icons.brightness_2,
                                size: 18, color: context.accentColor)))
                    : Center(),
              )
            ],
          ),
        );
      },
    );
  }
}

class PlaylistWidget extends StatefulWidget {
  const PlaylistWidget({Key? key}) : super(key: key);

  @override
  _PlaylistWidgetState createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  final GlobalKey<AnimatedListState> miniPlaylistKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Container(
        alignment: Alignment.topLeft,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.accentColor.withAlpha(70),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Selector<AudioPlayerNotifier,
            Tuple3<Playlist?, EpisodeBrief?, int?>>(
          selector: (_, audio) =>
              Tuple3(audio.playlist, audio.episode, audio.episodeIndex),
          // Both of are needed since the widget should rebuild on reorder and playlist is mutable.
          builder: (_, data, __) {
            var episodes = data.item1!.episodes;
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: episodes.length,
                    itemBuilder: (context, index) {
                      final isPlaying = index == data.item3;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (!isPlaying) {
                              audio.loadEpisodeFromCurrentPlaylist(index);
                            }
                          },
                          child: Container(
                            color: isPlaying
                                ? context.accentColor
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
                                      backgroundImage: episodes[index]
                                          .episodeOrPodcastImageProvider),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      episodes[index].title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (isPlaying)
                                  Container(
                                      height: 20,
                                      width: 20,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: WaveLoader(
                                          color: context.primaryColor)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 60.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: <Widget>[
                        Text(
                          data.item1!.name == 'Queue'
                              ? context.s.queue
                              : '${context.s.homeMenuPlaylist}${'-${data.item1!.name}'}',
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                              color: context.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Spacer(),
                        Material(
                          borderRadius: BorderRadius.circular(100),
                          color: context.primaryColor,
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
                              child: Icon(
                                Icons.skip_next,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Material(
                          borderRadius: BorderRadius.circular(100),
                          color: context.primaryColor,
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
                                child: Icon(
                                  LineIcons.database,
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
            );
          },
        ),
      ),
    );
  }
}

class SleepMode extends StatefulWidget {
  SleepMode({Key? key}) : super(key: key);

  @override
  SleepModeState createState() => SleepModeState();
}

class SleepModeState extends State<SleepMode>
    with SingleTickerProviderStateMixin {
  int? _minSelected;
  late bool _openClock;
  late AnimationController _controller;
  late Animation<double> _animation;
  Future _getDefaultTime() async {
    var defaultSleepTimerStorage = KeyValueStorage(defaultSleepTimerKey);
    var defaultTime = await defaultSleepTimerStorage.getInt(defaultValue: 30);
    if (mounted) setState(() => _minSelected = defaultTime);
  }

  @override
  void initState() {
    super.initState();
    _minSelected = 30;
    _getDefaultTime();
    _openClock = false;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Provider.of<AudioPlayerNotifier>(context, listen: false)
          ..sleepTimer(_minSelected)
          ..switchValue = 1;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<BoxShadow> customShadow(double scale) => [
        BoxShadow(
            blurRadius: 26 * (1 - scale),
            offset: Offset(-6, -6) * (1 - scale),
            color: Colors.white),
        BoxShadow(
            blurRadius: 8 * (1 - scale),
            offset: Offset(2, 2) * (1 - scale),
            color: Colors.grey[600]!.withOpacity(0.4))
      ];
  List<BoxShadow> customShadowNight(double scale) => [
        BoxShadow(
            blurRadius: 6 * (1 - scale),
            offset: Offset(-1, -1) * (1 - scale),
            color: Colors.grey[100]!.withOpacity(0.3)),
        BoxShadow(
            blurRadius: 8 * (1 - scale),
            offset: Offset(2, 2) * (1 - scale),
            color: Colors.black)
      ];

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final _colorTween =
        ColorTween(begin: context.accentColor.withAlpha(60), end: Colors.black);
    var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return Selector<AudioPlayerNotifier, Tuple3<int, double, SleepTimerMode>>(
      selector: (_, audio) =>
          Tuple3(audio.timeLeft, audio.switchValue, audio.sleepTimerMode),
      builder: (_, data, __) {
        var fraction =
            data.item2 == 1 ? 1.0 : math.min(_animation.value * 2, 1.0);
        var move =
            data.item2 == 1 ? 1.0 : math.max(_animation.value * 2 - 1, 0.0);
        return LayoutBuilder(builder: (context, constraints) {
          var width = constraints.maxWidth;
          return Container(
            decoration: BoxDecoration(
                color: _colorTween.transform(move),
                borderRadius: BorderRadius.circular(10)),
            child: Stack(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: move == 1
                            ? Center()
                            : _openClock
                                ? SleepTimerPicker(
                                    onChange: (duration) {
                                      setState(() {
                                        _minSelected = duration.inMinutes;
                                      });
                                    },
                                  )
                                : Wrap(
                                    direction: Axis.horizontal,
                                    children: kMinsToSelect
                                        .map((e) => InkWell(
                                              onTap: () => setState(
                                                  () => _minSelected = e),
                                              child: Container(
                                                margin: EdgeInsets.all(10.0),
                                                decoration: BoxDecoration(
                                                  color: (e == _minSelected)
                                                      ? context.accentColor
                                                      : context.primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                height: 30,
                                                width: 30,
                                                child: Text(e.toString(),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            (e == _minSelected)
                                                                ? Colors.white
                                                                : null)),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                      ),
                    ),
                    Stack(
                      children: <Widget>[
                        SizedBox(
                          height: 100,
                          width: width,
                        ),
                        Positioned(
                          left: data.item3 == SleepTimerMode.timer
                              ? -width * (move) / 4
                              : width * (move) / 4,
                          child: SizedBox(
                            height: 100,
                            width: width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  alignment: Alignment.center,
                                  height: 40,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: context.primaryColor),
                                    color: _colorTween.transform(move),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        audio.setSleepTimerMode =
                                            SleepTimerMode.endOfEpisode;
                                        if (fraction == 0) {
                                          _controller.forward();
                                        } else if (fraction == 1) {
                                          _controller.reverse();
                                          audio.cancelTimer();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: SizedBox(
                                        height: 40,
                                        width: 120,
                                        child: Center(
                                          child: Text(
                                            s.endOfEpisode,
                                            style: TextStyle(
                                                color: (move > 0
                                                    ? Colors.white
                                                    : null)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 100 * (1 - fraction),
                                  width: 1,
                                  color: context.primaryColorDark,
                                ),
                                Container(
                                  height: 40,
                                  width: 120,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: context.primaryColor),
                                    color: _colorTween.transform(move),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        audio.setSleepTimerMode =
                                            SleepTimerMode.timer;
                                        if (fraction == 0) {
                                          _controller.forward();
                                        } else if (fraction == 1) {
                                          _controller.reverse();
                                          audio.cancelTimer();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: SizedBox(
                                        height: 40,
                                        width: 120,
                                        child: Center(
                                          child: Text(
                                            data.item2 == 1
                                                ? data.item1.toTime
                                                : (_minSelected! * 60).toTime,
                                            style: TextStyle(
                                                color: (move > 0
                                                    ? Colors.white
                                                    : null)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 60.0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Text(context.s.sleepTimer,
                                style: TextStyle(
                                    color: context.accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Spacer(),
                            Material(
                              borderRadius: BorderRadius.circular(100),
                              color: context.primaryColor,
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
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                if (move > 0)
                  Positioned(
                    bottom: 120,
                    left: width / 2 - 100,
                    width: 200,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, -50 * move),
                        child: Text(s.goodNight,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white.withOpacity(move))),
                      ),
                    ),
                  ),
                if (data.item2 == 1) CustomPaint(painter: StarSky()),
                if (data.item2 == 1) MeteorLoader()
              ],
            ),
          );
        });
      },
    );
  }
}

class ChaptersWidget extends StatefulWidget {
  ChaptersWidget({Key? key}) : super(key: key);

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
    if (episode.chapterLink == '' || episode.chapterLink == null) {
      return [];
    }
    try {
      final file =
          await DefaultCacheManager().getSingleFile(episode.chapterLink!);
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
        Container(
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
                          side: BorderSide(color: context.accentColor)),
                    ),
                    // highlightedBorderColor: Colors.green[700],
                    onPressed: () {
                      context
                          .read<AudioPlayerNotifier>()
                          .seekTo(chapters.startTime! * 1000);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(
                            painter:
                                ListenedPainter(context.textColor, stroke: 2.0),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          chapters.startTime!.toTime,
                        ),
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
                  Text(chapters.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyText1),
                  if (chapters.url != '')
                    Row(
                      children: [
                        Expanded(
                            child: Text(chapters.url!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: context.accentColor))),
                        TextButton(
                            style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  context.accentColor),
                              overlayColor: MaterialStateProperty.all<Color>(
                                  context.primaryColor.withOpacity(0.3)),
                            ),
                            onPressed: () => chapters.url!.launchUrl,
                            child: Text('Visit')),
                      ],
                    ),
                  if (chapters.img != '')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: _ChapterImage(chapters.img),
                    )
                ],
              )),
              SizedBox(width: 8)
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.topLeft,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.accentColor.withAlpha(70),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Selector<AudioPlayerNotifier, EpisodeBrief?>(
          selector: (_, audio) => audio.episode,
          builder: (_, episode, __) => Scrollbar(
            child: Column(
              children: [
                Expanded(
                  child: _showChapter
                      ? FutureBuilder<List<Chapters>?>(
                          future: _getChapters(episode!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final data = snapshot.data!;
                              return ListView.builder(
                                  itemCount: data.length,
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    return _chapterDetailWidget(data[index]);
                                  });
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
                            if (episode!.episodeImage != '' &&
                                episode.enclosureUrl.substring(0, 4) != "file")
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: CachedNetworkImage(
                                    width: 100,
                                    fit: BoxFit.fitWidth,
                                    alignment: Alignment.center,
                                    imageUrl: episode.episodeImage!,
                                    placeholderFadeInDuration: Duration.zero,
                                    progressIndicatorBuilder: (context, url,
                                            downloadProgress) =>
                                        Container(
                                          height: 50,
                                          width: 50,
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: 20,
                                            height: 2,
                                            child: LinearProgressIndicator(
                                                value:
                                                    downloadProgress.progress),
                                          ),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        Center()),
                              ),
                            ShowNote(episode: episode)
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
                              color: context.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Spacer(),
                        SizedBox(width: 20),
                        if (episode.chapterLink != '')
                          Material(
                            borderRadius: BorderRadius.circular(100),
                            color: context.primaryColor,
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
                                      ? Icon(Icons.bookmark_border_outlined,
                                          size: 18)
                                      : Icon(Icons.chrome_reader_mode_outlined,
                                          size: 18)),
                            ),
                          ),
                      ],
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
}

class _ChapterImage extends StatefulWidget {
  final String? url;
  _ChapterImage(this.url, {Key? key}) : super(key: key);

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
                            value: downloadProgress.progress),
                      ),
                    ),
                errorWidget: (context, url, error) => Center()),
            if (!_openFullImage)
              Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                      color: Colors.black38,
                      offset: Offset(0, -5),
                      blurRadius: 20,
                      spreadRadius: 10)
                ]),
              )
          ],
        ),
      ),
    );
  }
}

class ControlPanel extends StatefulWidget {
  ControlPanel(
      {this.onExpand,
      this.onClose,
      this.maxHeight,
      this.isPlayingPage = false,
      Key? key})
      : super(key: key);
  final VoidCallback? onExpand;
  final VoidCallback? onClose;
  final double? maxHeight;
  final bool isPlayingPage;
  @override
  _ControlPanelState createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with TickerProviderStateMixin {
  double? _setSpeed;
  late AnimationController _controller;
  late AnimationController _rewindController;
  late AnimationController _fastForwardController;
  late AnimationController _playController;
  late Animation<double> _animation;
  TabController? _tabController;
  int _tabIndex = 0;
  List<BoxShadow> customShadow(double scale) => [
        BoxShadow(
            blurRadius: 26 * (1 - scale),
            offset: Offset(-6, -6) * (1 - scale),
            color: Colors.white),
        BoxShadow(
            blurRadius: 8 * (1 - scale),
            offset: Offset(2, 2) * (1 - scale),
            color: Colors.grey[600]!.withOpacity(0.4))
      ];
  List<BoxShadow> customShadowNight(double scale) => [
        BoxShadow(
            blurRadius: 6 * (1 - scale),
            offset: Offset(-1, -1) * (1 - scale),
            color: Colors.grey[100]!.withOpacity(0.3)),
        BoxShadow(
            blurRadius: 8 * (1 - scale),
            offset: Offset(2, 2) * (1 - scale),
            color: Colors.black)
      ];

  Future<List<double>> _getSpeedList() async {
    var storage = KeyValueStorage('speedListKey');
    return await storage.getSpeedList();
  }

  @override
  void initState() {
    _setSpeed = 0;
    _tabController = TabController(vsync: this, length: 3)
      ..addListener(() {
        setState(() => _tabIndex = _tabController!.index);
      });
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() => _setSpeed = _animation.value);
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
    _playController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rewindController.dispose();
    _fastForwardController.dispose();
    _playController.dispose();
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Container(
          color: context.accentBackgroundSoft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 16),
              Selector<AudioPlayerNotifier,
                  Tuple5<double, int, int, AudioProcessingState, String?>>(
                selector: (context, audio) => Tuple5(
                    audio.seekSliderValue,
                    audio.audioPosition,
                    audio.audioDuration,
                    audio.audioState,
                    audio.remoteErrorMessage),
                builder: (_, data, __) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(top: 20, left: 30, right: 30),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            //activeTrackColor: height <= widget.maxHeight
                            activeTrackColor: context.accentColor.withAlpha(70),
                            //   : Colors.transparent,
                            inactiveTrackColor:
                                context.colorScheme.secondaryContainer,
                            trackHeight: 8.0,
                            trackShape: MyRectangularTrackShape(),
                            thumbColor: context.accentColor,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 6.0,
                              disabledThumbRadius: 6.0,
                            ),
                            overlayColor: context.accentColor.withAlpha(32),
                            overlayShape:
                                RoundSliderOverlayShape(overlayRadius: 4.0),
                          ),
                          child: Slider(
                              value: data.item1,
                              onChanged: (val) {
                                audio.sliderSeek(val);
                              }),
                        ),
                      ),
                      Container(
                        height: 20.0,
                        padding: EdgeInsets.symmetric(horizontal: 30.0),
                        child: Row(
                          children: <Widget>[
                            Text(
                              (data.item2 ~/ 1000).toTime,
                              style: TextStyle(fontSize: 10),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: data.item5 != null
                                    ? Text(data.item5!,
                                        style: const TextStyle(
                                            color: Color(0xFFFF0000)))
                                    : Text(
                                        data.item4 ==
                                                    AudioProcessingState
                                                        .buffering ||
                                                data.item4 ==
                                                    AudioProcessingState.loading
                                            ? context.s.buffering
                                            : '',
                                        style: TextStyle(
                                            color: context.accentColor),
                                      ),
                              ),
                            ),
                            Text(
                              (data.item3 ~/ 1000).toTime,
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
                child: Selector<AudioPlayerNotifier, bool>(
                  selector: (_, audio) => audio.playing,
                  builder: (_, playing, __) {
                    Color? greyColor = context.brightness == Brightness.light
                        ? Colors.grey[700]
                        : Colors.grey[350];
                    if (playing) {
                      _playController.forward();
                    } else {
                      _playController.reverse();
                    }
                    return Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5)),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100.0),
                                  side: BorderSide(color: Colors.transparent),
                                ),
                              ),
                            ),
                            onPressed: audio.rewind,
                            child: Row(
                              children: [
                                Icon(Icons.fast_rewind,
                                    size: 32, color: greyColor),
                                SizedBox(width: 5),
                                Selector<AudioPlayerNotifier, int?>(
                                    selector: (_, audio) => audio.rewindSeconds,
                                    builder: (_, seconds, __) => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5.0),
                                          child: Text('$seconds s',
                                              style: GoogleFonts.teko(
                                                textBaseline:
                                                    TextBaseline.ideographic,
                                                textStyle: TextStyle(
                                                    color: greyColor,
                                                    fontSize: 25),
                                              )),
                                        )),
                              ],
                            ),
                          ),
                          // Container(
                          //   height: 60,
                          //   width: 60,
                          //   margin: EdgeInsets.symmetric(horizontal: 30),
                          //   decoration: BoxDecoration(
                          //       shape: BoxShape.circle,
                          //       boxShadow: _playBackgroundShadow(context,
                          //           controller: _playController)),
                          //   child: GestureDetector(
                          //     onTap: playing
                          //         ? () {
                          //             audio.pauseAduio();
                          //             _playController.reverse();
                          //           }
                          //         : () {
                          //             audio.resumeAudio();
                          //             _playController.forward();
                          //           },
                          //     child: Icon(
                          //       playing
                          //           ? Icons.pause_rounded
                          //           : Icons.play_arrow_rounded,
                          //       size: 40,
                          //       color: context.accentColor,
                          //       shadows: _playIconShadow(context,
                          //           controller: _playController),
                          //     ),
                          //   ),
                          // ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 30),
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: context.accentBackgroundSoft,
                              shape: BoxShape.circle,
                              boxShadow: !context.realDark
                                  ? _playContainerShadow(context,
                                      controller: _playController)
                                  : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: GestureDetector(
                                // borderRadius:
                                //     BorderRadius.all(Radius.circular(30)),
                                onTap: playing
                                    ? () {
                                        audio.pauseAduio();
                                      }
                                    : () {
                                        audio.resumeAudio();
                                      },
                                child: SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 40,
                                    color: context.accentColor,
                                    shadows: context.realDark
                                        ? _playIconShadow(context,
                                            controller: _playController)
                                        : [],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5)),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100.0),
                                  side: BorderSide(color: Colors.transparent),
                                ),
                              ),
                            ),
                            onPressed: audio.fastForward,
                            child: Row(
                              children: [
                                Selector<AudioPlayerNotifier, int?>(
                                    selector: (_, audio) =>
                                        audio.fastForwardSeconds,
                                    builder: (_, seconds, __) => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5.0),
                                          child: Text('$seconds s',
                                              style: GoogleFonts.teko(
                                                textStyle: TextStyle(
                                                    color: greyColor,
                                                    fontSize: 25),
                                              )),
                                        )),
                                SizedBox(width: 10),
                                Icon(Icons.fast_forward,
                                    size: 32.0, color: greyColor),
                              ],
                            ),
                          )
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
                      child: Selector<AudioPlayerNotifier, String?>(
                        selector: (_, audio) => audio.episode!.title,
                        builder: (_, title, __) {
                          return Container(
                            padding: EdgeInsets.only(left: 50, right: 50),
                            child: LayoutBuilder(
                              builder: (context, size) {
                                final span = TextSpan(
                                    text: title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20));
                                final tp = TextPainter(
                                    text: span,
                                    maxLines: 1,
                                    textDirection: TextDirection.ltr);
                                tp.layout(
                                    maxWidth: size.maxWidth -
                                        4); //Without -3 edge values don't behave right. -4 to be safe
                                if (tp.didExceedMaxLines) {
                                  return Marquee(
                                    text: title!,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                    scrollAxis: Axis.horizontal,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    blankSpace: 30.0,
                                    velocity: 50.0,
                                    pauseAfterRound: Duration.zero,
                                    startPadding: 0,
                                    accelerationDuration:
                                        Duration(milliseconds: 100),
                                    accelerationCurve: Curves.linear,
                                    decelerationDuration:
                                        Duration(milliseconds: 100),
                                    decelerationCurve: Curves.linear,
                                  );
                                } else {
                                  return Text(
                                    title!,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    if (height <= widget.maxHeight! + 20)
                      Opacity(
                        opacity: ((widget.maxHeight! + 20 - height) / 20)
                            .clamp(0, 1),
                        child: LastPosition(),
                      ),
                  ],
                ),
              ),
              if (height > widget.maxHeight!)
                Container(
                  height: height - widget.maxHeight!,
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Container(
                      height: context.height -
                          context.originalPadding.top -
                          context.originalPadding.bottom -
                          widget.maxHeight!,
                      child: ScrollConfiguration(
                        behavior: NoGrowBehavior(),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            PlaylistWidget(),
                            SleepMode(),
                            ChaptersWidget(),
                          ]
                              .map(
                                (e) => Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  decoration: BoxDecoration(
                                      borderRadius: context.radiusLarge),
                                  clipBehavior: Clip.antiAlias,
                                  child: e,
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
                        opacity: ((widget.maxHeight! + 25 - height) / 25)
                            .clamp(0, 1),
                        child: Selector<AudioPlayerNotifier,
                            Tuple4<EpisodeBrief?, bool, bool, double?>>(
                          selector: (_, audio) => Tuple4(
                              audio.episode,
                              audio.stopOnComplete,
                              audio.sleepTimerActive,
                              audio.currentSpeed),
                          builder: (_, data, __) {
                            final currentSpeed = data.item4 ?? 1.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
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
                                                    page: FutureBuilder(
                                                        // TODO: Check which fields are actually needed.
                                                        future: data.item1!
                                                            .copyWithFromDB(
                                                                newFields: [
                                                              EpisodeField
                                                                  .description,
                                                              EpisodeField
                                                                  .enclosureDuration,
                                                              EpisodeField
                                                                  .enclosureSize,
                                                              EpisodeField
                                                                  .episodeImage,
                                                              EpisodeField
                                                                  .podcastImage,
                                                              EpisodeField
                                                                  .primaryColor,
                                                              EpisodeField
                                                                  .isLiked,
                                                              EpisodeField
                                                                  .isNew,
                                                              EpisodeField
                                                                  .isPlayed,
                                                              EpisodeField
                                                                  .versionInfo
                                                            ]),
                                                        builder: ((context,
                                                                snapshot) =>
                                                            snapshot.hasData
                                                                ? EpisodeDetail(
                                                                    episodeItem:
                                                                        snapshot.data
                                                                            as EpisodeBrief,
                                                                    heroTag:
                                                                        'playpanel')
                                                                : Center()))));
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 30.0,
                                              width: 30.0,
                                              child: CircleAvatar(
                                                backgroundImage: data.item1!
                                                    .episodeOrPodcastImageProvider,
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Container(
                                              width: context.width - 130,
                                              child: Text(
                                                data.item1!.podcastTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (_setSpeed! > 0)
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: EdgeInsets.all(10.0),
                                        scrollDirection: Axis.horizontal,
                                        child: FutureBuilder<List<double>>(
                                          future: _getSpeedList(),
                                          initialData: [],
                                          builder: (context, snapshot) => Row(
                                            children: snapshot.data!
                                                .map<Widget>((e) => InkWell(
                                                      onTap: () {
                                                        if (_setSpeed == 1) {
                                                          audio.setSpeed(e);
                                                        }
                                                      },
                                                      child: Container(
                                                        height: 30,
                                                        width: 30,
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 5),
                                                        decoration: e ==
                                                                    currentSpeed &&
                                                                _setSpeed! > 0
                                                            ? BoxDecoration(
                                                                color: context
                                                                    .accentColor,
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: context
                                                                            .brightness ==
                                                                        Brightness
                                                                            .light
                                                                    ? customShadow(
                                                                        1.0)
                                                                    : customShadowNight(
                                                                        1.0),
                                                              )
                                                            : BoxDecoration(
                                                                color: context
                                                                    .primaryColor,
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: context
                                                                            .brightness ==
                                                                        Brightness
                                                                            .light
                                                                    ? customShadow(1 -
                                                                        _setSpeed!)
                                                                    : customShadowNight(1 -
                                                                        _setSpeed!)),
                                                        alignment:
                                                            Alignment.center,
                                                        child: _setSpeed! > 0
                                                            ? Text(e.toString(),
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: e ==
                                                                            currentSpeed
                                                                        ? Colors
                                                                            .white
                                                                        : null))
                                                            : Center(),
                                                      ),
                                                    ))
                                                .toList(),
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
                                            angle: math.pi * _setSpeed!,
                                            child: Text('X')),
                                        Text(currentSpeed.toStringAsFixed(1)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    if (_setSpeed == 0)
                      Positioned(
                        bottom: 0,
                        child: InkWell(
                            child: Container(
                              height: 30,
                              width: 115,
                              child: Align(
                                alignment: Alignment.center,
                                child: CustomPaint(
                                    size: Size(120, 5),
                                    painter: TabIndicator(
                                        index: _tabIndex,
                                        indicatorSize: 10,
                                        fraction: (height - widget.maxHeight!) /
                                            (context.height -
                                                context.originalPadding.top -
                                                context.originalPadding.bottom -
                                                widget.maxHeight!),
                                        accentColor: context.accentColor,
                                        color: context.textColor)),
                              ),
                            ),
                            onTap: widget.onExpand),
                      ),
                    if (_setSpeed == 0 && height > widget.maxHeight! - 20)
                      Opacity(
                        opacity: ((50 -
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
                              right: context.width / 2 - 80),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: context.accentColor,
                            unselectedLabelColor: context.textColor,
                            indicator: BoxDecoration(),
                            tabs: [
                              SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Icon(Icons.playlist_play)),
                              SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Transform.rotate(
                                      angle: math.pi * 0.7,
                                      child:
                                          Icon(Icons.brightness_2, size: 18))),
                              SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Icon(Icons.library_books, size: 18)),
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
