import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xml/xml.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../state/podcast_group.dart';
import '../util/extension_helper.dart';

enum SearchEngine {
  brave(url: "https://search.brave.com/search?q="),
  yandex(url: "https://yandex.com/search/?text="),
  google(url: "https://www.google.com/search?q="),
  duckduckgo(url: "https://duckduckgo.com/?q="),
  qwant(url: "https://qwant.com/search?q="),
  startpage(url: "https://eu.startpage.com/search?q="),
  librey(url: "https://librey.org/search.php?q="),
  yahoo(url: "https://search.yahoo.com/search?q="),
  ecosia(url: "https://www.ecosia.org/search?q="),
  bing(url: "https://www.bing.com/search?q=");

  const SearchEngine({required this.url});

  final String url;
}

class WebPodcastSearch extends StatefulWidget {
  const WebPodcastSearch({super.key});

  @override
  State<WebPodcastSearch> createState() => _WebPodcastSearchState();
}

class _WebPodcastSearchState extends State<WebPodcastSearch> {
  WebViewController webViewController = WebViewController();
  late Widget webView = Padding(
    padding: EdgeInsets.only(bottom: 0),
    child: WebViewWidget(controller: webViewController),
  );
  String url = "";
  List<String> foundUrls = [];

  @override
  void initState() {
    super.initState();
    WebViewCookieManager().clearCookies();
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    webViewController.clearCache();
    webViewController
        .clearLocalStorage(); // TODO: This doesn't clear google dark mode??
    webViewController.setNavigationDelegate(NavigationDelegate(
      onUrlChange: (change) async {
        if (change.url != null && change.url != "") {
          try {
            var response = await Dio().get(change.url!);
            if (response.statusCode == 200) {
              RssFeed.parse(response.data);
              if (!foundUrls.contains(change.url)) {
                foundUrls.add(change.url!);
              }
            }
          } catch (e) {
            if (e is! XmlParserException &&
                e is! XmlTagException &&
                e is! FormatException &&
                e is! ArgumentError &&
                e is! DioException) {
              rethrow;
            }
          }
        }
        if (mounted) setState(() => url = change.url ?? "");
      },
      onPageFinished: (url) async {
        await webViewController.runJavaScript("""
          let anchors = document.querySelectorAll('a');
          let urlsFromAnchors = Array.from(anchors).map(a => a.href);
          let urls = [...urlsFromAnchors];
          for (let url of urls) {
            if (url.endsWith(".rss") || url.endsWith(".xml")) {
              linksChannel.postMessage(url);
            }
          }
          
          document.querySelector('.cookie-wrapper').remove();
          document.querySelector('#didomi-host').remove();
        """);
        await Future.delayed(Duration(seconds: 1));
      },
    ));
    webViewController.addJavaScriptChannel(
      "linksChannel",
      onMessageReceived: (p0) async {
        if (!foundUrls.contains(p0.message)) {
          setState(() => foundUrls.add(p0.message));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (url.isNotEmpty) webView,
            _PodcastSearchPanel(
              delegate: _PodcastSearchDelegate(
                onSearch: (query) {
                  if (query.isEmpty) return;
                  try {
                    webViewController.loadRequest(Uri.parse(query));
                    if (mounted) setState(() {});
                  } catch (e) {
                    if (e is! FormatException && e is! ArgumentError) rethrow;
                    query = query.replaceAll(" ", "+");
                    if (!query.contains("rss")) query = "$query+rss+feed";
                    // query = Provider.of<SettingState>(context).searchEngine.url + query;
                    query = SearchEngine.ecosia.url + query;
                    webViewController.loadRequest(Uri.parse(query));
                    if (mounted) setState(() {});
                  }
                },
                onBack: () => webViewController.goBack(),
                onForward: () => webViewController.goForward(),
              ),
              urls: foundUrls,
              query: url,
            ),
          ],
        ),
      ),
    );
  }
}

class _PodcastSearchPanel extends StatefulWidget {
  final _PodcastSearchDelegate delegate;
  final List<String> urls;
  final String query;
  const _PodcastSearchPanel(
      {required this.delegate,
      this.urls = const [],
      this.query = "",
      super.key});

  @override
  State<_PodcastSearchPanel> createState() => _PodcastSearchPanelState();
}

class _PodcastSearchPanelState extends State<_PodcastSearchPanel> {
  ScrollController scrollController = ScrollController();
  int floatCount = 0;
  int urlCount = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (mounted) {
        if (scrollController.offset > 0) {
          if (scrollController.offset <= 0) {
            setState(() => floatCount = 1);
          } else {
            double previewSize = 140 + context.actionBarIconPadding.vertical;
            setState(
                () => floatCount = 1 + scrollController.offset ~/ previewSize);
          }
        } else {
          setState(() => floatCount = 0);
        }
      }
    });
  }

  @override
  void didUpdateWidget(_PodcastSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (urlCount < widget.urls.length) {
      urlCount = widget.urls.length;
      Future.delayed(
        Duration(milliseconds: 100),
        () {
          if (mounted) {
            scrollController.animateTo(
              scrollController.offset +
                  140 +
                  context.actionBarIconPadding.vertical,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutCirc,
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          hitTestBehavior: HitTestBehavior.deferToChild,
          controller: scrollController,
          shrinkWrap: true,
          children: [
            SizedBox(height: constraints.maxHeight - 120),
            _PodcastSearchCard(
              floating: floatCount > 0,
              short: true,
              child: _Controls(
                delegate: widget.delegate,
                query: widget.query,
                floating: floatCount > 0,
              ),
            ),
            ...widget.urls.mapIndexed(
              (i, e) => _PodcastSearchCard(
                floating: floatCount > i + 1,
                child: _PodcastPreview(e),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PodcastSearchCard extends StatefulWidget {
  final Widget child;
  final bool floating;
  final bool short;
  const _PodcastSearchCard(
      {required this.child,
      this.floating = true,
      this.short = false,
      super.key});
  @override
  State<_PodcastSearchCard> createState() => _PodcastSearchCardState();
}

class _PodcastSearchCardState extends State<_PodcastSearchCard>
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
  }

  @override
  void didUpdateWidget(_PodcastSearchCard oldWidget) {
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

class _Controls extends StatefulWidget {
  final _PodcastSearchDelegate delegate;
  final String query;
  final bool floating;
  const _Controls({
    required this.delegate,
    this.query = "",
    this.floating = true,
    super.key,
  });
  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();

  @override
  void didUpdateWidget(_Controls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      searchController.text = widget.query;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: context.actionBarIconPadding.vertical),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: context.actionBarIconPadding.copyWith(right: 0),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: context.radiusMedium,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      searchFocusNode.unfocus();
                      widget.delegate.onBack();
                    },
                    child: SizedBox(
                      width: context.actionBarButtonSizeHorizontal,
                      height: context.actionBarButtonSizeVertical,
                      child: Icon(
                        Icons.arrow_back,
                        size: context.actionBarIconSize,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: context.actionBarIconPadding.copyWith(left: 0),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: context.radiusMedium,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      searchFocusNode.unfocus();
                      widget.delegate.onForward();
                    },
                    child: SizedBox(
                      width: context.actionBarButtonSizeHorizontal,
                      height: context.actionBarButtonSizeVertical,
                      child: Icon(
                        Icons.arrow_forward,
                        size: context.actionBarIconSize,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOutQuad,
                width: context.width -
                    context.actionBarIconPadding.horizontal *
                        (widget.floating ? 6 : 4) -
                    context.actionBarButtonSizeHorizontal * 3,
                child: TextField(
                  focusNode: searchFocusNode,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    hintText: context.s.searchPodcast,
                    hintStyle: TextStyle(fontSize: 18),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.accentColor),
                      borderRadius: context.radiusSmall,
                    ),
                    enabledBorder:
                        OutlineInputBorder(borderRadius: context.radiusSmall),
                  ),
                  controller: searchController,
                  onSubmitted: (query) {
                    searchFocusNode.unfocus();
                    widget.delegate.onSearch(query);
                  },
                  onTap: () {
                    if (!searchFocusNode.hasFocus) {
                      searchController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: searchController.text.length);
                    }
                  },
                ),
              ),
              Padding(
                padding: context.actionBarIconPadding,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: context.radiusMedium,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      searchFocusNode.unfocus();
                      widget.delegate.onSearch(searchController.text);
                    },
                    child: SizedBox(
                      width: context.actionBarButtonSizeHorizontal,
                      height: context.actionBarButtonSizeVertical,
                      child: Icon(
                        Icons.search,
                        size: context.actionBarIconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: context.width - 80,
            child: Text(
              context.s.searchInstructions,
              style: context.textTheme.bodySmall!
                  .copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastSearchDelegate {
  final void Function(String query) onSearch;
  final void Function() onBack;
  final void Function() onForward;
  _PodcastSearchDelegate({
    this.onSearch = _defOnSearch,
    this.onBack = _defOnBack,
    this.onForward = _defOnForward,
  });
  static void _defOnSearch(String _) {}
  static void _defOnBack() {}
  static void _defOnForward() {}
}

class _PodcastPreview extends StatefulWidget {
  final String url;
  final bool floating;

  const _PodcastPreview(this.url, {this.floating = true, super.key});
  @override
  State<_PodcastPreview> createState() => _PodcastPreviewState();
}

class _PodcastPreviewState extends State<_PodcastPreview> {
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
