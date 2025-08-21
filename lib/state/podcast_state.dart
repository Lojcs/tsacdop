import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webfeed/webfeed.dart';
import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../service/opml_build.dart';
import '../type/episodebrief.dart';
import 'package:image/image.dart' as img;
import '../type/fireside_data.dart';
import '../type/podcastbrief.dart';
import '../type/podcastgroup.dart';
import '../util/extension_helper.dart';
import 'download_state.dart';
import 'episode_state.dart';
import 'podcast_group.dart';

const deletedPodcastId = "46e48103-06c7-4fe1-a0b1-68aa7205b7f0";

/// Global class to manage [PodcastBrief] field updates.
class PodcastState extends ChangeNotifier {
  final KeyValueStorage _groupStorage = KeyValueStorage(groupsKey);
  final Directory documents;
  PodcastState(this.documents) {
    ready = _loadGroups();
  }

  /// Load groups
  Future<void> _loadGroups() async {
    final groups = await _groupStorage.getGroups();
    for (var group in groups) {
      _groupMap[group.id] = group;
    }
  }

  late Future<void> ready;

  final DBHelper _dbHelper = DBHelper();
  BuildContext? _nullableContext;
  set context(BuildContext context) => _nullableContext = context;
  bool get background => _nullableContext == null;
  BuildContext get _context => _nullableContext!;

  /// podcast id : PodcastBrief
  final Map<String, PodcastBrief> _podcastMap = {};

  /// podcast id : PodcastBrief
  final Map<String, PodcastBrief> _remotePodcastMap = {};

  /// Set of deleted podcast ids.
  final Set<String> deletedIds = {};

  late final PodcastBrief deletedPodcast = PodcastBrief.localFolder(
      _context.s, documents,
      id: deletedPodcastId,
      title: _context.s.deleted,
      description: _context.s.deletedPodcastDesc);

  /// Convenience operator getting the [PodcastBrief] of a podcast.
  PodcastBrief operator [](String id) =>
      _podcastMap[id] ??
      _remotePodcastMap[id] ??
      (deletedIds.contains(id) ? deletedPodcast : _podcastMap[id]!);

  /// Flips to indicate some podcast property changed.
  bool podcastChange = false; // TODO: This doesn't update on sync'n stuff

  /// group id : PodcastGroup
  final Map<String, SuperPodcastGroup> _groupMap = {};

  /// Gets the list of groupIds
  List<String> get groupIds => _groupMap.keys.toList();

  /// Gets the group with id [id]
  SuperPodcastGroup getGroupById(String id) => _groupMap[id]!;

  /// Flips to indicate some group property changed.
  bool groupsChange = false;

  /// Increments to indicate that sync happened.
  int syncGeneneration = 0;

  /// Ids changed in last update
  Set<String> changedIds = {};

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

  /// Unsubscibes from podcast and deletes local data. Safe to call from the background.
  Future<void> unsubscribePodcast(String podcastId) async {
    final eState = background ? EpisodeState() : _context.episodeState;

    for (var groupId in _groupMap.keys) {
      _groupMap[groupId]!.removeFromGroup(podcastId);
    }
    await _saveGroup();

    final podcastEpisodeIds = await eState.getEpisodes(feedIds: [podcastId]);
    eState.deleteEpisodes(podcastEpisodeIds, deleteFromDatabase: false);

    await cachePodcasts([podcastId]);
    final podcast = _podcastMap[podcastId]!;
    // final dir = await getApplicationDocumentsDirectory();
    // final episodeImagesPath = "${dir.path}/${podcast.id}";
    // await Directory(episodeImagesPath).delete(recursive: true);
    await File(podcast.imagePath).delete();
    if (_podcastMap.remove(podcastId) != null) deletedIds.add(podcastId);
    await _dbHelper.delPodcast(podcastId);
  }

  /// Isolateable function that fetches a podcast based on its rss feed url.
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
  /// Episodes kept only as temp ids, [EpisodeBrief]s are kept in [EpisodeState]
  Future<(String, List<int>)?> addPodcastByUrl(String feedUrl) async {
    (String, List<int>)? ret;
    switch (await _dbHelper.checkPodcast(feedUrl)) {
      case String id:
        await cachePodcasts([id]);
        if (_context.mounted) {
          final episodeIds = await _context.episodeState
              .getEpisodes(feedIds: [id], limit: 100);
          ret = (id, episodeIds);
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
            _remotePodcastMap[podcast.id] = podcast;
            ret = (podcast.id, episodeIds);
          }
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

  /// Subscribes to a remote podcast.
  Future<void> subscribeRemotePodcast(
      String podcastId, List<int> episodeIds) async {
    if (_remotePodcastMap.containsKey(podcastId)) {
      final eState = _context.episodeState;
      final podcastRemote = _remotePodcastMap[podcastId]!;
      final episodesRemote = episodeIds
          .map((episodeId) => _context.episodeState[episodeId])
          .toList();
      if (podcastRemote.provider.contains('fireside')) {
        var data = FiresideData(podcastId,
            podcastRemote.webpage); // TODO: Move this into the isolate
        try {
          await data.fatchData();
        } catch (e) {
          developer.log(e.toString(), name: 'Fatch fireside data error');
        }
      }
      removeRemotePodcast(podcastId);
      eState.removeRemoteEpisodes(episodeIds);
      var (podcast, episodes) =
          await Isolate.run(() => _persistFeed(podcastRemote, episodesRemote));
      await _dbHelper.savePodcastLocal(podcastRemote);
      await _dbHelper.saveNewPodcastEpisodes(episodes);
      _groupMap[homeGroupId]!.addToGroup(podcastId);
      await _saveGroup();
    }
  }

  /// Subscribes to a podcast denoted by its url. Returns the podcast id.
  /// Safe to call from the background.
  Future<String?> subscribePodcastByUrl(String feedUrl) async {
    if (await _dbHelper.checkPodcast(feedUrl) == null) {
      var (podcast, episodes) = await Isolate.run(() => _fetchFeed(feedUrl));
      if (podcast != null) {
        podcast = await podcast.withColorFromImage();
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
            await Isolate.run(() => _persistFeed(podcast!, episodes));
        await _dbHelper.savePodcastLocal(podcast);
        await _dbHelper.saveNewPodcastEpisodes(episodesLocal);
        _groupMap[homeGroupId]!.addToGroup(podcast.id);
        await _saveGroup();
        return podcast.id;
      }
    }
    return null;
  }

  /// Subscribes to podcasts stored in an opml file. Safe to call from the background.
  Future<void> subscribeOpml(String opml) async {
    var rssExp = RegExp(r'^(https?):\/\/(.*)');
    Map<String, List<OmplOutline>> data = PodcastsBackup.parseOPML(opml);
    List<Future<String?>> futures = [];
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
    for (var rssUrl in rssUrls) {
      futures.add(subscribePodcastByUrl(rssUrl));
    }
    final ids = await Future.wait(futures);
    for (var (name, urls) in groups) {
      final groupId = addGroup(SuperPodcastGroup.create(name: name));
      final indicies = urls.map((url) => rssUrls.indexOf(url));
      for (var i in indicies) {
        String? podcastId = ids[i];
        if (podcastId != null) {
          addPodcastToGroup(podcastId: podcastId, groupId: groupId);
        }
      }
    }
  }

  /// Isolateable function that refetches a podcast and returns
  /// updated [PodcastBrief] and new [EpisodeBrief]s.
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

  /// Syncs a podcast already in the database. Returns the number of new episodes.
  /// Safe to call from the background.
  Future<int?> syncPodcast(String podcastId, {bool showToast = false}) async {
    if (_context.mounted && showToast) {
      Fluttertoast.showToast(
        msg: _context.s.refreshStarted,
        gravity: ToastGravity.BOTTOM,
      );
    }
    final episodes = await _dbHelper.getEpisodes(feedIds: [podcastId]);
    await cachePodcasts([podcastId]);
    var result =
        await Isolate.run(() => _syncFeed(_podcastMap[podcastId]!, episodes));
    if (result != null) {
      final (podcast, episodes) = result;
      _podcastMap[podcastId] = podcast;
      _dbHelper.savePodcastLocal(podcast);
      await _dbHelper.saveUpdatedPodcastEpisodes(episodes);
      final lastWorkStorage = KeyValueStorage(lastWorkKey);
      if (await lastWorkStorage.getInt() == 0) {
        await _dbHelper.unmarkNewOldEpisodes(podcastId);
      }
      await startDownload(episodes);
      syncGeneneration++;
      var refreshstorage = KeyValueStorage(refreshdateKey);
      await refreshstorage.saveInt(DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
      if (_context.mounted && showToast) {
        Fluttertoast.showToast(
          msg: _context.s.refreshFinished,
          gravity: ToastGravity.BOTTOM,
        );
      }
      return episodes.length;
    }
    return null;
  }

  Future<int> syncAllPodcasts() async {
    if (_context.mounted) {
      Fluttertoast.showToast(
        msg: _context.s.refreshStarted,
        gravity: ToastGravity.BOTTOM,
      );
    }
    var total = 0;
    final ids = await getPodcasts();
    Queue<Future<int?>> futures = Queue();
    for (var id in ids) {
      if (futures.length >= 4) total += await futures.removeFirst() ?? 0;
      futures.add(syncPodcast(id));
    }
    if (_context.mounted) {
      Fluttertoast.showToast(
        msg: _context.s.refreshFinished,
        gravity: ToastGravity.BOTTOM,
      );
    }
    return total;
  }

  /// Starts downloading the episodes. Safe to call from the background.
  Future<void> startDownload(List<EpisodeBrief> episodes) async {
    if (episodes.length < 100 && episodes.isNotEmpty) {
      final downloader = background
          ? _context.downloadState
          : SuperDownloadState(background: true);
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
  void addPodcastToGroup({required String podcastId, required String groupId}) {
    _groupMap[groupId]!.addToGroup(podcastId);
  }

  /// Remove podcast from the group.
  void removePodcastFromGroup(
      {required String podcastId, required String groupId}) {
    _groupMap[groupId]!.removeFromGroup(podcastId);
  }

  /// Add new group. If the group already exists it is replaced.
  String addGroup(SuperPodcastGroup podcastGroup) {
    _groupMap[podcastGroup.id] = podcastGroup;
    _saveGroup();
    return podcastGroup.id;
  }

  /// Remove group. Its podcasts are added to home group.
  void removeGroup(String groupId) {
    final group = _groupMap[groupId]!;
    for (var podcastId in group.podcastIds) {
      _groupMap[homeGroupId]!.addToGroup(podcastId);
    }
    _groupMap.remove(groupId);
    _saveGroup();
  }

  /// Modifies the group with the given callback.
  Future<void> modifyGroup(
      String groupId,
      FutureOr<SuperPodcastGroup> Function(SuperPodcastGroup group)
          modifier) async {
    final modifiedGroup = await modifier(_groupMap.remove(groupId)!);
    addGroup(modifiedGroup);
  }

  Future<void> _saveGroup() async {
    await _groupStorage.saveGroup(_groupMap.values.toList());
    groupsChange = !groupsChange;
    notifyListeners();
  }
}
