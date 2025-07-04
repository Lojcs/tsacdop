import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart' as tuple;

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../podcasts/podcast_manage.dart';
import '../podcasts/podcastlist.dart';
import '../state/episode_state.dart';
import '../state/podcast_group.dart';
import '../state/refresh_podcast.dart';
import '../state/setting_state.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/hide_player_route.dart';
import '../util/pageroute.dart';
import '../widgets/action_bar.dart';
import '../widgets/episode_card.dart';
import '../widgets/episodegrid.dart';

class ScrollPodcasts extends StatefulWidget {
  const ScrollPodcasts({super.key});

  @override
  State<ScrollPodcasts> createState() => _ScrollPodcastsState();
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
    final s = context.s;
    return FutureBuilder<(EpisodeGridLayout, bool?)>(
      future: getLayoutAndShowPlayed(layoutKey: podcastLayoutKey),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final layout = snapshot.data!.$1;
          double previewHeight = layout.getRowHeight(context.width);
          return Selector2<GroupList, RefreshWorker,
              tuple.Tuple3<List<PodcastGroup?>, bool, bool>>(
            selector: (_, groupList, refreshWorker) => tuple.Tuple3(
                groupList.groups, groupList.created, refreshWorker.created),
            builder: (_, data, __) {
              final groups = data.item1;
              final import = data.item2;
              if (groups.isEmpty) {
                return SizedBox(
                  height: previewHeight + 140,
                );
              }
              if (groups[_groupIndex]!.podcastList.isEmpty) {
                return SizedBox(
                  height: previewHeight + 140,
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
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 15.0),
                                    child: Text(
                                      groups[_groupIndex]!.name!,
                                      style: context.textTheme.bodyLarge!
                                          .copyWith(color: context.accentColor),
                                    ),
                                  ),
                                  Spacer(),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 15),
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
                                          style: context.textTheme.bodyLarge!
                                              .copyWith(
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
                                    _circleContainer(),
                                    _circleContainer(),
                                    _circleContainer()
                                  ],
                                )),
                          ],
                        ),
                      ),
                      Container(
                        height: previewHeight + 40,
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
                                              .copyWith(
                                                  color: context.accentColor)),
                                      TextSpan(
                                          text: 'Get started\n',
                                          style: context.textTheme.titleLarge!
                                              .copyWith(
                                                  color: context.accentColor)),
                                      TextSpan(text: 'Tap '),
                                      WidgetSpan(
                                          child:
                                              Icon(Icons.add_circle_outline)),
                                      TextSpan(text: ' to search podcasts')
                                    ],
                                  ))
                                : Text(s.noPodcastGroup,
                                    style: TextStyle(
                                        color: context
                                            .textTheme.bodyMedium!.color!
                                            .withValues(alpha: 0.5)))),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    child: Text(
                                      groups[_groupIndex]!.name!,
                                      style: context.textTheme.bodyLarge!
                                          .copyWith(color: context.accentColor),
                                    )),
                                Spacer(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
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
                                        style: context.textTheme.bodyLarge!
                                            .copyWith(
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
                            alignment: Alignment.centerLeft,
                            color: Colors.transparent,
                            child: TabBar(
                              enableFeedback: false,
                              splashFactory: NoSplash.splashFactory,
                              labelPadding:
                                  EdgeInsets.fromLTRB(6.0, 5.0, 6.0, 10.0),
                              indicator: CircleTabIndicator(
                                  color: context.accentColor, radius: 3),
                              isScrollable: true,
                              dividerHeight: 0,
                              tabAlignment: TabAlignment.start,
                              tabs: groups[_groupIndex]!.podcasts.map<Widget>(
                                (podcastLocal) {
                                  return Tab(
                                    child: Transform.translate(
                                      offset: Offset(
                                          0,
                                          _slideTween
                                              .animate(_controller)
                                              .value),
                                      child: LimitedBox(
                                        maxHeight: 50,
                                        maxWidth: 50,
                                        child: CircleAvatar(
                                          backgroundColor: podcastLocal
                                              .primaryColor!
                                              .toColor(),
                                          backgroundImage:
                                              podcastLocal.avatarImage,
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
                      height: previewHeight + 45,
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
                                child: Selector2<RefreshWorker, GroupList,
                                    (bool, bool)>(
                                  selector: (_, refreshWorker, groupWorker) => (
                                    refreshWorker.created,
                                    groupWorker.created
                                  ),
                                  builder: (_, data, __) =>
                                      FutureBuilder<List<int>>(
                                    future: _getPodcastPreview(
                                        podcastLocal,
                                        layout.getVerticalCount(
                                            context.width, context.height)),
                                    builder: (context, snapshot) => InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          HidePlayerRoute(
                                            PodcastDetail(
                                              podcastLocal: podcastLocal,
                                              initIds: snapshot.hasData
                                                  ? snapshot.data!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      child: PodcastPreview(
                                        podcastLocal: podcastLocal,
                                        previewIds: snapshot.hasData
                                            ? snapshot.data!.sublist(
                                                0,
                                                layout.getHorizontalCount(
                                                    context.width))
                                            : [],
                                        layout: layout,
                                      ),
                                    ),
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
        return Center();
      },
    );
  }

  Future<int?> _getPodcastUpdateCounts(String? id) async {
    final dbHelper = DBHelper();
    updateCount ??= await dbHelper.getPodcastUpdateCounts(id);
    return updateCount;
  }

  Widget _circleContainer() => Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        width: 50,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: context.primaryColor),
      );

  Widget _updateIndicator(PodcastBrief podcastLocal) => FutureBuilder<int?>(
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

  Future<List<int>> _getPodcastPreview(
      PodcastBrief podcastLocal, int limit) async {
    if (context.mounted) {
      return Provider.of<EpisodeState>(context, listen: false).getEpisodes(
        feedIds: [podcastLocal.id],
        sortBy: Sorter.pubDate,
        sortOrder: SortOrder.desc,
        limit: limit,
        filterDisplayVersion: false,
      );
    } else {
      return Future.value([]);
    }
  }
}

class PodcastPreview extends StatelessWidget {
  final PodcastBrief podcastLocal;

  /// Episodes to preview (only the first row is shown)
  final List<int> previewIds;
  final EpisodeGridLayout layout;

  const PodcastPreview(
      {required this.podcastLocal,
      required this.previewIds,
      required this.layout,
      super.key});

  @override
  Widget build(BuildContext context) {
    final c = podcastLocal.backgroudColor(context);
    return Column(
      children: <Widget>[
        Container(
          height: layout.getRowHeight(context.width),
          padding: EdgeInsets.all(5),
          child: Row(
            spacing: 10,
            children: previewIds
                .map(
                  (id) => Expanded(
                    child: InteractiveEpisodeCard(
                      id,
                      layout,
                      preferEpisodeImage: false,
                      showNumber: true,
                    ),
                  ),
                )
                .toList(),
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
                  podcastLocal.title,
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
