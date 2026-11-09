import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../core/service/database.dart';
import '../../podcast/carousel/widget/podcast_carousel.dart';
import '../../podcast/detail/widget/podcast_detail.dart';
import '../../group/widget/podcast_manage.dart';
import '../../group/widget/podcast_list.dart';
import '../../episode/state/episode_state.dart';
import '../../podcast/state/podcast_state.dart';
import '../../settings/state/setting_state.dart';
import '../../group/model/podcast_group.dart';
import '../../../core/extension/extension_helper.dart';
import '../../../core/route/hide_player_route.dart';
import '../../../core/route/page_route.dart';
import '../../episode/card/widget/episode_card.dart';
import '../../episode/grid/widget/episode_grid.dart';

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
      tween: Tween<double>(begin: 0.0, end: value),
      weight: 3 / 5,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(value), weight: 1 / 5),
    TweenSequenceItem(
      tween: Tween<double>(begin: -value, end: 0),
      weight: 1 / 5,
    ),
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

  Future<void> prevGroup(int groupCount) async {
    if (groupCount == 1) {
      Fluttertoast.showToast(
        msg: context.s.addSomeGroups,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      if (mounted) {
        setState(() => _slideTween = _getSlideTween(20));
        _controller.forward();
        await Future.delayed(Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            (_groupIndex != 0) ? _groupIndex-- : _groupIndex = groupCount - 1;
          });
        }
      }
    }
  }

  Future<void> nextGroup(int groupCount) async {
    if (groupCount == 1) {
      Fluttertoast.showToast(
        msg: context.s.addSomeGroups,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      setState(() => _slideTween = _getSlideTween(-20));
      await Future.delayed(Duration(milliseconds: 50));
      _controller.forward();
      if (mounted) {
        setState(() {
          (_groupIndex < groupCount - 1) ? _groupIndex++ : _groupIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Selector<SettingState, EpisodeGridLayout>(
      selector: (_, settings) => settings.actionBarPodcasts.get().layout,
      builder: (context, layout, _) {
        double previewHeight = layout.getRowHeight(context.width);
        return Selector<
          PodcastState,
          ({PodcastGroup group, bool change, int pCount})
        >(
          selector: (_, pState) {
            final groupId = pState.groupIds[_groupIndex];
            final group = pState.getGroupById(groupId)!;
            return (
              group: group,
              change: pState.groupsChange,
              pCount: pState.podcastCount,
            );
          },
          builder: (context, data, _) {
            return SizedBox(
              height: previewHeight + 140,
              child: DefaultTabController(
                length: data.group.podcastIds.isEmpty
                    ? 3
                    : data.group.podcastIds.length,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      onVerticalDragEnd: (event) async {
                        final groupCount = context.podcastState.groupIds.length;
                        if (event.primaryVelocity! > 200) {
                          await prevGroup(groupCount);
                        } else if (event.primaryVelocity! < -200) {
                          await nextGroup(groupCount);
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
                                    horizontal: 15.0,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) => ListView(
                                          children: context
                                              .podcastState
                                              .groupIds
                                              .map(
                                                (id) => context.podcastState
                                                    .getGroupById(id)!,
                                              )
                                              .mapIndexed(
                                                (i, e) => ListTile(
                                                  leading: SizedBox(),
                                                  title: Text(e.name),
                                                  onTap: () => setState(
                                                    () => _groupIndex = i,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      );
                                    },
                                    borderRadius: context.radiusTiny,
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(
                                        data.group.name,
                                        style: context.textTheme.bodyLarge!
                                            .copyWith(
                                              color: context.primaryColor,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                Spacer(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        SlideLeftRoute(page: PodcastManage()),
                                      );
                                    },
                                    onLongPress: () {
                                      Navigator.push(
                                        context,
                                        SlideLeftRoute(page: PodcastList()),
                                      );
                                    },
                                    borderRadius: context.radiusTiny,
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(
                                        s.homeGroupsSeeAll,
                                        style: context.textTheme.bodyLarge!
                                            .copyWith(
                                              color: context.primaryColor,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PodcastCarousel(groupId: data.group.id),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PodcastPreview extends StatelessWidget {
  final String podcastId;

  /// Episodes to preview (only the first row is shown)
  final List<int> previewIds;
  final EpisodeGridLayout layout;

  const PodcastPreview({
    required this.podcastId,
    required this.previewIds,
    required this.layout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Selector<PodcastState, (String, Color)>(
                  selector: (_, pState) => (
                    pState[podcastId].title,
                    pState[podcastId].backgroudColor(context),
                  ),
                  builder: (context, data, _) => Text(
                    data.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: data.$2,
                    ),
                  ),
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
