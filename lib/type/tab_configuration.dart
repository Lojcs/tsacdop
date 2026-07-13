// ignore_for_file: avoid_init_to_null

import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../widgets/episodegrid.dart';
import 'podcastbrief.dart';
import 'podcastgroup.dart';

/// Persistable configuration settings for an action bar
class ActionBarConfiguration extends Equatable {
  /// Default podcast group
  final String groupId;

  /// Default podcast
  final String podcastId;

  /// Default sorter
  final Sorter sortBy;

  /// Default filter new
  final bool? filterNew;

  /// Default filter liked
  final bool? filterLiked;

  /// Default filter played
  final bool? filterPlayed;

  /// Default filter downloaded
  final bool? filterDownloaded;

  /// Default filter display version
  final bool? filterDisplayVersion;

  /// Default sort order
  final SortOrder sortOrder;

  /// Default layout
  final EpisodeGridLayout layout;

  /// Title to search with.
  final String? searchTitleQuery;

  const ActionBarConfiguration({
    this.groupId = allGroupId,
    this.podcastId = podcastAllId,
    this.sortBy = Sorter.pubDate,
    this.filterNew = null,
    this.filterLiked = null,
    this.filterPlayed = null,
    this.filterDownloaded = null,
    this.filterDisplayVersion = false,
    this.searchTitleQuery = null,
    this.sortOrder = SortOrder.desc,
    this.layout = EpisodeGridLayout.medium,
  });

  factory ActionBarConfiguration.fromSerial(String source) {
    final jmap = json.decode(source);
    return ActionBarConfiguration(
      groupId: jmap['groupId'],
      podcastId: jmap['podcastId'],
      sortBy: Sorter.fromSerial(jmap['sortBy']),
      filterNew: jmap['filterNew'],
      filterLiked: jmap['filterLiked'],
      filterPlayed: jmap['filterPlayed'],
      filterDownloaded: jmap['filterDownloaded'],
      filterDisplayVersion: jmap['filterDisplayVersion'],
      searchTitleQuery: jmap['searchTitleQuery'],
      sortOrder: SortOrder.fromSerial(jmap['sortOrder']),
      layout: EpisodeGridLayout.fromSerial(jmap['layout']),
    );
  }

  String toSerial() => json.encode({
    'groupId': groupId,
    'podcastId': podcastId,
    'sortBy': sortBy.serial,
    'filterNew': filterNew,
    'filterLiked': filterLiked,
    'filterPlayed': filterPlayed,
    'filterDownloaded': filterDownloaded,
    'filterDisplayVersion': filterDisplayVersion,
    'searchTitleQuery': searchTitleQuery,
    'sortOrder': sortOrder.serial,
    'layout': layout.serial,
  });

  ActionBarConfiguration copyWith({String? groupId, String? podcastId}) =>
      ActionBarConfiguration(
        groupId: groupId ?? this.groupId,
        podcastId: podcastId ?? this.podcastId,
        sortBy: sortBy,
        filterNew: filterNew,
        filterLiked: filterLiked,
        filterPlayed: filterPlayed,
        filterDownloaded: filterDownloaded,
        filterDisplayVersion: filterDisplayVersion,
        searchTitleQuery: searchTitleQuery,
        sortOrder: sortOrder,
        layout: layout,
      );

  @override
  List<Object?> get props => [
    groupId,
    podcastId,
    sortBy,
    filterNew,
    filterLiked,
    filterPlayed,
    filterDownloaded,
    filterDisplayVersion,
    searchTitleQuery,
    sortOrder,
    layout,
  ];
}

/// Configuration of a home screen tab.
class HomeTabConfiguration extends Equatable {
  final String name;
  final ActionBarConfiguration actionBarConfiguration;

  const HomeTabConfiguration({
    required this.name,
    required this.actionBarConfiguration,
  });

  factory HomeTabConfiguration.fromSerial(String source) {
    final jmap = json.decode(source);
    return HomeTabConfiguration(
      name: jmap["name"],
      actionBarConfiguration: ActionBarConfiguration.fromSerial(
        jmap["actionBarConfiguration"],
      ),
    );
  }

  String toSerial() => json.encode({
    "name": name,
    "actionBarConfiguration": actionBarConfiguration.toSerial(),
  });

  HomeTabConfiguration copyWith({
    String? name,
    ActionBarConfiguration? actionBarConfiguration,
  }) => HomeTabConfiguration(
    name: name ?? this.name,
    actionBarConfiguration:
        actionBarConfiguration ?? this.actionBarConfiguration,
  );

  @override
  List<Object?> get props => [name, actionBarConfiguration];
}
