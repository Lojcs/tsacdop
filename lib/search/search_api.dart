import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../type/episodebrief.dart';
import 'search_controller.dart';

typedef AddFeeds = Future<void> Function(Iterable<String> feedUrls);
typedef AddEpisodes = void Function(Iterable<EpisodeBrief> episodes);
typedef QueryApi = Future<void> Function(
    String query, AddFeeds addFeeds, AddEpisodes addEpisodes);

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
    String query, AddFeeds addFeeds, AddEpisodes addEpisodes) async {
  const path = "https://api.podcastindex.org/search";
  try {
    final response = await Dio().get(path,
        queryParameters: {"term": Uri.encodeQueryComponent(query)},
        options: Options(responseType: ResponseType.json));
    final List results = response.data['results'];
    final feedUrls = results
        .map((result) => result is Map ? result['feedUrl'] as String : '');
    await addFeeds(feedUrls);
  } catch (e) {
    developer.log(e.toString());
  }
}

Future<void> _itunesQuery(
    String query, AddFeeds addFeeds, AddEpisodes addEpisodes) async {
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
    final feedUrls = results
        .map((result) => result is Map ? result['feedUrl'] as String : '');
    await addFeeds(feedUrls);
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
  Future<void> newQuery(String query) =>
      _searchApi.queryApi(query, addFeeds, addEpisodes);
}
