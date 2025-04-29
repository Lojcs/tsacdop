import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../local_storage/sqflite_localpodcast.dart';
import 'audio_state.dart';
import '../type/episodebrief.dart';

import '../type/play_histroy.dart';

/// Global class to manage [EpisodeBrief] field updates.
class EpisodeState extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  BuildContext? _context;
  late final AudioPlayerNotifier _audio =
      Provider.of<AudioPlayerNotifier>(_context!, listen: false);
  set context(BuildContext context) => _context = context;

  /// episode id : EpisodeBrief
  Map<int, EpisodeBrief> episodeMap = {};
  // using Id here to reduce memory footprint.

  /// Convenience operator for .episodeMap[id]!
  EpisodeBrief operator [](int id) => episodeMap[id]!;

  /// Indicates something changed
  bool globalChange = false;

  /// Ids changed in last update
  List<int> changedIds = [];

  EpisodeState();

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
      bool? filterDisplayVersion,
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
      filterDisplayVersion: filterDisplayVersion,
      filterAutoDownload: filterAutoDownload,
      customFilters: customFilters,
    );
    for (var episode in episodes) {
      episodeMap[episode.id] = episode;
    }
    return episodes.map((ep) => ep.id).toList();
  }

  /// Gets the versions of the episode with [id] and populates their versions fields.
  Future<void> populateEpisodeVersions(int id) async {
    assert(!episodeMap.keys.contains(id), "Populate called with unknown id");
    List<EpisodeBrief> versions =
        await _dbHelper.populateReturnVersions(episodeMap[id]!);
    for (var version in versions) {
      episodeMap[version.id] = version;
    }
  }

  /// Call this only when an episode is removed from the database // TODO: Actually do this
  void removeEpisode(int id) {
    episodeMap.remove(id);
  }

  /// Sets the episodes as liked
  Future<void> setLiked(List<int> ids) async {
    assert(!ids.every((id) => episodeMap.keys.contains(id)),
        "setLiked called with unknown id");
    await _dbHelper.setLiked(ids);
    changedIds.clear();
    for (var id in ids) {
      episodeMap[id] = episodeMap[id]!.copyWith(isLiked: true);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episodes as not liked
  Future<void> unsetLiked(List<int> ids) async {
    assert(!ids.every((id) => episodeMap.keys.contains(id)),
        "unsetLiked called with unknown id");
    await _dbHelper.setUnliked(ids);
    changedIds.clear();
    for (var id in ids) {
      episodeMap[id] = episodeMap[id]!.copyWith(isLiked: false);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episodes as not new
  Future<void> unsetNew(List<int> ids) async {
    assert(!ids.every((id) => episodeMap.keys.contains(id)),
        "unsetNew called with unknown id");
    await _dbHelper.removeEpisodesNewMark(ids);
    changedIds.clear();
    for (var id in ids) {
      episodeMap[id] = episodeMap[id]!.copyWith(isNew: false);
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
    assert(!ids.every((id) => episodeMap.keys.contains(id)),
        "setPlayed called with unknown id");
    changedIds.clear();
    for (var id in ids) {
      final history = PlayHistory(episodeMap[id]!.title,
          episodeMap[id]!.enclosureUrl, seconds, seekValue);
      await _dbHelper.saveHistory(history);
      episodeMap[id] = episodeMap[id]!.copyWith(isPlayed: true);
      changedIds.add(id);
    }
    if (changedIds.isNotEmpty) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the episodes as not played
  Future<void> unsetPlayed(List<int> ids) async {
    assert(!ids.every((id) => episodeMap.keys.contains(id)),
        "unsetPlayed called with unknown id");
    await _dbHelper.unsetLiked(ids);
    changedIds.clear();
    for (var id in ids) {
      episodeMap[id] = episodeMap[id]!.copyWith(isPlayed: false);
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
    assert(episodeMap.keys.contains(episodeId),
        "setDownloaded called with unknown id");
    changedIds.clear();
    await _dbHelper.setDownloaded(episodeId,
        mediaId: mediaId,
        taskId: taskId,
        size: size ?? episodeMap[episodeId]!.enclosureSize,
        duration: duration ?? episodeMap[episodeId]!.enclosureDuration);
    episodeMap[episodeId] =
        episodeMap[episodeId]!.copyWith(mediaId: mediaId, isDownloaded: true);
    changedIds.add(episodeId);
    globalChange = !globalChange;
    notifyListeners();
  }

  /// Sets the episode as not downloaded and sets its mediaId to its enclosureUrl
  Future<void> unsetDownloaded(int episodeId) async {
    assert(episodeMap.keys.contains(episodeId),
        "unsetDownloaded called with unknown id");
    changedIds.clear();
    await _dbHelper.unsetDownloaded(episodeId,
        enclosureUrl: episodeMap[episodeId]!.enclosureUrl);
    episodeMap[episodeId] = episodeMap[episodeId]!.copyWith(
        mediaId: episodeMap[episodeId]!.enclosureUrl, isDownloaded: false);
    changedIds.add(episodeId);
    globalChange = !globalChange;
    notifyListeners();
  }

  /// Sets the display version for all non downloaded versions of the episode
  Future<void> setDisplayVersion(int id) async {
    assert(episodeMap.keys.contains(id),
        "setDisplayVersion called with unknown id");
    await _dbHelper.setDisplayVersion(episodeMap[id]!);
    changedIds.clear();
    await populateEpisodeVersions(id);
    changedIds.addAll(episodeMap[id]!.versions!.toList());
    globalChange = !globalChange;
    notifyListeners();
  }
}
