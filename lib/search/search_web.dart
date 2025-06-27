import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xml/xml.dart';

import 'search_page.dart';

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
            SearchPanel(
              // delegate: CustomSearchDelegate(
              //   onSearch: (query) {
              //     if (query.isEmpty) return;
              //     try {
              //       webViewController.loadRequest(Uri.parse(query));
              //       if (mounted) setState(() {});
              //     } catch (e) {
              //       if (e is! FormatException && e is! ArgumentError) rethrow;
              //       query = query.replaceAll(" ", "+");
              //       if (!query.contains("rss")) query = "$query+rss+feed";
              //       // query = Provider.of<SettingState>(context).searchEngine.url + query;
              //       query = SearchEngine.ecosia.url + query;
              //       webViewController.loadRequest(Uri.parse(query));
              //       if (mounted) setState(() {});
              //     }
              //   },
              //   onBack: () => webViewController.goBack(),
              //   onForward: () => webViewController.goForward(),
              // ),
              urls: foundUrls,
            ),
          ],
        ),
      ),
    );
  }
}
