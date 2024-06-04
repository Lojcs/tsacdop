import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/local_storage/sqflite_localpodcast.dart';
import 'package:tsacdop/state/audio_state.dart';
import 'package:tsacdop/type/episodebrief.dart';

import '../type/play_histroy.dart';

/// Global class to manage [EpisodeBrief] field updates.
class EpisodeState extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  BuildContext? _context;
  late AudioPlayerNotifier _audio =
      Provider.of<AudioPlayerNotifier>(_context!, listen: false);
  set context(BuildContext context) => _context = context;

  Map<int, bool> episodeChangeMap = {};
  // using Id here to reduce memory footprint.
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

  Future<void> setLiked(EpisodeBrief episode) async {
    await _dbHelper.setLiked(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> unsetLiked(EpisodeBrief episode) async {
    await _dbHelper.setUnliked(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> unsetNew(EpisodeBrief episode) async {
    await _dbHelper.removeEpisodeNewMark(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> setListened(EpisodeBrief episode,
      {double seekValue = 1, int seconds = 0}) async {
    final history =
        PlayHistory(episode.title, episode.enclosureUrl, seconds, seekValue);
    await _dbHelper.saveHistory(history);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> unsetListened(EpisodeBrief episode) async {
    await _dbHelper.markNotListened(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> setDownloaded(EpisodeBrief episode, String taskId) async {
    await _dbHelper.setDownloaded(episode.enclosureUrl, taskId);
    await _audio.updateEpisodeMediaID(episode);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> unsetDownloaded(EpisodeBrief episode) async {
    await _dbHelper.unsetDownloaded(episode.enclosureUrl);
    await _audio.updateEpisodeMediaID(episode);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> setDisplayVersion(EpisodeBrief episode) async {
    await _dbHelper.setDisplayVersion(episode);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }
}
