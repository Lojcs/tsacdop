import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../generated/l10n.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/episode_state.dart';
import '../state/podcast_group.dart';
import '../state/podcast_state.dart';
import '../util/extension_helper.dart';
import '../widgets/action_bar.dart';

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
      eState.deleteEpisodes(delIds);
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

  late final MediaItem mediaItem =
      MediaItem(id: "lst:$id", title: name, playable: false);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Playlist && id == other.id && _generation == other._generation;
  }

  @override
  int get hashCode => [id, _generation].hashCode;
}

/// Class that provides a browsable media item
class BrowsableLibrary {
  static const podcastsId = '412f9d19-9f11-4aa3-b861-c203707c9af1';
  static const playlistsId = '174a1978-c2f2-46f4-b9a3-9c4c5c018c9c';
  static const groupsId = '7bf8bdcf-0283-4386-ac6a-956284358200';
  static const recentsId = 'b11447c7-34cb-41b1-b587-b40c64c7a544';

  BuildContext context;

  late final EpisodeState episodeState = context.episodeState;
  late final AudioPlayerNotifier audioState = context.audioState;
  late final PodcastState podcastState = context.podcastState;
  late final S s = S.current;
  BrowsableLibrary(this.context);

  late Map<String, List<MediaItem>> root = _basicRoot;

  Map<String, List<MediaItem>> get _basicRoot => {
        AudioService.browsableRootId: [
          MediaItem(
            id: playlistsId,
            title: s.playlists,
            playable: false,
          ),
          MediaItem(
            id: recentsId,
            title: s.homeTabMenuRecent,
            playable: false,
          ),
          MediaItem(
            id: podcastsId,
            title: s.podcast(2),
            playable: false,
          ),
          MediaItem(
            id: groupsId,
            title: s.groups(2),
            playable: false,
          ),
        ],
      };

  void reset() => root = _basicRoot;

  Future<List<MediaItem>> operator [](String parentMediaId) async {
    if (!root.containsKey(parentMediaId)) {
      List<String> splitId = parentMediaId.split(':');
      switch (splitId) {
        case [recentsId]:
          final (_, showPlayed) = await getLayoutAndShowPlayed();
          final episodeIds = await episodeState.getEpisodes(
              sortBy: Sorter.pubDate,
              sortOrder: SortOrder.desc,
              limit: 108,
              offset: 0,
              filterPlayed: showPlayed);
          root[parentMediaId] = episodeIds.mapIndexed((i, eid) {
            final episode = episodeState[eid];
            final encodedId = "epi:rec:$parentMediaId:$i:${episode.id}";
            return episode.mediaItem.copyWith(id: encodedId);
          }).toList();
          break;
        case [playlistsId]:
          root[parentMediaId] = audioState.playlists
              .map((playlist) => playlist.mediaItem)
              .toList();
          break;
        case [podcastsId]:
          final podcastIds = await context.podcastState.getPodcasts();
          root[parentMediaId] = podcastIds
              .map((podcast) => context.podcastState[podcast].mediaItem)
              .toList();
          break;
        case [groupsId]:
          root[parentMediaId] = podcastState.groupIds
              .map((id) => podcastState.getGroupById(id).mediaItem)
              .toList();
          break;
        case ['grp', final id, ...]:
          final (_, showPlayed) = await getLayoutAndShowPlayed();
          final episodeIds = await episodeState.getEpisodes(
              feedIds: podcastState.getGroupById(id).podcastIds,
              sortBy: Sorter.pubDate,
              sortOrder: SortOrder.desc,
              limit: 108,
              offset: 0,
              filterPlayed: showPlayed);
          root[parentMediaId] = episodeIds.mapIndexed((i, eid) {
            final episode = episodeState[eid];
            final encodedId = "epi:$parentMediaId:$i:${episode.id}";
            return episode.mediaItem.copyWith(id: encodedId);
          }).toList();
          break;
        case ['pod', final id, ...]:
          final (_, showPlayed) = await getLayoutAndShowPlayed();
          final episodeIds = await episodeState.getEpisodes(
              feedIds: [id],
              sortBy: Sorter.pubDate,
              sortOrder: SortOrder.desc,
              limit: 108,
              offset: 0,
              filterPlayed: showPlayed);
          root[parentMediaId] = episodeIds.mapIndexed((i, eid) {
            final episode = episodeState[eid];
            final encodedId = "epi:$parentMediaId:$i:${episode.id}";
            return episode.mediaItem.copyWith(id: encodedId);
          }).toList();
          break;
        case ['lst', final id, ...]:
          final playlist =
              audioState.playlists.firstWhere((playlist) => playlist.id == id);
          await playlist.cachePlaylist(episodeState);
          root[parentMediaId] = playlist.episodeIds.mapIndexed((i, eid) {
            final episode = episodeState[eid];
            final encodedId = "epi:$parentMediaId:$i:${episode.id}";
            return episode.mediaItem.copyWith(id: encodedId);
          }).toList();
          break;
        case ['epi', 'rec', final parentId, final index, ...]:
          final List<int> episodeIds = root[parentId]!
              .map((mItem) => int.parse(mItem.id.split(':').last))
              .toList();
          final playlist =
              Playlist(s.homeTabMenuRecent, episodeIds: episodeIds);
          audioState.addPlaylist(playlist);
          await audioState.playlistLoad(playlist, index: int.parse(index));
          break;
        case ['epi', 'grp', final parentId, final index, ...]:
          final List<int> episodeIds = root[parentId]!
              .map((mItem) => int.parse(mItem.id.split(':').last))
              .toList();
          final groupTitle = root[AudioService.browsableRootId]!
              .firstWhere((mItem) => mItem.id == parentId)
              .title;
          final playlist =
              Playlist("${s.groups(1)}: $groupTitle", episodeIds: episodeIds);
          audioState.addPlaylist(playlist);
          await audioState.playlistLoad(playlist, index: int.parse(index));
          break;
        case ['epi', 'pod', final parentId, final index, ...]:
          final List<int> episodeIds = root[parentId]!
              .map((mItem) => int.parse(mItem.id.split(':').last))
              .toList();
          final podcastTitle = root[AudioService.browsableRootId]!
              .firstWhere((mItem) => mItem.id == parentId)
              .title;
          final playlist = Playlist("${s.podcast(1)}: $podcastTitle",
              episodeIds: episodeIds);
          audioState.addPlaylist(playlist);
          await audioState.playlistLoad(playlist, index: int.parse(index));
          break;
        case ['epi', 'lst', final parentId, final index, ...]:
          final playlist = audioState.playlists
              .firstWhere((playlist) => playlist.id == parentId);
          await audioState.playlistLoad(playlist, index: int.parse(index));
          break;
      }
    }
    return root[parentMediaId] ?? [];
  }
}
