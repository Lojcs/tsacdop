import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/podcast_state.dart';
import '../type/podcastbrief.dart';
import '../util/extension_helper.dart';
import '../widgets/action_bar_generic_widgets.dart';
import 'search_controller.dart';
import 'search_page.dart';

class SearchButton extends StatefulWidget {
  final GlobalKey searchKey;
  const SearchButton(this.searchKey, {super.key});

  @override
  State<SearchButton> createState() => SearchButtonState();
}

class SearchButtonState extends State<SearchButton> {
  bool hideIcon = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      margin: EdgeInsets.all(6),
      child: !hideIcon
          ? IconButton(
              tooltip: context.s.search,
              splashRadius: 20,
              icon: Icon(
                Icons.search,
                key: widget.searchKey,
                color: context.actionBarIconColor,
              ),
              onPressed: () async {
                Navigator.push(
                  context,
                  SearchPanelRoute(
                    context,
                    widget.searchKey,
                    showIcon: () {
                      if (hideIcon) setState(() => hideIcon = false);
                    },
                    hideIcon: () {
                      if (!hideIcon) setState(() => hideIcon = true);
                    },
                  ),
                );
              },
            )
          : Center(),
    );
  }
}

class SearchPanelCard extends StatefulWidget {
  final Widget? child;
  final bool floating;
  final bool short;
  final Color? color;
  const SearchPanelCard(
      {required this.child,
      this.floating = true,
      this.short = false,
      this.color,
      super.key});
  @override
  State<SearchPanelCard> createState() => SearchPanelCardState();
}

class SearchPanelCardState extends State<SearchPanelCard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController controller;
  late Animation<double> animation;

  double get cardHeight => widget.short ? 120 : 140;

  late final Tween<double> outerHeightTween = Tween<double>(
      begin: cardHeight,
      end: cardHeight + context.actionBarIconPadding.vertical);
  late final BorderRadiusTween borderRadiusTween = BorderRadiusTween(
    begin: context.radiusMedium
        .copyWith(bottomLeft: Radius.zero, bottomRight: Radius.zero),
    end: context.radiusMedium,
  );
  late final EdgeInsetsTween marginTween = EdgeInsetsTween(
      begin: EdgeInsets.zero,
      end: EdgeInsets.symmetric(
          horizontal: context.actionBarIconPadding.horizontal));

  double get outerHeight => outerHeightTween.evaluate(animation);
  BorderRadius get radius => borderRadiusTween.evaluate(animation)!;
  EdgeInsets get margin => marginTween.evaluate(animation);
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        if (mounted) setState(() {});
      });
    animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOutQuad);
    if (widget.floating) controller.value = 1;
  }

  @override
  void didUpdateWidget(SearchPanelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.floating != oldWidget.floating) {
      if (widget.floating) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      height: outerHeight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            color: widget.color ?? context.surface,
            borderRadius: radius,
            boxShadow:
                context.boxShadowMedium(color: context.cardColorSchemeShadow),
          ),
          clipBehavior: Clip.hardEdge,
          margin: margin,
          padding: EdgeInsets.only(
            left: context.actionBarIconPadding.left,
            top: context.actionBarIconPadding.top / 2,
            right: context.actionBarIconPadding.right,
            bottom: context.actionBarIconPadding.bottom / 2,
          ),
          width: double.infinity,
          child: widget.child ?? LinearProgressIndicator(),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Preview
class SearchPodcastPreview extends StatefulWidget {
  final String podcastId;
  final List<int> episodeIdList;
  final bool floating;

  const SearchPodcastPreview(this.podcastId, this.episodeIdList,
      {this.floating = true, super.key});
  @override
  State<SearchPodcastPreview> createState() => SearchPodcastPreviewState();
}

class SearchPodcastPreviewState extends State<SearchPodcastPreview> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final cardColorScheme =
        context.podcastState[widget.podcastId].cardColorScheme(context);
    return Provider.value(
      value: cardColorScheme,
      builder: (context, child) => SearchPanelCard(
        color: context.realDark ? context.surface : cardColorScheme.card,
        child: Padding(
          padding: context.actionBarIconPadding * 2,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(vertical: 4),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOutQuad,
                    width: context.width -
                        110 -
                        context.actionBarIconPadding.horizontal *
                            (widget.floating ? 5 : 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Selector<PodcastState, String>(
                          selector: (_, pState) =>
                              pState[widget.podcastId].title,
                          builder: (context, title, _) => Text(
                            title,
                            maxLines: 2,
                            style: context.textTheme.titleLarge,
                          ),
                        ),
                        Selector<PodcastState, DataSource>(
                          selector: (_, pState) =>
                              pState[widget.podcastId].source,
                          builder: (context, source, _) => Row(
                            children: [
                              ActionBarButton(
                                enabled: source == DataSource.remote,
                                state: source == DataSource.remote,
                                buttonType: ActionBarButtonType.single,
                                onPressed: (value) => Provider.of<JointSearch>(
                                        context,
                                        listen: false)
                                    .subscribe(widget.podcastId),
                                tooltip:
                                    context.s.filterType(context.s.downloaded),
                                // connectRight: true,
                                width: 100,
                                falseChild: Center(
                                  child: Text(
                                    context.s.subscribed,
                                    style: context.textTheme.bodyLarge,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    context.s.subscribe,
                                    style: context.textTheme.bodyLarge!,
                                  ),
                                ),
                              ),
                              // ActionBarButton(
                              //   buttonType: ActionBarButtonType.single,
                              //   onPressed: (value) => Navigator.push(
                              //     context,
                              //     HidePlayerRoute(
                              //       PodcastDetail(
                              //         podcastId: widget.podcastId,
                              //       ),
                              //     ),
                              //   ),
                              //   tooltip:
                              //       context.s.filterType(context.s.downloaded),
                              //   connectLeft: true,
                              //   width: 100,
                              //   child: Center(
                              //     child: Text(
                              //       context.s.details,
                              //       style: context.textTheme.bodyLarge!
                              //           .copyWith(color: context.accentColor),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(borderRadius: context.radiusMedium),
                  clipBehavior: Clip.antiAlias,
                  width: 100,
                  height: 100,
                  child: Selector<PodcastState, String>(
                    selector: (_, pState) => pState[widget.podcastId].imageUrl,
                    builder: (context, imageUrl, _) => CachedNetworkImage(
                      imageUrl: imageUrl,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Container(
                        height: 50,
                        width: 50,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 20,
                          height: 2,
                          child: LinearProgressIndicator(
                              value: downloadProgress.progress),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchEpisodeGrid extends StatefulWidget {
  final List<int> episodes;
  const SearchEpisodeGrid(this.episodes, {super.key});
  @override
  State<StatefulWidget> createState() => SearchEpisodeGridState();
}

class SearchEpisodeGridState extends State<SearchEpisodeGrid> {
  @override
  Widget build(BuildContext context) {
    // SearchPanelCard(
    //                 short: true,
    //                 child: );
    // TODO: implement build
    throw UnimplementedError();
  }
}
