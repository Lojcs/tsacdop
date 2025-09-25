import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../state/episode_state.dart';
import '../state/podcast_state.dart';
import '../type/episodebrief.dart';
import 'search_api.dart';
import 'search_web.dart';

/// Abstract class for search controllers
abstract class Search extends ChangeNotifier {
  /// List of ids of search results that are podcasts.
  List<String> get podcastIds => [];

  /// List of ids of the episodes of a podcast search result.
  List<int>? getPodcastEpisodes(String podcastId) => [];

  /// List of ids of search results that are episodes.
  List<int> get episodeIds => [];

  /// Text of the query.
  String queryText = "";

  /// Searches the query if it is different from the last query.
  Future<void> query(String query) async {
    if (queryText != query && query != "") {
      queryText = query;
      newQuery(query);
    }
  }

  /// Searches the query and readies the results.
  /// Episodes are loaded immediately, podcasts can be loaded in the background
  Future<void> newQuery(String query);

  /// Removes podcast from results.
  void removePodcast(String podcastId);

  /// Maximum length of [podcastIds]. (it can be less due to results not having loaded in)
  int maxPodcastCount = 0;

  int get itemCount => maxPodcastCount + (episodeIds.isNotEmpty ? 1 : 0);

  /// Widget to be placed behind the search panel
  Widget background = Center();
}

/// Abtract class for search controllers that fetch data remotely
abstract class RemoteSearch extends Search {
  final PodcastState pState;
  final EpisodeState eState;

  RemoteSearch(this.pState, this.eState);

  @override
  final List<String> podcastIds = [];
  final List<String> podcastUrls = [];
  @override
  final List<int> episodeIds = [];

  final Map<String, List<int>> podcastEpisodes = {};
  @override
  List<int>? getPodcastEpisodes(String podcastId) => podcastEpisodes[podcastId];

  /// Incremented on clear, prevents results from previous searches
  /// from being added to results later.
  int _searchGeneration = 0;

  /// Call this when exiting to remove the remote data from [PodcastState] and [EpisodeState]
  void clear() {
    for (var podcastId in podcastIds) {
      pState.removeRemotePodcast(podcastId);
      eState.removeRemoteEpisodes(getPodcastEpisodes(podcastId)!);
    }
    eState.removeRemoteEpisodes(episodeIds);
    podcastIds.clear();
    podcastUrls.clear();
    podcastEpisodes.clear();
    episodeIds.clear();
    maxPodcastCount = 0;
    queryText = "";
    _searchGeneration++;
    if (hasListeners) notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  /// Helper to add feed to the podcasts list. Returns success.
  Future<bool> _addFeed(String feedUrl) async {
    bool ret = false;
    if (!podcastUrls.contains(feedUrl)) {
      final generation = _searchGeneration;
      final result = await pState.addPodcastByUrl(feedUrl);
      if (generation == _searchGeneration) {
        if (result != null) {
          final (podcastId, episodeIds) = result;
          podcastIds.add(podcastId);
          podcastUrls.add(feedUrl);
          podcastEpisodes[podcastId] = episodeIds;
          ret = true;
        } else {
          maxPodcastCount--;
        }
        notifyListeners();
      }
    }
    return ret;
  }

  /// Helper to try to add a single feed to the podcasts list. Returns success
  Future<bool> tryAddFeed(String feedUrl) {
    maxPodcastCount++;
    return _addFeed(feedUrl);
  }

  /// Helper to add feeds to the podcasts list.
  Future<void> addFeeds(Iterable<String> feedUrls) async {
    final generation = _searchGeneration;
    Queue<Future<void>> futures = Queue();
    maxPodcastCount = podcastIds.length + feedUrls.length;
    for (var feedUrl in feedUrls) {
      if (generation != _searchGeneration) break;
      if (futures.length >= 8) await futures.removeFirst();
      futures.add(_addFeed(feedUrl)); // Don't await
    }
    await Future.wait(futures);
  }

  void addEpisodes(Iterable<EpisodeBrief> episodes) {
    throw UnimplementedError();
  }

  @override
  void removePodcast(String podcastId) {
    pState.removeRemotePodcast(podcastId);
    eState.removeRemoteEpisodes(getPodcastEpisodes(podcastId)!);
    final index = podcastIds.indexOf(podcastId);
    podcastIds.removeAt(index);
    podcastUrls.removeAt(index);
    podcastEpisodes.remove(podcastId);
    maxPodcastCount--;
    notifyListeners();
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

/// Joins api search and web search.
class JointSearch extends Search {
  final PodcastState pState;
  final EpisodeState eState;
  JointSearch(this.pState, this.eState)
      : apiSearch = ApiSearch(pState, eState),
        webSearch = SearchEngineSearch(pState, eState) {
    apiSearch.addListener(() => notifyListeners());
    webSearch.addListener(() => notifyListeners());
  }

  ApiSearch apiSearch;
  SearchEngineSearch webSearch;

  bool _searchWeb = false;
  bool get searchWeb => _searchWeb;
  set searchWeb(bool boo) {
    _searchWeb = boo;
    notifyListeners();
  }

  SearchApi get searchApi => apiSearch.searchApi;
  set searchApi(SearchApi api) => apiSearch.searchApi = api;

  SearchEngine get searchEngine => webSearch.searchEngine;
  set searchEngine(SearchEngine engine) => webSearch.searchEngine = engine;

  @override
  List<String> get podcastIds => apiSearch.podcastIds + webSearch.podcastIds;
  @override
  List<int> get episodeIds => apiSearch.episodeIds + webSearch.episodeIds;

  @override
  Future<void> newQuery(String query) =>
      _searchWeb ? webSearch.newQuery(query) : apiSearch.newQuery(query);

  @override
  void removePodcast(String podcastId) => _searchWeb
      ? webSearch.removePodcast(podcastId)
      : apiSearch.removePodcast(podcastId);

  @override
  Widget get background =>
      _searchWeb ? webSearch.background : apiSearch.background;

  @override
  int get maxPodcastCount =>
      apiSearch.maxPodcastCount + webSearch.maxPodcastCount;

  @override
  int get itemCount => apiSearch.itemCount + webSearch.itemCount;

  void clear() {
    queryText = "";
    apiSearch.clear();
    webSearch.clear();
  }

  @override
  void dispose() {
    apiSearch.dispose();
    webSearch.dispose();
    super.dispose();
  }

  @override
  List<int>? getPodcastEpisodes(String podcastId) =>
      apiSearch.getPodcastEpisodes(podcastId) ??
      webSearch.getPodcastEpisodes(podcastId);

  Future<void> subscribe(String podcastId) async {
    if (apiSearch.podcastIds.contains(podcastId)) {
      await apiSearch.subscribe(podcastId);
    } else {
      await webSearch.subscribe(podcastId);
    }
  }
}
