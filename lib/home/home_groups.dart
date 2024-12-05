import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart' as tuple;

import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../podcasts/podcast_manage.dart';
import '../podcasts/podcastlist.dart';
import '../state/episode_state.dart';
import '../state/podcast_group.dart';
import '../state/refresh_podcast.dart';
import '../state/setting_state.dart';
import '../type/episodebrief.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/hide_player_route.dart';
import '../util/pageroute.dart';
import '../widgets/episode_card.dart';
import '../widgets/episodegrid.dart';

class ScrollPodcasts extends StatefulWidget {
  @override
  _ScrollPodcastsState createState() => _ScrollPodcastsState();
}

class _ScrollPodcastsState extends State<ScrollPodcasts>
    with SingleTickerProviderStateMixin {
  int _groupIndex = 0;
  late AnimationController _controller;
  late TweenSequence _slideTween;
  TweenSequence<double> _getSlideTween(double value) => TweenSequence<double>([
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: value), weight: 3 / 5),
        TweenSequenceItem(tween: ConstantTween<double>(value), weight: 1 / 5),
        TweenSequenceItem(
            tween: Tween<double>(begin: -value, end: 0), weight: 1 / 5)
      ]);

  int? updateCount;

  @override
  void initState() {
    super.initState();
    _groupIndex = 0;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150))
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _controller.reset();
          });
    _slideTween = _getSlideTween(0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final s = context.s;
    return Selector2<GroupList, RefreshWorker,
        tuple.Tuple3<List<PodcastGroup?>, bool, bool>>(
      selector: (_, groupList, refreshWorker) => tuple.Tuple3(
          groupList.groups, groupList.created, refreshWorker.created),
      builder: (_, data, __) {
        final groups = data.item1;
        final import = data.item2;
        if (groups.isEmpty) {
          return SizedBox(
            height: (width - 20) / 3 + 140,
          );
        }
        if (groups[_groupIndex]!.podcastList.length == 0) {
          return SizedBox(
            height: (width - 20) / 3 + 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(
                  onVerticalDragEnd: (event) {
                    if (event.primaryVelocity! > 200) {
                      if (groups.length == 1) {
                        Fluttertoast.showToast(
                          msg: s.addSomeGroups,
                          gravity: ToastGravity.BOTTOM,
                        );
                      } else {
                        if (mounted) {
                          setState(() {
                            (_groupIndex != 0)
                                ? _groupIndex--
                                : _groupIndex = groups.length - 1;
                          });
                        }
                      }
                    } else if (event.primaryVelocity! < -200) {
                      if (groups.length == 1) {
                        Fluttertoast.showToast(
                          msg: s.addSomeGroups,
                          gravity: ToastGravity.BOTTOM,
                        );
                      } else {
                        if (mounted) {
                          setState(
                            () {
                              (_groupIndex < groups.length - 1)
                                  ? _groupIndex++
                                  : _groupIndex = 0;
                            },
                          );
                        }
                      }
                    }
                  },
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 30,
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.0),
                              child: Text(
                                groups[_groupIndex]!.name!,
                                style: context.textTheme.bodyLarge!
                                    .copyWith(color: context.accentColor),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () {
                                  if (!import) {
                                    Navigator.push(
                                      context,
                                      SlideLeftRoute(
                                        page: context
                                                .read<SettingState>()
                                                .openAllPodcastDefalt!
                                            ? PodcastList()
                                            : PodcastManage(),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  if (!import) {
                                    Navigator.push(
                                      context,
                                      SlideLeftRoute(page: PodcastList()),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(
                                    s.homeGroupsSeeAll,
                                    style:
                                        context.textTheme.bodyLarge!.copyWith(
                                      color: import
                                          ? context.primaryColorDark
                                          : context.accentColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          height: 70,
                          color: Colors.transparent,
                          child: Row(
                            children: <Widget>[
                              _circleContainer(context),
                              _circleContainer(context),
                              _circleContainer(context)
                            ],
                          )),
                    ],
                  ),
                ),
                Container(
                  height: (width - 20) / 3 + 40,
                  color: Colors.transparent,
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  child: Center(
                      child: _groupIndex == 0
                          ? Text.rich(TextSpan(
                              style: context.textTheme.titleLarge!
                                  .copyWith(height: 2),
                              children: [
                                TextSpan(
                                    text: 'Welcome to Tsacdop\n',
                                    style: context.textTheme.titleLarge!
                                        .copyWith(color: context.accentColor)),
                                TextSpan(
                                    text: 'Get started\n',
                                    style: context.textTheme.titleLarge!
                                        .copyWith(color: context.accentColor)),
                                TextSpan(text: 'Tap '),
                                WidgetSpan(
                                    child: Icon(Icons.add_circle_outline)),
                                TextSpan(text: ' to search podcasts')
                              ],
                            ))
                          : Text(s.noPodcastGroup,
                              style: TextStyle(
                                  color: context.textTheme.bodyMedium!.color!
                                      .withOpacity(0.5)))),
                ),
              ],
            ),
          );
        }
        return DefaultTabController(
          length: groups[_groupIndex]!.podcasts.length,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                onVerticalDragEnd: (event) async {
                  if (event.primaryVelocity! > 200) {
                    if (groups.length == 1) {
                      Fluttertoast.showToast(
                        msg: s.addSomeGroups,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      if (mounted) {
                        setState(() => _slideTween = _getSlideTween(20));
                        _controller.forward();
                        await Future.delayed(Duration(milliseconds: 50));
                        if (mounted) {
                          setState(() {
                            (_groupIndex != 0)
                                ? _groupIndex--
                                : _groupIndex = groups.length - 1;
                          });
                        }
                      }
                    }
                  } else if (event.primaryVelocity! < -200) {
                    if (groups.length == 1) {
                      Fluttertoast.showToast(
                        msg: s.addSomeGroups,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      setState(() => _slideTween = _getSlideTween(-20));
                      await Future.delayed(Duration(milliseconds: 50));
                      _controller.forward();
                      if (mounted) {
                        setState(() {
                          (_groupIndex < groups.length - 1)
                              ? _groupIndex++
                              : _groupIndex = 0;
                        });
                      }
                    }
                  }
                },
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: <Widget>[
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Text(
                                groups[_groupIndex]!.name!,
                                style: context.textTheme.bodyLarge!
                                    .copyWith(color: context.accentColor),
                              )),
                          Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: InkWell(
                              onTap: () {
                                if (!import) {
                                  Navigator.push(
                                    context,
                                    SlideLeftRoute(
                                        page: context
                                                .read<SettingState>()
                                                .openAllPodcastDefalt!
                                            ? PodcastList()
                                            : PodcastManage()),
                                  );
                                }
                              },
                              onLongPress: () {
                                if (!import) {
                                  Navigator.push(
                                    context,
                                    SlideLeftRoute(page: PodcastList()),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(5),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  s.homeGroupsSeeAll,
                                  style: context.textTheme.bodyLarge!.copyWith(
                                      color: import
                                          ? context.primaryColorDark
                                          : context.accentColor),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      height: 70,
                      width: width,
                      alignment: Alignment.centerLeft,
                      color: Colors.transparent,
                      child: TabBar(
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            return states.contains(WidgetState.focused)
                                ? null
                                : Colors.transparent;
                          },
                        ),
                        labelPadding: EdgeInsets.fromLTRB(6.0, 5.0, 6.0, 10.0),
                        indicator: CircleTabIndicator(
                            color: context.accentColor, radius: 3),
                        isScrollable: true,
                        tabs: groups[_groupIndex]!.podcasts.map<Widget>(
                          (podcastLocal) {
                            final color = podcastLocal.backgroudColor(context);
                            return Tab(
                              child: Transform.translate(
                                offset: Offset(
                                    0, _slideTween.animate(_controller).value),
                                child: LimitedBox(
                                  maxHeight: 50,
                                  maxWidth: 50,
                                  child: CircleAvatar(
                                    backgroundColor: color.withOpacity(0.5),
                                    backgroundImage: podcastLocal.avatarImage,
                                    child: _updateIndicator(
                                        podcastLocal), // TODO: This doesn't update currently
                                  ),
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: (width - 20) / 3 + 45,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBarView(
                  children: groups[_groupIndex]!.podcasts.map<Widget>(
                    (podcastLocal) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        key: ObjectKey(podcastLocal.title),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                HidePlayerRoute(
                                  PodcastDetail(
                                    podcastLocal: podcastLocal,
                                  ),
                                  PodcastDetail(
                                      podcastLocal: podcastLocal, hide: true),
                                  duration: Duration(milliseconds: 300),
                                ),
                              );
                            },
                            child: PodcastPreview(
                              podcastLocal: podcastLocal,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<int?> _getPodcastUpdateCounts(String? id) async {
    final dbHelper = DBHelper();
    if (updateCount == null) {
      updateCount = await dbHelper.getPodcastUpdateCounts(id);
    }
    return updateCount;
  }

  Widget _circleContainer(BuildContext context) => Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        width: 50,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: context.primaryColor),
      );

  Widget _updateIndicator(PodcastLocal podcastLocal) => FutureBuilder<int?>(
        future: _getPodcastUpdateCounts(podcastLocal.id),
        initialData: 0,
        builder: (context, snapshot) {
          return snapshot.data! > 0
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    alignment: Alignment.center,
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: context.surface, width: 2),
                        shape: BoxShape.circle),
                  ),
                )
              : Center();
        },
      );
}

class PodcastPreview extends StatefulWidget {
  final PodcastLocal? podcastLocal;

  PodcastPreview({this.podcastLocal, Key? key}) : super(key: key);

  @override
  _PodcastPreviewState createState() => _PodcastPreviewState();
}

class _PodcastPreviewState extends State<PodcastPreview> {
  List<EpisodeBrief> episodePreview = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.podcastLocal!.backgroudColor(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: Selector2<RefreshWorker, GroupList, tuple.Tuple2<bool, bool>>(
            selector: (_, refreshWorker, groupWorker) =>
                tuple.Tuple2(refreshWorker.created, groupWorker.created),
            builder: (_, data, __) {
              return FutureBuilder<List<EpisodeBrief>>(
                future: _getPodcastPreview(widget.podcastLocal!),
                builder: (context, snapshot) {
                  return (snapshot.hasData)
                      ? ShowEpisode(
                          episodes: snapshot.data,
                          podcastLocal: widget.podcastLocal,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(5.0),
                        );
                },
              );
            },
          ),
        ),
        Container(
          height: 40,
          padding: EdgeInsets.only(left: 10.0),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Text(
                  widget.podcastLocal!.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, color: c),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<EpisodeBrief>> _getPodcastPreview(
      PodcastLocal podcastLocal) async {
    if (episodePreview.isEmpty) {
      final dbHelper = DBHelper();
      episodePreview = await dbHelper.getEpisodes(
        feedIds: [podcastLocal.id],
        optionalFields: [
          EpisodeField.description,
          EpisodeField.enclosureDuration,
          EpisodeField.enclosureSize,
          EpisodeField.isDownloaded,
          EpisodeField.episodeImage,
          EpisodeField.podcastImage,
          EpisodeField.primaryColor,
          EpisodeField.isLiked,
          EpisodeField.isNew,
          EpisodeField.isPlayed,
          EpisodeField.versionInfo
        ],
        sortBy: Sorter.pubDate,
        sortOrder: SortOrder.DESC,
        limit: 2,
        episodeState: Provider.of<EpisodeState>(context, listen: false),
      );
    }
    return episodePreview;
  }
}

class ShowEpisode extends StatelessWidget {
  final List<EpisodeBrief>? episodes;
  final PodcastLocal? podcastLocal;
  ShowEpisode({Key? key, this.episodes, this.podcastLocal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: NeverScrollableScrollPhysics(),
      primary: false,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.all(5.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1.5,
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return InteractiveEpisodeCard(
                    context, episodes![index], Layout.medium,
                    preferEpisodeImage: false);
              },
              childCount: math.min(episodes!.length, 2),
            ),
          ),
        ),
      ],
    );
  }
}

//Circle Indicator
class CircleTabIndicator extends Decoration {
  final BoxPainter _painter;
  CircleTabIndicator({required Color color, required double radius})
      : _painter = _CirclePainter(color, radius);
  static _returnNull() => null;
  @override
  BoxPainter createBoxPainter([VoidCallback onChanged = _returnNull]) =>
      _painter;
}

class _CirclePainter extends BoxPainter {
  final Paint _paint;
  final double radius;

  _CirclePainter(Color color, this.radius)
      : _paint = Paint()
          ..color = color
          ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final circleOffset =
        offset + Offset(cfg.size!.width / 2, cfg.size!.height - radius);
    canvas.drawCircle(circleOffset, radius, _paint);
  }
}
