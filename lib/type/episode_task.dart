import 'package:flutter_downloader/flutter_downloader.dart';

import 'episodebrief.dart';

// TODO: Do we need episodeBrief here?
class EpisodeTask {
  final String taskId;
  final EpisodeBrief episode;
  int? progress;
  DownloadTaskStatus? status;
  EpisodeTask(this.episode, this.taskId,
      {this.progress = 0, this.status = DownloadTaskStatus.undefined});

  EpisodeTask copyWith(
      {String? taskId, int? progress, DownloadTaskStatus? status}) {
    return EpisodeTask(episode, taskId ?? this.taskId,
        progress: progress ?? this.progress, status: status ?? this.status);
  }
}

class SuperEpisodeTask {
  final String taskId;
  final String episodeId;
  int progress;
  DownloadTaskStatus status;
  SuperEpisodeTask(this.episodeId, this.taskId,
      {this.progress = 0, this.status = DownloadTaskStatus.undefined});

  SuperEpisodeTask copyWith(
      {String? taskId, int? progress, DownloadTaskStatus? status}) {
    return SuperEpisodeTask(episodeId, taskId ?? this.taskId,
        progress: progress ?? this.progress, status: status ?? this.status);
  }
}
