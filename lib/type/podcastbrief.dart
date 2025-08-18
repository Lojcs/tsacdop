import 'dart:io';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:color_thief_dart/color_thief_dart.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:webfeed/webfeed.dart';

import '../generated/l10n.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/podcast_group.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import 'fireside_data.dart';
import 'theme_data.dart';

enum DataSource {
  database, // Persistent from database
  user, // Temp from user
  remote, // Temp from rss feed
}

class PodcastBrief extends Equatable {
  final String id;
  final String title;
  final String rssUrl;
  final String rssHash;

  final String author;
  final String provider;
  final List<PodcastHost> firesideHosts;
  final String description;
  final String webpage;
  final List<String> funding;

  final String imageUrl;
  final String imagePath;
  final String firesideBackgroundImage;
  final Color primaryColor;

  /// Number of episodes added in the last sync
  final int syncEpisodeCount;
  final int episodeCount;

  /// True: mark new episodes as new, False: don't mark
  final bool hideNewMark;

  /// True: don't auto sync, False: auto sync according to global setting
  final bool noAutoSync;

  /// True: auto download new episodes, False: don't auto download
  final bool autoDownload;
  final int skipSecondsStart;
  final int skipSecondsEnd;

  final DataSource source;

  PodcastBrief({
    required this.id,
    required this.title,
    required this.rssUrl,
    this.rssHash = "",
    required this.author,
    required this.provider,
    this.firesideHosts = const [],
    required this.description,
    required this.webpage,
    required this.funding,
    required this.imageUrl,
    required this.imagePath,
    this.firesideBackgroundImage = "",
    required this.primaryColor,
    required this.syncEpisodeCount,
    required this.episodeCount,
    required this.hideNewMark,
    required this.noAutoSync,
    required this.autoDownload,
    this.skipSecondsStart = 0,
    this.skipSecondsEnd = 0,
    this.source = DataSource.database,
  });

  /// Black local folder podcast object.
  PodcastBrief.localFolder(S s, Directory applicationDocumentsDirectory,
      {String? id, String? title, String? description})
      : id = id ?? localFolderId,
        title = title ?? s.localFolder,
        rssUrl = "",
        rssHash = "",
        author = s.deviceStorage,
        provider = "",
        firesideHosts = [],
        description = description ?? s.localFolderDescription,
        webpage = "",
        funding = [],
        imageUrl = "",
        imagePath =
            "${applicationDocumentsDirectory.path}/assets/avatar_backup.png",
        firesideBackgroundImage = "",
        primaryColor = Colors.teal,
        syncEpisodeCount = 0,
        episodeCount = 0,
        hideNewMark = true,
        noAutoSync = true,
        autoDownload = false,
        skipSecondsStart = 0,
        skipSecondsEnd = 0,
        source = DataSource.user;

  /// Construct a [PodcastBrief] from an [RssFeed].
  /// This is callable from a background isolate, and so doesn't parse its color.
  /// Use [withColorFromImage] to fill the correct color.
  PodcastBrief.fromFeed(RssFeed feed, this.rssUrl, this.rssHash)
      : id = Uuid().v4(),
        title = feed.title ?? feed.itunes?.title ?? "",
        author = feed.author ?? feed.itunes?.author ?? "",
        provider = feed.generator ?? "",
        firesideHosts = [],
        description = feed.description ??
            feed.itunes?.summary ??
            feed.itunes?.subtitle ??
            "",
        webpage = feed.link ?? "",
        funding = [for (var f in (feed.podcastFunding ?? [])) f.url],
        imageUrl = feed.image?.url ??
            feed.itunes?.image?.href ??
            "https://ui-avatars.com/api/?size=300&background="
                "${avatarColors[math.Random().nextInt(3)]}"
                "&color=fff&name=${feed.title}&length=2&bold=true",
        imagePath = "",
        firesideBackgroundImage = "",
        primaryColor = Colors.teal,
        syncEpisodeCount = 0,
        episodeCount = feed.items?.length ?? 0,
        hideNewMark = false,
        noAutoSync = false,
        autoDownload = false,
        skipSecondsStart = 0,
        skipSecondsEnd = 0,
        source = DataSource.remote;

  /// Returns a copy with the [primaryColor] replaced with a color derived from
  /// [imagePath] or [imageUrl].
  Future<PodcastBrief> withColorFromImage() async {
    ImageProvider imageProvider;
    if (imagePath != "") {
      imageProvider = FileImage(File(imagePath));
    } else {
      imageProvider = NetworkImage(imageUrl);
    }
    final image = await getImageFromProvider(imageProvider);
    final colorString = (await getColorFromImage(image)).toString();
    final color = colorString.toColor();
    return copyWith(primaryColor: color);
  }

  ImageProvider get avatarImage {
    // TODO: Get rid of this
    return (File(imagePath).existsSync()
            ? FileImage(File(imagePath))
            : const AssetImage('assets/avatar_backup.png'))
        as ImageProvider<Object>;
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

  /// Gets the podcast color sceme for the provided [context].brightness.
  /// Caches its results so can be used freely.
  ColorScheme colorScheme(BuildContext context) {
    return context.brightness == Brightness.light
        ? colorSchemeLight
        : colorSchemeDark;
  }

  /// Gets the podcast card color sceme for the provided [context].brightness.
  /// Caches its results so can be used freely.
  CardColorScheme cardColorScheme(BuildContext context) {
    return context.brightness == Brightness.light
        ? cardColorSchemeLight
        : cardColorSchemeDark;
  }

  Color backgroudColor(BuildContext context) {
    return cardColorScheme(context).saturated;
    // return context.brightness == Brightness.light
    //     ? primaryColor.colorizedark()
    //     : primaryColor.colorizeLight();
  }

  PodcastBrief copyWith({
    String? id,
    String? title,
    String? rssUrl,
    String? rssHash,
    String? author,
    String? provider,
    List<PodcastHost>? firesideHosts,
    String? description,
    String? webpage,
    List<String>? funding,
    String? imageUrl,
    String? imagePath,
    String? firesideBackgroundImage,
    Color? primaryColor,
    int? syncEpisodeCount,
    int? episodeCount,
    bool? hideNewMark,
    bool? noAutoSync,
    bool? autoDownload,
    int? skipSecondsStart,
    int? skipSecondsEnd,
    DataSource? source,
  }) =>
      PodcastBrief(
          id: id ?? this.id,
          title: title ?? this.title,
          rssUrl: rssUrl ?? this.rssUrl,
          rssHash: rssHash ?? this.rssHash,
          author: author ?? this.author,
          provider: provider ?? this.provider,
          firesideHosts: firesideHosts ?? this.firesideHosts,
          description: description ?? this.description,
          webpage: webpage ?? this.webpage,
          funding: funding ?? this.funding,
          imageUrl: imageUrl ?? this.imageUrl,
          imagePath: imagePath ?? this.imagePath,
          firesideBackgroundImage:
              firesideBackgroundImage ?? this.firesideBackgroundImage,
          primaryColor: primaryColor ?? this.primaryColor,
          syncEpisodeCount: syncEpisodeCount ?? this.syncEpisodeCount,
          episodeCount: episodeCount ?? this.episodeCount,
          hideNewMark: hideNewMark ?? this.hideNewMark,
          noAutoSync: noAutoSync ?? this.noAutoSync,
          autoDownload: autoDownload ?? this.autoDownload,
          skipSecondsStart: skipSecondsStart ?? this.skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd ?? this.skipSecondsEnd,
          source: source ?? this.source);

  MediaItem get mediaItem =>
      MediaItem(id: "pod:$id", title: title, playable: false);

  @override
  List<Object?> get props => [id, rssUrl];
}
