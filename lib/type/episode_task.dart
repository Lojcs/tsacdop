import 'package:flutter_downloader/flutter_downloader.dart';

/// Class that holds information about an episode download task.
class EpisodeTask {
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
  EpisodeTask(this.episodeId, this.taskId,
      {this.progress = -1,
      this.status = DownloadTaskStatus.undefined,
      this.pendingAction = false});

  EpisodeTask copyWith(
      {String? taskId,
      int? progress,
      DownloadTaskStatus? status,
      bool? pendingAction}) {
    return EpisodeTask(episodeId, taskId ?? this.taskId,
        progress: progress ?? this.progress,
        status: status ?? this.status,
        pendingAction: pendingAction ?? this.pendingAction);
  }
}
