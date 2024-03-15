import 'package:flutter/material.dart';
import 'package:tsacdop/local_storage/sqflite_localpodcast.dart';
import 'package:tsacdop/type/episodebrief.dart';

import '../type/play_histroy.dart';

/// Global class to manage [EpisodeBrief] field updates.
class EpisodeState extends ChangeNotifier {
  DBHelper _dbHelper = DBHelper();
  Map<int, bool> episodeChangeMap = {};
  // using Id here to reduce memory footprint.

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
    if (episode.isLiked != null && !episode.isLiked!) {
      await _dbHelper.setLiked(episode.enclosureUrl);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }

  Future<void> unsetLiked(EpisodeBrief episode) async {
    if (episode.isLiked != null && episode.isLiked!) {
      await _dbHelper.setUnliked(episode.enclosureUrl);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }

  Future<void> unsetNew(EpisodeBrief episode) async {
    if (episode.isNew != null && episode.isNew!) {
      await _dbHelper.removeEpisodeNewMark(episode.enclosureUrl);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }

  Future<void> setListened(EpisodeBrief episode) async {
    if (episode.isPlayed != null && !episode.isPlayed!) {
      final history = PlayHistory(episode.title, episode.enclosureUrl, 0, 1);
      await _dbHelper.saveHistory(history);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }

  Future<void> unsetListened(EpisodeBrief episode) async {
    if (episode.isPlayed != null && episode.isPlayed!) {
      await _dbHelper.markNotListened(episode.enclosureUrl);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }

  Future<void> setDownloaded(EpisodeBrief episode, String taskId) async {
    if (episode.isDownloaded != null && !episode.isDownloaded!) {
      await _dbHelper.saveDownloaded(episode.enclosureUrl, taskId);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }

  Future<void> unsetDownloaded(EpisodeBrief episode) async {
    if (episode.isDownloaded != null && episode.isDownloaded!) {
      await _dbHelper.delDownloaded(episode.enclosureUrl);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }

  Future<void> setDisplayVersion(EpisodeBrief episode) async {
    if (episode.versionInfo == VersionInfo.IS) {
      await _dbHelper.setDisplayVersion(episode);
      if (episodeChangeMap.containsKey(episode.id)) {
        episodeChangeMap[episode.id] = !episodeChangeMap[episode.id]!;
        notifyListeners();
      }
    }
  }
}
