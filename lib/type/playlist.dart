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
  final List<String> episodeList;

  /// Eposides in playlist.
  final List<EpisodeBrief> episodes;

  List<MediaItem> get mediaItems =>
      [for (var episode in episodes) episode.mediaItem];

  bool get isEmpty => episodeList.isEmpty;

  bool get isNotEmpty => episodeList.isNotEmpty;

  int get length => episodeList.length;

  bool get isQueue => name == 'Queue';

  bool contains(EpisodeBrief episode) => episodes.contains(episode);

  Playlist(this.name,
      {String? id,
      this.isLocal = false,
      List<String>? episodeList,
      List<EpisodeBrief>? episodes})
      : id = id ?? Uuid().v4(),
        assert(name != ''),
        episodeList = episodeList ?? [],
        episodes = episodes ?? [];

  PlaylistEntity toEntity() {
    return PlaylistEntity(name, id, isLocal, episodeList.toSet().toList());
  }

  static Playlist fromEntity(PlaylistEntity entity) {
    return Playlist(
      entity.name,
      id: entity.id,
      isLocal: entity.isLocal,
      episodeList: entity.episodeList,
    );
  }

  final DBHelper _dbHelper = DBHelper();
//  final KeyValueStorage _playlistStorage = KeyValueStorage(playlistKey);

  /// Clears and (re)initialises the playlist with the urls in [episodeList].
  Future<void> getPlaylist() async {
    // // Don't reload if already loaded
    // if (!reload && episodes.length == episodeList.length) return;
    episodes.clear();
    if (episodeList.isNotEmpty) {
      // Single database call should be faster
      episodes.addAll(await _dbHelper
          .getEpisodes(episodeUrls: episodeList, optionalFields: [
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
    if (episodes.length < episodeList.length) {
      List<bool> episodesFound = List<bool>.filled(episodeList.length, false);
      for (EpisodeBrief? episode in episodes) {
        int index = episodeList.indexOf(episode!.enclosureUrl);
        episodesFound[index] = true;
      }
      for (int i = episodesFound.length - 1; i >= 0; i--) {
        if (!episodesFound[i]) {
          episodeList.removeAt(i);
        }
      }
    }
    // Sort episodes in episodeList order
    if (episodes.length == episodeList.length) {
      List<bool> sorted = List<bool>.filled(episodes.length, false);
      for (int i = 0; i < episodes.length; i++) {
        if (!sorted[i]) {
          int index = episodeList.indexOf(episodes[i].enclosureUrl);
          EpisodeBrief? temp;
          while (index != i) {
            temp = episodes[index];
            episodes[index] = episodes[i];
            episodes[i] = temp;
            sorted[index] = true;
            index = episodeList.indexOf(episodes[i].enclosureUrl);
          }
          sorted[index] = true;
        }
      }
    }
  }

// Future<void> savePlaylist() async {
//    var urls = <String>[];
//    urls.addAll(_playlist.map((e) => e.enclosureUrl));
//    await _playlistStorage.saveStringList(urls.toSet().toList());
//  }

  /// Adds episodes to the playlist at [index].
  /// Don't directly use on playlists that might be live. Use [AudioState.addToPlaylistPlus] instead.
  void addEpisodes(List<EpisodeBrief> newEpisodes, int index,
      {EpisodeCollision ifExists = EpisodeCollision.Ignore}) {
    switch (ifExists) {
      case EpisodeCollision.KeepExisting:
        newEpisodes.removeWhere((episode) => episodes.contains(episode));
        break;
      case EpisodeCollision.Replace:
        episodes.removeWhere((episode) => newEpisodes.contains(episode));
        episodeList.removeWhere(
            (url) => newEpisodes.any((episode) => episode.enclosureUrl == url));
        break;
      case EpisodeCollision.Ignore:
        break;
    }
    if (index == episodeList.length) {
      episodes.addAll(newEpisodes);
      episodeList
          .addAll([for (var episode in newEpisodes) episode.enclosureUrl]);
    } else {
      episodes.insertAll(index, newEpisodes);
      episodeList.insertAll(
          index, [for (var episode in newEpisodes) episode.enclosureUrl]);
    }
  }

  void removeEpisodes(List<EpisodeBrief> delEpisodes, {bool delLocal = true}) {
    List<String> delUrls = [
      for (var episode in delEpisodes) episode.enclosureUrl
    ];
    episodes.removeWhere((episode) => delEpisodes.contains(episode));
    episodeList.removeWhere((url) => delUrls.contains(url));
    if (isLocal! && delLocal) {
      _dbHelper.deleteLocalEpisodes(delUrls);
    }
  }

  void removeEpisodesAt(int index, {int number = 1}) {
    int end = index + number;
    List<String> delEpisodes = episodeList.getRange(index, end).toList();
    _dbHelper.deleteLocalEpisodes(delEpisodes);
    episodeList.removeRange(index, end);
    episodes.removeRange(index, end);
  }

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

  int delFromPlaylist(EpisodeBrief episodeBrief) {
    var index = episodes.indexOf(episodeBrief);
    episodes.removeWhere(
        (episode) => episode.enclosureUrl == episodeBrief.enclosureUrl);
    episodeList.removeWhere((url) => url == episodeBrief.enclosureUrl);
    if (isLocal!) {
      _dbHelper.deleteLocalEpisodes([episodeBrief.enclosureUrl]);
    }
    return index;
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    final episode = episodes.removeAt(oldIndex);
    episodes.insert(newIndex, episode);
    episodeList.removeAt(oldIndex);
    episodeList.insert(newIndex, episode.enclosureUrl);
  }

  void clear() {
    episodeList.clear();
    episodes.clear();
  }

  @override
  List<Object?> get props => [id, name];
}
