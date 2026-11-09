import 'dart:async';
import 'dart:developer' as developer;
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/misc/ListedMap.dart';
import '../../../core/service/database.dart';
import '../../episode/model/episode_brief.dart';
import '../../../core/extension/extension_helper.dart';
import '../../../core/misc/general_dialog.dart';
import '../../episode/state/episode_state.dart';
import '../../settings/state/setting_state.dart';
import 'episode_task.dart';

/// State object that manages episode downloads. [EpisodeState] aware.
/// Uses [FileDownloader] database tracking for only ongoing downloads.
class DownloadState extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  late SettingState _settingState = SettingState();
  late EpisodeState _episodeState;
  bool background = true;

  set context(BuildContext context) {
    _settingState = context.settingState;
    _episodeState = context.episodeState;
    background = false;
  }

  /// Downloader instance.
  final FileDownloader downloader = FileDownloader();

  /// Tasks that are [TaskStatus.isNotFinalState]
  /// episode id : [EpisodeTask]
  final ListedMap<int, EpisodeTask> _ongoingEpisodeTasks = .blank();

  int get taskCount => _ongoingEpisodeTasks.length;
  bool taskExists(int episodeId) => _ongoingEpisodeTasks.containsKey(episodeId);
  int getEpisodeIdAt(int index) => _ongoingEpisodeTasks.elementAt(index);
  EpisodeTask? operator [](int episodeId) => _ongoingEpisodeTasks[episodeId];

  late StreamSubscription<TaskUpdate> _taskUpdateSubscription;
  late StreamSubscription<TaskRecord> _taskRecordSubscription;
  late StreamSubscription<List<ConnectivityResult>> _connectivityStream;

  /// Removes and cancels an ongoing task.
  Future<void> _removeTask(int episodeId) async {
    _ongoingEpisodeTasks.remove(episodeId);
    final taskId = episodeId.toString();
    await downloader.cancelTaskWithId(taskId);
    await downloader.database.deleteRecordWithId(taskId);
    notifyListeners();
  }

  /// Create download state. Foreground mode requires the assignment of [context]
  /// and updates [EpisodeState] with download status and notifies its listeners.
  /// Background mode updates the database directly and doesn't notify.
  /// [downloadsComplete] is signaled when all downloads are finished.
  ///
  /// Wait for [ready] before using.
  new() {
    ready = _init();
  }

  /// Seperate function to keep async functions ordered.
  Future<void> _init() async {
    await downloader.ready;
    _listenToUpdates();
    downloader.configureNotification(
      running: TaskNotification("Downloading episode", "{displayName}"),
      progressBar: true,
    );
    await downloader.start();
    await _settingState.ready;
    await _startNetworkListener();
    await autoDelete();
    notifyListeners();
  }

  void _listenToUpdates() {
    _taskUpdateSubscription = downloader.updates.listen(_taskUpdateListener);
    _taskRecordSubscription = downloader.database.updates.listen(
      _taskRecordListener,
    );
  }

  Future<void> _taskUpdateListener(TaskUpdate update) async {
    final episodeId = int.parse(update.task.taskId);
    final EpisodeTask task;
    if (_ongoingEpisodeTasks.containsKey(episodeId)) {
      task = _ongoingEpisodeTasks[episodeId]!;
    } else {
      task = .fromDownloadTask(update.task as DownloadTask);
    }
    switch (update) {
      case TaskStatusUpdate _:
        _ongoingEpisodeTasks[episodeId] = task.copyWith(
          status: update,
          pendingAction: false,
        );
      case TaskProgressUpdate _:
        _ongoingEpisodeTasks[episodeId] = task.copyWith(progress: update);
    }
    notifyListeners();
  }

  Future<void> _taskRecordListener(TaskRecord record) async {
    if (record.status == .complete) {
      await _onDownloadFinished(record.task as DownloadTask);
    } else {
      if (!background) {
        await _episodeState.cacheEpisodes([int.parse(record.taskId)]);
      }
    }
  }

  /// Saves the finished download to the database.
  Future<void> _onDownloadFinished(DownloadTask downloadTask) async {
    final episodeId = int.parse(downloadTask.taskId);
    await _removeTask(episodeId);
    // I tried to combine these two but audioplayer only seems to work if the
    // file name is uri encoded and file only works if it is not.
    final filePath = await downloadTask.filePath();
    var fileStat = await File(filePath).stat();
    final fileUri = Uri.file(filePath).toString();
    var duration = await AudioPlayer().setUrl(fileUri);
    if (!background) {
      await _episodeState.cacheEpisodes([episodeId]);
      await _episodeState.setDownloaded(
        episodeId,
        mediaId: fileUri,
        size: fileStat.size,
        duration: duration?.inSeconds ?? 0,
      );
    } else {
      await _dbHelper.setDownloaded(
        episodeId,
        mediaId: fileUri,
        size: fileStat.size,
        duration: duration?.inSeconds ?? 0,
      );
    }
  }

  late Future<void> ready;

  @override
  void dispose() async {
    await _taskUpdateSubscription.cancel();
    await _taskRecordSubscription.cancel();
    await _connectivityStream.cancel();
    super.dispose();
  }

  /// Starts the downloads, prompting the user if on mobile data and
  /// auto download on mobile data setting is disabled.
  /// If accepted enables mobile data downloading until all downloads
  /// are finished or app restarts.
  Future<bool> manualDownload(
    BuildContext context,
    List<int> episodeIds,
  ) async {
    final s = context.s;
    final forbidden = await _isConnectionForbidden();
    var showWarning = _settingState.downloadAskOnForbidden.get() && forbidden;
    bool downloadWarningApproved = false;
    if (showWarning && context.mounted) {
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
              downloadWarningApproved = true;
              Navigator.of(context).pop();
            },
            child: Text(s.confirm, style: TextStyle(color: context.error)),
          ),
        ],
      );
    }
    if (downloadWarningApproved || !showWarning) {
      for (var episodeId in episodeIds) {
        await download(_episodeState[episodeId]);
      }
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: context.s.downloadStart,
          gravity: ToastGravity.BOTTOM,
        );
      }
      return true;
    } else {
      return false;
    }
  }

  /// Starts download according to auto download preferences.
  Future<void> autoDownload(EpisodeBrief episode) async {
    if (_settingState.autoDownload.get()) {
      await download(episode);
    }
    final forbidden = await _isConnectionForbidden();
    var pause = !_settingState.autoDownloadOnForbidden.get() && forbidden;
    if (pause) {
      await Future.delayed(Duration(seconds: 1));
      await pauseDownload(episode.id);
    }
  }

  /// Starts the download of an episode.
  Future<void> download(EpisodeBrief episode) async {
    if (!episode.isDownloaded &&
        !_ongoingEpisodeTasks.containsKey(episode.id)) {
      final dir = _settingState.downloadStoragePath.get();
      final episodeTask = await EpisodeTask.newTask(episode, dir);
      final started = await downloader.enqueue(episodeTask.downloadTask);
      if (started) {
        _ongoingEpisodeTasks[episode.id] = episodeTask;
      }
    }
  }

  Future<void> removeDownload(int episodeId) async {
    if (_ongoingEpisodeTasks.containsKey(episodeId)) {
      await removeOngoingDownload(episodeId);
    } else {
      await removeCompletedDownload(episodeId);
    }
  }

  /// Cancels and removes a currently ongoing download.
  Future<void> removeOngoingDownload(int episodeId) async {
    if (_ongoingEpisodeTasks.containsKey(episodeId)) {
      final task = _ongoingEpisodeTasks[episodeId]!;
      if (task.pendingAction != true) {
        await _removeTask(episodeId);
      }
    }
  }

  /// Removes a completed download and unmarks the episode.
  Future<void> removeCompletedDownload(int episodeId) async {
    final EpisodeBrief episode;
    if (background) {
      episode = (await _dbHelper.getEpisodes(episodeIds: [episodeId])).first;
      await _dbHelper.unsetDownloaded(
        episodeId,
        enclosureUrl: episode.enclosureUrl,
      );
    } else {
      await _episodeState.cacheEpisodes([episodeId]);
      episode = _episodeState[episodeId];
      await _episodeState.unsetDownloaded(episodeId);
    }
    final file = Uri.parse(episode.mediaId).toFile();
    if (await file.exists()) await file.delete();
  }

  /// Removes a download missing from the database.
  Future<void> removeDanglingDownload(String uri) async {
    final file = Uri.parse(uri).toFile();
    if (await file.exists()) await file.delete();
  }

  /// Returns the uris of all downloaded files.
  Future<Set<String>> getAllFileUris() async =>
      (await Future.wait(
            (await getExternalStorageDirectories())!.map(
              (dir) => dir.list().toList(),
            ),
          ))
          .expand((e) => e)
          .whereType<File>()
          .map((file) => Uri.file(file.path).toString())
          .toSet();

  /// Retries an episode's failed download.
  Future<void> retryDownload(int episodeId) async {
    if (_ongoingEpisodeTasks.containsKey(episodeId)) {
      final task = _ongoingEpisodeTasks[episodeId]!;
      if (task.pendingAction != true) {
        await _removeTask(episodeId);
        _ongoingEpisodeTasks[episodeId] = task.copyWith(pendingAction: true);
        await downloader.enqueue(task.downloadTask);
      }
    }
  }

  /// Pauses an episode's ongoing download.
  Future<void> pauseDownload(int episodeId) async {
    if (_ongoingEpisodeTasks.containsKey(episodeId)) {
      final task = _ongoingEpisodeTasks[episodeId]!;
      if (task.pendingAction != true) {
        _ongoingEpisodeTasks[episodeId] = task.copyWith(pendingAction: true);
        await downloader.pause(task.downloadTask);
      }
    }
  }

  /// Resumes an episode's ongoing download.
  Future<void> resumeDownload(int episodeId) async {
    if (_ongoingEpisodeTasks.containsKey(episodeId)) {
      final task = _ongoingEpisodeTasks[episodeId]!;
      if (task.pendingAction != true) {
        _ongoingEpisodeTasks[episodeId] = task.copyWith(pendingAction: true);
        await downloader.resume(task.downloadTask);
      }
    }
  }

  /// Deletes old downloads.
  /// Uses dbHelper directly as caching is done during removal if needed.
  Future<void> autoDelete() async {
    developer.log("Start to auto delete outdated episodes");
    var deleteAfterTime = _settingState.autoDeleteAfterTime.get();
    final deletePlayed = _settingState.autoDeleteAfterPlayed.get();
    final deleteIfLargerThan = _settingState.autoDeleteOldestIfTotalAbove.get();
    Set<EpisodeBrief> episodes = {};
    if (deleteAfterTime > Duration.zero) {
      var deadline = DateTime.now()
          .subtract(deleteAfterTime)
          .millisecondsSinceEpoch;
      episodes.addAll(
        await _dbHelper.getEpisodes(
          rangeParameters: [Sorter.downloadDate],
          rangeDelimiters: [(-1, deadline)],
          filterDownloaded: true,
        ),
      );
    }
    if (deletePlayed) {
      episodes.addAll(
        await _dbHelper.getEpisodes(filterPlayed: true, filterDownloaded: true),
      );
    }
    if (deleteIfLargerThan != 0) {
      final dir = _settingState.downloadStoragePath.get();
      final size = await Directory(dir).getSize();
      var excess = size - deleteIfLargerThan;
      if (excess > 0) {
        final oldDownloads = await _dbHelper.getEpisodes(
          filterDownloaded: true,
          sortBy: .downloadDate,
          sortOrder: .asc,
        );
        for (var download in oldDownloads) {
          episodes.add(download);
          excess -= download.enclosureSize;
          if (excess <= 0) break;
        }
      }
    }
    if (episodes.isNotEmpty) {
      for (var episode in episodes) {
        await removeOngoingDownload(episode.id);
      }
    }
    developer.log("Auto deleted ${episodes.length} episodes");
  }

  /// Listens to network changes to pause or unpause downloads.
  Future<void> _startNetworkListener() async {
    await _checkConnectivityCallback(await Connectivity().checkConnectivity());
    _connectivityStream = Connectivity().onConnectivityChanged
        .distinct()
        .listen(_checkConnectivityCallback);
  }

  Future<bool> _isConnectionForbidden([
    List<ConnectivityResult>? connectivity,
  ]) async {
    connectivity ??= await Connectivity().checkConnectivity();
    final forbiddenSet = _settingState.forbiddenDownloadConnections.get();
    return connectivity.any((c) => forbiddenSet.contains(c));
  }

  /// Pauses and unpauses downloads based on network state.
  Future<void> _checkConnectivityCallback(
    List<ConnectivityResult> connectivity,
  ) async {
    final pauseAndResume = _settingState.pauseDownloadOnForbiddenConnected
        .get();
    if (pauseAndResume) {
      final forbidden = await _isConnectionForbidden(connectivity);
      if (forbidden) {
        await downloader.pauseAll();
      } else {
        await downloader.resumeAll();
      }
    }
  }
}
