import '../local_storage/sqflite_localpodcast.dart';
import 'episodebrief.dart';

class PlayHistory {
  final DBHelper _dbHelper = DBHelper();

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

  EpisodeBrief? _episode;
  EpisodeBrief? get episode => _episode;

  Future<void> getEpisode() async {
    var episodes = await _dbHelper.getEpisodes(episodeUrls: [
      url!
    ], optionalFields: [
      EpisodeField.mediaId,
      EpisodeField.isNew,
      EpisodeField.skipSecondsStart,
      EpisodeField.skipSecondsEnd,
      EpisodeField.episodeImage,
      EpisodeField.podcastImage,
      EpisodeField.chapterLink
    ]);
    if (episodes.isEmpty)
      _episode = null;
    else
      _episode = episodes[0];
  }
}
