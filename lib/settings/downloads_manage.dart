import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../state/download_state.dart';
import '../type/episodebrief.dart';
import '../type/theme_data.dart';
import '../util/extension_helper.dart';
import '../widgets/action_bar.dart';
import '../widgets/custom_widget.dart';

class DownloadsManage extends StatefulWidget {
  const DownloadsManage({super.key});

  @override
  _DownloadsManageState createState() => _DownloadsManageState();
}

class _DownloadsManageState extends State<DownloadsManage> {
  //Downloaded size
  late int _size;
  //Downloaded files
  late int _fileNum;
  late bool _clearing;
  late List<EpisodeBrief> _selectedList;

  /// Episodes to display
  List<EpisodeBrief> _episodes = [];

  /// Function to get episodes
  Future<List<EpisodeBrief>> Function(int count) _getEpisodes = (int _) async {
    return <EpisodeBrief>[];
  };

  /// If true, stop grid load animation.
  bool _scroll = false;

  late ScrollController _controller;

  /// Episodes num load first time.
  late int _top = 108;

  /// Load more episodes when scroll to bottom.
  bool _loadMore = false;

  Future<void> _getStorageSize() async {
    _size = 0;
    _fileNum = 0;
    final dirs = await getExternalStorageDirectories();
    for (var dir in dirs!) {
      dir.list().forEach((d) {
        var fileDir = Directory(d.path);
        fileDir.list().forEach((file) async {
          await File(file.path).stat().then((value) {
            _size += value.size;
            _fileNum += 1;
            if (mounted) setState(() {});
          });
        });
      });
    }
  }

  Future<void> _delSelectedEpisodes() async {
    setState(() => _clearing = true);
    // await Future.forEach(_selectedList, (EpisodeBrief episode) async
    for (var episode in _selectedList) {
      var downloader = Provider.of<DownloadState>(context, listen: false);
      await downloader.delTask(episode);
      if (mounted) setState(() {});
    }
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _clearing = false;
      });
    }
    await Future.delayed(Duration(seconds: 1));
    if (mounted) setState(() => _selectedList = []);
    _getStorageSize();
  }

  String _downloadDateToString(BuildContext context,
      {required int downloadDate, int? pubDate}) {
    final s = context.s;
    var date = DateTime.fromMillisecondsSinceEpoch(downloadDate);
    var diffrence = DateTime.now().toUtc().difference(date);
    if (diffrence.inHours < 24) {
      return s.hoursAgo(diffrence.inHours);
    } else if (diffrence.inDays < 7) {
      return s.daysAgo(diffrence.inDays);
    } else {
      return DateFormat.yMMMd().format(
          DateTime.fromMillisecondsSinceEpoch(pubDate!, isUtc: true).toLocal());
    }
  }

  int sumSelected() {
    var sum = 0;
    if (_selectedList.isEmpty) {
      return sum;
    } else {
      for (var episode in _selectedList) {
        sum += episode.enclosureSize!;
      }
      return sum;
    }
  }

  @override
  void initState() {
    super.initState();
    _clearing = false;
    _selectedList = [];
    _controller = ScrollController();
    _getStorageSize();
  }

  @override
  void deactivate() {
    context.statusBarColor = null;
    _controller.dispose();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    Color appBarColor = context.realDark
        ? Colors.black
        : Theme.of(context).extension<CardColorScheme>()!.saturated;
    context.statusBarColor = appBarColor;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlay,
      child: Scaffold(
        backgroundColor: context.surface,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              CustomScrollView(
                controller: _controller
                  ..addListener(() async {
                    if (_controller.offset >=
                            _controller.position.maxScrollExtent -
                                context.width &&
                        _episodes.length == _top) {
                      if (!_loadMore) {
                        if (mounted) setState(() => _loadMore = true);
                        _top = _top + 36;
                        _episodes = await _getEpisodes(_top);
                        if (mounted) setState(() => _loadMore = false);
                      }
                    }
                    if (mounted && !_scroll && _controller.offset > 0) {
                      setState(() => _scroll = true);
                    }
                  }),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    leading: CustomBackButton(),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: appBarColor,
                  ),
                  SliverAppBar(
                    pinned: true,
                    leading: Center(),
                    toolbarHeight: 100,
                    flexibleSpace: Container(
                      height: 140.0,
                      color: appBarColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: RichText(
                              text: TextSpan(
                                text: 'Total ',
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 20,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: _fileNum.toString(),
                                    style: GoogleFonts.cairo(
                                        textStyle: TextStyle(
                                      color: context.accentColor,
                                      fontSize: 40,
                                    )),
                                  ),
                                  TextSpan(
                                      text: _fileNum < 2
                                          ? ' episode'
                                          : ' episodes ',
                                      style: TextStyle(
                                        color: context.accentColor,
                                        fontSize: 20,
                                      )),
                                  TextSpan(
                                    text: (_size ~/ 1000000) < 1000
                                        ? (_size ~/ 1000000).toString()
                                        : (_size / 1000000000)
                                            .toStringAsFixed(1),
                                    style: GoogleFonts.cairo(
                                        textStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 50,
                                    )),
                                  ),
                                  TextSpan(
                                      text: (_size ~/ 1000000) < 1000
                                          ? 'Mb'
                                          : 'Gb',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 20,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ActionBar(
                    onGetEpisodesChanged: (getEpisodes) async {
                      _getEpisodes = getEpisodes;
                      _episodes = await _getEpisodes(_top);
                      if (mounted) setState(() {});
                    },
                    widgetsFirstRow: const [
                      ActionBarDropdownSortBy(0, 0),
                      ActionBarSwitchSortOrder(0, 1),
                      ActionBarSpacer(0, 2),
                      ActionBarFilterLiked(0, 3),
                      ActionBarFilterPlayed(0, 4),
                    ],
                    sortByItems: const [
                      Sorter.downloadDate,
                      Sorter.enclosureSize,
                      Sorter.enclosureDuration,
                      Sorter.pubDate
                    ],
                    sortBy: Sorter.downloadDate,
                    filterDownloaded: true,
                    extraFields: [EpisodeField.downloadDate],
                  ),
                  SliverList.builder(
                    itemCount: _episodes.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: <Widget>[
                          ListTile(
                            onTap: () {
                              if (_selectedList.contains(_episodes[index])) {
                                setState(() => _selectedList.removeWhere(
                                    (episode) =>
                                        episode.enclosureUrl ==
                                        _episodes[index].enclosureUrl));
                              } else {
                                setState(
                                    () => _selectedList.add(_episodes[index]));
                              }
                            },
                            leading: CircleAvatar(
                                backgroundImage: _episodes[index].avatarImage),
                            title: Text(
                              _episodes[index].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Text(_downloadDateToString(context,
                                    downloadDate:
                                        _episodes[index].downloadDate!,
                                    pubDate: _episodes[index].pubDate)),
                                SizedBox(width: 20),
                                if (_episodes[index].enclosureSize != 0)
                                  Text(
                                      '${_episodes[index].enclosureSize! ~/ 1000000} Mb'),
                              ],
                            ),
                            trailing: Checkbox(
                              value: _selectedList.contains(_episodes[index]),
                              onChanged: (boo) {
                                if (boo!) {
                                  setState(() =>
                                      _selectedList.add(_episodes[index]));
                                } else {
                                  setState(
                                    () => _selectedList.removeWhere((episode) =>
                                        episode.enclosureUrl ==
                                        _episodes[index].enclosureUrl),
                                  );
                                }
                              },
                            ),
                          ),
                          Divider(
                            height: 2,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: 800),
                curve: Curves.elasticInOut,
                left: context.width / 2 - 50,
                bottom: _selectedList.isEmpty ? -100 : 30,
                child: InkWell(
                    onTap: _delSelectedEpisodes,
                    child: Stack(
                      alignment: _clearing
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      children: <Widget>[
                        Container(
                          alignment: Alignment.center,
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0)),
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Icon(
                                LineIcons.alternateTrash,
                                color: Colors.white,
                              ),
                              Text('${sumSelected() ~/ 1000000}Mb',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            alignment: Alignment.center,
                            width: _clearing ? 100 : 0,
                            height: _clearing ? 40 : 0,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20.0)),
                              color: Colors.red.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
