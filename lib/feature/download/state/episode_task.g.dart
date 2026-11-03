// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_task.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EpisodeTaskCWProxy {
  EpisodeTask episodeId(int episodeId);

  EpisodeTask downloadTask(DownloadTask downloadTask);

  EpisodeTask status(TaskStatusUpdate? status);

  EpisodeTask progress(TaskProgressUpdate? progress);

  EpisodeTask pendingAction(bool pendingAction);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EpisodeTask(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EpisodeTask(...).copyWith(id: 12, name: "My name")
  /// ```
  EpisodeTask call({
    int episodeId,
    DownloadTask downloadTask,
    TaskStatusUpdate? status,
    TaskProgressUpdate? progress,
    bool pendingAction,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEpisodeTask.copyWith(...)` or call `instanceOfEpisodeTask.copyWith.fieldName(value)` for a single field.
class _$EpisodeTaskCWProxyImpl implements _$EpisodeTaskCWProxy {
  const _$EpisodeTaskCWProxyImpl(this._value);

  final EpisodeTask _value;

  @override
  EpisodeTask episodeId(int episodeId) => call(episodeId: episodeId);

  @override
  EpisodeTask downloadTask(DownloadTask downloadTask) =>
      call(downloadTask: downloadTask);

  @override
  EpisodeTask status(TaskStatusUpdate? status) => call(status: status);

  @override
  EpisodeTask progress(TaskProgressUpdate? progress) =>
      call(progress: progress);

  @override
  EpisodeTask pendingAction(bool pendingAction) =>
      call(pendingAction: pendingAction);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EpisodeTask(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EpisodeTask(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EpisodeTask call({
    Object? episodeId = const $CopyWithPlaceholder(),
    Object? downloadTask = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? progress = const $CopyWithPlaceholder(),
    Object? pendingAction = const $CopyWithPlaceholder(),
  }) {
    return EpisodeTask(
      episodeId: episodeId == const $CopyWithPlaceholder() || episodeId == null
          ? _value.episodeId
          // ignore: cast_nullable_to_non_nullable
          : episodeId as int,
      downloadTask:
          downloadTask == const $CopyWithPlaceholder() || downloadTask == null
          ? _value.downloadTask
          // ignore: cast_nullable_to_non_nullable
          : downloadTask as DownloadTask,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TaskStatusUpdate?,
      progress: progress == const $CopyWithPlaceholder()
          ? _value.progress
          // ignore: cast_nullable_to_non_nullable
          : progress as TaskProgressUpdate?,
      pendingAction:
          pendingAction == const $CopyWithPlaceholder() || pendingAction == null
          ? _value.pendingAction
          // ignore: cast_nullable_to_non_nullable
          : pendingAction as bool,
    );
  }
}

extension $EpisodeTaskCopyWith on EpisodeTask {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEpisodeTask.copyWith(...)` or `instanceOfEpisodeTask.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EpisodeTaskCWProxy get copyWith => _$EpisodeTaskCWProxyImpl(this);
}
