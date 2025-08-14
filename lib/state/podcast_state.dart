import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../type/episodebrief.dart';
import '../type/podcastbrief.dart';
import '../util/extension_helper.dart';

const deletedPodcastId = "46e48103-06c7-4fe1-a0b1-68aa7205b7f0";

/// Global class to manage [PodcastBrief] field updates.
class PodcastState extends ChangeNotifier {
  final Directory documents;
  PodcastState(this.documents);

  final DBHelper _dbHelper = DBHelper();
  late BuildContext _context;
  set context(BuildContext context) => _context = context;

  /// podcast id : PodcastBrief
  final Map<String, PodcastBrief> _podcastMap = {};

  /// podcast id : (PodcastBrief, List episode id)
  final Map<String, (PodcastBrief, List<int>)> _remotePodcastMap = {};

  /// List of deleted podcast ids.
  final List<String> deletedIds = [];

  late final PodcastBrief deletedPodcast = PodcastBrief.localFolder(
      _context.s, documents,
      id: deletedPodcastId,
      title: _context.s.deleted,
      description: _context.s.deletedPodcastDesc);

  /// Convenience operator for .podcastMap[id]!
  PodcastBrief operator [](String id) =>
      _podcastMap[id] ??
      _remotePodcastMap[id]?.$1 ??
      (deletedIds.contains(id) ? deletedPodcast : _podcastMap[id]!);

  /// Indicates something changed
  bool globalChange = false;

  /// Ids changed in last update
  List<String> changedIds = [];

  /// Ensures the podcasts with the given ids are cached.
  /// Returns the ids not found in database.
  Future<List<String>> cachePodcasts(List<String> podcastIds) async {
    List<String> missingIds = [];
    for (var id in podcastIds) {
      if (!_podcastMap.containsKey(id)) {
        missingIds.add(id);
      }
    }
    List<String> foundIds = await getPodcasts(podcastIds: missingIds);
    return missingIds.where((id) => !foundIds.contains(id)).toList();
  }

  /// Queries the database with the provided options and returns found podcasts.
  /// Filters are tri-state (null - no filter, true - only, false - exclude)
  Future<List<String>> getPodcasts(
      {List<String>? groupIds,
      List<String>? podcastIds,
      List<String>? rssUrls,
      bool? filterAutoUpdate}) async {
    List<PodcastBrief> podcasts = await _dbHelper.getPodcasts(
        groupIds: groupIds,
        podcastIds: podcastIds,
        rssUrls: rssUrls,
        filterNoAutoSync: filterAutoUpdate);
    for (var podcast in podcasts) {
      _podcastMap[podcast.id] = podcast;
    }
    return podcasts.map((pod) => pod.id).toList();
  }

  /// Call this only when a podcast is removed from the database
  void deleteSavedPodcast(String id) {
    if (_podcastMap.remove(id) != null) deletedIds.add(id);
    _dbHelper.delPodcastLocal(id);
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

  /// Adds a podcast and its episodes dentoed by its rss feed url.
  /// If the podcast is already subscribed to, uses data from the database.
  /// Otherwise tries to fetch the rss feed and parse it.
  Future<(String, List<int>)?> addRemotePodcast(String feedUrl) async {
    final dbHelper = DBHelper();
    (String, List<int>)? returnId;
    switch (await dbHelper.checkPodcast(feedUrl)) {
      case String id:
        await cachePodcasts([id]);
        if (_context.mounted) {
          final episodeIds =
              await _context.episodeState.getEpisodes(feedIds: [id]);
          returnId = (id, episodeIds);
        }
      case null:
        var (podcast, episodes) =
            await Isolate.run(() => _addFeedIsolated(feedUrl));
        if (podcast != null) {
          podcast = await podcast.withColorFromImage();
          episodes = episodes
              .map((e) => e.copyWith(primaryColor: podcast!.primaryColor))
              .toList();
          if (_context.mounted) {
            final episodeIds =
                _context.episodeState.addRemoteEpisodes(episodes);
            _remotePodcastMap[podcast.id] = (podcast, episodeIds);
            returnId = (podcast.id, episodeIds);
          }
        }
    }
    notifyListeners();
    return returnId;
  }

  void removeRemotePodcast((String, List<int>) remotePodcast) {
    if (_remotePodcastMap.containsKey(remotePodcast.$1)) {
      if (_context.mounted) {
        _context.episodeState.removeRemoteEpisodes(remotePodcast.$2);
      }
      _remotePodcastMap.remove(remotePodcast.$1);
    }
  }

  /// Changes the given properties of the given podcasts.
  Future<void> changePodcastProperty(
    List<String> ids, {
    bool? hideNewMark,
    bool? noAutoSync,
    bool? autoDownload,
    int? skipSecondsStart,
    int? skipSecondsEnd,
  }) async {
    assert(ids.every((id) => _podcastMap.keys.contains(id)),
        "saveNoAutoSync called with unknown id");
    await _dbHelper.savePodcastProperties(
      ids,
      hideNewMark: hideNewMark,
      noAutoSync: noAutoSync,
      autoDownload: autoDownload,
      skipSecondsStart: skipSecondsStart,
      skipSecondsEnd: skipSecondsEnd,
    );
    changedIds.clear();
    for (var id in ids) {
      _podcastMap[id] = _podcastMap[id]!.copyWith(
        hideNewMark: hideNewMark,
        noAutoSync: noAutoSync,
        autoDownload: autoDownload,
        skipSecondsStart: skipSecondsStart,
        skipSecondsEnd: skipSecondsEnd,
      );
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }
}
