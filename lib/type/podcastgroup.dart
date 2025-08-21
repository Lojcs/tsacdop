import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../util/extension_helper.dart';

const homeGroupId = "1dd67d78-a22b-45c5-95c2-ed4a84a955ef";
const allGroupId = "13541601-2ad5-4ab1-b919-3142a195c7c3";

class SuperPodcastGroup extends Equatable {
  /// Group uuid.
  final String id;

  /// Group name.
  final String name;

  /// Group theme color, not used.
  final Color color;

  /// Id lists of podcasts in group.
  final List<String> podcastIds;

  SuperPodcastGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.podcastIds,
  });

  SuperPodcastGroup.create({
    String? id,
    required this.name,
    this.color = Colors.teal,
    this.podcastIds = const [],
  }) : id = id ?? Uuid().v4();

  Map<String, Object?> toJson() => {
        'name': name,
        'id': id,
        'color': color.torgbString(),
        'podcastList': podcastIds
      };

  SuperPodcastGroup.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        color = Color(int.parse('FF${(json['color'] as String).toUpperCase()}',
            radix: 16)),
        podcastIds = List<String>.from(json['podcastList'] as List<dynamic>);

  SuperPodcastGroup copyWith(
          {String? id, String? name, Color? color, List<String>? podcastIds}) =>
      SuperPodcastGroup(
          id: id ?? this.id,
          name: name ?? this.name,
          color: color ?? this.color,
          podcastIds: podcastIds ?? this.podcastIds);

  /// Add [podcastId] to group. -1 adds to the end.
  void addToGroup(String podcastId, {int index = -1}) {
    if (!podcastIds.contains(podcastId)) {
      if (index == -1) {
        podcastIds.add(podcastId);
      } else {
        podcastIds.insert(index, podcastId);
      }
    }
  }

  void removeFromGroup(String podcastId) => podcastIds.remove(podcastId);

  void reorderGroup(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final podcast = podcastIds.removeAt(oldIndex);
    podcastIds.insert(newIndex, podcast);
  }

  late final MediaItem mediaItem =
      MediaItem(id: "grp:$id", title: name, playable: false);

  @override
  List<Object?> get props => [id, name];
}
