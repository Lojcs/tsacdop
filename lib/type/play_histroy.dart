import '../state/episode_state.dart';

class PlayHistory {
  /// Episdoe title.
  String? title;

  /// Episode url
  String? url;

  /// Play record seconds.
  int? seconds;

  /// Play record count,
  double? seekValue;

  /// Listened date.
  DateTime? playdate;

  PlayHistory(this.title, this.url, this.seconds, this.seekValue,
      {this.playdate});

  int? _episodeId;
  int? get episodeId => _episodeId;

  Future<void> getEpisodeId(EpisodeState eState) async {
    var episodes = await eState.getEpisodes(episodeUrls: [url!]);
    if (episodes.isEmpty) {
      _episodeId = null;
    } else {
      _episodeId = episodes[0];
    }
  }
}
