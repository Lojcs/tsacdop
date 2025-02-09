import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../type/podcastlocal.dart';
import 'download_state.dart';

enum RefreshState { none, fetch, error, artwork }

class RefreshItem {
  String title;
  RefreshState refreshState;
  bool artwork;
  RefreshItem(this.title, this.refreshState, {this.artwork = false});
}

class RefreshWorker extends ChangeNotifier {
  // TODO: Why not workmanager?
  FlutterIsolate? refreshIsolate;
  late ReceivePort receivePort;
  late SendPort refreshSendPort;

  RefreshItem _currentRefreshItem = RefreshItem('', RefreshState.none);
  bool _complete = false;
  RefreshItem get currentRefreshItem => _currentRefreshItem;
  bool get complete => _complete;

  bool _created = false;
  bool get created => _created;

  Future<void> _createIsolate() async {
    receivePort = ReceivePort();
    refreshIsolate = await FlutterIsolate.spawn(
        refreshIsolateEntryPoint, receivePort.sendPort);
  }

  void _listen(List<String>? podcasts) {
    receivePort.distinct().listen((message) {
      if (message is SendPort) {
        refreshSendPort = message;
        refreshSendPort.send(podcasts);
      }
      if (message is List) {
        _currentRefreshItem =
            RefreshItem(message[0], RefreshState.values[message[1]]);
        notifyListeners();
      } else if (message is String && message == "done") {
        _currentRefreshItem = RefreshItem('', RefreshState.none);
        refreshIsolate?.kill();
        refreshIsolate = null;
        _created = false;
        _complete = true;
        notifyListeners();
        _complete = false;
      }
    });
  }

  Future<void> start(List<String>? podcasts) async {
    if (!_created) {
      if (podcasts!.isEmpty) {
        final refreshstorage = KeyValueStorage(refreshdateKey);
        await refreshstorage.saveInt(DateTime.now().millisecondsSinceEpoch);
      }
      _complete = false;
      await _createIsolate();
      _listen(podcasts);
      _created = true;
    }
  }

  void dispose() {
    refreshIsolate?.kill();
    refreshIsolate = null;
    super.dispose();
  }
}

@pragma('vm:entry-point')
Future<void> refreshIsolateEntryPoint(SendPort sendPort) async {
  var refreshReceivePort = ReceivePort();
  sendPort.send(refreshReceivePort.sendPort);
  var _dbHelper = DBHelper();

  Future<void> _refreshAll(List<String> podcasts) async {
    var podcastList;
    if (podcasts.isEmpty) {
      podcastList = await _dbHelper.getPodcastLocalAll(updateOnly: true);
    } else {
      podcastList = await _dbHelper.getPodcastLocal(podcasts, updateOnly: true);
    }
    await podcastSync(podcasts: podcastList);
    sendPort.send("done");
  }

  refreshReceivePort.distinct().listen((message) async {
    if (message is List<dynamic>) {
      await _refreshAll(message as List<String>);
    }
  });
}

Future<void> podcastSync({List<PodcastLocal>? podcasts}) async {
  final dbHelper = DBHelper();
  final podcastList;
  if (podcasts == null || podcasts.isEmpty) {
    podcastList = await dbHelper.getPodcastLocalAll(updateOnly: true);
  } else {
    podcastList = podcasts;
  }
  //lastWork is a indicator for if the app was opened since last backgroundwork
  //if the app wes opend,then the old marked new episode would be marked not new.
  final lastWorkStorage = KeyValueStorage(lastWorkKey);
  final lastWork = await lastWorkStorage.getInt();
  for (var podcastLocal in podcastList) {
    await dbHelper.updatePodcastRss(podcastLocal, keepNewMark: lastWork);
    developer.log('Refresh ${podcastLocal.title}');
  }
  await FlutterDownloader.initialize();
  final downloader = AutoDownloader();

  final autoDownloadStorage = KeyValueStorage(autoDownloadNetworkKey);
  final autoDownloadNetwork = await autoDownloadStorage.getInt();
  final result = await Connectivity().checkConnectivity();
  if (autoDownloadNetwork == 1 || result.contains(ConnectivityResult.wifi)) {
    final episodes = await dbHelper.getEpisodes(
        optionalFields: [EpisodeField.isDownloaded],
        filterNew: true,
        filterDownloaded: false,
        filterAutoDownload: true);
    // For safety
    if (episodes.length < 100 && episodes.length > 0) {
      downloader.bindBackgroundIsolate();
      await downloader.startTask(episodes);
      // This doesn't seem to work unless it's awaited.
    }
  }
  await lastWorkStorage.saveInt(1);
  if (podcasts == null || podcasts.isEmpty) {
    var refreshstorage = KeyValueStorage(refreshdateKey);
    await refreshstorage.saveInt(DateTime.now().millisecondsSinceEpoch);
  }
}
