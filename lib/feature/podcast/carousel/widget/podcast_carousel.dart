import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/extension/extension_helper.dart';
import '../../../../core/route/hide_player_route.dart';
import '../../../../core/service/database.dart';
import '../../../episode/grid/widget/episode_grid.dart';
import '../../../episode/state/episode_state.dart';
import '../../../group/model/podcast_group.dart';
import '../../../home/widget/home_groups.dart';
import '../../../settings/state/setting_state.dart';
import '../../detail/widget/podcast_detail.dart';
import '../../state/podcast_state.dart';

class PodcastCarousel extends StatelessWidget {
  final String groupId;
  const PodcastCarousel({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Selector<SettingState, EpisodeGridLayout>(
      selector: (_, settings) => settings.actionBarPodcasts.get().layout,
      builder: (context, layout, _) => Selector<PodcastState, PodcastGroup>(
        selector: (_, pState) => pState.getGroupById(groupId)!,
        builder: (context, group, _) => Column(
          children: [
            Container(
              height: 70,
              alignment: Alignment.centerLeft,
              color: Colors.transparent,
              child: TabBar(
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                labelPadding: EdgeInsets.fromLTRB(6.0, 5.0, 6.0, 10.0),
                indicator: CircleTabIndicator(
                  color: context.primaryColor,
                  radius: 3,
                ),
                isScrollable: true,
                dividerHeight: 0,
                tabAlignment: TabAlignment.start,
                tabs: group.podcastIds.isEmpty
                    ? [
                        _circleContainer(context),
                        _circleContainer(context),
                        _circleContainer(context),
                      ]
                    : group.podcastIds.map<Widget>((podcastId) {
                        final podcast = context.podcastState[podcastId];
                        return Tab(
                          child: LimitedBox(
                            maxHeight: 50,
                            maxWidth: 50,
                            child: CircleAvatar(
                              backgroundColor: podcast.primaryColor,
                              backgroundImage: podcast.avatarImage,
                              child: _updateIndicator(podcastId),
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
            Container(
              height: layout.getRowHeight(context.width) + 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: group.podcastIds.isEmpty
                  ? Center(
                      child: Selector<PodcastState, bool>(
                        selector: (_, pState) => pState.podcastCount == 0,
                        builder: (context, empty, _) => empty
                            ? Column(
                                mainAxisAlignment: .center,
                                children: [
                                  Text(
                                    context.s.welcome,
                                    style: context.textTheme.headlineMedium!
                                        .copyWith(color: context.primaryColor),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    context.s.getStarted,
                                    style: context.textTheme.titleLarge!
                                        .copyWith(color: context.primaryColor),
                                  ),
                                  SizedBox(height: 4),
                                  DefaultTextStyle(
                                    style: context.textTheme.titleMedium!,
                                    child: Builder(
                                      builder: (context) {
                                        final text = context.s.getStartedDes(
                                          "\uFFFC",
                                        );
                                        final parts = text.split("\uFFFC");
                                        final icon = Icons.search;
                                        return Row(
                                          mainAxisAlignment: .center,
                                          children: [
                                            Text(parts[0]),
                                            Text(
                                              String.fromCharCode(
                                                icon.codePoint,
                                              ),
                                              style: context
                                                  .textTheme
                                                  .titleLarge!
                                                  .copyWith(
                                                    fontFamily: icon.fontFamily,
                                                    package: icon.fontPackage,
                                                    fontFamilyFallback:
                                                        icon.fontFamilyFallback,
                                                  ),
                                            ),
                                            Text(parts[1]),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                context.s.noPodcastGroup,
                                style: TextStyle(
                                  color: context.textTheme.bodyMedium!.color!
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                    )
                  : TabBarView(
                      children: group.podcastIds.map<Widget>((podcastId) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 5.0),
                          key: ObjectKey(podcastId),
                          child: Material(
                            color: Colors.transparent,
                            child: FutureBuilder<List<int>>(
                              future: _getPodcastPreview(
                                context,
                                podcastId,
                                layout.getVerticalCount(
                                  context.width,
                                  context.height,
                                ),
                              ),
                              builder: (context, snapshot) => InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    HidePlayerRoute(
                                      PodcastDetail(
                                        podcastId: podcastId,
                                        initIds: snapshot.hasData
                                            ? snapshot.data!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                child: PodcastPreview(
                                  podcastId: podcastId,
                                  previewIds: snapshot.hasData
                                      ? snapshot.data!.sublist(
                                          0,
                                          math.min(
                                            layout.getHorizontalCount(
                                              context.width,
                                            ),
                                            snapshot.data!.length,
                                          ),
                                        )
                                      : [],
                                  layout: layout,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleContainer(BuildContext context) => Tab(
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.secondaryContainer,
      ),
    ),
  );

  Widget _updateIndicator(String podcastId) => Selector<PodcastState, int>(
    selector: (_, pState) => pState[podcastId].syncEpisodeCount,
    builder: (context, count, _) => count > 0
        ? Align(
            alignment: Alignment.bottomRight,
            child: Container(
              alignment: Alignment.center,
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: context.primaryColor,
                border: Border.all(color: context.surface, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          )
        : Center(),
  );

  Future<List<int>> _getPodcastPreview(
    BuildContext context,
    String podcastId,
    int limit,
  ) async {
    if (context.mounted) {
      return context.episodeState.getEpisodes(
        podcastIds: [podcastId],
        sortBy: Sorter.pubDate,
        sortOrder: SortOrder.desc,
        limit: limit,
        filterDuplicateVersions: false,
      );
    } else {
      return Future.value([]);
    }
  }
}
