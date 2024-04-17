import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:color_thief_dart/color_thief_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import '../home/home.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
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
  PlaylistHome({Key? key}) : super(key: key);

  @override
  _PlaylistHomeState createState() => _PlaylistHomeState();
}

class _PlaylistHomeState extends State<PlaylistHome> {
  Widget? _body;
  String? _selected;

  @override
  void initState() {
    Future.microtask(() => context.read<AudioPlayerNotifier>().initPlaylists());
    super.initState();
    //context.read<AudioPlayerNotifier>().initPlaylist();
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
            side: BorderSide(color: context.background),
            primary: color,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarIconBrightness:
            Theme.of(context).colorScheme.brightness,
        statusBarIconBrightness: Theme.of(context).colorScheme.brightness,
        systemNavigationBarColor: Theme.of(context).primaryColor,
      ),
      child: WillPopScope(
        onWillPop: () {
          if (context.read<SettingState>().openPlaylistDefault!) {
            Navigator.push(context, SlideRightRoute(page: Home()));
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
            backgroundColor: context.background,
            appBar: AppBar(
              leading: CustomBackButton(),
              centerTitle: true,
              title: Selector<AudioPlayerNotifier, EpisodeBrief?>(
                selector: (_, audio) => audio.episode,
                builder: (_, data, __) {
                  return Text(
                    data?.title ?? '',
                    maxLines: 1,
                    style: context.textTheme.headlineSmall,
                  );
                },
              ),
              backgroundColor: context.background,
              scrolledUnderElevation: 0,
            ),
            body: Column(
              children: [
                Container(
                  color: context.background,
                  height: 100,
                  child: Selector<AudioPlayerNotifier,
                      Tuple4<Playlist?, bool, bool, EpisodeBrief?>>(
                    selector: (_, audio) => Tuple4(audio.playlist,
                        audio.playerRunning, audio.playing, audio.episode),
                    builder: (_, data, __) {
                      final running = data.item2;
                      final playing = data.item3;
                      final audio = context.read<AudioPlayerNotifier>();
                      return Row(
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
                                        if (running) {
                                          audio.rewind();
                                        }
                                      }),
                                  SizedBox(width: 15),
                                  IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                          playing
                                              ? LineIcons.pauseCircle
                                              : LineIcons.play,
                                          size: 40),
                                      onPressed: () {
                                        if (running) {
                                          playing
                                              ? audio.pauseAduio()
                                              : audio.resumeAudio();
                                        } else if (data.item1!.isEmpty) {
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
                                        if (running) {
                                          audio.fastForward();
                                        }
                                      }),
                                  IconButton(
                                      splashRadius: 20,
                                      icon: Icon(Icons.skip_next),
                                      onPressed: () {
                                        if (running &&
                                            !(data.item1!.length == 1 &&
                                                !data.item1!.isQueue)) {
                                          audio.skipToNext();
                                        }
                                      }),
                                ],
                              ),
                              SizedBox(height: 10),
                              if (data.item2)
                                Selector<AudioPlayerNotifier,
                                    Tuple4<bool, int?, String?, int>>(
                                  selector: (_, audio) => Tuple4(
                                      audio.buffering,
                                      audio.audioPosition,
                                      audio.remoteErrorMessage,
                                      audio.audioDuration),
                                  builder: (_, info, __) {
                                    return info.item3 != null
                                        ? Text(info.item3!,
                                            style: TextStyle(
                                                color: Color(0xFFFF0000)))
                                        : info.item1
                                            ? Text(
                                                s.buffering,
                                                style: TextStyle(
                                                    color: context.accentColor),
                                              )
                                            : Text(
                                                '${(info.item2! ~/ 1000).toTime} / ${(info.item4 ~/ 1000).toTime}');
                                  },
                                ),
                              if (!data.item2)
                                Selector<AudioPlayerNotifier, int>(
                                  selector: (_, audio) =>
                                      audio.audioStartPosition,
                                  builder: (_, position, __) {
                                    return Text(
                                        '${(position ~/ 1000).toTime} / ${(data.item4?.enclosureDuration ?? 0).toTime}');
                                  },
                                ),
                            ],
                          )),
                          data.item4 != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: Image(
                                              image: data.item4!.avatarImage)),
                                      Selector<AudioPlayerNotifier, int>(
                                        selector: (_, audio) {
                                          if (!audio.playerRunning &&
                                              audio.episode!
                                                      .enclosureDuration !=
                                                  0) {
                                            return (audio.audioPosition ~/
                                                (audio.episode!
                                                        .enclosureDuration! *
                                                    10));
                                          } else if (audio.playerRunning &&
                                              audio.audioDuration != 0) {
                                            return ((audio.audioPosition! *
                                                    100) ~/
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
                                                      .withOpacity(0.9)),
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
                          SizedBox(
                            width: 20,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  color: context.background,
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
  const _Queue({Key? key}) : super(key: key);

  @override
  __QueueState createState() => __QueueState();
}

class __QueueState extends State<_Queue> {
  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerNotifier, Tuple3<Playlist?, bool, int?>>(
      selector: (_, audio) =>
          Tuple3(audio.playlist, audio.playerRunning, audio.episodeIndex),
      builder: (_, data, __) {
        Playlist? playlist = data.item1;
        bool running = data.item2;
        int? episodeIndex = data.item3;
        if (playlist == null || episodeIndex == null) {
          return Center();
        } else {
          List<EpisodeBrief> episodes = playlist.episodes;
          return ReorderableListView.builder(
            itemCount: playlist.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              context
                  .read<AudioPlayerNotifier>()
                  .reorderPlaylist(oldIndex, newIndex);
              setState(() {});
            },
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              if (running && index == episodeIndex) {
                return EpisodeTile(episodes[index],
                    key: ValueKey(episodes[index].enclosureUrl),
                    isPlaying: true,
                    canReorder: true,
                    havePadding: true,
                    tileColor: context.accentBackground);
              } else {
                return DismissibleContainer(
                  episode: episodes[index],
                  index: index,
                  onRemove: (value) => setState(() {}),
                  key: ValueKey(episodes[index].enclosureUrl),
                );
              }
            },
          );
        }
      },
    );
  }
}

class _History extends StatefulWidget {
  const _History({Key? key}) : super(key: key);

  @override
  __HistoryState createState() => __HistoryState();
}

class __HistoryState extends State<_History> {
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
    for (var record in playHistory) {
      await record.getEpisode();
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
            textScaleFactor: MediaQuery.of(context).textScaleFactor,
            textDirection: TextDirection.ltr)
          ..layout())
        .size;
    return size;
  }

  Widget _timeTag(BuildContext context,
      {required EpisodeBrief episode,
      required int seconds,
      required double seekValue}) {
    final audio = context.watch<AudioPlayerNotifier>();
    final textWidth = _getMaskStop(seekValue, seconds).width;
    final stop = seekValue - 20 / textWidth + 40 * seekValue / textWidth;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            audio.episodeLoad(episode, startPosition: (seconds * 1000).toInt());
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

  Widget _playlistButton(BuildContext context, {EpisodeBrief? episode}) {
    final audio = context.watch<AudioPlayerNotifier>();
    final s = context.s;
    return SizedBox(
      child: Selector<AudioPlayerNotifier, List<EpisodeBrief?>>(
        selector: (_, audio) => audio.queue.episodes,
        builder: (_, data, __) {
          return data.contains(episode)
              ? IconButton(
                  icon: Icon(Icons.playlist_add_check,
                      color: context.accentColor),
                  onPressed: () async {
                    audio.delFromPlaylist(episode!);
                    Fluttertoast.showToast(
                      msg: s.toastRemovePlaylist,
                      gravity: ToastGravity.BOTTOM,
                    );
                  })
              : IconButton(
                  icon: Icon(Icons.playlist_add, color: Colors.grey[700]),
                  onPressed: () async {
                    await audio.addToPlaylistPlus([episode!]);
                    Fluttertoast.showToast(
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
    final audio = context.watch<AudioPlayerNotifier>();
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
                          final episode = snapshot.data![index].episode;
                          return episode == null
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
                                            onTap: () => audio.episodeLoad(
                                                episode,
                                                startPosition: seekValue! < 0.9
                                                    ? (seconds! * 1000).toInt()
                                                    : 0),
                                            leading: CircleAvatar(
                                                backgroundColor: context
                                                    .colorScheme
                                                    .secondaryContainer,
                                                backgroundImage: episode
                                                    .podcastImageProvider),
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
                                                        episode: episode,
                                                        seekValue: seekValue,
                                                        seconds: seconds!),
                                                  _playlistButton(context,
                                                      episode: episode),
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
  const _Playlists({Key? key}) : super(key: key);

  @override
  __PlaylistsState createState() => __PlaylistsState();
}

class __PlaylistsState extends State<_Playlists> {
  Future<EpisodeBrief?> _getEpisode(String url) async {
    var dbHelper = DBHelper();
    List episodes = await dbHelper.getEpisodes(episodeUrls: [
      url
    ], optionalFields: [
      EpisodeField.mediaId,
      EpisodeField.primaryColor,
      EpisodeField.isNew,
      EpisodeField.skipSecondsStart,
      EpisodeField.skipSecondsEnd,
      EpisodeField.episodeImage,
      EpisodeField.chapterLink
    ]);
    if (episodes.isEmpty)
      return null;
    else
      return episodes[0];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Selector<AudioPlayerNotifier, List<Playlist>>(
        selector: (_, audio) => audio.playlists,
        builder: (_, data, __) {
          return ScrollConfiguration(
            behavior: NoGrowBehavior(),
            child: ListView.builder(
                itemCount: data.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final queue = data.first;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                                  PlaylistDetail(data[index])),
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
                              child: GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    childAspectRatio: 1,
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 0.0,
                                    crossAxisSpacing: 0.0,
                                  ),
                                  itemCount: math.min(queue.episodes.length, 4),
                                  itemBuilder: (_, index) {
                                    if (index < queue.episodeList.length) {
                                      return Image(
                                        image:
                                            queue.episodes[index]!.avatarImage,
                                      );
                                    }
                                    return Center();
                                  }),
                            ),
                            SizedBox(width: 15),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.queue,
                                  style: context.textTheme.headline6,
                                ),
                                Text(
                                    '${queue.length} ${s.episode(queue.length).toLowerCase()}'),
                                TextButton(
                                  style: TextButton.styleFrom(
                                      primary: context.accentColor,
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
                  if (index < data.length) {
                    final episodeList = data[index].episodeList;
                    return ListTile(
                      onTap: () async {
                        await context
                            .read<AudioPlayerNotifier>()
                            .updatePlaylist(data[index], updateEpisodes: true);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) =>
                                  PlaylistDetail(data[index])),
                        );
                      },
                      leading: Container(
                        height: 50,
                        width: 50,
                        color: context.primaryColorDark,
                        child: episodeList.isEmpty
                            ? Center()
                            : FutureBuilder<EpisodeBrief?>(
                                future: _getEpisode(episodeList.first),
                                builder: (_, snapshot) {
                                  if (snapshot.data != null) {
                                    return SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: Image(
                                            image: snapshot.data!.avatarImage));
                                  }
                                  return Center();
                                }),
                      ),
                      title: Text(data[index].name!),
                      subtitle: Text(
                          '${data[index].length} ${s.episode(data[index].length).toLowerCase()}'),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                            primary: context.accentColor,
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
                              .playlistLoad(data[index]);
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

enum NewPlaylistOption { blank, randon10, latest10, folder }

class _NewPlaylist extends StatefulWidget {
  _NewPlaylist({Key? key}) : super(key: key);

  @override
  __NewPlaylistState createState() => __NewPlaylistState();
}

class __NewPlaylistState extends State<_NewPlaylist> {
  final _dbHelper = DBHelper();
  String _playlistName = '';
  NewPlaylistOption? _option;
  late bool _loadFolder;
  FocusNode? _focusNode;
  int? _error;

  @override
  void initState() {
    super.initState();
    _loadFolder = false;
    _focusNode = FocusNode();
    _option = NewPlaylistOption.blank;
  }

  Future<List<EpisodeBrief>> _random() async {
    return await _dbHelper.getEpisodes(
        excludedFeedIds: [localFolderId], sortBy: Sorter.random, limit: 10);
  }

  Future<List<EpisodeBrief>> _recent() async {
    return await _dbHelper.getEpisodes(
        excludedFeedIds: [localFolderId],
        sortBy: Sorter.pubDate,
        sortOrder: SortOrder.DESC,
        limit: 10);
  }

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
      case NewPlaylistOption.randon10:
        return ['Randon 10', 'Add 10 random episodes to playlists'];
      case NewPlaylistOption.latest10:
        return ['Latest 10', 'Add 10 latest updated episodes to playlist'];
      case NewPlaylistOption.folder:
        return ['Local folder', 'Choose a local folder'];
      default:
        return ['', ''];
    }
  }

  Future<List<EpisodeBrief>> _loadLocalFolder() async {
    var episodes = <EpisodeBrief>[];
    var dirPath;
    try {
      dirPath = await FilePicker.platform.getDirectoryPath();
    } catch (e) {
      developer.log(e.toString(), name: 'Failed to load dir.');
    }
    final localFolder = await _dbHelper.getPodcastLocal([localFolderId]);
    if (localFolder.isEmpty) {
      final localPodcast = PodcastLocal('Local Folder', '', '', '',
          'Local Folder', localFolderId, '', '', '', []);
      await _dbHelper.savePodcastLocal(localPodcast);
    }
    if (dirPath != null) {
      var dir = Directory(dirPath);
      for (var file in dir.listSync()) {
        if (file is File) {
          if (file.path.split('.').last == 'mp3') {
            final episode = await _getEpisodeFromFile(file.path);
            episodes.add(episode);
            await _dbHelper.saveLocalEpisode(episode);
          }
        }
      }
    }
    return episodes;
  }

  Future<EpisodeBrief> _getEpisodeFromFile(String path) async {
    final fileLength = File(path).statSync().size;
    final pubDate = DateTime.now().millisecondsSinceEpoch;
    var primaryColor;
    var imagePath;
    var metadata = await MetadataRetriever.fromFile(File(path));
    if (metadata.albumArt != null) {
      final dir = await getApplicationDocumentsDirectory();
      final image = img.decodeImage(metadata.albumArt!)!;
      final thumbnail = img.copyResize(image, width: 300);
      var uuid = Uuid().v4();
      File("${dir.path}/$uuid.png").writeAsBytesSync(img.encodePng(thumbnail));
      imagePath = "${dir.path}/$uuid.png";
      primaryColor = await _getColor(File(imagePath));
    }
    final fileName = path.split('/').last;
    return EpisodeBrief(0, fileName, 'file://$path', localFolderId,
        metadata.albumName ?? '', pubDate, // metadata.year ?
        description: context.s.localEpisodeDescription(path),
        enclosureDuration: metadata.trackDuration,
        enclosureSize: fileLength,
        mediaId: 'file://$path',
        podcastImage: '',
        episodeImage: imagePath ?? '',
        primaryColor: primaryColor);
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
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        titlePadding: EdgeInsets.all(20),
        actionsPadding: EdgeInsets.zero,
        actions: <Widget>[
          FlatButton(
            splashColor: context.accentColor.withAlpha(70),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              s.cancel,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          FlatButton(
            splashColor: context.accentColor.withAlpha(70),
            onPressed: () async {
              if (_playlistName == '') {
                setState(() => _error = 0);
              } else if (context
                  .read<AudioPlayerNotifier>()
                  .playlistExists(_playlistName)) {
                setState(() => _error = 1);
              } else {
                var playlist;
                switch (_option) {
                  case NewPlaylistOption.blank:
                    playlist = Playlist(
                      _playlistName,
                    );
                    break;
                  case NewPlaylistOption.latest10:
                    final recent = await _recent();
                    playlist = Playlist(
                      _playlistName,
                      episodeList: [for (var e in recent) e.enclosureUrl],
                    );
                    await playlist.getPlaylist();
                    break;
                  case NewPlaylistOption.randon10:
                    final random = await _random();
                    playlist = Playlist(
                      _playlistName,
                      episodeList: [for (var e in random) e.enclosureUrl],
                    );
                    await playlist.getPlaylist();
                    break;
                  case NewPlaylistOption.folder:
                    _focusNode!.unfocus();
                    setState(() {
                      _loadFolder = true;
                    });
                    final episodes = await _loadLocalFolder();
                    if (episodes.isNotEmpty) {
                      playlist = Playlist(
                        _playlistName,
                        isLocal: true,
                        episodeList: [for (var e in episodes) e.enclosureUrl],
                      );
                      await playlist.getPlaylist();
                    }
                    if (mounted) {
                      setState(() {
                        _loadFolder = false;
                      });
                    }
                    break;
                  default:
                    break;
                }
                if (playlist != null) {
                  context.read<AudioPlayerNotifier>().addPlaylist(playlist);
                }
                Navigator.of(context).pop();
              }
            },
            child:
                Text(s.confirm, style: TextStyle(color: context.accentColor)),
          )
        ],
        title: SizedBox(
            width: context.width - 160, child: Text(s.createNewPlaylist)),
        content: _loadFolder
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
                      _createOption(NewPlaylistOption.randon10),
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
