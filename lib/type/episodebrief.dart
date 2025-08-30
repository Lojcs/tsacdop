import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import '../generated/l10n.dart';
import '../local_storage/sqflite_localpodcast.dart';
import 'podcastbrief.dart';
import 'theme_data.dart';
import '../util/extension_helper.dart';

String urlFromRssItem(RssItem item) =>
    item.enclosure != null && item.enclosure!.url != null
        ? (item.enclosure!.url!.isXimalaya()
            ? item.enclosure!.url!.split('=').last
            : item.enclosure!.url!)
        : "";

class EpisodeBrief extends Equatable {
  final int id;
  final String title;
  final String enclosureUrl;
  final String podcastId;
  final String podcastTitle;
  final int pubDate;

  final String showNotes;
  final int number;
  final int enclosureDuration;
  final int enclosureSize;
  final bool isDownloaded;
  final int downloadDate;
  final String mediaId;
  final String episodeImageUrl;
  final String podcastImagePath;
  final String _primaryColor;
  Color get primaryColor => _primaryColor.toargbColor();

  final bool isExplicit;
  final bool isLiked;
  final bool isNew;
  final bool isPlayed;
  final bool isDisplayVersion;
  final List<int>? versions;
  final int skipSecondsStart;
  final int skipSecondsEnd;
  final String chapterLink;

  final DataSource source;
  EpisodeBrief({
    required this.id,
    required this.title,
    required this.enclosureUrl,
    required this.podcastId,
    required this.podcastTitle,
    required this.pubDate,
    required this.showNotes,
    required this.number,
    required this.enclosureDuration,
    required this.enclosureSize,
    required this.isDownloaded,
    required this.downloadDate,
    required this.mediaId,
    required this.episodeImageUrl,
    required this.podcastImagePath,
    required Color primaryColor,
    required this.isExplicit,
    required this.isLiked,
    required this.isNew,
    required this.isPlayed,
    required this.isDisplayVersion,
    this.versions,
    this.skipSecondsStart = 0,
    this.skipSecondsEnd = 0,
    required this.chapterLink,
    required this.source,
  }) : _primaryColor = primaryColor.toargbString();

  /// Use for new user episodes not yet in database
  EpisodeBrief.user({
    required this.title,
    required this.enclosureUrl,
    String? podcastTitle,
    required this.pubDate,
    required this.showNotes,
    required this.enclosureDuration,
    required this.enclosureSize,
    required this.mediaId,
    this.episodeImageUrl = '',
    Color? primaryColor,
  })  : id = -1,
        podcastId = localFolderId,
        podcastTitle = podcastTitle ?? S.current.localFolder,
        number = -1,
        isDownloaded = true,
        downloadDate = pubDate,
        podcastImagePath = '',
        _primaryColor = (primaryColor ?? Colors.teal).toargbString(),
        isExplicit = false,
        isLiked = false,
        isNew = false,
        isPlayed = false,
        isDisplayVersion = true,
        versions = null,
        skipSecondsStart = 0,
        skipSecondsEnd = 0,
        chapterLink = '',
        source = DataSource.user;

  /// Use for new remote episodes not yet in database
  EpisodeBrief.fromRssItem(RssItem item, this.podcastId, this.podcastTitle,
      this.number, this.podcastImagePath, Color primaryColor)
      : id = -1,
        title = item.title ?? item.itunes?.title ?? "",
        enclosureUrl = urlFromRssItem(item),
        pubDate = item.pubDate?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        showNotes = [
          item.content?.value ?? "",
          item.description ?? "",
          item.itunes?.summary ?? ""
        ].reduce((s1, s2) => s1.length > s2.length ? s1 : s2),
        enclosureDuration = item.itunes?.duration?.inSeconds ?? 0,
        enclosureSize = item.enclosure?.length ?? 0,
        isDownloaded = false,
        downloadDate = 0,
        mediaId = item.enclosure != null && item.enclosure!.url != null
            ? (item.enclosure!.url!.isXimalaya()
                ? item.enclosure!.url!.split('=').last
                : item.enclosure!.url!)
            : "",
        episodeImageUrl = item.itunes?.image?.href ?? '',
        _primaryColor = primaryColor.toargbString(),
        isExplicit = item.itunes?.explicit ?? false,
        isLiked = false,
        isNew = DateTime.now().difference(item.pubDate ?? DateTime(0)) <
            Duration(days: 1),
        isPlayed = false,
        isDisplayVersion = true,
        versions = [],
        skipSecondsStart = 0,
        skipSecondsEnd = 0,
        chapterLink = item.podcastChapters?.url ?? '',
        source = DataSource.remote;

  late final MediaItem mediaItem = MediaItem(
      id: mediaId,
      title: title,
      isLive: !isDownloaded,
      artist: podcastTitle,
      album: podcastTitle,
      duration: Duration(seconds: enclosureDuration),
      // artUri: Uri.parse('file://$podcastImage'),
      // Andoid auto can't show local images
      artUri: Uri.parse(
          episodeImageUrl != '' ? episodeImageUrl : 'file://$podcastImagePath'),
      extras: {
        'skipSecondsStart': skipSecondsStart,
        'skipSecondsEnd': skipSecondsEnd
      });

  ImageProvider get avatarImage {
    // TODO: Get rid of this
    if (podcastImagePath != '') {
      if (File(podcastImagePath).existsSync()) {
        return FileImage(File(podcastImagePath));
      }
    } else if (episodeImageUrl != '') {
      if (File(episodeImageUrl).existsSync()) {
        return FileImage(File(episodeImageUrl));
      } else if (episodeImageUrl != '') {
        return CachedNetworkImageProvider(episodeImageUrl);
      }
    }
    return AssetImage('assets/avatar_backup.png');
  }

  late final ImageProvider _episodeImageProvider = ((episodeImageUrl != '')
      ? (File(episodeImageUrl).existsSync())
          ? FileImage(File(episodeImageUrl))
          : (episodeImageUrl != '')
              ? CachedNetworkImageProvider(episodeImageUrl)
              : const AssetImage('assets/avatar_backup.png')
      : const AssetImage('assets/avatar_backup.png')) as ImageProvider;

  late final ImageProvider podcastImageProvider = ((podcastImagePath != '')
      ? (File(podcastImagePath).existsSync())
          ? FileImage(File(podcastImagePath))
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
    return context.realDark ? context.surface : cardColorScheme(context).card;
  }

  /// Convenience method to get the selected card color for current theme
  Color selectedCardColor(BuildContext context) {
    return context.realDark
        ? context.surface
        : cardColorScheme(context).selected;
  }

  /// Convenience method to get the card shadow color for current theme
  Color cardShadowColor(BuildContext context) {
    return cardColorScheme(context).shadow;
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

  /// Gets the episode card color sceme for the provided [context].brightness.
  /// Caches its results so can be used freely.
  CardColorScheme cardColorScheme(BuildContext context) {
    return context.brightness == Brightness.light
        ? cardColorSchemeLight
        : cardColorSchemeDark;
  }

  EpisodeBrief copyWith(
          {int? id,
          String? title,
          String? enclosureUrl,
          String? podcastId,
          String? podcastTitle,
          int? pubDate,
          String? showNotes,
          int? number,
          int? enclosureDuration,
          int? enclosureSize,
          bool? isDownloaded,
          int? downloadDate,
          String? mediaId,
          String? episodeImageUrl,
          String? episodeImagePath,
          String? podcastImagePath,
          Color? primaryColor,
          bool? isExplicit,
          bool? isLiked,
          bool? isNew,
          bool? isPlayed,
          bool? isDisplayVersion,
          List<int>? versions,
          int? skipSecondsStart,
          int? skipSecondsEnd,
          String? chapterLink,
          DataSource? source}) =>
      EpisodeBrief(
          id: id ?? this.id,
          title: title ?? this.title,
          enclosureUrl: enclosureUrl ?? this.enclosureUrl,
          podcastId: podcastId ?? this.podcastId,
          podcastTitle: podcastTitle ?? this.podcastTitle,
          pubDate: pubDate ?? this.pubDate,
          showNotes: showNotes ?? this.showNotes,
          number: number ?? this.number,
          enclosureDuration: enclosureDuration ?? this.enclosureDuration,
          enclosureSize: enclosureSize ?? this.enclosureSize,
          isDownloaded: isDownloaded ?? this.isDownloaded,
          downloadDate: downloadDate ?? this.downloadDate,
          mediaId: mediaId ?? this.mediaId,
          episodeImageUrl: episodeImageUrl ?? this.episodeImageUrl,
          podcastImagePath: podcastImagePath ?? this.podcastImagePath,
          primaryColor: primaryColor ?? this.primaryColor,
          isExplicit: isExplicit ?? this.isExplicit,
          isLiked: isLiked ?? this.isLiked,
          isNew: isNew ?? this.isNew,
          isPlayed: isPlayed ?? this.isPlayed,
          isDisplayVersion: isDisplayVersion ?? this.isDisplayVersion,
          versions: versions ?? this.versions,
          skipSecondsStart: skipSecondsStart ?? this.skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd ?? this.skipSecondsEnd,
          chapterLink: chapterLink ?? this.chapterLink,
          source: source ?? this.source);

  @override
  List<Object?> get props => [id, enclosureUrl];
}
