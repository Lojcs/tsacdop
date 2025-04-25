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

  /// episode id : bool. Bool flips when episode property changes, indicating the need for refetching from database.
  Map<int, bool> episodeChangeMap = {};
  // using Id here to reduce memory footprint.

  /// Indicates something changed
  bool globalChange = false;

  /// Ids changed in last update
  List<int> changedIds = [];

  EpisodeState();

  /// Call this when you want to listen to an episode's field changes.
  void addEpisode(EpisodeBrief episode) {
    if (!episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = false;
    }
  }

  /// Call this only when an episode is removed from the database // TODO: Actually do this
  void removeEpisode(EpisodeBrief episode) {
    episodeChangeMap.remove(episode.id);
  }

  Future<void> setLiked(List<EpisodeBrief> episodes) async {
    await _dbHelper.setLiked(episodes.map((e) => e.id).toList());
    bool changeHappened = false;
    changedIds.clear();
    for (var episode in episodes) {
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        changedIds.add(episode.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  Future<void> unsetLiked(List<EpisodeBrief> episodes) async {
    await _dbHelper.setUnliked(episodes.map((e) => e.id).toList());
    bool changeHappened = false;
    changedIds.clear();
    for (var episode in episodes) {
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        changedIds.add(episode.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  Future<void> unsetNew(List<EpisodeBrief> episodes) async {
    await _dbHelper.removeEpisodesNewMark(episodes.map((e) => e.id).toList());
    bool changeHappened = false;
    changedIds.clear();
    for (var episode in episodes) {
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        changedIds.add(episode.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  Future<void> setListened(List<EpisodeBrief> episodes,
      {double seekValue = 1, int seconds = 0}) async {
    bool changeHappened = false;
    changedIds.clear();
    for (var episode in episodes) {
      final history =
          PlayHistory(episode.title, episode.enclosureUrl, seconds, seekValue);
      await _dbHelper.saveHistory(history);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        changedIds.add(episode.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  Future<void> unsetListened(List<EpisodeBrief> episodes) async {
    await _dbHelper
        .markNotListened(episodes.map((e) => e.enclosureUrl).toList());
    bool changeHappened = false;
    changedIds.clear();
    for (var episode in episodes) {
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        changedIds.add(episode.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  Future<void> setDownloaded(List<EpisodeBrief> episodes, String taskId) async {
    bool changeHappened = false;
    changedIds.clear();
    for (var episode in episodes) {
      await _dbHelper.setDownloaded(episode.id, taskId);
      await _audio.updateEpisodeMediaID(episode);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        changedIds.add(episode.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  Future<void> unsetDownloaded(List<EpisodeBrief> episodes) async {
    await _dbHelper.unsetDownloaded(episodes.map((e) => e.id).toList());
    bool changeHappened = false;
    changedIds.clear();
    for (var episode in episodes) {
      await _audio.updateEpisodeMediaID(episode);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        changedIds.add(episode.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }

  /// Sets the display version for all non downloaded versions of the episode
  Future<void> setDisplayVersion(EpisodeBrief episode) async {
    await _dbHelper.setDisplayVersion(episode);
    bool changeHappened = false;
    changedIds.clear();
    episode = await episode.updateFromDB(getVersions: true);
    for (var version in episode.versions!) {
      if (episodeChangeMap.containsKey(version.id)) {
        episodeChangeMap[version.id] = !episodeChangeMap[version.id]!;
        changedIds.add(version.id);
        changeHappened = true;
      }
    }
    if (changeHappened) {
      globalChange = !globalChange;
      notifyListeners();
    }
  }
}
