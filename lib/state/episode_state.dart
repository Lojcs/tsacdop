import 'package:flutter/material.dart';
import 'package:tsacdop/local_storage/sqflite_localpodcast.dart';
import 'package:tsacdop/type/episodebrief.dart';

import '../type/play_histroy.dart';

class EpisodeState extends ChangeNotifier {
  DBHelper _dbHelper = DBHelper();
  Map<int, bool> episodeChangeMap = {};

  void addEpisode(EpisodeBrief episode) {
    if (!episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = false;
    }
  }

  Future<void> setLiked(EpisodeBrief episode) async {
    await _dbHelper.setLiked(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> setUnliked(EpisodeBrief episode) async {
    await _dbHelper.setUniked(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> markListened(EpisodeBrief episode) async {
    final history = PlayHistory(episode.title, episode.enclosureUrl, 0, 1);
    await _dbHelper.saveHistory(history);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> markNotListened(EpisodeBrief episode) async {
    await _dbHelper.markNotListened(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> saveDownloaded(EpisodeBrief episode, String taskId) async {
    await _dbHelper.saveDownloaded(episode.enclosureUrl, taskId);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }

  Future<void> delDownloaded(EpisodeBrief episode) async {
    await _dbHelper.delDownloaded(episode.enclosureUrl);
    if (episodeChangeMap.containsKey(episode.id)) {
      episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
      notifyListeners();
    }
  }
}
