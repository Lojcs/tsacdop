import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/episode_state.dart';
import '../state/podcast_state.dart';
import '../util/extension_helper.dart';
import 'search_widgets.dart';

abstract class Search extends ChangeNotifier {
  /// List of ids of search results that are podcasts.
  List<(String, List<int>)> get podcasts => [];

  /// List of ids of search results that are episodes.
  List<int> get episodes => [];

  /// Searches the query and readies the results.
  /// Episodes are loaded immediately, podcasts can be loaded in the background
  Future<void> query(String query);

  /// Maximum length of [podcasts]. (it can be less due to results failing to load / parse)
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
  final PodcastState pState;

  ApiSearch(this.pState);

  @override
  final List<(String, List<int>)> podcasts = [];

  /// Call this when exiting to remove the remote data from [PodcastState] and [EpisodeState]
  void release() => podcasts.forEach(pState.removeRemotePodcast);

  @override
  void dispose() {
    release();
    super.dispose();
  }

  /// Helper to add feeds to the podcasts list.
  Future<void> _addFeed(String feedUrl) async {
    final remotePodcast = await pState.addRemotePodcast(feedUrl);
    if (remotePodcast != null) {
      podcasts.add(remotePodcast);
      notifyListeners();
    }
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
    const path = "https://api.podcastindex.org/search";
    try {
      final response = await Dio().get(path,
          queryParameters: {"term": Uri.encodeQueryComponent(query)});
      final List results = response.data['results'];
      final feedUrls = results
          .map((result) => result is Map ? result['feedUrl'] as String : '');
      addFeeds(feedUrls);
    } catch (e) {
      developer.log(e.toString());
    }
  }
}
