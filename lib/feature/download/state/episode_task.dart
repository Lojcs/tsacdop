import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as path;

import '../../episode/state/episode_brief.dart';

part "episode_task.g.dart";

@CopyWith()
class EpisodeTask({
  /// Database episode id.
  required final int episodeId,

  /// [FileDownloader] task.
  required final DownloadTask downloadTask,

  /// Download status.
  required final TaskStatusUpdate? status,

  /// Download progress.
  required final TaskProgressUpdate? progress,

  /// Signals that a request has been sent to the downloader
  /// and the answer is pending.
  required final bool pendingAction,
}) with Equatable {
  /// [FileDownloader] download task id.
  late final String taskId = episodeId.toString();

  new fromDownloadTask(DownloadTask downloadTask)
    : this(
        episodeId: int.parse(downloadTask.taskId),
        downloadTask: downloadTask,
        status: null,
        progress: null,
        pendingAction: false,
      );

  static Future<EpisodeTask> newTask(
    EpisodeBrief episode,
    String downloadStoragePath,
  ) async {
    final localPath = path.join(
      downloadStoragePath,
      episode.podcastTitle.replaceAll('/', ''),
    );
    final saveDir = Directory(localPath);
    if (!(await saveDir.exists())) await saveDir.create();
    final dateFull = DateTime.now().toIso8601String();
    var cleanTitle = episode.title.replaceAll('/', '');
    final extension = episode.enclosureUrl
        .split('/')
        .last
        .split('.')
        .last
        .split('?')
        .first;
    final titleTail = " - $dateFull.$extension";
    if (cleanTitle.length > 100 - titleTail.length) {
      cleanTitle = cleanTitle.substring(0, 100 - titleTail.length);
    }
    final fileName = '$cleanTitle$titleTail';
    return EpisodeTask(
      episodeId: episode.id,
      downloadTask: DownloadTask(
        taskId: episode.id.toString(),
        url: episode.enclosureUrl,
        filename: fileName,
        directory: localPath,
        baseDirectory: .root,
        updates: .statusAndProgress,
        allowPause: true,
        displayName: "${episode.podcastTitle}: ${episode.title}",
      ),
      status: null,
      progress: null,
      pendingAction: false,
    );
  }

  @override
  List<Object?> get props => [
    taskId,
    episodeId,
    progress,
    status,
    pendingAction,
  ];
}
