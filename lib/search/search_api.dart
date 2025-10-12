import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../type/episodebrief.dart';
import '../type/podcastbrief.dart';
import 'search_controller.dart';

typedef AddPodcasts = void Function(Iterable<PodcastBrief> feedUrls);
typedef AddEpisodes = void Function(Iterable<EpisodeBrief> episodes);
typedef QueryApi = Future<void> Function(
    String query, AddPodcasts addFeeds, AddEpisodes addEpisodes);

enum SearchApi {
  podcastIndex(
    name: "PodcastIndex",
    queryApi: _podcastIndexQuery,
  ),
  itunes(
    name: "iTunes",
    queryApi: _itunesQuery,
  );

  const SearchApi(
      {required this.name, required this.queryApi, this.bespokeIcon});

  final String name;
  final QueryApi queryApi;
  final Widget? bespokeIcon;
  Widget get icon => bespokeIcon ?? Text(name.substring(0, 1));
}

Future<void> _podcastIndexQuery(
    String query, AddPodcasts addPodcasts, AddEpisodes addEpisodes) async {
  const path = "https://api.podcastindex.org/search";
  try {
    final response = await Dio().get(path,
        queryParameters: {"term": Uri.encodeQueryComponent(query)},
        options: Options(responseType: ResponseType.json));
    final List results = response.data['results'];
    final podcasts = results
        .map((result) => PodcastBrief.api(
            title: result['collectionName'] as String,
            rssUrl: result['feedUrl'] as String,
            imageUrl: result['artworkUrl100'] as String))
        .toList();
    // for (var i = 0; i < podcasts.length; i++) {
    //   podcasts[i] = await podcasts[i].withColorFromImage();
    // }
    addPodcasts(podcasts);
  } catch (e) {
    developer.log(e.toString());
  }
}

Future<void> _itunesQuery(
    String query, AddPodcasts addPodcasts, AddEpisodes addEpisodes) async {
  const path = "https://itunes.apple.com/search";
  try {
    final response = await Dio().get<String>(path,
        queryParameters: {
          "term": Uri.encodeQueryComponent(query),
          "media": "podcast"
        },
        options: Options(responseType: ResponseType.plain));
    // Itunes adds 3 newlines before the json to confuse Dio.
    final responseJson = json.decode(response.data!);
    final List results = responseJson['results'];
    final podcasts = results
        .map((result) => switch (result['feedUrl']) {
              String rssUrl => PodcastBrief.api(
                  title: result['collectionName'] as String,
                  rssUrl: rssUrl,
                  imageUrl: result['artworkUrl100'] as String),
              _ => null
            })
        .nonNulls
        .toList();
    // for (var i = 0; i < podcasts.length; i++) {
    //   podcasts[i] = await podcasts[i].withColorFromImage();
    // }
    addPodcasts(podcasts);
  } catch (e) {
    developer.log(e.toString());
  }
}

class ApiSearch extends RemoteSearch {
  SearchApi _searchApi = SearchApi.podcastIndex;

  SearchApi get searchApi => _searchApi;
  set searchApi(SearchApi api) {
    _searchApi = api;
    notifyListeners();
  }

  ApiSearch(super.pState, super.eState);

  @override
  Future<void> preparePodcastEpisodes(String podcastId) async {}

  @override
  Future<void> newQuery(String query) => _searchApi.queryApi(
      query,
      (podcasts) => addFeeds(podcasts.map((podcast) => podcast.rssUrl)),
      addEpisodes);
}
