import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webfeed/webfeed.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../type/episodebrief.dart';
import 'package:image/image.dart' as img;
import '../type/fireside_data.dart';
import '../type/podcastbrief.dart';
import '../util/extension_helper.dart';
import 'download_state.dart';

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

@pragma('vm:entry-point')
  static Future<(PodcastBrief?, List<EpisodeBrief>)> _fetchFeed(
      String feedUrl) async {
    PodcastBrief? podcast;
    List<EpisodeBrief> episodes = [];
    try {
      final dio = Dio();
      final response = await dio.get(feedUrl); // Does dynamic work?
      final feed = RssFeed.parse(response.data);
      final digest = sha256.convert(response.data);
      podcast = PodcastBrief.fromFeed(
          feed,
          response.redirects.isEmpty ? feedUrl : response.realUri.toString(),
          digest.toString());
      final items = feed.items ?? [];
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        episodes.add(EpisodeBrief.fromRssItem(
            item, podcast.rssUrl, podcast.title, i, "", Colors.teal));
      }
      episodes = episodes.whereNot((e) => e.enclosureUrl == "").toList();
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
        var (podcast, episodes) = await Isolate.run(() => _fetchFeed(feedUrl));
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

@pragma('vm:entry-point')
  static Future<(PodcastBrief?, List<EpisodeBrief>)> _persistFeed(
      PodcastBrief podcast, List<EpisodeBrief> episodes) async {
    final dir = await getApplicationDocumentsDirectory();
    try {
      var imageResponse = await Dio().get<List<int>>(podcast.imageUrl,
          options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: Duration(seconds: 90)));
      var image = img.decodeImage(Uint8List.fromList(imageResponse.data!))!;
      img.Image? thumbnail = img.copyResize(image, width: 300);
      final imagePath = "${dir.path}/${podcast.id}.png";
      File(imagePath).writeAsBytesSync(img.encodePng(thumbnail));
      podcast = podcast.copyWith(imagePath: imagePath);
    } catch (e) {
      podcast = podcast.copyWith(imagePath: "");
    }
    // final episodeImagesPath = "${dir.path}/${podcast.id}";
    // final episodeImagesFolder = File(episodeImagesPath);
    // if (!episodeImagesFolder.existsSync()) episodeImagesFolder.createSync();
    // for (var episode in episodes) {
    //   try {
    //     var imageResponse = await Dio().get<List<int>>(episode.episodeImageUrl,
    //         options: Options(
    //             responseType: ResponseType.bytes,
    //             receiveTimeout: Duration(seconds: 90)));
    //     var image = img.decodeImage(Uint8List.fromList(imageResponse.data!))!;
    //     final imageDigest = sha256.convert(imageResponse.data!);
    //     final imagePath = "$episodeImagesPath/${imageDigest.toString()}.png";
    //     final imageFile = File(imagePath);
    //     if (!imageFile.existsSync()) {
    //       img.Image? thumbnail = img.copyResize(image, width: 300);
    //       File(imagePath).writeAsBytesSync(img.encodePng(thumbnail));
    //     }
    //     episode = episode.copyWith(episodeImagePath: imagePath);
    //   } catch (e) {
    //     episode = episode.copyWith(episodeImagePath: "");
    //   }
    // }

    episodes.sortBy<num>((episode) => episode.pubDate);
    episodes = episodes
        .mapIndexed((i, episode) => episode.copyWith(number: i + 1))
        .toList();
    return (podcast, episodes);
  }

  Future<void> subscribeRemotePodcast(String podcastId) async {
    if (_remotePodcastMap.containsKey(podcastId)) {
      final (podcastRemote, episodesRemote) = _remotePodcastMap[podcastId]!;
      _dbHelper.savePodcastLocal(podcastRemote);
      if (podcastRemote.provider.contains('fireside')) {
        var data = FiresideData(podcastId, podcastRemote.webpage);
        try {
          await data.fatchData();
        } catch (e) {
          developer.log(e.toString(), name: 'Fatch fireside data error');
        }
      }
      var (podcast, episodes) = await Isolate.run(() => _persistFeed(
            podcastRemote,
            episodesRemote
                .map((episodeId) => _context.episodeState[episodeId])
                .toList(),
          ));
      await _dbHelper.saveNewPodcastEpisodes(episodes);
      removeRemotePodcast((podcastId, episodesRemote));
    }
  }

@pragma('vm:entry-point')
  static Future<(PodcastBrief, List<EpisodeBrief>)?> _syncFeed(
      PodcastBrief podcast, List<EpisodeBrief> episodes) async {
    final dir = await getApplicationDocumentsDirectory();
    try {
      final dio = Dio();
      final response = await dio.get(podcast.rssUrl); // Does dynamic work?
      final digest = sha256.convert(response.data);
      if (digest.toString() != podcast.rssHash) {
        final feed = RssFeed.parse(response.data);
        var podcastNew = PodcastBrief.fromFeed(
            feed,
            response.redirects.isEmpty
                ? podcast.rssUrl
                : response.realUri.toString(),
            digest.toString());
        if (podcastNew.imageUrl != podcast.imageUrl) {
          var imageResponse = await Dio().get<List<int>>(podcast.rssUrl,
              options: Options(
                  responseType: ResponseType.bytes,
                  receiveTimeout: Duration(seconds: 90)));
          var image = img.decodeImage(Uint8List.fromList(imageResponse.data!))!;
          img.Image? thumbnail = img.copyResize(image, width: 300);
          final imagePath = "${dir.path}/${podcast.id}.png";
          File(imagePath).writeAsBytesSync(img.encodePng(thumbnail));
          podcast = podcast.copyWith(imagePath: imagePath);
        }
        final items = feed.items ?? [];
        final enclosureUrls = episodes.map((e) => e.enclosureUrl).toSet();
        final newEnclosureUrls =
            items.map(urlFromRssItem).whereNot((url) => url == "").toSet();
        final onlyNew = newEnclosureUrls.difference(enclosureUrls);
        final onlyNewEpisodes = items
            .where((i) => onlyNew.contains(urlFromRssItem(i)))
            .map((item) => EpisodeBrief.fromRssItem(
                item, podcast.rssUrl, podcast.title, -1, "", Colors.teal))
            .toList();
        onlyNewEpisodes.sortBy<num>((episode) => episode.pubDate);
        return (podcastNew, onlyNewEpisodes);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> syncPodcast(String podcastId) async {
    final episodes = await _dbHelper.getEpisodes(feedIds: [podcastId]);
    await cachePodcasts([podcastId]);
    var result =
        await Isolate.run(() => _syncFeed(_podcastMap[podcastId]!, episodes));
    if (result != null) {
      final (podcast, episodes) = result;
      _dbHelper.savePodcastLocal(podcast);
      await _dbHelper.saveNewPodcastEpisodes(episodes);
      final lastWorkStorage = KeyValueStorage(lastWorkKey);
      if (await lastWorkStorage.getInt() == 0) {
        await _dbHelper.unmarkNewOldEpisodes(podcastId);
      }
      await startDownload(episodes);
    }
  }

  Future<void> startDownload(List<EpisodeBrief> episodes) async {
    move this to the downloader
    final autoDownloadStorage = KeyValueStorage(autoDownloadNetworkKey);
    final autoDownloadNetwork = await autoDownloadStorage.getInt();
    final result = await Connectivity().checkConnectivity();
    if (autoDownloadNetwork == 1 || result.contains(ConnectivityResult.wifi)) {
      // For safety
      if (episodes.length < 100 && episodes.isNotEmpty) {
        await FlutterDownloader.initialize();
        final downloader = AutoDownloader();
        downloader.bindBackgroundIsolate();
        await downloader.startTask(episodes);
        // This doesn't seem to work unless it's awaited.
      }
    }
    final lastWorkStorage = KeyValueStorage(lastWorkKey);
    await lastWorkStorage.saveInt(1);
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
