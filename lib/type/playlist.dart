import 'package:uuid/uuid.dart';
import '../state/episode_state.dart';

enum EpisodeCollision { keepExisting, replace, ignore }

class Playlist {
  /// Playlist name. the default playlist is named "Playlist".
  final String name;

  /// Unique id for playlist.
  final String id;

  /// Wheter playlist is from local files.
  final bool isLocal;

  /// Episode url list for playlist.
  final List<int> episodeIds;

  /// Wheter the episodes are cached in [EpisodeState].
  bool cached = false;

  /// Incremented each time playlist is modified in memory.
  int _generation = 0;

  bool get isEmpty => episodeIds.isEmpty;
  bool get isNotEmpty => episodeIds.isNotEmpty;
  int get length => episodeIds.length;
  bool contains(int episodeId) => episodeIds.contains(episodeId);
  int operator [](int i) => episodeIds[i];

  bool get isQueue => name == 'Queue';

  Playlist(this.name,
      {String? id, this.isLocal = false, this.episodeIds = const []})
      : id = id ?? Uuid().v4(),
        assert(name != '');

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'id': id,
      'isLocal': isLocal,
      'episodeIdList': episodeIds
    };
  }

  Playlist.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        id = json['id'] as String,
        isLocal = json['isLocal'] == true,
        episodeIds = List<int>.from(json['episodeIdList']);

  /// Caches [episodeIds] into [eState] and removes missing ids from the playlist.
  Future<bool> cachePlaylist(EpisodeState eState) async {
    if (cached) return true;
    List<int> missingIds = await eState.cacheEpisodes(episodeIds);
    episodeIds.removeWhere((id) => missingIds.contains(id));
    cached = true;
    return true;
  }

  /// Adds [newEpisodes] to the playlist at [index].
  /// Don't directly use on playlists that might be live. Use [AudioState.addToPlaylist] instead.
  void addEpisodes(List<int> newEpisodes, int index,
      {EpisodeCollision ifExists = EpisodeCollision.ignore}) {
    _generation++;
    switch (ifExists) {
      case EpisodeCollision.keepExisting:
        newEpisodes.removeWhere((episode) => episodeIds.contains(episode));
        break;
      case EpisodeCollision.replace:
        episodeIds.removeWhere((episode) => newEpisodes.contains(episode));
        break;
      case EpisodeCollision.ignore:
        break;
    }
    if (index >= episodeIds.length) {
      episodeIds.addAll(newEpisodes);
    } else {
      episodeIds.insertAll(index, newEpisodes);
    }
  }

  /// Removes [number] episodes at [index] from playlist.
  /// Don't directly use on playlists that might be live. Use [AudioState.removeFromPlaylistAt] instead.
  /// [eState] is used to delete local episodes.
  void removeEpisodesAt(EpisodeState eState, int index,
      {int number = 1, bool delLocal = true}) {
    _generation++;
    int end = index + number;
    List<int> delIds = episodeIds.getRange(index, end).toList();
    episodeIds.removeRange(index, end);
    if (isLocal && delLocal) {
      eState.deleteLocalEpisodes(delIds);
    }
  }

  /// Moves episode at [oldIndex] to [newIndex].
  /// Don't directly use on playlists that might be live. Use [AudioState.reorderPlaylist] instead.
  void reorderPlaylist(int oldIndex, int newIndex) {
    _generation++;
    final id = episodeIds.removeAt(oldIndex);
    episodeIds.insert(newIndex, id);
  }

  /// Clears all episodes in playlist.
  /// Don't directly use on playlists that might be live. Use [AudioState.clearPlaylist] instead.
  void clear() {
    _generation++;
    episodeIds.clear();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Playlist && id == other.id && _generation == other._generation;
  }
}
