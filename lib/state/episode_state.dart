import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../util/extension_helper.dart';
import 'audio_state.dart';
import '../type/episodebrief.dart';

import '../type/play_histroy.dart';
import 'download_state.dart';

/// Global class to manage [EpisodeBrief] field updates.
class EpisodeState extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  late AudioPlayerNotifier _audioState;
  late SuperDownloadState _downloadState;
  bool _background = true;
  set context(BuildContext context) {
    _audioState = context.audioState;
    _downloadState = context.downloadState;
    _background = false;
  }

  bool get background => _background;

  /// episode id : EpisodeBrief
  final Map<int, EpisodeBrief> _episodeMap = {};

  /// episode id : EpisodeBrief
  final Map<int, EpisodeBrief> _remoteEpisodeMap = {};

  int _remoteId = -1;
  // using Id here to reduce memory footprint.

  /// Set of deleted episode ids.
  final Set<int> deletedIds = {};

  late final EpisodeBrief deletedEpisode = EpisodeBrief.user(
      title: S.current.deleted,
      enclosureUrl: "",
      pubDate: 0,
      showNotes: S.current.deletedEpisodeDesc,
      enclosureDuration: 0,
      enclosureSize: 0,
      mediaId: "");

  /// Convenience operator for getting the [EpisodeBrief] of an episode.
  EpisodeBrief operator [](int id) =>
      _episodeMap[id] ??
      _remoteEpisodeMap[id] ??
      (deletedIds.contains(id) ? deletedEpisode : _episodeMap[id]!);

  /// Indicates something changed
  bool globalChange = false;

  /// Ids changed in last update
  Set<int> changedIds = {};

  EpisodeState();

  /// Ensures the episodes with the given ids are cached.
  /// Returns the ids not found in database.
  Future<List<int>> cacheEpisodes(List<int> episodeIds) async {
    List<int> missingIds = [];
    for (var id in episodeIds) {
      if (!_episodeMap.containsKey(id)) {
        missingIds.add(id);
      }
    }
    if (missingIds.isNotEmpty) {
      List<int> foundIds = await getEpisodes(episodeIds: missingIds);
      return missingIds.where((id) => !foundIds.contains(id)).toList();
    } else {
      return [];
    }
  }

  /// Queries the database with the provided options and returns found episodes.
  /// Filters are tri-state (null - no filter, true - only, false - exclude)
  Future<List<int>> getEpisodes(
      {List<String>? feedIds,
      List<String>? excludedFeedIds,
      List<int>? episodeIds,
      List<int>? excludedEpisodeIds,
      List<String>? episodeUrls,
      List<String>? excludedEpisodeUrls,
      List<String>? episodeTitles,
      List<String>? excludedEpisodeTitles,
      List<String>? likeEpisodeTitles,
      List<String>? excludedLikeEpisodeTitles,
      Sorter? sortBy,
      SortOrder sortOrder = SortOrder.desc,
      List<Sorter>? rangeParameters,
      List<(int, int)>? rangeDelimiters,
      int limit = -1,
      int offset = -1,
      bool? filterNew,
      bool? filterLiked,
      bool? filterPlayed,
      bool? filterDownloaded,
      bool? filterDuplicateVersions,
      bool? filterAutoDownload,
      List<String>? customFilters,
      List<String>? customArguements}) async {
    List<EpisodeBrief> episodes = await _dbHelper.getEpisodes(
      feedIds: feedIds,
      excludedFeedIds: excludedFeedIds,
      episodeIds: episodeIds,
      excludedEpisodeIds: excludedEpisodeIds,
      episodeUrls: episodeUrls,
      excludedEpisodeUrls: excludedEpisodeUrls,
      episodeTitles: episodeTitles,
      excludedEpisodeTitles: excludedEpisodeTitles,
      likeEpisodeTitles: likeEpisodeTitles,
      excludedLikeEpisodeTitles: excludedLikeEpisodeTitles,
      sortBy: sortBy,
      sortOrder: sortOrder,
      rangeParameters: rangeParameters,
      rangeDelimiters: rangeDelimiters,
      limit: limit,
      offset: offset,
      filterNew: filterNew,
      filterLiked: filterLiked,
      filterPlayed: filterPlayed,
      filterDownloaded: filterDownloaded,
      filterDuplicateVersions: filterDuplicateVersions,
      filterAutoDownload: filterAutoDownload,
      customFilters: customFilters,
    );
    for (var episode in episodes) {
      _episodeMap[episode.id] = episode;
    }
    return episodes.map((ep) => ep.id).toList();
  }

  /// Gets the versions of the episode with [id] and populates their versions fields.
  Future<void> populateEpisodeVersions(int id) async {
    assert(_episodeMap.keys.contains(id), "Populate called with unknown id");
    List<EpisodeBrief> versions =
        await _dbHelper.populateReturnVersions(_episodeMap[id]!, force: true);
    for (var version in versions) {
      _episodeMap[version.id] = version;
    }
  }

  /// Call this only when an episode is removed from the database
  Future<void> deleteEpisodes(List<int> ids,
      {bool deleteFromDatabase = true}) async {
    final dState =
        background ? SuperDownloadState(background: true) : _downloadState;
    final downloaded =
        await getEpisodes(episodeIds: ids, filterDownloaded: true);
    for (var id in downloaded) {
      await dState.removeDownload(id);
    }
    for (var id in ids) {
      if (_episodeMap.remove(id) != null) deletedIds.add(id);
    }
    if (deleteFromDatabase) await _dbHelper.deleteLocalEpisodes(ids);
  }

  List<int> addRemoteEpisodes(Iterable<EpisodeBrief> episodes) {
    List<int> ids = [];
    for (var episode in episodes) {
      int id = _remoteId--;
      ids.add(id);
      _remoteEpisodeMap[id] = episode.copyWith(id: id);
    }
    return ids;
  }

  void removeRemoteEpisodes(List<int> episodeIds) {
    _remoteEpisodeMap.removeWhere((id, _) => episodeIds.contains(id));
  }

  /// Sets the episodes as liked
  Future<void> setLiked(List<int> ids) async {
    assert(ids.every((id) => _episodeMap.keys.contains(id)),
        "setLiked called with unknown id");
    await _dbHelper.setLiked(ids);
    changedIds.clear();
    for (var id in ids) {
      _episodeMap[id] = _episodeMap[id]!.copyWith(isLiked: true);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episodes as not liked
  Future<void> unsetLiked(List<int> ids) async {
    assert(ids.every((id) => _episodeMap.keys.contains(id)),
        "unsetLiked called with unknown id");
    await _dbHelper.setUnliked(ids);
    changedIds.clear();
    for (var id in ids) {
      _episodeMap[id] = _episodeMap[id]!.copyWith(isLiked: false);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episodes as not new
  Future<void> unsetNew(List<int> ids) async {
    assert(ids.every((id) => _episodeMap.keys.contains(id)),
        "unsetNew called with unknown id");
    await _dbHelper.removeEpisodesNewMark(ids);
    changedIds.clear();
    for (var id in ids) {
      _episodeMap[id] = _episodeMap[id]!.copyWith(isNew: false);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episodes as played
  Future<void> setPlayed(List<int> ids,
      {double seekValue = 1, int seconds = 0}) async {
    assert(ids.every((id) => _episodeMap.keys.contains(id)),
        "setPlayed called with unknown id");
    changedIds.clear();
    for (var id in ids) {
      final history = PlayHistory(_episodeMap[id]!.title,
          _episodeMap[id]!.enclosureUrl, seconds, seekValue);
      await _dbHelper.saveHistory(history);
      _episodeMap[id] = _episodeMap[id]!.copyWith(isPlayed: true);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episodes as not played
  Future<void> unsetPlayed(List<int> ids) async {
    assert(ids.every((id) => _episodeMap.keys.contains(id)),
        "unsetPlayed called with unknown id");
    await _dbHelper
        .unsetListened(ids.map((id) => _episodeMap[id]!.enclosureUrl).toList());
    changedIds.clear();
    for (var id in ids) {
      _episodeMap[id] = _episodeMap[id]!.copyWith(isPlayed: false);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episode as downloaded and saves its mediaId, download task id
  /// size and duration
  Future<void> setDownloaded(int episodeId,
      {required String mediaId,
      required String taskId,
      int? size,
      int? duration}) async {
    assert(_episodeMap.keys.contains(episodeId),
        "setDownloaded called with unknown id");
    changedIds.clear();
    await _dbHelper.setDownloaded(episodeId,
        mediaId: mediaId,
        taskId: taskId,
        size: size ?? _episodeMap[episodeId]!.enclosureSize,
        duration: duration ?? _episodeMap[episodeId]!.enclosureDuration);
    _episodeMap[episodeId] =
        _episodeMap[episodeId]!.copyWith(mediaId: mediaId, isDownloaded: true);
    changedIds.add(episodeId);
    globalChange = !globalChange;
    if (!background) {
      _audioState.updateEpisodeMediaID(_episodeMap[episodeId]!);
    }
    notifyListeners();
  }

  /// Sets the episode as not downloaded and sets its mediaId to its enclosureUrl
  Future<void> unsetDownloaded(int episodeId) async {
    assert(_episodeMap.keys.contains(episodeId),
        "unsetDownloaded called with unknown id");
    changedIds.clear();
    await _dbHelper.unsetDownloaded(episodeId,
        enclosureUrl: _episodeMap[episodeId]!.enclosureUrl);
    _episodeMap[episodeId] = _episodeMap[episodeId]!.copyWith(
        mediaId: _episodeMap[episodeId]!.enclosureUrl, isDownloaded: false);
    changedIds.add(episodeId);
    globalChange = !globalChange;
    if (!background) {
      _audioState.updateEpisodeMediaID(_episodeMap[episodeId]!);
    }
    notifyListeners();
  }

  /// Sets the display version for all non downloaded versions of the episode
  Future<void> setDisplayVersion(int id) async {
    print(_episodeMap[id]!.isDisplayVersion);
    assert(_episodeMap.keys.contains(id),
        "setDisplayVersion called with unknown id");
    await _dbHelper.setDisplayVersion(_episodeMap[id]!);
    changedIds.clear();
    await populateEpisodeVersions(id);
    changedIds.addAll(_episodeMap[id]!.versions!.toList());
    globalChange = !globalChange;
    notifyListeners();
    print(_episodeMap[id]!.isDisplayVersion);
  }
}
