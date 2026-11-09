import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

import '../../../core/service/database.dart';
import '../../group/model/podcast_group.dart';
import '../../home/model/tab_configuration.dart';
import '../../podcast/model/podcast_brief.dart';
import '../../podcast/state/podcast_state.dart';

@CopyWith()
class EpisodeQuery with Equatable {
  final List<String>? podcastIds;
  final List<String>? excludedFeedIds;
  final List<int>? episodeIds;
  final List<int>? excludedEpisodeIds;
  final List<String>? episodeUrls;
  final List<String>? excludedEpisodeUrls;
  final List<String>? episodeTitles;
  final List<String>? excludedEpisodeTitles;
  final List<String>? likeEpisodeTitles;
  final List<String>? excludedLikeEpisodeTitles;
  final Sorter? sortBy;
  final SortOrder sortOrder;

  /// List of parameters to limit range on.
  final List<Sorter>? rangeParameters;

  /// Upper and lower bounds for each range parameter. Use -1 for unbounded.
  final List<(int, int)>? rangeDelimiters;
  final int limit;
  final int offset;
  final bool? filterNew;
  final bool? filterLiked;
  final bool? filterPlayed;
  final bool? filterDownloaded;
  final bool? filterDuplicateVersions;
  final bool? filterAutoDownload;
  final bool? filterInteracted;

  /// Custom sql filters.
  final List<String>? customFilters;

  /// Arguments for the custom sql filters.
  final List<String>? customArguments;

  const new({
    this.podcastIds,
    this.excludedFeedIds,
    this.episodeIds,
    this.excludedEpisodeIds,
    this.episodeUrls,
    this.excludedEpisodeUrls,
    this.episodeTitles,
    this.excludedEpisodeTitles,
    this.likeEpisodeTitles,
    this.excludedLikeEpisodeTitles,
    this.sortBy,
    this.sortOrder = SortOrder.desc,
    this.rangeParameters,
    this.rangeDelimiters,
    this.limit = -1,
    this.offset = -1,
    this.filterNew,
    this.filterLiked,
    this.filterPlayed,
    this.filterDownloaded,
    this.filterDuplicateVersions,
    this.filterAutoDownload,
    this.filterInteracted,
    this.customFilters,
    this.customArguments,
  });

  factory fromActionBarConfiguration({
    required ActionBarConfiguration configuration,
    required PodcastState podcastState,
    required int limit,
    int offset = -1,
  }) {
    final List<String> groupPodcastIds = configuration.groupId == allGroupId
        ? []
        : podcastState.getGroupById(configuration.groupId)!.podcastIds;
    return .new(
      podcastIds: configuration.podcastId != podcastAllId
          ? groupPodcastIds.isEmpty ||
                    groupPodcastIds.contains(configuration.podcastId)
                ? [configuration.podcastId]
                : null
          : (groupPodcastIds.isNotEmpty ? groupPodcastIds : null),
      likeEpisodeTitles: configuration.searchTitleQuery == null
          ? null
          : [configuration.searchTitleQuery!],
      sortBy: configuration.sortBy,
      sortOrder: configuration.sortOrder,
      limit: limit,
      offset: offset,
      filterNew: configuration.filterNew,
      filterLiked: configuration.filterLiked,
      filterPlayed: configuration.filterPlayed,
      filterDownloaded: configuration.filterDownloaded,
      filterDuplicateVersions: configuration.filterDisplayVersion,
    );
  }

  @override
  List<Object?> get props => [
    podcastIds,
    excludedFeedIds,
    episodeIds,
    excludedEpisodeIds,
    episodeUrls,
    excludedEpisodeUrls,
    episodeTitles,
    excludedEpisodeTitles,
    likeEpisodeTitles,
    excludedLikeEpisodeTitles,
    sortBy,
    sortOrder,
    rangeParameters,
    rangeDelimiters,
    limit,
    offset,
    filterNew,
    filterLiked,
    filterPlayed,
    filterDownloaded,
    filterDuplicateVersions,
    filterAutoDownload,
    filterInteracted,
    customFilters,
    customArguments,
  ];
}
