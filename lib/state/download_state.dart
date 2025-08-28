import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../type/episode_task.dart';
import '../type/episodebrief.dart';
import '../util/extension_helper.dart';
import '../widgets/general_dialog.dart';
import 'episode_state.dart';

/// State object that manages episode downloads. [EpisodeState] aware.
class SuperDownloadState extends ChangeNotifier {
  final autoDownloadStorage = KeyValueStorage(autoDownloadNetworkKey);
  final DBHelper _dbHelper = DBHelper();
  late EpisodeState _episodeState;

  set context(BuildContext context) => _episodeState = context.episodeState;

  /// episode id : [EpisodeTask]
  final Map<int, SuperEpisodeTask> _ongoingEpisodeTasks = {};

  /// episode id : [EpisodeTask]
  final Map<int, SuperEpisodeTask> _otherEpisodeTasks = {};
  Completer downloadsComplete = Completer();
  final bool background;
  bool initDone = false;
  bool downloadOnMobile = false;

  late StreamSubscription<dynamic> _downloaderStream;
  late StreamSubscription<List<ConnectivityResult>> _connectivityStream;

  /// Returns [EpisodeTask] for episode with id [episodeId] if it exists.
  SuperEpisodeTask? operator [](int episodeId) =>
      _ongoingEpisodeTasks[episodeId] ?? _otherEpisodeTasks[episodeId];

  List<SuperEpisodeTask> get ongoingDownloads =>
      _ongoingEpisodeTasks.values.toList();
  List<SuperEpisodeTask> get otherDownloads =>
      _otherEpisodeTasks.values.toList();
  List<SuperEpisodeTask> get allDownloads =>
      [..._ongoingEpisodeTasks.values, ..._otherEpisodeTasks.values];

  /// Flips to indicate that the download lists have been modified.
  bool listsUpdate = false;

  /// Returns [EpisodeTask] for episode with id [taskId] if it exists.
  SuperEpisodeTask? _getTaskWithId(String taskId) {
    final ongoingTask =
        _ongoingEpisodeTasks.values.where((eTask) => eTask.taskId == taskId);
    if (ongoingTask.isNotEmpty) {
      return ongoingTask.first;
    } else {
      final otherTask =
          _otherEpisodeTasks.values.where((eTask) => eTask.taskId == taskId);
      if (otherTask.isNotEmpty) {
        return otherTask.first;
      } else {
        return null;
      }
    }
  }

  /// Adds task to the correct task list.
  void _addTask(SuperEpisodeTask eTask) {
    if (eTask.status == DownloadTaskStatus.running ||
        eTask.status == DownloadTaskStatus.enqueued) {
      _ongoingEpisodeTasks[eTask.episodeId] = eTask;
      _otherEpisodeTasks.remove(eTask.episodeId);
    } else {
      _otherEpisodeTasks[eTask.episodeId] = eTask;
      _ongoingEpisodeTasks.remove(eTask.episodeId);
    }
    listsUpdate = !listsUpdate;
    notifyListeners();
  }

  /// Removes and returns task from the correct task list based on either its episode or task id.
  SuperEpisodeTask? _removeTask({int? episodeId, String? taskId}) {
    SuperEpisodeTask? ret;
    if (episodeId != null) {
      ret = _ongoingEpisodeTasks.remove(episodeId) ??
          _otherEpisodeTasks.remove(episodeId);
    } else if (taskId != null) {
      final ongoingTask =
          _ongoingEpisodeTasks.values.where((eTask) => eTask.taskId == taskId);
      if (ongoingTask.isNotEmpty) {
        ret = _ongoingEpisodeTasks.remove(ongoingTask.first.episodeId);
      } else {
        final otherTask =
            _otherEpisodeTasks.values.where((eTask) => eTask.taskId == taskId);
        if (otherTask.isNotEmpty) {
          ret = _otherEpisodeTasks.remove(otherTask.first.episodeId);
        }
      }
    }
    listsUpdate = !listsUpdate;
    notifyListeners();
    return ret;
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    developer.log(
        'Flutter downloader task with id $id : (${DownloadTaskStatus.fromInt(status)}) $progress');
    final send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  /// Create download state. Foreground mode requires the assignment of [context]
  /// and updates [EpisodeState] with download status and notifies its listeners.
  /// Background mode updates the database directly and doesn't notify.
  /// [downloadsComplete] is signaled when all downloads are finished.
  SuperDownloadState({this.background = false}) {
    _starter();
  }

  /// Seperate function to keep async functions ordered.
  Future<void> _starter() async {
    if (!FlutterDownloader.initialized) {
      await FlutterDownloader.initialize();
      await _loadTasks();
      await _bindBackgroundIsolate();
      await _startNetworkListener();
      await _autoDelete();
      initDone = true;
      notifyListeners();
    }
  }

  @override
  void dispose() async {
    await _downloaderStream.cancel();
    await _connectivityStream.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (initDone) {
      if (_ongoingEpisodeTasks.isEmpty) {
        downloadOnMobile = false;
        downloadsComplete.complete();
      } else {
        downloadsComplete = Completer();
      }
      super.notifyListeners();
    }
  }

  /// Starts the downloads, prompting the user if on mobile data and
  /// auto download on mobile data setting is disabled.
  /// If accepted enables mobile data downloading until all downloads
  /// are finished or app restarts.
  Future<void> requestDownload(BuildContext context, List<int> episodeIds,
      {VoidCallback? onSuccess}) async {
    final s = context.s;
    final autoDownload = await autoDownloadStorage.getInt();
    final result = await Connectivity().checkConnectivity();
    final usingWifi = result.contains(ConnectivityResult.wifi);
    var downloadAllowed = autoDownload == 1 || usingWifi;
    if (!downloadAllowed && context.mounted) {
      await generalDialog(
        context,
        title: Text(s.cellularConfirm),
        content: Text(s.cellularConfirmDes),
        actions: <Widget>[
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(
              s.cancel,
              style: TextStyle(color: context.colorScheme.onSecondaryContainer),
            ),
          ),
          TextButton(
            onPressed: () {
              downloadOnMobile = true;
              Navigator.of(context).pop();
            },
            child: Text(
              s.confirm,
              style: TextStyle(color: context.error),
            ),
          )
        ],
      );
    }
    if (downloadAllowed || downloadOnMobile) {
      for (var episodeId in episodeIds) {
        await download(_episodeState[episodeId]);
      }
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: context.s.downloadStart,
          gravity: ToastGravity.BOTTOM,
        );
      }
      if (onSuccess != null) {
        onSuccess();
      }
    }
  }

  /// Starts the download of an episode.
  Future<void> download(EpisodeBrief episode,
      {bool showNotification = true}) async {
    if (!episode.isDownloaded && this[episode.id] == null) {
      final dir = await _getDownloadDirectory();
      final localPath =
          path.join(dir.path, episode.podcastTitle.replaceAll('/', ''));
      final saveDir = Directory(localPath);
      if (!saveDir.existsSync()) await saveDir.create();
      final dateFull = DateTime.now().toIso8601String();
      final cleanTitle = episode.title.replaceAll('/', '');
      final extension =
          episode.enclosureUrl.split('/').last.split('.').last.split('?').first;
      var fileName = '$cleanTitle - $dateFull.$extension';
      if (fileName.length > 100) fileName = fileName.substring(100);
      var taskId = await FlutterDownloader.enqueue(
        fileName: fileName,
        url: episode.enclosureUrl,
        savedDir: localPath,
        showNotification: showNotification,
        openFileFromNotification: false,
      );
      if (taskId != null) {
        _addTask(SuperEpisodeTask(episode.id, taskId));
      }
    }
  }

  /// Removes an episode's download.
  Future<void> removeDownload(int episodeId) async {
    final episodeTask = this[episodeId];
    if (episodeTask != null && episodeTask.pendingAction != true) {
      _removeTask(episodeId: episodeId);
      await FlutterDownloader.remove(
          taskId: episodeTask.taskId, shouldDeleteContent: true);
      if (background) {
        final episode = await _dbHelper.getEpisodes(episodeIds: [episodeId]);
        await _dbHelper.unsetDownloaded(episodeId,
            enclosureUrl: episode.first.enclosureUrl);
      } else {
        await _episodeState.cacheEpisodes([episodeId]);
        await _episodeState.unsetDownloaded(episodeId);
      }
    }
  }

  /// Retries an episode's ongoing download.
  Future<void> retryDownload(int episodeId) async {
    final episodeTask = this[episodeId];
    if (episodeTask != null && episodeTask.pendingAction != true) {
      episodeTask.pendingAction = true;
      var newTaskId = await FlutterDownloader.retry(taskId: episodeTask.taskId);
      await FlutterDownloader.remove(taskId: episodeTask.taskId);
      _addTask(episodeTask.copyWith(taskId: newTaskId));
    }
  }

  /// Pauses an episode's ongoing download.
  /// If running in the background, removes it from the task list as well.
  Future<void> pauseDownload(int episodeId) async {
    final episodeTask = this[episodeId];
    if (episodeTask != null && episodeTask.pendingAction != true) {
      episodeTask.pendingAction = true;
      if (episodeTask.progress >= 0) {
        await FlutterDownloader.pause(taskId: episodeTask.taskId);
      }
    }
  }

  /// Resumes an episode's ongoing download.
  Future<void> resumeDownload(int episodeId) async {
    final episodeTask = this[episodeId];
    if (episodeTask != null && episodeTask.pendingAction != true) {
      episodeTask.pendingAction = true;
      var newTaskId =
          await FlutterDownloader.resume(taskId: episodeTask.taskId);
      await FlutterDownloader.remove(taskId: episodeTask.taskId);
      _addTask(episodeTask.copyWith(taskId: newTaskId));
    }
  }

  /// Loads [DownloadTask]s from the downloader and saves them as [SuperEpisodeTask]s.
  /// Removes downloads for episodes no longer in the database.
  /// Unsets downloaded status for downloads externally deleted.
  /// Sets downloaded status for downloads that exist but aren't marked.
  Future<void> _loadTasks() async {
    var tasks = await FlutterDownloader.loadTasks();
    if (tasks != null && tasks.isNotEmpty) {
      final episodes = await _dbHelper.getEpisodes(
          episodeUrls: tasks.map((task) => task.url).toList());
      final episodeUrls = {for (var ep in episodes) ep.enclosureUrl: ep};
      final downloadedEpisodeUrls =
          episodes.where((ep) => ep.isDownloaded).toSet();
      for (var task in tasks) {
        final episode = episodeUrls[task.url];
        if (episode == null) {
          // Episode removed from the database
          FlutterDownloader.remove(
              taskId: task.taskId, shouldDeleteContent: true);
        } else {
          var episodeTask =
              SuperEpisodeTask(episode.id, task.taskId, status: task.status);
          if (task.status == DownloadTaskStatus.complete) {
            episodeTask = episodeTask.copyWith(progress: 100);
            final marked = downloadedEpisodeUrls.contains(episode);
            final exists =
                File(path.join(task.savedDir, task.filename)).existsSync();
            if (marked && !exists) {
              // Episode marked as downloaded but file isn't there.
              await removeDownload(episode.id);
            } else if (!marked && exists) {
              // Episode download is finished but it isn't marked as downloaded.
              _addTask(episodeTask);
              await _onDownloadFinished(episodeTask);
            } else {
              // Normal finished download.
              _addTask(episodeTask);
            }
          } else {
            // Normal ongoing download.
            _addTask(episodeTask);
          }
        }
      }
    }
  }

  /// Registers a port listener for flutter downloader's background isolate.
  Future<void> _bindBackgroundIsolate() async {
    final port = ReceivePort();
    final isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      await _bindBackgroundIsolate();
      return;
    }

    _downloaderStream = port.listen((dynamic data) async {
      String id = data[0];
      int status = data[1];
      int progress = data[2];
      final episodeTask = _getTaskWithId(id);
      if (episodeTask != null) {
        episodeTask.status = DownloadTaskStatus.fromInt(status);
        episodeTask.progress = progress;
        episodeTask.pendingAction = false;
        _addTask(episodeTask);

        switch (episodeTask.status) {
          case DownloadTaskStatus.undefined:
            break;
          case DownloadTaskStatus.enqueued || DownloadTaskStatus.running:
            break;
          case DownloadTaskStatus.complete:
            await _onDownloadFinished(episodeTask);
            break;
          case DownloadTaskStatus.failed ||
                DownloadTaskStatus.canceled ||
                DownloadTaskStatus.paused:
            break;
        }
        _checkConnectivityCallback(await Connectivity().checkConnectivity());
      }
    });
    await FlutterDownloader.registerCallback(downloadCallback);
  }

  /// Deletes old downloads.
  Future<void> _autoDelete() async {
    developer.log('Start to auto delete outdated episodes');
    final autoDeleteStorage = KeyValueStorage(autoDeleteKey);
    final deletePlayedStorage = KeyValueStorage(deleteAfterPlayedKey);
    var autoDelete = await autoDeleteStorage.getInt(defaultValue: 30);
    final deletePlayed = await deletePlayedStorage.getBool(defaultValue: false);
    if (autoDelete > 0 || deletePlayed) {
      var deadline = DateTime.now()
          .subtract(Duration(days: autoDelete))
          .millisecondsSinceEpoch;
      var episodes = await _dbHelper.getEpisodes(
          rangeParameters: [Sorter.downloadDate],
          rangeDelimiters: [(-1, deadline)],
          filterDownloaded: true);
      episodes.addAll(await _dbHelper.getEpisodes(
          filterPlayed: true, filterDownloaded: true));
      if (episodes.isNotEmpty) {
        for (var episode in episodes) {
          await removeDownload(episode.id);
        }
      }
    }
  }

  /// Listens to network changes to pause or unpause downloads.
  Future<void> _startNetworkListener() async {
    await _checkConnectivityCallback(await Connectivity().checkConnectivity());
    _connectivityStream = Connectivity()
        .onConnectivityChanged
        .distinct()
        .listen(_checkConnectivityCallback);
  }

  /// Pauses and unpauses downloads based on network state.
  Future<void> _checkConnectivityCallback(
      List<ConnectivityResult> connectivity) async {
    final autoDownload = await autoDownloadStorage.getInt();
    if (autoDownload == 0 && !connectivity.contains(ConnectivityResult.wifi)) {
      if (!downloadOnMobile) {
        for (var episodeTask in _ongoingEpisodeTasks.values) {
          pauseDownload(episodeTask.episodeId);
        }
      }
    } else {
      for (var episodeTask in _otherEpisodeTasks.values) {
        if (episodeTask.status == DownloadTaskStatus.paused) {
          resumeDownload(episodeTask.episodeId);
        }
      }
    }
  }

  /// Saves the finished download to the database.
  Future<void> _onDownloadFinished(SuperEpisodeTask episodeTask) async {
    final completeTask = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id = '${episodeTask.taskId}'");
    // I tried to combine these two but audioplayer only seems to work if the
    // file name is uri encoded and file only works if it is not.
    final fileUri =
        'file://${path.join(completeTask!.first.savedDir, Uri.encodeComponent(completeTask.first.filename!))}';
    final filePath =
        path.join(completeTask.first.savedDir, completeTask.first.filename!);
    var fileStat = await File(filePath).stat();
    var duration = await AudioPlayer().setUrl(fileUri);
    if (!background) {
      await _episodeState.cacheEpisodes([episodeTask.episodeId]);
      await _episodeState.setDownloaded(episodeTask.episodeId,
          mediaId: fileUri,
          taskId: episodeTask.taskId,
          size: fileStat.size,
          duration: duration?.inSeconds ?? 0);
    } else {
      await _dbHelper.setDownloaded(episodeTask.episodeId,
          mediaId: fileUri,
          taskId: episodeTask.taskId,
          size: fileStat.size,
          duration: duration?.inSeconds ?? 0);
    }
  }
}

Future<Directory> _getDownloadDirectory() async {
  final storage = KeyValueStorage(downloadPositionKey);
  final index = await storage.getInt();
  final externalDirs = await getExternalStorageDirectories();
  return externalDirs![index];
}
