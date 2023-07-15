import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:tsacdop/local_storage/sqflite_localpodcast.dart';
import '../util/extension_helper.dart';

class EpisodeBrief extends Equatable {
  final String id;
  final String title;
  final String enclosureUrl;
  final String podcastId;
  final String podcastTitle;
  final int pubDate;

  final String? description;
  final int? enclosureDuration;
  final int? enclosureSize;
  final bool? downloaded;
  final int? downloadDate;
  final String? mediaId;
  final String? episodeImage;
  final String? podcastImage; // Unused?
  final String? primaryColor;
  final bool? isExplicit;
  final bool? isLiked;
  final bool? isNew;
  final bool? isPlayed;
  final VersionInfo? versionInfo;
  final int? skipSecondsStart;
  final int? skipSecondsEnd;
  final String? chapterLink;

  EpisodeBrief(this.id, this.title, this.enclosureUrl, this.podcastId,
      this.podcastTitle, this.pubDate,
      {this.description,
      this.enclosureDuration,
      this.enclosureSize,
      this.downloaded,
      this.downloadDate,
      this.mediaId,
      this.episodeImage,
      this.podcastImage,
      this.primaryColor,
      this.isExplicit,
      this.isLiked,
      this.isNew,
      this.isPlayed,
      this.versionInfo,
      this.skipSecondsStart,
      this.skipSecondsEnd,
      this.chapterLink});

  MediaItem toMediaItem() {
    return MediaItem(
        id: mediaId!,
        title: title!,
        artist: podcastTitle,
        album: podcastTitle,
        duration: Duration.zero,
        artUri: Uri.parse(
            podcastImage == '' ? episodeImage! : 'file://$podcastImage'),
        extras: {
          'skipSecondsStart': skipSecondsStart,
          'skipSecondsEnd': skipSecondsEnd
        });
  }

  ImageProvider get avatarImage {
    return File(podcastImage!).existsSync()
        ? FileImage(File(podcastImage!))
        : File(episodeImage!).existsSync()
            ? FileImage(File(episodeImage!))
            : ((episodeImage != '')
                    ? CachedNetworkImageProvider(episodeImage!)
                    : AssetImage('assets/avatar_backup.png'))
                as ImageProvider<Object>;
  }

  Color backgroudColor(BuildContext context) {
    if (primaryColor == '') return context.accentColor;
    return context.brightness == Brightness.light
        ? primaryColor!.colorizedark()
        : primaryColor!.colorizeLight();
  }

  Color cardColor(BuildContext context) {
    final schema = ColorScheme.fromSeed(
      seedColor: primaryColor!.colorizedark(),
      brightness: context.brightness,
    );
    return schema.primaryContainer;
  }

  EpisodeBrief copyWith(
          {String? id,
          String? title,
          String? enclosureUrl,
          String? podcastId,
          String? podcastTitle,
          int? pubDate,
          String? description,
          int? enclosureDuration,
          int? enclosureSize,
          bool? downloaded,
          int? downloadDate,
          String? mediaId,
          String? episodeImage,
          String? podcastImage,
          String? primaryColor,
          bool? isExplicit,
          bool? isLiked,
          bool? isNew,
          bool? isPlayed,
          VersionInfo? versionInfo,
          int? skipSecondsStart,
          int? skipSecondsEnd,
          String? chapterLink}) =>
      EpisodeBrief(
          id ?? this.id,
          title ?? this.title,
          enclosureUrl ?? this.enclosureUrl,
          podcastId ?? this.podcastId,
          podcastTitle ?? this.podcastTitle,
          pubDate ?? this.pubDate,
          description: description ?? this.description,
          enclosureDuration: enclosureDuration ?? this.enclosureDuration,
          enclosureSize: enclosureSize ?? this.enclosureSize,
          downloaded: downloaded ?? this.downloaded,
          downloadDate: downloadDate ?? this.downloadDate,
          mediaId: mediaId ?? this.mediaId,
          episodeImage: episodeImage ?? this.episodeImage,
          podcastImage: podcastImage ?? this.podcastImage,
          primaryColor: primaryColor ?? this.primaryColor,
          isExplicit: isExplicit ?? this.isExplicit,
          isLiked: isLiked ?? this.isLiked,
          isNew: isNew ?? this.isNew,
          isPlayed: isPlayed ?? this.isPlayed,
          versionInfo: versionInfo ?? this.versionInfo,
          skipSecondsStart: skipSecondsStart ?? this.skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd ?? this.skipSecondsEnd,
          chapterLink: chapterLink ?? this.chapterLink);

  @override
  List<Object?> get props => [id];
}
