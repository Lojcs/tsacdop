import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'search_controller.dart';

/// Abstract class for web search
abstract class WebSearch extends RemoteSearch {
  final WebViewController _webViewController = WebViewController();

  WebSearch(super.pState, super.eState) {
    WebViewCookieManager().clearCookies();
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.clearCache();
    _webViewController
        .clearLocalStorage(); // TODO: This doesn't clear google dark mode??
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onUrlChange: (change) async {
          if (change.url != null && change.url != "") {
            await tryAddFeed(change.url!);
          }
        },
        onPageFinished: (url) async {
          await _webViewController.runJavaScript("""
          let anchors = document.querySelectorAll('a');
          let urlsFromAnchors = Array.from(anchors).map(a => a.href);
          let urls = [...urlsFromAnchors];
          for (let url of urls) {
            if (url.endsWith(".rss") || url.endsWith(".xml")) {
              linksChannel.postMessage(url);
            }
          }
        """);
          for (var element in removedElements) {
            await _webViewController.runJavaScript(
              "document.querySelector('$element').remove();",
            );
          }
          await Future.delayed(Duration(seconds: 1));
        },
      ),
    );
    _webViewController.addJavaScriptChannel(
      "linksChannel",
      onMessageReceived: (p0) => tryAddFeed(p0.message),
    );
    background = WebViewWidget(controller: _webViewController);
  }

  /// Url to append the query to.
  String get baseSearchUrl;

  /// Elements to query and remove in javascript.
  List<String> get removedElements;

  String sanitizeQuery(String query) => query.replaceAll(" ", "+");

  Uri queryToUri(String query) {
    if (!query.contains("rss")) query = "$query+rss+feed";
    return Uri.parse(baseSearchUrl + sanitizeQuery(query));
  }

  @override
  Future<void> newQuery(String query) async {
    try {
      _webViewController.loadRequest(Uri.parse(query));
    } catch (e) {
      if (e is! FormatException && e is! ArgumentError) rethrow;
      _webViewController.loadRequest(queryToUri(query));
    }
  }

  @override
  Future<void> preparePodcastEpisodes(String podcastId) async {}

  Future<void> goBack() => _webViewController.goBack();
  Future<void> goForward() => _webViewController.goForward();
}

enum SearchEngine {
  bing(
    name: "Bing",
    baseSearchUrl: "https://www.bing.com/search?q=",
    serial: "bing",
  ),
  brave(
    name: "Brave",
    baseSearchUrl: "https://search.brave.com/search?q=",
    serial: "brave",
  ),
  duckduckgo(
    name: "DuckDuckGo",
    baseSearchUrl: "https://duckduckgo.com/?q=",
    serial: "duckduckgo",
  ),
  ecosia(
    name: "Ecosia",
    baseSearchUrl: "https://www.ecosia.org/search?q=",
    removedElements: [".cookie-wrapper", "#didomi-host"],
    serial: "ecosia",
  ),
  google(
    name: "Google",
    baseSearchUrl: "https://www.google.com/search?q=",
    serial: "google",
  ),
  qwant(
    name: "Qwant",
    baseSearchUrl: "https://qwant.com/search?q=",
    serial: "qwant",
  ),
  startpage(
    name: "Startpage",
    baseSearchUrl: "https://eu.startpage.com/search?q=",
    serial: "startpage",
  ),
  yahoo(
    name: "Yahoo",
    baseSearchUrl: "https://search.yahoo.com/search?q=",
    serial: "yahoo",
  ),
  yandex(
    name: "Yandex",
    baseSearchUrl: "https://yandex.com/search/?text=",
    serial: "yandex",
  );

  const SearchEngine({
    required this.name,
    required this.baseSearchUrl,
    this.removedElements = const [],
    this.bespokeIcon,
    required this.serial,
  });

  factory SearchEngine.fromSerial(String serial) => switch (serial) {
    "bing" => bing,
    "brave" => brave,
    "duckduckgo" => duckduckgo,
    "ecosia" => ecosia,
    "google" => google,
    "qwant" => qwant,
    "startpage" => startpage,
    "yahoo" => yahoo,
    "yandex" => yandex,
    _ => ecosia,
  };

  final String name;
  final String baseSearchUrl;
  final List<String> removedElements;
  final Widget? bespokeIcon;
  final String serial;
  Widget get icon => bespokeIcon ?? Text(name.substring(0, 1));
}

class SearchEngineSearch extends WebSearch {
  SearchEngine _searchEngine = SearchEngine.ecosia;

  SearchEngine get searchEngine => _searchEngine;
  set searchEngine(SearchEngine engine) {
    _searchEngine = engine;
    notifyListeners();
  }

  SearchEngineSearch(
    super.pState,
    super.eState, [
    SearchEngine searchEngine = SearchEngine.ecosia,
  ]) : _searchEngine = searchEngine;
  @override
  String get baseSearchUrl => searchEngine.baseSearchUrl;
  @override
  List<String> get removedElements => searchEngine.removedElements;
}
