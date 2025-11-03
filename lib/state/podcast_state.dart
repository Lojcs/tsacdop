import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:developer' as dev;
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:webfeed/webfeed.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../backup/opml_helper.dart';
import '../type/episodebrief.dart';
import 'package:image/image.dart' as img;
import '../type/fireside_data.dart';
import '../type/podcastbrief.dart';
import '../type/podcastgroup.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import 'download_state.dart';
import 'episode_state.dart';

const deletedPodcastId = "46e48103-06c7-4fe1-a0b1-68aa7205b7f0";

/// Global class to manage [PodcastBrief] field updates.
class PodcastState extends ChangeNotifier {
  final Directory documents;
  final rootIsolateToken = ServicesBinding.rootIsolateToken!;
  PodcastState(this.documents) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    ready = _loadGroups();
  }

  /// Load groups
  Future<void> _loadGroups() async {
    final groups = await _dbHelper.getGroups();
    for (var group in groups) {
      _groupMap[group.id] = group;
    }
    await cacheGroup(homeGroupId);
  }

  late Future<void> ready;

  final DBHelper _dbHelper = DBHelper();

  late EpisodeState _episodeState;
  late DownloadState _downloadState;
  bool _background = true;
  set context(BuildContext context) {
    _episodeState = context.episodeState;
    _downloadState = context.downloadState;
    _background = false;
  }

  bool get background => _background;

  /// podcast id : PodcastBrief
  final Map<String, PodcastBrief> _podcastMap = {};

  /// podcast id : PodcastBrief
  final Map<String, PodcastBrief> _remotePodcastMap = {};

  /// Set of deleted podcast ids.
  final Set<String> deletedIds = {};

  /// Convenience operator getting the [PodcastBrief] of a podcast.
  PodcastBrief operator [](String id) =>
      _podcastMap[id] ??
      _remotePodcastMap[id] ??
      (deletedIds.contains(id) ? _podcastMap[id]! : _podcastMap[id]!);

  /// Flips to indicate some podcast property changed.
  bool podcastChange = false; // TODO: This doesn't update on sync'n stuff

  /// group id : PodcastGroup
  final Map<String, PodcastGroup> _groupMap = {};

  /// Gets the list of groupIds
  List<String> get groupIds => _groupMap.keys.toList();

  /// Gets the group with id [id]
  PodcastGroup getGroupById(String id) => _groupMap[id]!;

  /// Flips to indicate some group property changed.
  bool groupsChange = false;

  /// Ids changed in last update
  Set<String> changedIds = {};

  late OpmlProgress _opmlProgress = OpmlProgress(_setOpmlProgress, done: true);
  OpmlProgress get opmlProgress => _opmlProgress;
  void _setOpmlProgress(OpmlProgress progress) {
    _opmlProgress = progress;
    notifyListeners();
  }

  /// Ensures the podcast with the given id is cached.
  /// Returns wheter it was found.
  Future<bool> cachePodcast(String podcastId) async {
    List<String> foundIds = await getPodcasts(podcastIds: [podcastId]);
    return foundIds.isNotEmpty;
  }

  /// Ensures the group with the given id is cached.
  /// Returns wheter it was found.
  Future<bool> cacheGroup(String groupId) async {
    List<String> foundIds = await getPodcasts(groupIds: [groupId]);
    return foundIds.isNotEmpty;
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

  /// Unsubscibes from podcast and deletes local data. Safe to call from the background.
  Future<void> unsubscribePodcast(String podcastId) async {
    final eState = background ? EpisodeState() : _episodeState;

    for (var groupId in _groupMap.keys) {
      _groupMap[groupId]!.removeFromGroup(podcastId);
      await _dbHelper.removePodcastFromGroup(
          podcastId: podcastId, groupId: groupId);
    }
    groupsChange = !groupsChange;

    final podcastEpisodeIds = await eState.getEpisodes(feedIds: [podcastId]);
    eState.deleteEpisodes(podcastEpisodeIds, deleteFromDatabase: false);

    await cachePodcast(podcastId);
    final podcast = _podcastMap[podcastId]!;
    // final dir = await getApplicationDocumentsDirectory();
    // final episodeImagesPath = "${dir.path}/${podcast.id}";
    // await Directory(episodeImagesPath).delete(recursive: true);
    await File(podcast.imagePath).delete();
    if (_podcastMap.remove(podcastId) != null) deletedIds.add(podcastId);
    await _dbHelper.delPodcast(podcastId);
    notifyListeners();
  }

  /// Isolateable function that fetches a podcast from an rss feed url.
  static Future<(PodcastBrief?, List<EpisodeBrief>)> _fetchFeed(
      String feedUrl) async {
    PodcastBrief? podcast;
    List<EpisodeBrief> episodes = [];
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(feedUrl,
          options: Options(responseType: ResponseType.bytes));
      if (response.data != null) {
        final feed = RssFeed.parse(utf8.decode(response.data!));
        final digest = sha256.convert(response.data!);
        podcast = PodcastBrief.fromFeed(
            feed,
            response.redirects.isEmpty ? feedUrl : response.realUri.toString(),
            digest.toString());
        final items = feed.items ?? [];
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          episodes.add(EpisodeBrief.fromRssItem(
              item, podcast.id, podcast.title, i, "", Colors.teal));
        }
        episodes = episodes.whereNot((e) => e.enclosureUrl == "").toList();
      }
    } catch (e) {
      developer.log(e.toString());
    }
    return (podcast, episodes);
  }

  /// Adds a podcast and its episodes denoted by its rss feed url.
  /// Not safe to call from the background.
  /// If the podcast is already subscribed to, uses data from [EpisodeState].
  /// Otherwise tries to fetch the rss feed and parse it.
  /// Episodes kept only as temp ids, [EpisodeBrief]s are kept in [EpisodeState]
  Future<(String, List<int>)?> addPodcastByUrl(String feedUrl) async {
    (String, List<int>)? ret;
    switch (await _dbHelper.checkPodcast(feedUrl)) {
      case String id:
        await cachePodcast(id);
        final episodeIds =
            await _episodeState.getEpisodes(feedIds: [id], limit: 100);
        ret = (id, episodeIds);

      case null:
        var (podcast, episodes) = await Isolater(_fetchFeed).run(feedUrl);
        if (podcast != null) {
          try {
            podcast = await podcast.withColorFromImage();
          } catch (e) {
            return ret;
          }
          episodes = episodes
              .map((e) => e.copyWith(primaryColor: podcast!.primaryColor))
              .toList();
          final episodeIds = _episodeState.addRemoteEpisodes(episodes);
          _remotePodcastMap[podcast.id] = podcast;
          ret = (podcast.id, episodeIds);
        }
    }
    notifyListeners();
    return ret;
  }

  /// Removes remote podcast from the remote podcast map.
  void removeRemotePodcast(String remotePodcastId) {
    _remotePodcastMap.remove(remotePodcastId);
  }

  /// Isolateable function that prepares a remote podcast for saving into database.
  static Future<(PodcastBrief, List<EpisodeBrief>)> _persistFeed(
      (PodcastBrief, List<EpisodeBrief>) data) async {
    var (podcast, episodes) = data;
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
    // final episodeImagesFolder = Directory(episodeImagesPath);
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

  /// Subscribes to a remote podcast. Not safe to call from the background.
  Future<(String, List<int>)?> subscribeRemotePodcast(
      String podcastId, List<int> episodeIds) async {
    (String, List<int>)? ret;
    if (_remotePodcastMap.containsKey(podcastId)) {
      final podcastRemote = _remotePodcastMap[podcastId]!;
      final episodesRemote =
          episodeIds.map((episodeId) => _episodeState[episodeId]).toList();
      if (podcastRemote.provider.contains('fireside')) {
        var data = FiresideData(podcastId,
            podcastRemote.webpage); // TODO: Move this into the isolate
        try {
          await data.fatchData();
        } catch (e) {
          developer.log(e.toString(), name: 'Fatch fireside data error');
        }
      }
      var (podcastLocal, episodesLocal) =
          await Isolater(_persistFeed).run((podcastRemote, episodesRemote));
      await _dbHelper.savePodcastLocal(podcastLocal);
      await _dbHelper.saveNewPodcastEpisodes(episodesLocal);
      await addPodcastToGroup(podcastId: podcastId, groupId: homeGroupId);

      await cachePodcast(podcastId);
      final newEpisodeIds =
          await _episodeState.getEpisodes(feedIds: [podcastId], limit: 100);
      ret = (podcastId, newEpisodeIds);

      removeRemotePodcast(podcastId);
      _episodeState.removeRemoteEpisodes(episodeIds);
    }
    return ret;
  }

  /// Subscribes to a podcast denoted by its url. Returns the podcast id.
  /// Safe to call from the background.
  Future<String?> subscribePodcastByUrl(String feedUrl) async {
    if (await _dbHelper.checkPodcast(feedUrl) == null) {
      var (podcast, episodes) = await Isolater(_fetchFeed).run(feedUrl);
      if (podcast != null) {
        try {
          podcast = await podcast.withColorFromImage();
        } catch (e) {
          return null;
        }
        episodes = episodes
            .map((e) => e.copyWith(primaryColor: podcast!.primaryColor))
            .toList();
        if (podcast.provider.contains('fireside')) {
          var data = FiresideData(
              podcast.id, podcast.webpage); // TODO: Move this into the isolate
          try {
            await data.fatchData();
          } catch (e) {
            developer.log(e.toString(), name: 'Fatch fireside data error');
          }
        }
        var (podcastLocal, episodesLocal) =
            await Isolater(_persistFeed).run((podcast, episodes));
        await _dbHelper.savePodcastLocal(podcastLocal);
        await _dbHelper.saveNewPodcastEpisodes(episodesLocal);
        await cachePodcast(podcast.id);
        await addPodcastToGroup(podcastId: podcast.id, groupId: homeGroupId);
        return podcast.id;
      }
    }
    return null;
  }

  /// Subscribes to podcasts stored in an opml file. Safe to call from the background.
  Future<void> subscribeOpml(String opml) async {
    opmlProgress.reset();
    var rssExp = RegExp(r'^(https?):\/\/(.*)');
    Map<String, List<OmplOutline>> data = PodcastsBackup.parseOPML(opml);
    List<(String, List<String>)> groups = [];
    for (var entry in data.entries) {
      final group = (entry.key, <String>[]);
      var list = entry.value.reversed;
      for (var rss in list) {
        var rssLink = rssExp.stringMatch(rss.xmlUrl!);
        if (rssLink != null) group.$2.add(rssLink);
      }
      groups.add(group);
    }
    final rssUrls = {for (var (_, urls) in groups) ...urls}.toList();
    opmlProgress.begin(rssUrls.length, groups.length);
    final futures = Queue<Future<String?>>();
    final ids = <String?>[];
    for (var rssUrl in rssUrls) {
      if (futures.length >= 8) ids.add(await futures.removeFirst());
      futures.add(Future(() async {
        final result = await subscribePodcastByUrl(rssUrl);
        opmlProgress.subscribe();
        return result;
      }));
    }
    ids.addAll(await Future.wait(futures));
    opmlProgress.beginAddingGroups();
    for (var (name, urls) in groups) {
      if (name == "Home") {
        opmlProgress.addGroup();
        continue;
      }
      final groupId = await addGroup(PodcastGroup.create(name: name));
      final indicies = urls.map((url) => rssUrls.indexOf(url));
      for (var i in indicies) {
        String? podcastId = ids[i];
        if (podcastId != null) {
          await addPodcastToGroup(podcastId: podcastId, groupId: groupId);
        }
      }
      opmlProgress.addGroup();
    }
    opmlProgress.finish();
  }

  /// Isolateable function that refetches a podcast and returns
  /// updated [PodcastBrief] and new [EpisodeBrief]s.
  static Future<(PodcastBrief, List<EpisodeBrief>)?> _syncFeed(
      (PodcastBrief, List<EpisodeBrief>) data) async {
    var (podcast, episodes) = data;
    final dir = await getApplicationDocumentsDirectory();
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(podcast.rssUrl,
          options: Options(responseType: ResponseType.bytes));
      if (response.data != null) {
        final digest = sha256.convert(response.data!);
        if (digest.toString() != podcast.rssHash) {
          final feed = RssFeed.parse(utf8.decode(response.data!));
          final items = feed.items ?? [];
          final enclosureUrls = episodes.map((e) => e.enclosureUrl).toSet();
          final newEnclosureUrls =
              items.map(urlFromRssItem).whereNot((url) => url == "").toSet();
          final onlyNew = newEnclosureUrls.difference(enclosureUrls);
          final onlyNewEpisodes = items
              .where((i) => onlyNew.contains(urlFromRssItem(i)))
              .map((item) => EpisodeBrief.fromRssItem(
                  item, podcast.id, podcast.title, -1, "", Colors.teal))
              .toList();
          onlyNewEpisodes.sortBy<num>((episode) => episode.pubDate);
          var podcastNew = podcast.withUpdatedInfo(
              feed,
              response.redirects.isEmpty
                  ? podcast.rssUrl
                  : response.realUri.toString(),
              digest.toString(),
              onlyNewEpisodes.length);
          if (podcastNew.imageUrl != podcast.imageUrl) {
            var imageResponse = await Dio().get<List<int>>(podcastNew.imageUrl,
                options: Options(
                    responseType: ResponseType.bytes,
                    receiveTimeout: Duration(seconds: 90)));
            var image =
                img.decodeImage(Uint8List.fromList(imageResponse.data!))!;
            img.Image? thumbnail = img.copyResize(image, width: 300);
            final imagePath = "${dir.path}/${podcast.id}.png";
            File(imagePath).writeAsBytesSync(img.encodePng(thumbnail));
            podcastNew = podcastNew.copyWith(imagePath: imagePath);
          }
          return (podcastNew, onlyNewEpisodes);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Syncs a podcast already in the database. Returns the number of new episodes.
  /// Safe to call from the background.
  Future<int?> syncPodcast(String podcastId) async {
    dev.log("${DateTime.now()} - Syncing podcast with id: $podcastId");
    final episodes = await _dbHelper.getEpisodes(feedIds: [podcastId]);
    await cachePodcast(podcastId);
    var result =
        await Isolater(_syncFeed).run((_podcastMap[podcastId]!, episodes));
    if (result != null) {
      var (podcast, newEpisodes) = result;
      try {
        podcast = await podcast.withColorFromImage();
      } catch (e) {
        return null;
      }
      newEpisodes = newEpisodes
          .map((e) => e.copyWith(primaryColor: podcast.primaryColor))
          .toList();
      if (_podcastMap[podcastId]!.primaryColor != podcast.primaryColor) {
        await _dbHelper.savePodcastProperties([podcastId],
            primaryColor: podcast.primaryColor);
      }
      _podcastMap[podcastId] = podcast;
      if (newEpisodes.isNotEmpty) {
        await _dbHelper.saveUpdatedPodcastEpisodes(newEpisodes);
      }
      final lastWorkStorage = KeyValueStorage(lastWorkKey);
      if (await lastWorkStorage.getInt() == 0) {
        await _dbHelper.unmarkNewOldEpisodes(podcastId);
      }
      if (podcast.autoDownload) {
        final savedEpisodes = await _dbHelper.getEpisodes(
            feedIds: [podcastId], filterNew: true, filterDownloaded: false);
        await startDownload(savedEpisodes);
      }
      var refreshstorage = KeyValueStorage(refreshdateKey);
      await refreshstorage.saveInt(DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
      return newEpisodes.length;
    }
    return null;
  }

  Future<int> syncAllPodcasts() async {
    var total = 0;
    final ids = await getPodcasts();
    Queue<Future<int?>> futures = Queue();
    for (var id in ids) {
      if (futures.length >= 8) total += await futures.removeFirst() ?? 0;
      futures.add(syncPodcast(id));
    }
    await Future.wait(futures);
    if (!kReleaseMode) {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File(path.join(dir.path, "syncLog.txt"));
      if (!logFile.existsSync()) logFile.createSync();
      final prevLog = logFile.readAsStringSync();
      final newLog =
          "$prevLog\n${DateTime.now()} - Synced all. Background: $background, new episodes: $total";
      logFile.writeAsStringSync(newLog);
    }
    return total;
  }

  /// Starts downloading the episodes. Safe to call from the background.
  Future<void> startDownload(List<EpisodeBrief> episodes) async {
    if (episodes.length < 100 && episodes.isNotEmpty) {
      final downloader =
          background ? DownloadState(background: true) : _downloadState;
      final lastWorkStorage = KeyValueStorage(lastWorkKey);
      await lastWorkStorage.saveInt(1);
      for (var episode in episodes) {
        await downloader.download(episode);
      }
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
      podcastChange = !podcastChange;
      notifyListeners();
    }
  }

  List<String> findPodcastGroups(String podcastId) {
    List<String> result = [];
    for (var group in _groupMap.values) {
      if (group.podcastIds.contains(podcastId)) {
        result.add(group.id);
      }
    }
    return result;
  }

  /// Add podcast into the group.
  Future<void> addPodcastToGroup(
      {required String podcastId, required String groupId}) async {
    _groupMap[groupId]!.addToGroup(podcastId);
    await _dbHelper.addPodcastToGroup(podcastId: podcastId, groupId: groupId);
    groupsChange = !groupsChange;
    notifyListeners();
  }

  /// Remove podcast from the group.
  Future<void> removePodcastFromGroup(
      {required String podcastId, required String groupId}) async {
    _groupMap[groupId]!.removeFromGroup(podcastId);
    await _dbHelper.removePodcastFromGroup(
        podcastId: podcastId, groupId: groupId);
    groupsChange = !groupsChange;
    notifyListeners();
  }

  /// Add new group. If the group already exists it is replaced.
  Future<String> addGroup(PodcastGroup podcastGroup) async {
    _groupMap[podcastGroup.id] = podcastGroup;
    await _dbHelper.addGroup(podcastGroup);
    groupsChange = !groupsChange;
    notifyListeners();
    return podcastGroup.id;
  }

  /// Remove group. Its podcasts are added to home group.
  Future<void> removeGroup(String groupId) async {
    final group = _groupMap[groupId]!;
    for (var podcastId in group.podcastIds) {
      _groupMap[homeGroupId]!.addToGroup(podcastId);
    }
    _groupMap.remove(groupId);
    await _dbHelper.removeGroup(groupId);
    groupsChange = !groupsChange;
    notifyListeners();
  }

  /// Modifies the group with the given callback.
  Future<void> modifyGroup(String groupId,
      FutureOr<PodcastGroup> Function(PodcastGroup group) modifier) async {
    final modifiedGroup = await modifier(_groupMap.remove(groupId)!);
    await addGroup(modifiedGroup);
  }
}
