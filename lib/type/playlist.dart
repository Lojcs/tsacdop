import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../state/episode_state.dart';

enum EpisodeCollision { keepExisting, replace, ignore }

class Playlist extends Equatable {
  /// Playlist name. the default playlist is named "Playlist".
  final String name;

  /// Unique id for playlist.
  final String id;

  /// Wheter playlist is from local files.
  final bool isLocal;

  /// Episode url list for playlist.
  final List<int> episodeIdList;

  /// Wheter the episodes are cached in [EpisodeState].
  bool cached = false;

  bool get isEmpty => episodeIdList.isEmpty;
  bool get isNotEmpty => episodeIdList.isNotEmpty;
  int get length => episodeIdList.length;
  bool contains(int episodeId) => episodeIdList.contains(episodeId);
  int operator [](int i) => episodeIdList[i];

  bool get isQueue => name == 'Queue';

  Playlist(this.name,
      {String? id, this.isLocal = false, this.episodeIdList = const []})
      : id = id ?? Uuid().v4(),
        assert(name != '');

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'id': id,
      'isLocal': isLocal,
      'episodeIdList': episodeIdList
    };
  }

  Playlist.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        id = json['id'] as String,
        isLocal = json['isLocal'] == true,
        episodeIdList = json['episodeIdList'] as List<int>;

  /// Caches [episodeIdList] into [eState] and removes missing ids from the playlist.
  Future<void> cachePlaylist(EpisodeState eState) async {
    if (cached) return;
    List<int> missingIds = await eState.cacheEpisodes(episodeIdList);
    episodeIdList.removeWhere((id) => missingIds.contains(id));
    cached = true;
  }

  /// Adds [newEpisodes] to the playlist at [index].
  /// Don't directly use on playlists that might be live. Use [AudioState.addToPlaylist] instead.
  void addEpisodes(List<int> newEpisodes, int index,
      {EpisodeCollision ifExists = EpisodeCollision.ignore}) {
    switch (ifExists) {
      case EpisodeCollision.keepExisting:
        newEpisodes.removeWhere((episode) => episodeIdList.contains(episode));
        break;
      case EpisodeCollision.replace:
        episodeIdList.removeWhere((episode) => newEpisodes.contains(episode));
        break;
      case EpisodeCollision.ignore:
        break;
    }
    if (index >= episodeIdList.length) {
      episodeIdList.addAll(newEpisodes);
    } else {
      episodeIdList.insertAll(index, newEpisodes);
    }
  }

  /// Removes [number] episodes at [index] from playlist.
  /// Don't directly use on playlists that might be live. Use [AudioState.removeFromPlaylistAt] instead.
  void removeEpisodesAt(EpisodeState eState, int index,
      {int number = 1, bool delLocal = true}) {
    int end = index + number;
    List<int> delIds = episodeIdList.getRange(index, end).toList();
    episodeIdList.removeRange(index, end);
    if (isLocal && delLocal) {
      eState.deleteLocalEpisodes(delIds);
    }
  }

  /// Moves episode at [oldIndex] to [newIndex].
  /// Don't directly use on playlists that might be live. Use [AudioState.reorderPlaylist] instead.
  void reorderPlaylist(int oldIndex, int newIndex) {
    final id = episodeIdList.removeAt(oldIndex);
    episodeIdList.insert(newIndex, id);
  }

  /// Clears all episodes in playlist.
  /// Don't directly use on playlists that might be live. Use [AudioState.clearPlaylist] instead.
  void clear() {
    episodeIdList.clear();
  }

  @override
  List<Object?> get props => [id, name];
}
