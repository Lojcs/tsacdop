import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:color_thief_dart/color_thief_dart.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import '../home/home.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/episode_state.dart';
import '../state/setting_state.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/playlist.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import '../util/pageroute.dart';
import '../widgets/custom_widget.dart';
import '../widgets/dismissible_container.dart';
import 'playlist_page.dart';

class PlaylistHome extends StatefulWidget {
  const PlaylistHome({super.key});

  @override
  State<PlaylistHome> createState() => _PlaylistHomeState();
}

class _PlaylistHomeState extends State<PlaylistHome> {
  Widget? _body;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = 'PlayNext';
    _body = _Queue();
  }

  Widget _tabWidget(
      {required Widget icon,
      String? label,
      Function? onTap,
      required bool isSelected,
      Color? color}) {
    return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
            iconColor: color,
            iconSize: context.actionBarIconSize,
            foregroundColor: color,
            side: BorderSide(color: context.surface),
            backgroundColor:
                isSelected ? context.primaryColorDark : Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(100)))),
        icon: icon,
        label: isSelected ? Text(label!) : Center(),
        onPressed: onTap as void Function()?);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlay,
      child: PopScope(
        canPop: !context.read<SettingState>().openPlaylistDefault!,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            Navigator.push(context, SlideRightRoute(page: Home()));
          }
        },
        child: Scaffold(
            backgroundColor: context.surface,
            appBar: AppBar(
              leading: CustomBackButton(),
              centerTitle: true,
              title: Selector<AudioPlayerNotifier, String?>(
                selector: (_, audio) => audio.episodeBrief?.title,
                builder: (_, data, __) {
                  return Text(
                    data ?? '',
                    maxLines: 1,
                    style: context.textTheme.headlineSmall,
                  );
                },
              ),
              backgroundColor: context.surface,
              scrolledUnderElevation: 0,
            ),
            body: Column(
              children: [
                Container(
                  color: context.surface,
                  height: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                    splashRadius: 20,
                                    icon: Icon(Icons.fast_rewind),
                                    onPressed: () {
                                      if (audio.playerRunning) {
                                        audio.rewind();
                                      }
                                    }),
                                SizedBox(width: 15),
                                IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Selector<AudioPlayerNotifier, bool>(
                                      selector: (_, audio) => audio.playing,
                                      builder: (_, playing, __) => Icon(
                                          playing
                                              ? LineIcons.pauseCircle
                                              : LineIcons.play,
                                          size: 40),
                                    ),
                                    onPressed: () {
                                      if (audio.playerRunning) {
                                        audio.playing
                                            ? audio.pauseAduio()
                                            : audio.resumeAudio();
                                      } else if (audio.playlist.isEmpty) {
                                        Fluttertoast.showToast(
                                            msg: 'Playlist is empty');
                                      } else {
                                        context
                                            .read<AudioPlayerNotifier>()
                                            .playFromLastPosition();
                                      }
                                    }),
                                SizedBox(width: 15),
                                IconButton(
                                    splashRadius: 20,
                                    icon: Icon(Icons.fast_forward),
                                    onPressed: () {
                                      if (audio.playerRunning) {
                                        audio.fastForward();
                                      }
                                    }),
                                IconButton(
                                    splashRadius: 20,
                                    icon: Icon(Icons.skip_next),
                                    onPressed: () {
                                      if (audio.playerRunning &&
                                          !(audio.playlist.length == 1 &&
                                              !audio.playlist.isQueue)) {
                                        audio.skipToNext();
                                      }
                                    }),
                              ],
                            ),
                            SizedBox(height: 10),
                            Selector<AudioPlayerNotifier, bool>(
                              selector: (_, audio) => audio.playerRunning,
                              builder: (_, running, __) => running
                                  ? Selector<AudioPlayerNotifier,
                                      (bool, int?, String?, int)>(
                                      selector: (_, audio) => (
                                        audio.buffering,
                                        audio.audioPosition,
                                        audio.remoteErrorMessage,
                                        audio.audioDuration
                                      ),
                                      builder: (_, info, __) {
                                        return info.$3 != null
                                            ? Text(info.$3!,
                                                style: TextStyle(
                                                    color: Color(0xFFFF0000)))
                                            : info.$1
                                                ? Text(
                                                    s.buffering,
                                                    style: TextStyle(
                                                        color: context
                                                            .accentColor),
                                                  )
                                                : Text(
                                                    '${(info.$2! ~/ 1000).toTime} / ${(info.$4 ~/ 1000).toTime}');
                                      },
                                    )
                                  : Selector<AudioPlayerNotifier, (int, int)>(
                                      selector: (_, audio) => (
                                        audio.historyPosition,
                                        audio.episodeBrief?.enclosureDuration ??
                                            0
                                      ),
                                      builder: (_, data, __) => Text(
                                          '${(data.$1 ~/ 1000).toTime} / ${data.$2.toTime}'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Selector<AudioPlayerNotifier, EpisodeBrief?>(
                        selector: (_, audio) => audio.episodeBrief,
                        builder: (_, episodeBrief, __) => episodeBrief != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: Image(
                                            image: episodeBrief
                                                .episodeOrPodcastImageProvider)),
                                    Selector<AudioPlayerNotifier, int>(
                                      selector: (_, audio) {
                                        if (!audio.playerRunning &&
                                            episodeBrief.enclosureDuration !=
                                                0) {
                                          return (audio.audioPosition ~/
                                              (episodeBrief.enclosureDuration *
                                                  10));
                                        } else if (audio.playerRunning &&
                                            audio.audioDuration != 0) {
                                          return ((audio.audioPosition * 100) ~/
                                              audio.audioDuration);
                                        } else {
                                          return 0;
                                        }
                                      },
                                      builder: (_, progress, __) {
                                        return SizedBox(
                                          height: 80,
                                          width: 80,
                                          child: CustomPaint(
                                            painter: CircleProgressIndicator(
                                                progress,
                                                color: context.primaryColor
                                                    .withValues(alpha: 0.9)),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                    color: context.accentColor.withAlpha(70),
                                    borderRadius: BorderRadius.circular(10)),
                                width: 80,
                                height: 80),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                ),
                Container(
                  color: context.surface,
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tabWidget(
                          icon: Icon(Icons.queue_music_rounded),
                          label: s.playNext,
                          color: Colors.blue,
                          isSelected: _selected == 'PlayNext',
                          onTap: () => setState(() {
                                _body = _Queue();
                                _selected = 'PlayNext';
                              })),
                      _tabWidget(
                          icon: Icon(Icons.history),
                          label: s.settingsHistory,
                          color: Colors.green,
                          isSelected: _selected == 'History',
                          onTap: () => setState(() {
                                _body = _History();
                                _selected = 'History';
                              })),
                      _tabWidget(
                          icon: Icon(Icons.playlist_play),
                          label: s.playlists,
                          color: Colors.purple,
                          isSelected: _selected == 'Playlists',
                          onTap: () => setState(() {
                                _body = _Playlists();
                                _selected = 'Playlists';
                              })),
                    ],
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: Container(
                    // color: Colors.blue,
                    child: _body,
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class _Queue extends StatefulWidget {
  const _Queue();

  @override
  State<_Queue> createState() => _QueueState();
}

class _QueueState extends State<_Queue> {
  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return Selector<AudioPlayerNotifier, Playlist>(
      selector: (_, audio) => audio.playlist,
      builder: (_, playlist, __) {
        List<int> episodeIds = playlist.episodeIds.toList();
        return ReorderableListView.builder(
          itemCount: playlist.length,
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) newIndex -= 1;
            final episode = episodeIds.removeAt(oldIndex);
            episodeIds.insert(newIndex,
                episode); // Without this the animation isn't smooth as the below call takes time to complete (I think)
            await audio.reorderPlaylist(oldIndex, newIndex);
            if (mounted) setState(() {});
          },
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            if (audio.playerRunning && index == audio.episodeIndex) {
              return EpisodeTile(episodeIds[index],
                  key: ValueKey(episodeIds[index]),
                  isPlaying: true,
                  canReorder: true,
                  havePadding: true,
                  tileColor: context.accentBackground);
            } else {
              return DismissibleContainer(
                playlist: playlist,
                episodeId: episodeIds[index],
                index: index,
                onRemove: () {},
                key: ValueKey(episodeIds[index]),
              );
            }
          },
        );
      },
    );
  }
}

class _History extends StatefulWidget {
  const _History();

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  var dbHelper = DBHelper();
  bool _loadMore = false;
  late Future<List<PlayHistory>> _getData;
  int? _top;

  @override
  void initState() {
    super.initState();
    _top = 20;
    _getData = getPlayRecords(_top);
  }

  Future<List<PlayHistory>> getPlayRecords(int? top) async {
    List<PlayHistory> playHistory;
    playHistory = await dbHelper.getPlayRecords(top);
    if (mounted) {
      EpisodeState eState = context.episodeState;
      for (var record in playHistory) {
        await record.getEpisodeId(eState);
      }
    }
    return playHistory;
  }

  Future<void> _loadMoreData() async {
    if (mounted) {
      setState(() {
        _loadMore = true;
      });
    }
    await Future.delayed(Duration(milliseconds: 500));
    _top = _top! + 20;
    if (mounted) {
      setState(() {
        _getData = getPlayRecords(_top);
        _loadMore = false;
      });
    }
  }

  Size _getMaskStop(double seekValue, int seconds) {
    final size = (TextPainter(
            text: TextSpan(text: seconds.toTime),
            maxLines: 1,
            textScaler: MediaQuery.of(context).textScaler,
            textDirection: TextDirection.ltr)
          ..layout())
        .size;
    return size;
  }

  Widget _timeTag(BuildContext context,
      {required int episodeId,
      required int seconds,
      required double seekValue}) {
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    final textWidth = _getMaskStop(seekValue, seconds).width;
    final stop = seekValue - 20 / textWidth + 40 * seekValue / textWidth;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            audio.loadEpisodeToQueue(episodeId,
                startPosition: (seconds * 1000).toInt());
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(alignment: Alignment.center, children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  colors: <Color>[
                    context.accentColor,
                    context.primaryColorDark
                  ],
                  stops: [seekValue, seekValue],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: Container(
                margin: EdgeInsets.symmetric(
                    vertical:
                        0.5), // Prevents visual glitch where the white shows through on the top or bottom
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                width: textWidth + 40,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  colors: <Color>[Colors.white, context.accentColor],
                  stops: [stop, stop],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: Text(
                seconds.toTime,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _playlistButton(BuildContext context, {required int episodeId}) {
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    final s = context.s;
    return SizedBox(
      child: Selector<AudioPlayerNotifier, Playlist>(
        selector: (_, audio) => audio.playlist,
        builder: (_, data, __) {
          return data.contains(episodeId)
              ? IconButton(
                  icon: Icon(Icons.playlist_add_check,
                      color: context.accentColor),
                  onPressed: () async {
                    await audio.removeFromPlaylist([episodeId]);
                    await Fluttertoast.showToast(
                      msg: s.toastRemovePlaylist,
                      gravity: ToastGravity.BOTTOM,
                    );
                  })
              : IconButton(
                  icon: Icon(Icons.playlist_add, color: Colors.grey[700]),
                  onPressed: () async {
                    await audio.addToPlaylist([episodeId]);
                    await Fluttertoast.showToast(
                      msg: s.toastAddPlaylist,
                      gravity: ToastGravity.BOTTOM,
                    );
                  });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return FutureBuilder<List<PlayHistory>>(
        future: _getData,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        snapshot.data!.length == _top) {
                      if (!_loadMore) {
                        _loadMoreData();
                      }
                    }
                    return true;
                  },
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: snapshot.data!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == snapshot.data!.length) {
                          return SizedBox(
                              height: 2,
                              child: _loadMore
                                  ? LinearProgressIndicator()
                                  : Center());
                        } else {
                          final seekValue = snapshot.data![index].seekValue;
                          final seconds = snapshot.data![index].seconds;
                          final date = snapshot
                              .data![index].playdate!.millisecondsSinceEpoch;
                          final episodeId = snapshot.data![index].episodeId;
                          return episodeId == null
                              ? Center()
                              : SizedBox(
                                  height: 90.0,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: ListTile(
                                            contentPadding: EdgeInsets.fromLTRB(
                                                24, 8, 20, 8),
                                            onTap: () => audio
                                                .loadEpisodeToQueue(episodeId,
                                                    startPosition:
                                                        seekValue < 0.9
                                                            ? (seconds! * 1000)
                                                                .toInt()
                                                            : 0),
                                            leading: CircleAvatar(
                                                backgroundColor: context
                                                    .colorScheme
                                                    .secondaryContainer,
                                                backgroundImage: context
                                                    .episodeState[episodeId]
                                                    .episodeOrPodcastImageProvider),
                                            title: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 5.0),
                                              child: Text(
                                                snapshot.data![index].title!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            subtitle: SizedBox(
                                              height: 40,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: <Widget>[
                                                  if (seekValue! < 0.9)
                                                    _timeTag(context,
                                                        episodeId: episodeId,
                                                        seekValue: seekValue,
                                                        seconds: seconds!),
                                                  _playlistButton(context,
                                                      episodeId: episodeId),
                                                  Spacer(),
                                                  Text(
                                                    date.toDate(context),
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Divider(height: 1)
                                    ],
                                  ),
                                );
                        }
                      }),
                )
              : Center(
                  child: SizedBox(
                      height: 25,
                      width: 25,
                      child: CircularProgressIndicator()),
                );
        });
  }
}

class _Playlists extends StatefulWidget {
  const _Playlists();

  @override
  State<_Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<_Playlists> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final eState = context.episodeState;
    return Selector<AudioPlayerNotifier, Tuple2<List<Playlist>, int>>(
        selector: (_, audio) => Tuple2(audio.playlists, audio.playlists.length),
        // Getting the length seperately so the selector notices data changed
        builder: (_, data, __) {
          return ScrollConfiguration(
            behavior: NoGrowBehavior(),
            child: ListView.builder(
                itemCount: data.item2 + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final queue = data.item1.first;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                                  PlaylistDetail(data.item1[index])),
                        ).then((value) => setState(() {}));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              color: context.primaryColorDark,
                              child: FutureBuilder<Playlist>(
                                future: Future.sync(() async {
                                  await queue.cachePlaylist(eState);
                                  return queue;
                                }),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final queueSnapshot = snapshot.data!;
                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        childAspectRatio: 1,
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 0.0,
                                        crossAxisSpacing: 0.0,
                                      ),
                                      itemCount:
                                          math.min(queueSnapshot.length, 4),
                                      itemBuilder: (_, index) {
                                        if (index < queueSnapshot.length) {
                                          return Image(
                                            image: eState[queueSnapshot[index]]
                                                .episodeOrPodcastImageProvider,
                                          );
                                        }
                                        return Center();
                                      },
                                    );
                                  } else {
                                    return Center();
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 15),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.queue,
                                  style: context.textTheme.titleLarge,
                                ),
                                Text(
                                    '${queue.length} ${s.episode(queue.length).toLowerCase()}'),
                                TextButton(
                                  style: TextButton.styleFrom(
                                      foregroundColor: context.accentColor,
                                      textStyle: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    context
                                        .read<AudioPlayerNotifier>()
                                        .playlistLoad(queue);
                                  },
                                  child: Row(
                                    children: <Widget>[
                                      Text(s.play.toUpperCase(),
                                          style: TextStyle(
                                            color: context.accentColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      Icon(
                                        Icons.play_arrow,
                                        color: context.accentColor,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  if (index < data.item2) {
                    final episodeList = data.item1[index].episodeIds;
                    return ListTile(
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                                  PlaylistDetail(data.item1[index])),
                        );
                      },
                      leading: Container(
                        height: 50,
                        width: 50,
                        color: context.primaryColorDark,
                        child: FutureBuilder<bool>(
                          future: data.item1[index].cachePlaylist(eState),
                          builder: (context, snapshot) => episodeList.isEmpty ||
                                  !snapshot.hasData
                              ? Center()
                              : Image(
                                  image: Provider.of<EpisodeState>(context,
                                              listen: false)[
                                          data.item1[index].episodeIds.first]
                                      .podcastImageProvider),
                        ),
                      ),
                      title: Text(data.item1[index].name),
                      subtitle: Text(
                          '${data.item1[index].length} ${s.episode(data.item1[index].length).toLowerCase()}'),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: context.accentColor,
                            textStyle: TextStyle(fontWeight: FontWeight.bold)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(s.play.toUpperCase(),
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                )),
                            Icon(
                              Icons.play_arrow,
                              color: context.accentColor,
                            ),
                          ],
                        ),
                        onPressed: () {
                          context
                              .read<AudioPlayerNotifier>()
                              .playlistLoad(data.item1[index]);
                        },
                      ),
                    );
                  }
                  return ListTile(
                    onTap: () {
                      showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: MaterialLocalizations.of(context)
                              .modalBarrierDismissLabel,
                          barrierColor: Colors.black54,
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder:
                              (context, animaiton, secondaryAnimation) =>
                                  _NewPlaylist());
                    },
                    leading: Container(
                      height: 50,
                      width: 50,
                      color: context.primaryColorDark,
                      child: Center(child: Icon(Icons.add)),
                    ),
                    title: Text(s.createNewPlaylist),
                  );
                }),
          );
        });
  }
}

enum NewPlaylistOption { blank, random10, latest10, folder }

class _NewPlaylist extends StatefulWidget {
  const _NewPlaylist();

  @override
  State<_NewPlaylist> createState() => _NewPlaylistState();
}

class _NewPlaylistState extends State<_NewPlaylist> {
  final _dbHelper = DBHelper();
  String _playlistName = '';
  late NewPlaylistOption _option;
  late bool _processing;
  FocusNode? _focusNode;
  int? _error;

  @override
  void initState() {
    super.initState();
    _processing = false;
    _focusNode = FocusNode();
    _option = NewPlaylistOption.blank;
  }

  Future<List<int>> _random() =>
      Provider.of<EpisodeState>(context, listen: false).getEpisodes(
          excludedFeedIds: [localFolderId], sortBy: Sorter.random, limit: 10);

  Future<List<int>> _recent() =>
      Provider.of<EpisodeState>(context, listen: false).getEpisodes(
          excludedFeedIds: [localFolderId],
          sortBy: Sorter.pubDate,
          sortOrder: SortOrder.desc,
          limit: 10);

  Widget _createOption(NewPlaylistOption option) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() => _option = option);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _option == option
                  ? context.accentColor
                  : context.primaryColorDark),
          child: Text(_optionLabel(option).first,
              style: TextStyle(
                  color: _option == option ? Colors.white : context.textColor)),
        ),
      ),
    );
  }

  List<String> _optionLabel(NewPlaylistOption option) {
    switch (option) {
      case NewPlaylistOption.blank:
        return ['Empty', 'Add episodes later'];
      case NewPlaylistOption.random10:
        return ['Randon 10', 'Add 10 random episodes to playlists'];
      case NewPlaylistOption.latest10:
        return ['Latest 10', 'Add 10 latest updated episodes to playlist'];
      case NewPlaylistOption.folder:
        return ['Local folder', 'Choose a local folder'];
    }
  }

  Future<bool> _checkPermmison() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    Permission permission;
    if (androidInfo.version.sdkInt >= 33) {
      permission = Permission.audio;
    } else {
      permission = Permission.storage;
    }

    final permissionStatus = await permission.status;
    if (permissionStatus != PermissionStatus.granted) {
      await [permission].request();
      if (await permission.status == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<List<int>> _loadLocalFolder() async {
    String? dirPath;
    try {
      dirPath = await FilePicker.platform.getDirectoryPath();
    } catch (e) {
      developer.log(e.toString(), name: 'Failed to load dir.');
    }
    final localFolder = await _dbHelper.getPodcastLocal([localFolderId]);
    if (localFolder.isEmpty || true) {
      String defaultColor = "[28, 204, 196]"; // Color of avatar_backup
      final dir = await getApplicationDocumentsDirectory();
      if (!File("${dir.path}/avatar_backup.png").existsSync()) {
        final byteData = await rootBundle.load('assets/avatar_backup.png');

        final file = File('${dir.path}/assets/avatar_backup.png');
        file.createSync(recursive: true);
        file.writeAsBytesSync(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }
      final localPodcast = PodcastLocal(
        'Local Folder',
        '',
        '',
        defaultColor,
        'Local Folder',
        localFolderId,
        "${dir.path}/assets/avatar_backup.png",
        '',
        '',
        [],
      );
      await _dbHelper.savePodcastLocal(localPodcast);
    }
    final episodeIds = <int>[];
    if (dirPath != null) {
      var dir = Directory(dirPath);
      for (var file in dir.listSync()) {
        if (file is File) {
          if (file.path.split('.').last == 'mp3') {
            final episode = await _getEpisodeFromFile(file.path);
            episodeIds.add(await _dbHelper.saveLocalEpisode(episode));
          }
        }
      }
    }
    if (mounted) {
      context.episodeState.getEpisodes(episodeIds: episodeIds);
    }
    return episodeIds;
  }

  Future<EpisodeBrief> _getEpisodeFromFile(String path) async {
    final fileLength = File(path).statSync().size;
    final pubDate = DateTime.now().millisecondsSinceEpoch;
    String? primaryColor;
    String? imagePath;
    var metadata = await MetadataRetriever.fromFile(File(path));
    if (metadata.albumArt != null) {
      final dir = await getApplicationDocumentsDirectory();
      final image = img.decodeImage(metadata.albumArt!)!;
      final thumbnail = img.copyResize(image, width: 300);
      var uuid = Uuid().v4();
      imagePath =
          "${dir.path}/fromLocalFolder/$uuid.png"; // TODO: I couldn't get this to show up on the notification :(
      final file = File(imagePath);
      file.createSync(recursive: true);
      file.writeAsBytesSync(img.encodePng(thumbnail));
      primaryColor = await _getColor(File(imagePath));
    }
    final fileName = path.split('/').last;
    return EpisodeBrief.local(
      title: fileName, enclosureUrl: 'file://$path',
      podcastTitle: metadata.albumName ?? '',
      pubDate: pubDate, // metadata.year ?
      description: context.s.localEpisodeDescription(path),
      enclosureDuration: metadata.trackDuration! ~/ 1000,
      enclosureSize: fileLength,
      mediaId: 'file://$path',
      episodeImage: imagePath ?? '',
      primaryColor: primaryColor?.toColor(),
    );
  }

  Future<String> _getColor(File file) async {
    final imageProvider = FileImage(file);
    var colorImage = await getImageFromProvider(imageProvider);
    var color = await getColorFromImage(colorImage);
    var primaryColor = color.toString();
    return primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final eState = context.episodeState;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor:
            Theme.of(context).brightness == Brightness.light
                ? Color.fromRGBO(113, 113, 113, 1)
                : Color.fromRGBO(5, 5, 5, 1),
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        backgroundColor: context.accentBackgroundWeak,
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        titlePadding: EdgeInsets.all(20),
        actionsPadding: EdgeInsets.zero,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              s.cancel,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (!_processing) {
                if (_playlistName == '') {
                  setState(() => _error = 0);
                } else if (context
                    .read<AudioPlayerNotifier>()
                    .playlistExists(_playlistName)) {
                  setState(() => _error = 1);
                } else {
                  Playlist playlist;
                  switch (_option) {
                    case NewPlaylistOption.blank:
                      playlist = Playlist(
                        _playlistName,
                      );
                      break;
                    case NewPlaylistOption.latest10:
                      if (mounted) {
                        setState(() {
                          _processing = true;
                        });
                      }
                      final recent = await _recent();
                      playlist = Playlist(
                        _playlistName,
                        episodeIds: recent,
                      );
                      await playlist.cachePlaylist(eState);
                      if (mounted) {
                        setState(() {
                          _processing = false;
                        });
                      }
                      break;
                    case NewPlaylistOption.random10:
                      if (mounted) {
                        setState(() {
                          _processing = true;
                        });
                      }
                      final random = await _random();
                      playlist = Playlist(
                        _playlistName,
                        episodeIds: random,
                      );
                      await playlist.cachePlaylist(eState);
                      if (mounted) {
                        setState(() {
                          _processing = false;
                        });
                      }
                      break;
                    case NewPlaylistOption.folder:
                      _focusNode!.unfocus();
                      if (mounted) {
                        setState(() {
                          _processing = true;
                        });
                      }
                      if (!(await _checkPermmison())) {
                        Navigator.of(context).pop();
                        return;
                      }
                      final episodes = await _loadLocalFolder();
                      if (episodes.isEmpty) {
                        if (context.mounted) Navigator.of(context).pop();
                        return;
                      }
                      playlist = Playlist(
                        _playlistName,
                        isLocal: true,
                        episodeIds: episodes,
                      );
                      await playlist.cachePlaylist(eState);
                      if (mounted) {
                        setState(() {
                          _processing = false;
                        });
                      }
                      break;
                  }
                  context.read<AudioPlayerNotifier>().addPlaylist(playlist);
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text(s.confirm,
                style: TextStyle(
                    color:
                        _processing ? Colors.grey[600] : context.accentColor)),
          )
        ],
        title: SizedBox(
            width: context.width - 160, child: Text(s.createNewPlaylist)),
        content: _processing
            ? SizedBox(
                height: 50,
                child: Center(
                  child: Platform.isIOS
                      ? CupertinoActivityIndicator()
                      : CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      hintText: s.createNewPlaylist,
                      hintStyle: TextStyle(fontSize: 18),
                      filled: true,
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: context.accentColor, width: 2.0),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: context.accentColor, width: 2.0),
                      ),
                    ),
                    cursorRadius: Radius.circular(2),
                    autofocus: true,
                    maxLines: 1,
                    onChanged: (value) {
                      _playlistName = value;
                    },
                  ),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: _error != null
                          ? Text(
                              _error == 1
                                  ? s.playlistExisted
                                  : s.playlistNameEmpty,
                              style: TextStyle(color: Colors.red[400]),
                            )
                          : Center()),
                  SizedBox(height: 10),
                  Wrap(
                    children: [
                      _createOption(NewPlaylistOption.blank),
                      _createOption(NewPlaylistOption.random10),
                      _createOption(NewPlaylistOption.latest10),
                      _createOption(NewPlaylistOption.folder)
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
