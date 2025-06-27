import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../state/podcast_group.dart';
import '../util/extension_helper.dart';
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
                  SearchRoute(
                    context,
                    widget.searchKey,
                    showIcon: () => setState(() => hideIcon = false),
                    hideIcon: () => setState(() => hideIcon = true),
                  ),
                );
              },
            )
          : Center(),
    );
  }
}

class PodcastSearchCard extends StatefulWidget {
  final Widget child;
  final bool floating;
  final bool short;
  const PodcastSearchCard(
      {required this.child,
      this.floating = true,
      this.short = false,
      super.key});
  @override
  State<PodcastSearchCard> createState() => PodcastSearchCardState();
}

class PodcastSearchCardState extends State<PodcastSearchCard>
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
          horizontal: context.actionBarIconPadding.vertical));

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
  void didUpdateWidget(PodcastSearchCard oldWidget) {
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
            color: context.surface,
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
          child: widget.child,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class SearchPodcastPreview extends StatefulWidget {
  final String url;
  final bool floating;

  const SearchPodcastPreview(this.url, {this.floating = true, super.key});
  @override
  State<SearchPodcastPreview> createState() => SearchPodcastPreviewState();
}

class SearchPodcastPreviewState extends State<SearchPodcastPreview> {
  RssFeed? rssFeed;
  bool? subscribed;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RssFeed>(
      future: getFeed(),
      builder: (context, snapshot) => Padding(
        padding: context.actionBarIconPadding * 2,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedContainer(
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
                    Text(
                      snapshot.hasData
                          ? snapshot.data!.title!
                          : context.s.loading,
                      maxLines: 2,
                      style: context.textTheme.titleLarge,
                    ),
                    ElevatedButton(
                      onPressed:
                          snapshot.hasData && !subscribed! ? subscribe : null,
                      child: snapshot.hasData
                          ? Text(
                              subscribed!
                                  ? context.s.podcastSubscribed
                                  : context.s.subscribe,
                              style: subscribed!
                                  ? context.textTheme.bodyLarge
                                  : context.textTheme.bodyLarge!
                                      .copyWith(color: context.accentColor),
                            )
                          : Center(),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(borderRadius: context.radiusMedium),
                clipBehavior: Clip.antiAlias,
                width: 100,
                height: 100,
                child: snapshot.hasData
                    ? CachedNetworkImage(
                        imageUrl: snapshot.data!.itunes?.image?.href ??
                            snapshot.data!.image?.url ??
                            "https://ui-avatars.com/api/?size=300&background=388E3C&color=fff&name=${snapshot.data!.title!}&length=2&bold=true",
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
                      )
                    : Center(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<RssFeed> getFeed() async {
    if (rssFeed == null) {
      subscribed = (await DBHelper().checkPodcast(widget.url)) != "";
      var response = await Dio().get(widget.url);
      if (response.statusCode == 200) {
        rssFeed = RssFeed.parse(response.data);
      }
    }
    return rssFeed!;
  }

  void subscribe() {
    final subscribeWorker = Provider.of<GroupList>(context, listen: false);
    var item = SubscribeItem(
      widget.url,
      rssFeed!.title ?? widget.url,
      imgUrl: rssFeed!.itunes?.image?.href ?? rssFeed!.image?.url ?? "",
      group: 'Home',
    );
    subscribeWorker.setSubscribeItem(item);
    setState(() => subscribed = true);
  }
}
