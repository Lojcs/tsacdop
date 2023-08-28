import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/episodes/menu_bar.dart';
import 'package:tsacdop/episodes/shownote.dart';
import 'package:tsacdop/util/helpers.dart';
import 'package:tsacdop/widgets/custom_dropdown.dart';
import 'package:tuple/tuple.dart';

import '../home/audioplayer.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../util/extension_helper.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_widget.dart';

class EpisodeDetail extends StatefulWidget {
  final EpisodeBrief? episodeItem;
  final String heroTag;
  final bool hide;
  EpisodeDetail(
      {this.episodeItem, this.heroTag = '', this.hide = false, Key? key})
      : super(key: key);

  @override
  _EpisodeDetailState createState() => _EpisodeDetailState();
}

class _EpisodeDetailState extends State<EpisodeDetail> {
  final _dbHelper = DBHelper();
  final textstyle = TextStyle(fontSize: 15.0, color: Colors.black);
  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();
  double? downloadProgress;

  /// Show page title.
  late bool _showTitle;
  late bool _showMenu;
  late EpisodeBrief _episodeItem;
  late bool updated;
  String? path;

  Future<PlayHistory> _getPosition(EpisodeBrief episode) async {
    return await _dbHelper.getPosition(episode);
  }

  late ScrollController _controller;
  _scrollListener() {
    if (_controller.position.userScrollDirection == ScrollDirection.reverse) {
      if (_showMenu && mounted) {
        setState(() {
          _showMenu = false;
        });
      }
    }
    if (_controller.position.userScrollDirection == ScrollDirection.forward) {
      if (!_showMenu && mounted) {
        setState(() {
          _showMenu = true;
        });
      }
    }
    if (_controller.offset > context.textTheme.headline5!.fontSize!) {
      if (!_showTitle) setState(() => _showTitle = true);
    } else if (_showTitle) setState(() => _showTitle = false);
  }

  @override
  void initState() {
    super.initState();
    _showMenu = true;
    _showTitle = false;
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    _episodeItem = widget.episodeItem!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final audio = context.watch<AudioPlayerNotifier>();
    return Selector<EpisodeState, bool>(
        selector: (_, episodeState) =>
            episodeState.episodeChangeMap[_episodeItem.id]!,
        builder: (_, data, __) => FutureBuilder<EpisodeBrief>(
            future: _episodeItem.copyWithFromDB(update: true),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _episodeItem = snapshot.data!;
              }
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                    statusBarColor: _episodeItem.cardColor(context),
                    systemNavigationBarColor: _episodeItem!.cardColor(context),
                    systemNavigationBarContrastEnforced: false,
                    systemNavigationBarIconBrightness: context.iconBrightness,
                    statusBarBrightness: context.brightness,
                    statusBarIconBrightness: context.iconBrightness),
                child: WillPopScope(
                  onWillPop: () async {
                    if (_playerKey.currentState != null &&
                        _playerKey.currentState!.initSize! > 100) {
                      _playerKey.currentState!.backToMini();
                      return false;
                    } else {
                      return true;
                    }
                  },
                  child: Scaffold(
                    backgroundColor: context.background,
                    body: SafeArea(
                      child: Stack(
                        children: <Widget>[
                          StretchingOverscrollIndicator(
                            axisDirection: AxisDirection.down,
                            child: NestedScrollView(
                              scrollDirection: Axis.vertical,
                              controller: _controller,
                              headerSliverBuilder: (context, innerBoxScrolled) {
                                return <Widget>[
                                  SliverAppBar(
                                    backgroundColor:
                                        _episodeItem.cardColor(context),
                                    floating: true,
                                    pinned: true,
                                    scrolledUnderElevation: 0,
                                    title: _showTitle
                                        ? Text(
                                            _episodeItem.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : Text(
                                            _episodeItem.podcastTitle,
                                            maxLines: 1,
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: context.textColor
                                                    .withOpacity(0.7)),
                                          ),
                                    leading: CustomBackButton(),
                                    elevation: 0,
                                  ),
                                ];
                              },
                              body: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _episodeItem.title,
                                          textAlign: TextAlign.left,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 10, 20, 10),
                                      child: Row(
                                        children: [
                                          if (_episodeItem.versionInfo ==
                                              VersionInfo.NONE)
                                            DropdownButton(
                                              hint: Text(
                                                  s.published(formateDate(
                                                      _episodeItem.pubDate)),
                                                  style: TextStyle(
                                                      color:
                                                          context.accentColor)),
                                              underline: Center(),
                                              isDense: true,
                                              icon: Center(),
                                              items: [
                                                DropdownMenuItem(
                                                    child: Text(
                                                        s.published(formateDate(
                                                            _episodeItem
                                                                .pubDate)),
                                                        style: TextStyle(
                                                            color: context
                                                                .accentColor)))
                                              ],
                                              onChanged: null,
                                            )
                                          else
                                            FutureBuilder<EpisodeBrief>(
                                              // TODO: Make ui responsive.
                                              future: _getEpisodeVersions(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  List<EpisodeBrief?> versions =
                                                      snapshot.data!.versions!
                                                          .values
                                                          .toList();
                                                  versions.sort((a, b) => b!
                                                      .pubDate
                                                      .compareTo(a!.pubDate));
                                                  return MyDropdownButton(
                                                      hint: Text(
                                                          s.published(formateDate(
                                                              _episodeItem
                                                                  .pubDate)),
                                                          style: TextStyle(
                                                              color: context
                                                                  .accentColor)),
                                                      underline: Center(),
                                                      isDense: true,
                                                      value: versions
                                                          .singleWhere((e) =>
                                                              e!.versionInfo !=
                                                              VersionInfo.IS),
                                                      items: versions
                                                          .map((e) =>
                                                              DropdownMenuItem(
                                                                  value: e,
                                                                  child: Row(
                                                                    children: [
                                                                      Text(
                                                                          s.published(formateDate(e!
                                                                              .pubDate)),
                                                                          style:
                                                                              TextStyle(color: context.accentColor))
                                                                    ],
                                                                  )))
                                                          .toList(),
                                                      onChanged: (EpisodeBrief?
                                                          episode) {
                                                        _setEpisodeDisplayVersion(
                                                            episode!);
                                                      });
                                                } else {
                                                  return Center();
                                                }
                                              },
                                            ),
                                          SizedBox(width: 10),
                                          if (_episodeItem.isExplicit == true)
                                            Text('E',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: context.error))
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: Row(
                                        children: <Widget>[
                                          if (_episodeItem.enclosureDuration !=
                                              0)
                                            Container(
                                                decoration: BoxDecoration(
                                                    color: context.secondary,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                16.0))),
                                                height: 30.0,
                                                margin: EdgeInsets.only(
                                                    right: 12.0),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10.0),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  s.minsCount(
                                                    _episodeItem
                                                            .enclosureDuration! ~/
                                                        60,
                                                  ),
                                                  style: TextStyle(
                                                      color:
                                                          context.background),
                                                )),
                                          if (_episodeItem!.enclosureSize !=
                                                  null &&
                                              _episodeItem!.enclosureSize != 0)
                                            Container(
                                              decoration: BoxDecoration(
                                                  color: context.tertiary,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              16.0))),
                                              height: 30.0,
                                              margin:
                                                  EdgeInsets.only(right: 12.0),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10.0),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${_episodeItem!.enclosureSize! ~/ 1000000}MB',
                                                style: TextStyle(
                                                    color: context.background),
                                              ),
                                            ),
                                          FutureBuilder<PlayHistory>(
                                              future:
                                                  _getPosition(_episodeItem!),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  developer.log(
                                                      snapshot.error as String);
                                                }
                                                if (snapshot.hasData &&
                                                    snapshot.data!.seekValue! <
                                                        0.9 &&
                                                    snapshot.data!.seconds! >
                                                        10) {
                                                  return ButtonTheme(
                                                    height: 28,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 0),
                                                    child: OutlinedButton(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            side: BorderSide(
                                                                color: context
                                                                    .accentColor)),
                                                      ),
                                                      onPressed: () =>
                                                          audio.episodeLoad(
                                                              _episodeItem,
                                                              startPosition:
                                                                  (snapshot.data!
                                                                              .seconds! *
                                                                          1000)
                                                                      .toInt()),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child: CustomPaint(
                                                              painter:
                                                                  ListenedPainter(
                                                                      context
                                                                          .textColor,
                                                                      stroke:
                                                                          2.0),
                                                            ),
                                                          ),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            snapshot
                                                                .data!
                                                                .seconds!
                                                                .toTime,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  return Center();
                                                }
                                              }),
                                        ],
                                      ),
                                    ),
                                    ShowNote(episode: _episodeItem),
                                    Selector<AudioPlayerNotifier,
                                            Tuple2<bool, PlayerHeight?>>(
                                        selector: (_, audio) => Tuple2(
                                            audio.playerRunning,
                                            audio.playerHeight),
                                        builder: (_, data, __) {
                                          final height = kMinPlayerHeight[
                                              data.item2!.index];
                                          return SizedBox(
                                            height: data.item1 ? height : 0,
                                          );
                                        }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Selector<AudioPlayerNotifier,
                              Tuple2<bool, PlayerHeight?>>(
                            selector: (_, audio) =>
                                Tuple2(audio.playerRunning, audio.playerHeight),
                            builder: (_, data, __) {
                              final height =
                                  kMinPlayerHeight[data.item2!.index];
                              return Container(
                                alignment: Alignment.bottomCenter,
                                padding: EdgeInsets.only(
                                    bottom: data.item1 ? height : 0),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 400),
                                  height: _showMenu ? 50 : 0,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: MenuBar(
                                        episodeItem: _episodeItem,
                                        heroTag: widget.heroTag,
                                        hide: widget.hide),
                                  ),
                                ),
                              );
                            },
                          ),
                          Selector<AudioPlayerNotifier, EpisodeBrief?>(
                            selector: (_, audio) => audio.episode,
                            builder: (_, data, __) => Container(
                              child: PlayerWidget(
                                  playerKey: _playerKey,
                                  isPlayingPage: data == _episodeItem),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }));
  }

  Future<EpisodeBrief> _getEpisodeVersions() async {
    if (_episodeItem.versions == null ||
        _episodeItem.versions!.containsValue(null)) {
      EpisodeBrief episode = await _dbHelper.populateEpisodeVersions(
          _episodeItem); // Not using copyWithFromDB since we need the original.
      _episodeItem = episode;
    }
    return _episodeItem;
  }

  Future<void> _setEpisodeDisplayVersion(EpisodeBrief episode) async {
    await _dbHelper.setEpisodeDisplayVersion(episode);
    Map<int, EpisodeBrief?>? versions = episode.versions!;
    for (int version in versions.keys) {
      if (versions[version]!.versionInfo == VersionInfo.FHAS ||
          versions[version]!.versionInfo == VersionInfo.HAS) {
        versions[versions[version]!.id] =
            versions[version]!.copyWith(versionInfo: VersionInfo.IS);
      }
    }
    episode =
        episode.copyWith(versionInfo: VersionInfo.FHAS, versions: versions);
    episode.versions![episode.id] = episode;
    if (mounted) {
      setState(() {
        _episodeItem = episode;
      });
    }
  }
}
