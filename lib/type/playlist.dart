import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../local_storage/sqflite_localpodcast.dart';
import 'episodebrief.dart';

class PlaylistEntity {
  final String? name;
  final String? id;
  final bool? isLocal;
  final List<String> episodeList;

  PlaylistEntity(this.name, this.id, this.isLocal, this.episodeList);

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'id': id,
      'isLocal': isLocal,
      'episodeList': episodeList
    };
  }

  static PlaylistEntity fromJson(Map<String, dynamic> json) {
    var list = List<String>.from(json['episodeList'] as Iterable<dynamic>);
    return PlaylistEntity(json['name'] as String?, json['id'] as String?,
        json['isLocal'] == null ? false : json['isLocal'] as bool?, list);
  }
}

enum EpisodeCollision { KeepExisting, Replace, Ignore }

class Playlist extends Equatable {
  /// Playlist name. the default playlist is named "Playlist".
  final String? name;

  /// Unique id for playlist.
  final String id;

  final bool? isLocal;

  /// Episode url list for playlist.
  final List<String> episodeUrlList;

  /// Episodes in playlist.
  final List<EpisodeBrief> episodes;

  List<MediaItem> get mediaItems =>
      [for (var episode in episodes) episode.mediaItem];

  bool get isEmpty => episodeUrlList.isEmpty;

  bool get isNotEmpty => episodeUrlList.isNotEmpty;

  int get length => episodeUrlList.length;

  bool get isQueue => name == 'Queue';

  bool contains(EpisodeBrief episode) => episodes.contains(episode);

  Playlist(this.name,
      {String? id,
      this.isLocal = false,
      List<String>? episodeUrlList,
      List<EpisodeBrief>? episodes})
      : id = id ?? Uuid().v4(),
        assert(name != ''),
        episodeUrlList = episodeUrlList ?? [],
        episodes = episodes ?? [];

  PlaylistEntity toEntity() {
    return PlaylistEntity(name, id, isLocal, episodeUrlList.toSet().toList());
  }

  static Playlist fromEntity(PlaylistEntity entity) {
    return Playlist(
      entity.name,
      id: entity.id,
      isLocal: entity.isLocal,
      episodeUrlList: entity.episodeList,
    );
  }

  final DBHelper _dbHelper = DBHelper();
//  final KeyValueStorage _playlistStorage = KeyValueStorage(playlistKey);

  /// Initialises the playlist with the urls in [episodeUrlList].
  Future<void> getPlaylist() async {
    // Don't reload if already loaded (hope this doesn't break anything)
    if (episodes.length == episodeUrlList.length) return;

    episodes.clear();
    if (episodeUrlList.isNotEmpty) {
      // Single database call should be faster
      episodes.addAll(await _dbHelper
          .getEpisodes(episodeUrls: episodeUrlList, optionalFields: [
        EpisodeField.enclosureDuration,
        EpisodeField.enclosureSize,
        EpisodeField.mediaId,
        EpisodeField.primaryColor,
        EpisodeField.isExplicit,
        EpisodeField.isNew,
        EpisodeField.skipSecondsStart,
        EpisodeField.skipSecondsEnd,
        EpisodeField.episodeImage,
        EpisodeField.podcastImage,
        EpisodeField.chapterLink
      ]));
    }
    // Remove episode urls from episodeList if they are not in the database
    if (episodes.length < episodeUrlList.length) {
      List<bool> episodesFound =
          List<bool>.filled(episodeUrlList.length, false);
      for (EpisodeBrief? episode in episodes) {
        int index = episodeUrlList.indexOf(episode!.enclosureUrl);
        episodesFound[index] = true;
      }
      for (int i = episodesFound.length - 1; i >= 0; i--) {
        if (!episodesFound[i]) {
          episodeUrlList.removeAt(i);
        }
      }
    }
    // Sort episodes in episodeList order
    if (episodes.length == episodeUrlList.length) {
      List<bool> sorted = List<bool>.filled(episodes.length, false);
      for (int i = 0; i < episodes.length; i++) {
        if (!sorted[i]) {
          int index = episodeUrlList.indexOf(episodes[i].enclosureUrl);
          EpisodeBrief? temp;
          while (index != i) {
            temp = episodes[index];
            episodes[index] = episodes[i];
            episodes[i] = temp;
            sorted[index] = true;
            index = episodeUrlList.indexOf(episodes[i].enclosureUrl);
          }
          sorted[index] = true;
        }
      }
    }
  }

  /// Adds [newEpisodes] to the playlist at [index].
  /// Don't directly use on playlists that might be live. Use [AudioState.addToPlaylist] instead.
  void addEpisodes(List<EpisodeBrief> newEpisodes, int index,
      {EpisodeCollision ifExists = EpisodeCollision.Ignore}) {
    switch (ifExists) {
      case EpisodeCollision.KeepExisting:
        newEpisodes.removeWhere((episode) => episodes.contains(episode));
        break;
      case EpisodeCollision.Replace:
        episodes.removeWhere((episode) => newEpisodes.contains(episode));
        episodeUrlList.removeWhere(
            (url) => newEpisodes.any((episode) => episode.enclosureUrl == url));
        break;
      case EpisodeCollision.Ignore:
        break;
    }
    if (index >= episodeUrlList.length) {
      episodes.addAll(newEpisodes);
      episodeUrlList
          .addAll([for (var episode in newEpisodes) episode.enclosureUrl]);
    } else {
      episodes.insertAll(index, newEpisodes);
      episodeUrlList.insertAll(
          index, [for (var episode in newEpisodes) episode.enclosureUrl]);
    }
  }

  /// Removes [number] episodes at [index] from playlist.
  /// Don't directly use on playlists that might be live. Use [AudioState.removeFromPlaylistAt] instead.
  void removeEpisodesAt(int index, {int number = 1, bool delLocal = true}) {
    int end = index + number;
    List<String> delUrls = episodeUrlList.getRange(index, end).toList();
    episodeUrlList.removeRange(index, end);
    episodes.removeRange(index, end);
    if (isLocal! && delLocal) {
      _dbHelper.deleteLocalEpisodes(delUrls);
    }
  }

  /// Moves episode at [oldIndex] to [newIndex].
  /// Don't directly use on playlists that might be live. Use [AudioState.reorderPlaylist] instead.
  void reorderPlaylist(int oldIndex, int newIndex) {
    final episode = episodes.removeAt(oldIndex);
    episodes.insert(newIndex, episode);
    episodeUrlList.removeAt(oldIndex);
    episodeUrlList.insert(newIndex, episode.enclosureUrl);
  }

  /// Replaces matching playlist episodes with the provided [episode].
  /// Don't directly use on playlists that might be live. Use [AudioState.updateEpisodeMediaID] instead.
  List<int> updateEpisode(EpisodeBrief episode) {
    List<int> indexes = [];
    for (int i = 0; i < episodes.length; i++) {
      if (episodes[i] == episode) {
        indexes.add(i);
        episodes[i] = episode;
      }
    }
    return indexes;
  }

  /// Clears all episodes in playlist.
  /// Don't directly use on playlists that might be live. Use [AudioState.clearPlaylist] instead.
  void clear() {
    episodeUrlList.clear();
    episodes.clear();
  }

  @override
  List<Object?> get props => [id, name];
}
