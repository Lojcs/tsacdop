import 'dart:io';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:webfeed/webfeed.dart';

import '../state/podcast_group.dart';
import '../util/extension_helper.dart';

enum PodcastSource { local, saved, remote }

class PodcastBrief extends Equatable {
  final String title;
  final String imageUrl;
  final String rssUrl;
  final String author;

  final String primaryColor;
  final String id;
  final String imagePath;
  final String provider;
  final String link;

  final String description;

  final int? updateCount;
  final int? episodeCount;

  final List<String> funding;

  final PodcastSource source;

  //set setUpdateCount(i) => updateCount = i;

  //set setEpisodeCount(i) => episodeCount = i;

  const PodcastBrief(
    this.title,
    this.imageUrl,
    this.rssUrl,
    this.primaryColor,
    this.author,
    this.id,
    this.imagePath,
    this.provider,
    this.link,
    this.funding, {
    this.description = '',
    this.updateCount = 0,
    this.episodeCount = 0,
    this.source = PodcastSource.saved,
  });

  PodcastBrief.fromFeed(RssFeed feed, this.rssUrl)
      : title = feed.title ?? "",
        imageUrl = feed.image?.url ??
            feed.itunes?.image?.href ??
            "https://ui-avatars.com/api/?size=300&background="
                "${avatarColors[math.Random().nextInt(3)]}"
                "&color=fff&name=${feed.title}&length=2&bold=true",
        primaryColor = "",
        author = feed.author ?? feed.itunes?.author ?? "",
        id = Uuid().v4(),
        imagePath = "",
        provider = feed.generator ?? "",
        link = feed.link ?? "",
        funding = [for (var f in (feed.podcastFunding ?? [])) f.url],
        description = feed.description ??
            feed.itunes?.summary ??
            feed.itunes?.subtitle ??
            "",
        updateCount = 0,
        episodeCount = feed.items?.length ?? 0,
        source = PodcastSource.remote;

  ImageProvider get avatarImage {
    return (File(imagePath!).existsSync()
            ? FileImage(File(imagePath!))
            : const AssetImage('assets/avatar_backup.png'))
        as ImageProvider<Object>;
  }

  Color backgroudColor(BuildContext context) {
    return context.brightness == Brightness.light
        ? primaryColor!.colorizedark()
        : primaryColor!.colorizeLight();
  }

  Color cardColor(BuildContext context) {
    return ColorScheme.fromSeed(
      seedColor: primaryColor!.toColor(),
      brightness: context.brightness,
    ).secondaryContainer;
  }

  PodcastBrief copyWith(
      {String? primaryColor,
      int? updateCount,
      int? episodeCount,
      PodcastSource? source}) {
    return PodcastBrief(
        title,
        imageUrl,
        rssUrl,
        primaryColor ?? this.primaryColor,
        author,
        id,
        imagePath,
        provider,
        link,
        funding,
        description: description,
        updateCount: updateCount ?? this.updateCount,
        episodeCount: episodeCount ?? this.episodeCount,
        source: source ?? this.source);
  }

  MediaItem get mediaItem =>
      MediaItem(id: "pod:$id", title: title, playable: false);

  @override
  List<Object?> get props => [id, rssUrl];
}
