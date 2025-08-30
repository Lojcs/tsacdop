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
  List<String> get podcastIds => [];

  /// List of ids of the episodes of a podcast search result.
  List<int> getPodcastEpisodes(String podcastId) => [];

  /// List of ids of search results that are episodes.
  List<int> get episodeIds => [];

  /// Searches the query and readies the results.
  /// Episodes are loaded immediately, podcasts can be loaded in the background
  Future<void> query(String query);

  /// Maximum length of [podcastIds]. (it can be less due to results not having loaded in)
  int maxPodcastLength = 0;

  /// Widget to be placed behind the search panel
  static const Widget background = Center();
}

/// Abtract class for api helpers
abstract class RemoteSearch extends Search {
  final PodcastState pState;
  final EpisodeState eState;

  RemoteSearch(this.pState, this.eState);

  @override
  final List<String> podcastIds = [];
  @override
  final List<int> episodeIds = [];

  final Map<String, List<int>> podcastEpisodes = {};
  @override
  List<int> getPodcastEpisodes(String podcastId) => podcastEpisodes[podcastId]!;

  /// Call this when exiting to remove the remote data from [PodcastState] and [EpisodeState]
  void release() {
    for (var podcastId in podcastIds) {
      pState.removeRemotePodcast(podcastId);
      eState.removeRemoteEpisodes(getPodcastEpisodes(podcastId));
    }
    eState.removeRemoteEpisodes(episodeIds);
  }

  @override
  void dispose() {
    release();
    super.dispose();
  }

  /// Helper to add feeds to the podcasts list.
  Future<void> _addFeed(String feedUrl) async {
    final result = await pState.addPodcastByUrl(feedUrl);
    if (result != null) {
      final (podcastId, episodeIds) = result;
      podcastIds.add(podcastId);
      podcastEpisodes[podcastId] = episodeIds;
      notifyListeners();
    }
  }

  /// Helper to add feeds to the podcasts list.
  Future<void> addFeeds(Iterable<String> feedUrls) async {
    maxPodcastLength = feedUrls.length;
    Queue<Future<void>> futures = Queue();
    for (var feed in feedUrls) {
      if (futures.length >= 8) await futures.removeFirst();
      futures.add(_addFeed(feed)); // Don't await
    }
  }

  /// Subscribe to the remote podcast with id [podcastId].
  Future<void> subscribe(String podcastId) async {
    final index = podcastIds.indexOf(podcastId);
    final result = await pState.subscribeRemotePodcast(
        podcastId, podcastEpisodes[podcastId]!);
    if (result != null) {
      podcastEpisodes.remove(podcastId);
      podcastIds[index] = result.$1;
      podcastEpisodes[result.$1] = result.$2;
    }
  }
}

class PodcastIndexSearch extends RemoteSearch {
  PodcastIndexSearch(super.pState, super.eState);

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
