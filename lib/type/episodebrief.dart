import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../local_storage/sqflite_localpodcast.dart';
import 'theme_data.dart';
import '../util/extension_helper.dart';

class EpisodeBrief extends Equatable {
  final int id;
  final String title;
  final String enclosureUrl;
  final String podcastId;
  final String podcastTitle;
  final int pubDate;

  final String description;
  final int number;
  final int enclosureDuration;
  final int enclosureSize;
  final bool isDownloaded;
  final int downloadDate;
  final String mediaId;
  final String episodeImage;
  final String podcastImage;
  final Color primaryColor;
  final bool isExplicit;
  final bool isLiked;
  final bool isNew;
  final bool isPlayed;
  final bool isDisplayVersion;
  final List<int>? versions;
  final int skipSecondsStart;
  final int skipSecondsEnd;
  final String chapterLink;

  EpisodeBrief({
    required this.id,
    required this.title,
    required this.enclosureUrl,
    required this.podcastId,
    required this.podcastTitle,
    required this.pubDate,
    required this.description,
    required this.number,
    required this.enclosureDuration,
    required this.enclosureSize,
    required this.isDownloaded,
    required this.downloadDate,
    required this.mediaId,
    required this.episodeImage,
    required this.podcastImage,
    required this.primaryColor,
    required this.isExplicit,
    required this.isLiked,
    required this.isNew,
    required this.isPlayed,
    required this.isDisplayVersion,
    this.versions,
    this.skipSecondsStart = 0,
    this.skipSecondsEnd = 0,
    required this.chapterLink,
  });

  /// Use for new local episodes not yet in database
  EpisodeBrief.local({
    required this.title,
    required this.enclosureUrl,
    String? podcastTitle,
    required this.pubDate,
    required this.description,
    required this.enclosureDuration,
    required this.enclosureSize,
    required this.mediaId,
    required this.episodeImage,
    Color? primaryColor,
  })  : id = -1,
        podcastId = localFolderId,
        podcastTitle = podcastTitle ?? 'Local Folder',
        number = -1,
        isDownloaded = true,
        downloadDate = pubDate,
        podcastImage = '',
        primaryColor = primaryColor ?? Colors.teal,
        isExplicit = false,
        isLiked = false,
        isNew = false,
        isPlayed = false,
        isDisplayVersion = true,
        versions = null,
        skipSecondsStart = 0,
        skipSecondsEnd = 0,
        chapterLink = '';

  late final MediaItem mediaItem = MediaItem(
      id: mediaId,
      title: title,
      artist: podcastTitle,
      album: podcastTitle,
      duration: Duration(seconds: enclosureDuration),
      artUri: Uri.parse('file://$podcastImage'),
      // artUri:
      //     Uri.parse(episodeImage != '' ? episodeImage : 'file://$podcastImage'),
      extras: {
        'skipSecondsStart': skipSecondsStart,
        'skipSecondsEnd': skipSecondsEnd
      });

  ImageProvider get avatarImage {
    // TODO: Get rid of this
    if (podcastImage != '') {
      if (File(podcastImage).existsSync()) {
        return FileImage(File(podcastImage));
      }
    } else if (episodeImage != '') {
      if (File(episodeImage).existsSync()) {
        return FileImage(File(episodeImage));
      } else if (episodeImage != '') {
        return CachedNetworkImageProvider(episodeImage);
      }
    }
    return AssetImage('assets/avatar_backup.png');
  }

  late final ImageProvider _episodeImageProvider = ((episodeImage != '')
      ? (File(episodeImage).existsSync())
          ? FileImage(File(episodeImage))
          : (episodeImage != '')
              ? CachedNetworkImageProvider(episodeImage)
              : const AssetImage('assets/avatar_backup.png')
      : const AssetImage('assets/avatar_backup.png')) as ImageProvider;

  late final ImageProvider podcastImageProvider = ((podcastImage != '')
      ? (File(podcastImage).existsSync())
          ? FileImage(File(podcastImage))
          : const AssetImage('assets/avatar_backup.png')
      : const AssetImage('assets/avatar_backup.png')) as ImageProvider;

  // late final ImageProvider
  //     episodeOrPodcastImageProvider = // TODO: Control internet usage
  //     _episodeImageProvider != const AssetImage('assets/avatar_backup.png')
  //         ? _episodeImageProvider
  //         : podcastImageProvider;

  // Until episode image caching is implemented don't use episode images
  late final ImageProvider episodeOrPodcastImageProvider = podcastImageProvider;

  Color backgroudColor(BuildContext context) {
    return colorScheme(context).onSecondaryContainer;
  }

  /// Convenience method to get the card color for current theme
  Color cardColor(BuildContext context) {
    return context.realDark
        ? context.surface
        : context.brightness == Brightness.light
            ? cardColorSchemeLight.card
            : cardColorSchemeDark.card;
  }

  /// Convenience method to get the selected card color for current theme
  Color selectedCardColor(BuildContext context) {
    return context.realDark
        ? context.surface
        : context.brightness == Brightness.light
            ? cardColorSchemeLight.selected
            : cardColorSchemeDark.selected;
  }

  /// Convenience method to get the card shadow color for current theme
  Color cardShadowColor(BuildContext context) {
    return context.brightness == Brightness.light
        ? cardColorSchemeLight.shadow
        : cardColorSchemeDark.shadow;
  }

  /// Convenience method to get the card progress indicator color for current theme
  Color progressIndicatorColor(BuildContext context) {
    return context.realDark
        ? context.surface
        : context.brightness == Brightness.light
            ? cardColorSchemeLight.progress
            : cardColorSchemeDark.progress;
  }

  late final ColorScheme colorSchemeLight = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  );
  late final ColorScheme colorSchemeDark = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  );
  late final CardColorScheme cardColorSchemeLight =
      CardColorScheme(colorSchemeLight);
  late final CardColorScheme cardColorSchemeDark =
      CardColorScheme(colorSchemeDark);

  late final Color realDarkBorderColor =
      Color.lerp(colorSchemeDark.primary, Colors.black, 0.5)!;
  late final Color realDarkBorderColorSelected =
      Color.lerp(colorSchemeDark.primary, Colors.white, 0.5)!;

  /// Gets the episode color sceme for the provided [context].brightness.
  /// Caches its results so can be used freely.
  ColorScheme colorScheme(BuildContext context) {
    return context.brightness == Brightness.light
        ? colorSchemeLight
        : colorSchemeDark;
  }

  EpisodeBrief copyWith(
          {int? id,
          String? title,
          String? enclosureUrl,
          String? podcastId,
          String? podcastTitle,
          int? pubDate,
          String? description,
          int? number,
          int? enclosureDuration,
          int? enclosureSize,
          bool? isDownloaded,
          int? downloadDate,
          String? mediaId,
          String? episodeImage,
          String? podcastImage,
          Color? primaryColor,
          bool? isExplicit,
          bool? isLiked,
          bool? isNew,
          bool? isPlayed,
          bool? isDisplayVersion,
          List<int>? versions,
          int? skipSecondsStart,
          int? skipSecondsEnd,
          String? chapterLink}) =>
      EpisodeBrief(
          id: id ?? this.id,
          title: title ?? this.title,
          enclosureUrl: enclosureUrl ?? this.enclosureUrl,
          podcastId: podcastId ?? this.podcastId,
          podcastTitle: podcastTitle ?? this.podcastTitle,
          pubDate: pubDate ?? this.pubDate,
          description: description ?? this.description,
          number: number ?? this.number,
          enclosureDuration: enclosureDuration ?? this.enclosureDuration,
          enclosureSize: enclosureSize ?? this.enclosureSize,
          isDownloaded: isDownloaded ?? this.isDownloaded,
          downloadDate: downloadDate ?? this.downloadDate,
          mediaId: mediaId ?? this.mediaId,
          episodeImage: episodeImage ?? this.episodeImage,
          podcastImage: podcastImage ?? this.podcastImage,
          primaryColor: primaryColor ?? this.primaryColor,
          isExplicit: isExplicit ?? this.isExplicit,
          isLiked: isLiked ?? this.isLiked,
          isNew: isNew ?? this.isNew,
          isPlayed: isPlayed ?? this.isPlayed,
          isDisplayVersion: isDisplayVersion ?? this.isDisplayVersion,
          versions: versions ?? this.versions,
          skipSecondsStart: skipSecondsStart ?? this.skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd ?? this.skipSecondsEnd,
          chapterLink: chapterLink ?? this.chapterLink);

  @override
  List<Object?> get props => [id, enclosureUrl];
}
