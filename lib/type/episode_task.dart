import 'package:flutter_downloader/flutter_downloader.dart';

/// Class that holds information about an episode download task.
class SuperEpisodeTask {
  /// [FlutterDownloader] download task id.
  final String taskId;

  /// Database episode id.
  final int episodeId;

  /// Download progress.
  int progress;

  /// Download status.
  DownloadTaskStatus status;

  /// Signals that a request has been sent to the downloader and the answer is pending.
  bool pendingAction;
  SuperEpisodeTask(this.episodeId, this.taskId,
      {this.progress = -1,
      this.status = DownloadTaskStatus.undefined,
      this.pendingAction = false});

  SuperEpisodeTask copyWith(
      {String? taskId,
      int? progress,
      DownloadTaskStatus? status,
      bool? pendingAction}) {
    return SuperEpisodeTask(episodeId, taskId ?? this.taskId,
        progress: progress ?? this.progress,
        status: status ?? this.status,
        pendingAction: pendingAction ?? this.pendingAction);
  }
}
