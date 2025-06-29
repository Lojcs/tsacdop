import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:color_thief_dart/color_thief_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import 'search_widgets.dart';

abstract class Search extends ChangeNotifier {
  /// Map of podcast results of search.
  final List<(PodcastBrief, List<int>)> podcasts = [];

  /// List of episode results of search.
  final List<int> episodes = [];

  /// Searches the query and readies the results.
  /// Episodes are loaded immediately, podcasts can be loaded in the background
  Future<void> query(String query);

  /// Maximum length of [podcasts]
  int maxPodcastLength = 0;

  /// Returns the [i]th card widget
  Widget? operator [](int i) {
    if (episodes.isNotEmpty) {
      if (i == 0) return SearchPanelCard(child: SearchEpisodeGrid(episodes));
      i--;
    }
    if (i < podcasts.length) {
      return SearchPanelCard(
          child: SearchPodcastPreview(podcasts[i].$1, podcasts[i].$2));
    } else if (podcasts.length < maxPodcastLength) {
      return Selector<Search, bool>(
        selector: (_, search) => search.podcasts.length > i,
        builder: (context, value, _) => value
            ? SearchPanelCard(
                child: SearchPodcastPreview(podcasts[i].$1, podcasts[i].$2),
              )
            : SearchPanelCard(
                child: Container(
                  decoration: BoxDecoration(borderRadius: context.radiusSmall),
                  clipBehavior: Clip.antiAlias,
                  child: LinearProgressIndicator(),
                ),
              ),
      );
    } else {
      return null;
    }
  }

  /// Widget to be placed behind the search panel
  static const Widget background = Center();
}

/// Abtract class for api helpers
abstract class ApiSearch extends Search {
  final EpisodeState eState;

  ApiSearch(this.eState);

  List<int> get _remoteEpisodeIds => podcasts
      .map((episodes) => episodes.$2)
      .reduce((l1, l2) => [...l1, ...l2]);

  /// Call this when ApiHelper is done to remove the remote episodes from episodeState
  void release() => eState.removeRemoteEpisodes(_remoteEpisodeIds);

  @override
  void dispose() {
    release();
    super.dispose();
  }

  static Future<(PodcastBrief?, List<EpisodeBrief>)> _addFeedIsolated(
      String feedUrl) async {
    PodcastBrief? podcast;
    List<EpisodeBrief> episodes = [];
    try {
      final dio = Dio();
      final response = await dio.get(feedUrl);
      final feed = RssFeed.parse(response.data);
      podcast = PodcastBrief.fromFeed(feed,
          response.redirects.isEmpty ? feedUrl : response.realUri.toString());
      final items = feed.items ?? [];
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        episodes.add(EpisodeBrief.fromRssItem(item, podcast.rssUrl,
            podcast.title, i, podcast.imageUrl, Colors.teal));
      }
    } catch (e) {
      developer.log(e.toString());
    }
    return (podcast, episodes);
  }

  /// Helper to add feeds to the podcasts list.
  Future<void> _addFeed(String feedUrl) async {
    final dbHelper = DBHelper();
    switch (await dbHelper.checkPodcast(feedUrl)) {
      case String id:
        final podcast = await dbHelper.getPodcast(id);
        final episodes = await dbHelper.getEpisodes(feedIds: [id]);
        podcasts.add((podcast!, eState.addRemoteEpisodes(episodes)));
      case null:
        var (podcast, episodes) =
            await Isolate.run(() => _addFeedIsolated(feedUrl));
        if (podcast != null) {
          final imageProvider = NetworkImage(podcast.imageUrl);
          var image = await getImageFromProvider(imageProvider);
          final colorString = (await getColorFromImage(image)).toString();
          final color = colorString.toColor();
          podcast = podcast.copyWith(primaryColor: colorString);
          episodes =
              episodes.map((e) => e.copyWith(primaryColor: color)).toList();
          podcasts.add((podcast, eState.addRemoteEpisodes(episodes)));
        }
    }
    notifyListeners();
  }

  /// Helper to add feeds to the podcasts list.
  Future<void> addFeeds(Iterable<String> feedUrls) async {
    maxPodcastLength = feedUrls.length;
    Queue<Future> futures = Queue();
    for (final feed in feedUrls) {
      if (futures.length >= 5) await futures.removeFirst();
      futures.add(_addFeed(feed)); // Don't await
    }
  }
}

class PodcastIndexSearch extends ApiSearch {
  PodcastIndexSearch(super.eState);

  @override
  Future<void> query(String query) async {
    const initial = "https://api.podcastindex.org/search?term=";
    try {
      final request = initial + Uri.encodeQueryComponent(query);
      final response = await Dio().get(request);
      final List results = response.data['results'];
      final feedUrls = results
          .map((result) => result is Map ? result['feedUrl'] as String : '');
      addFeeds(feedUrls);
    } catch (e) {
      developer.log(e.toString());
    }
  }
}
