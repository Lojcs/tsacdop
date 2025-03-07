import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../type/episode_task.dart';
import '../type/episodebrief.dart';
import 'episode_state.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  developer.log('Homepage callback task in $id  status ($status) $progress');
  final send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
  send.send([id, status, progress]);
}

@pragma('vm:entry-point')
void autoDownloadCallback(String id, int status, int progress) {
  developer
      .log('Autodownload callback task in $id  status ($status) $progress');
  final send = IsolateNameServer.lookupPortByName('auto_downloader_send_port')!;
  send.send([id, status, progress]);
}

//For background auto downlaod
class AutoDownloader {
  final DBHelper _dbHelper = DBHelper();
  final List<EpisodeTask> _episodeTasks = [];
  final Completer _completer = Completer();
  AutoDownloader() {
    FlutterDownloader.registerCallback(autoDownloadCallback);
  }

  bindBackgroundIsolate() {
    var port = ReceivePort();
    var isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'auto_downloader_send_port');
    if (!isSuccess) {
      IsolateNameServer.removePortNameMapping('auto_downloader_send_port');
      bindBackgroundIsolate();
      return;
    }
    port.listen((dynamic data) async {
      String id = data[0];
      int status = data[1];
      int progress = data[2];
      EpisodeTask episodeTask =
          _episodeTasks.firstWhere((task) => task.taskId == id);

      episodeTask.status = DownloadTaskStatus.fromInt(status);
      episodeTask.progress = progress;
      if (episodeTask.status == DownloadTaskStatus.complete) {
        await _saveMediaId(episodeTask);
      } else if (episodeTask.status == DownloadTaskStatus.failed ||
          episodeTask.status == DownloadTaskStatus.canceled) {
        _episodeTasks.removeWhere((element) =>
            element.episode!.enclosureUrl == episodeTask.episode!.enclosureUrl);
        if (_episodeTasks.isEmpty) _unbindBackgroundIsolate();
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('auto_downloader_send_port');
    _completer.complete();
  }

  Future _saveMediaId(EpisodeTask episodeTask) async {
    final completeTask = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id = '${episodeTask.taskId}'");
    final filePath =
        'file://${path.join(completeTask!.first.savedDir, Uri.encodeComponent(completeTask.first.filename!))}';
    final fileStat = await File(
            path.join(completeTask.first.savedDir, completeTask.first.filename))
        .stat();
    await _dbHelper.saveMediaId(episodeTask.episode!, filePath,
        taskId: episodeTask.taskId, size: fileStat.size);
    _episodeTasks.removeWhere((element) =>
        element.episode!.enclosureUrl == episodeTask.episode!.enclosureUrl);
    if (_episodeTasks.isEmpty) _unbindBackgroundIsolate();
  }

  Future startTask(List<EpisodeBrief> episodes,
      {bool showNotification = false}) async {
    for (var episode in episodes) {
      await taskStarter(episode, _episodeTasks,
          showNotification: showNotification);
    }
    await _completer.future;
    return;
  }
}

//For download episode inside app
class DownloadState extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  late final EpisodeState _episodeState;
  List<EpisodeTask> _episodeTasks = [];
  List<EpisodeTask> get episodeTasks => _episodeTasks;

  /// Flips to indicate a download has finished.
  bool downloadFinished = false;

  DownloadState(BuildContext context) {
    _episodeState = Provider.of<EpisodeState>(context, listen: false);
    _autoDelete();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void addListener(VoidCallback listener) async {
    _loadTasks();
    super.addListener(listener);
  }

  Future<void> _loadTasks() async {
    _episodeTasks = [];
    var tasks = await FlutterDownloader.loadTasks();
    if (tasks != null && tasks.isNotEmpty) {
      for (var task in tasks) {
        EpisodeBrief? episode;
        List<EpisodeBrief> episodes = await _dbHelper.getEpisodes(episodeUrls: [
          task.url
        ], optionalFields: [
          EpisodeField.isDownloaded,
          EpisodeField.mediaId,
          EpisodeField.isNew,
          EpisodeField.skipSecondsStart,
          EpisodeField.skipSecondsEnd,
          EpisodeField.episodeImage,
          EpisodeField.podcastImage,
          EpisodeField.chapterLink
        ]);
        if (episodes.isEmpty)
          episode = null;
        else
          episode = episodes[0];
        if (episode == null) {
          await FlutterDownloader.remove(
              taskId: task.taskId, shouldDeleteContent: true);
        } else {
          if (task.status == DownloadTaskStatus.complete) {
            var exist =
                await File(path.join(task.savedDir, task.filename)).exists();
            if (!exist) {
              await FlutterDownloader.remove(
                  taskId: task.taskId, shouldDeleteContent: true);
              await _dbHelper.saveMediaId(episode, episode.enclosureUrl,
                  episodeState: _episodeState);
            } else {
              var filePath =
                  'file://${path.join(task.savedDir, Uri.encodeComponent(task.filename!))}';
              if (episode.enclosureUrl == episode.mediaId) {
                var fileStat =
                    await File(path.join(task.savedDir, task.filename)).stat();
                await _dbHelper.saveMediaId(episode, filePath,
                    episodeState: _episodeState,
                    taskId: task.taskId,
                    size: fileStat.size);
              }
              _episodeTasks.add(EpisodeTask(
                  episode.copyWith(mediaId: filePath, isDownloaded: true),
                  task.taskId,
                  progress: task.progress,
                  status: task.status));
            }
          } else {
            _episodeTasks.add(EpisodeTask(episode, task.taskId,
                progress: task.progress, status: task.status));
          }
        }
      }
    }
    notifyListeners();
  }

  void _bindBackgroundIsolate() {
    final port = ReceivePort();
    final isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }

    port.listen((dynamic data) {
      String id = data[0];
      int status = data[1];
      int progress = data[2];

      for (var episodeTask in _episodeTasks) {
        if (episodeTask.taskId == id) {
          episodeTask.status = DownloadTaskStatus.fromInt(status);
          episodeTask.progress = progress;
          if (episodeTask.status == DownloadTaskStatus.complete) {
            _saveMediaId(episodeTask).then((value) {
              downloadFinished = !downloadFinished;
              notifyListeners();
            });
          } else {
            notifyListeners();
          }
        }
      }
    });
  }

  Future _saveMediaId(EpisodeTask episodeTask) async {
    episodeTask.status = DownloadTaskStatus.complete;
    final completeTask = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id = '${episodeTask.taskId}'");
    final filePath =
        'file://${path.join(completeTask!.first.savedDir, Uri.encodeComponent(completeTask.first.filename!))}';
    final fileStat = await File(
            path.join(completeTask.first.savedDir, completeTask.first.filename))
        .stat();
    await _dbHelper.saveMediaId(episodeTask.episode!, filePath,
        episodeState: _episodeState,
        taskId: episodeTask.taskId,
        size: fileStat.size);
    EpisodeBrief episode =
        await episodeTask.episode!.copyWithFromDB(newFields: [
      EpisodeField.isDownloaded,
      EpisodeField.mediaId,
      EpisodeField.isNew,
    ]);
    _removeTask(episodeTask.episode);
    _episodeTasks.add(EpisodeTask(episode, episodeTask.taskId,
        progress: 100, status: DownloadTaskStatus.complete));
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  EpisodeTask episodeToTask(EpisodeBrief? episode) {
    return _episodeTasks.firstWhere(
        (task) => task.episode!.enclosureUrl == episode!.enclosureUrl,
        orElse: () {
      return EpisodeTask(
        episode,
        '',
      );
    });
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  Future startTask(EpisodeBrief episode, {bool showNotification = true}) async {
    episode =
        await episode.copyWithFromDB(newFields: [EpisodeField.isDownloaded]);

    taskStarter(episode, _episodeTasks, showNotification: showNotification);

    notifyListeners();
  }

  Future pauseTask(EpisodeBrief? episode) async {
    var task = episodeToTask(episode);
    if (task.progress! > 0) {
      await FlutterDownloader.pause(taskId: task.taskId!);
    }
    notifyListeners();
  }

  Future resumeTask(EpisodeBrief episode) async {
    var task = episodeToTask(episode);
    var newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
    await FlutterDownloader.remove(taskId: task.taskId!);
    var index = _episodeTasks.indexOf(task);
    _episodeTasks[index] = task.copyWith(taskId: newTaskId);
    notifyListeners();
  }

  Future retryTask(EpisodeBrief episode) async {
    var task = episodeToTask(episode);
    var newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
    await FlutterDownloader.remove(taskId: task.taskId!);
    var index = _episodeTasks.indexOf(task);
    _episodeTasks[index] = task.copyWith(taskId: newTaskId);
    notifyListeners();
  }

  Future removeTask(EpisodeBrief episode) async {
    var task = episodeToTask(episode);
    await FlutterDownloader.remove(
        taskId: task.taskId!, shouldDeleteContent: false);
  }

  Future<void> delTask(EpisodeBrief episode) async {
    var task = episodeToTask(episode);
    await FlutterDownloader.remove(
        taskId: task.taskId!, shouldDeleteContent: true);
    await _dbHelper.saveMediaId(episode, episode.enclosureUrl,
        episodeState: _episodeState);

    for (var episodeTask in _episodeTasks) {
      if (episodeTask.taskId == task.taskId) {
        episodeTask.status = DownloadTaskStatus.undefined;
      }
      notifyListeners();
    }
    _removeTask(episode);
  }

  void _removeTask(EpisodeBrief? episode) {
    _episodeTasks.removeWhere((element) => element.episode == episode);
    notifyListeners();
  }

  Future<void> _autoDelete() async {
    developer.log('Start auto delete outdated episodes');
    final autoDeleteStorage = KeyValueStorage(autoDeleteKey);
    final deletePlayedStorage = KeyValueStorage(deleteAfterPlayedKey);
    final autoDelete = await autoDeleteStorage.getInt();
    final deletePlayed = await deletePlayedStorage.getBool(defaultValue: false);
    if (autoDelete == 0) {
      await autoDeleteStorage.saveInt(30);
    } else if (autoDelete > 0 && deletePlayed) {
      var deadline = DateTime.now()
          .subtract(Duration(days: autoDelete))
          .millisecondsSinceEpoch;
      var episodes = await _dbHelper.getEpisodes(
          rangeParameters: [Sorter.downloadDate],
          rangeDelimiters: [Tuple2(-1, deadline)],
          filterDownloaded: true);
      episodes.addAll(await _dbHelper.getEpisodes(
          filterPlayed: true, filterDownloaded: true));
      if (episodes.isNotEmpty) {
        for (var episode in episodes) {
          await delTask(episode);
        }
      }
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query:
              'SELECT * FROM task WHERE time_created < $deadline AND status = 3');
      for (var task in tasks ?? []) {
        FlutterDownloader.remove(
            taskId: task.taskId, shouldDeleteContent: true);
      }
    }
  }
}

Future<Directory> _getDownloadDirectory() async {
  final storage = KeyValueStorage(downloadPositionKey);
  final index = await storage.getInt();
  final externalDirs = await getExternalStorageDirectories();
  return externalDirs![index];
}

Future<void> taskStarter(EpisodeBrief episode, List<EpisodeTask> episodeTasks,
    {bool showNotification = false}) async {
  if (!episode.isDownloaded! &&
      !episodeTasks.any((task) => task.episode == episode)) {
    final dir = await _getDownloadDirectory();
    var localPath =
        path.join(dir.path, episode.podcastTitle.replaceAll('/', ''));
    final saveDir = Directory(localPath);
    var hasExisted = await saveDir.exists();
    if (!hasExisted) {
      await saveDir.create();
    }
    var now = DateTime.now();
    String dateFull = now.toIso8601String();
    var fileName =
        '${episode.title.replaceAll('/', '')},$dateFull,${episode.enclosureUrl.split('/').last.split('.').last.split('?').first}';
    if (fileName.length > 100) {
      fileName = fileName.substring(fileName.length - 100);
    }
    var taskId = await FlutterDownloader.enqueue(
      fileName: fileName,
      url: episode.enclosureUrl,
      savedDir: localPath,
      showNotification: showNotification,
      openFileFromNotification: false,
    );
    episodeTasks.add(EpisodeTask(episode, taskId));
  }
}
