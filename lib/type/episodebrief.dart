import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:tsacdop/local_storage/sqflite_localpodcast.dart';
import '../util/extension_helper.dart';

class EpisodeBrief extends Equatable {
  final int id;
  final String title;
  final String enclosureUrl;
  final String podcastId;
  final String podcastTitle;
  final int pubDate;

  final String? description;
  final int? number;
  final int? enclosureDuration;
  final int? enclosureSize;
  final bool? isDownloaded;
  final int? downloadDate;
  final String? mediaId;
  final String? episodeImage;
  final String? podcastImage;
  final String? primaryColor;
  final bool? isExplicit;
  final bool? isLiked;
  final bool? isNew;
  final bool? isPlayed;
  final VersionInfo? versionInfo;
  final Map<int, EpisodeBrief?>? versions;
  final int skipSecondsStart;
  final int skipSecondsEnd;
  final String? chapterLink;

  EpisodeBrief(this.id, this.title, this.enclosureUrl, this.podcastId,
      this.podcastTitle, this.pubDate,
      {this.description,
      this.number,
      this.enclosureDuration,
      this.enclosureSize,
      this.isDownloaded,
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
      this.versions, // Could auto polpulate maybe
      this.skipSecondsStart = 0,
      this.skipSecondsEnd = 0,
      this.chapterLink});

  late final MediaItem mediaItem = MediaItem(
      id: mediaId!,
      title: title,
      artist: podcastTitle,
      album: podcastTitle,
      duration: enclosureDuration != null
          ? Duration(seconds: enclosureDuration!)
          : Duration.zero,
      artUri: Uri.parse(
          episodeImage != '' ? episodeImage! : 'file://$podcastImage'),
      extras: {
        'skipSecondsStart': skipSecondsStart,
        'skipSecondsEnd': skipSecondsEnd
      });

  ImageProvider get avatarImage {
    // TODO: Get rid of this
    if (podcastImage != null) {
      if (File(podcastImage!).existsSync()) {
        return FileImage(File(podcastImage!));
      }
    } else if (episodeImage != null) {
      if (File(episodeImage!).existsSync()) {
        return FileImage(File(episodeImage!));
      } else if (episodeImage != '') {
        return CachedNetworkImageProvider(episodeImage!);
      }
    }
    return AssetImage('assets/avatar_backup.png');
  }

  late final ImageProvider episodeImageProvider = ((episodeImage != null)
      ? (File(episodeImage!).existsSync())
          ? FileImage(File(episodeImage!))
          : (episodeImage != '')
              ? CachedNetworkImageProvider(episodeImage!)
              : const AssetImage('assets/avatar_backup.png')
      : const AssetImage('assets/avatar_backup.png')) as ImageProvider;

  late final ImageProvider podcastImageProvider = ((podcastImage != null)
      ? (File(podcastImage!).existsSync())
          ? FileImage(File(podcastImage!))
          : const AssetImage('assets/avatar_backup.png')
      : const AssetImage('assets/avatar_backup.png')) as ImageProvider;

  late final ImageProvider
      episodeOrPodcastImageProvider = // TODO: Control internet usage
      episodeImageProvider != const AssetImage('assets/avatar_backup.png')
          ? episodeImageProvider
          : podcastImageProvider;

  Color backgroudColor(BuildContext context) {
    return getColorScheme(context).onSecondaryContainer;
  }

  Color cardColor(BuildContext context) {
    return getColorScheme(context).secondaryContainer;
  }

  late final ColorScheme colorSchemeLight = ColorScheme.fromSeed(
    seedColor: primaryColor!.toColor(),
    brightness: Brightness.light,
  );
  late final ColorScheme colorSchemeDark = ColorScheme.fromSeed(
    seedColor: primaryColor!.toColor(),
    brightness: Brightness.dark,
  );

  /// Gets the episode color sceme for the provided [context].brightness.
  /// Caches its results so can be used freely.
  ColorScheme getColorScheme(BuildContext context) {
    return context.brightness == Brightness.light
        ? colorSchemeLight
        : colorSchemeDark;
  }

  /// The list of filled fields in the form of [EpisodeField]s.
  late final List<EpisodeField> fields = _getfields();

  dynamic _getFieldValue(EpisodeField episodeField) {
    switch (episodeField) {
      case EpisodeField.description:
        return description;
      case EpisodeField.number:
        return number;
      case EpisodeField.enclosureDuration:
        return enclosureDuration;
      case EpisodeField.enclosureSize:
        return enclosureSize;
      case EpisodeField.isDownloaded:
        return isDownloaded;
      case EpisodeField.downloadDate:
        return downloadDate;
      case EpisodeField.mediaId:
        return mediaId;
      case EpisodeField.episodeImage:
        return episodeImage;
      case EpisodeField.podcastImage:
        return podcastImage;
      case EpisodeField.primaryColor:
        return primaryColor;
      case EpisodeField.isExplicit:
        return isExplicit;
      case EpisodeField.isLiked:
        return isLiked;
      case EpisodeField.isNew:
        return isNew;
      case EpisodeField.isPlayed:
        return isPlayed;
      case EpisodeField.versionInfo:
        return versionInfo;
      case EpisodeField.versions:
        return versions;
      case EpisodeField.versionsPopulated:
        return null;
      case EpisodeField.skipSecondsStart:
        return skipSecondsStart;
      case EpisodeField.skipSecondsEnd:
        return skipSecondsEnd;
      case EpisodeField.chapterLink:
        return chapterLink;
    }
  }

  List<EpisodeField> _getfields() {
    List<EpisodeField> fieldList = [];
    for (EpisodeField field in EpisodeField.values) {
      if (_getFieldValue(field) != null) fieldList.add(field);
    }
    if (versions != null) {
      if (versions!.length == 0) {
        fieldList.add(EpisodeField.versionsPopulated);
      } else if (versions!.values.first != null) {
        fieldList.add(EpisodeField.versionsPopulated);
      }
    }
    return fieldList;
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
          String? primaryColor,
          bool? isExplicit,
          bool? isLiked,
          bool? isNew,
          bool? isPlayed,
          VersionInfo? versionInfo,
          Map<int, EpisodeBrief?>? versions,
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
          versionInfo: versionInfo ?? this.versionInfo,
          versions: versions ?? this.versions,
          skipSecondsStart: skipSecondsStart ?? this.skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd ?? this.skipSecondsEnd,
          chapterLink: chapterLink ?? this.chapterLink);

  /// Returns a copy with the [newFields] filled from the database.
  /// [keepExisting] disables overwriting already existing fields.
  /// [update] refetches all already existing fields from database.
  Future<EpisodeBrief> copyWithFromDB(
      {List<EpisodeField>? newFields,
      bool keepExisting = false,
      bool update = false}) async {
    assert(newFields != null || update,
        "If update is false newFields can't be null.");
    assert(!keepExisting || !update,
        "Can't both update and keep existing fields.");
    Map<EpisodeField, List> _fieldsMap = {
      // I'm so sorry this is so ugly
      EpisodeField.description: [const Symbol("description"), description],
      EpisodeField.number: [const Symbol("number"), number],
      EpisodeField.enclosureDuration: [
        const Symbol("enclosureDuration"),
        enclosureDuration
      ],
      EpisodeField.enclosureSize: [
        const Symbol("enclosureSize"),
        enclosureSize
      ],
      EpisodeField.isDownloaded: [const Symbol("isDownloaded"), isDownloaded],
      EpisodeField.downloadDate: [const Symbol("downloadDate"), downloadDate],
      EpisodeField.mediaId: [const Symbol("mediaId"), mediaId],
      EpisodeField.episodeImage: [const Symbol("episodeImage"), episodeImage],
      EpisodeField.podcastImage: [const Symbol("podcastImage"), podcastImage],
      EpisodeField.primaryColor: [const Symbol("primaryColor"), primaryColor],
      EpisodeField.isExplicit: [const Symbol("isExplicit"), isExplicit],
      EpisodeField.isLiked: [const Symbol("isLiked"), isLiked],
      EpisodeField.isNew: [const Symbol("isNew"), isNew],
      EpisodeField.isPlayed: [const Symbol("isPlayed"), isPlayed],
      EpisodeField.versionInfo: [const Symbol("versionInfo"), versionInfo],
      EpisodeField.versions: [const Symbol("versions"), versions],
      EpisodeField.skipSecondsStart: [
        const Symbol("skipSecondsStart"),
        skipSecondsStart
      ],
      EpisodeField.skipSecondsEnd: [
        const Symbol("skipSecondsEnd"),
        skipSecondsEnd
      ],
      EpisodeField.chapterLink: [const Symbol("chapterLink"), chapterLink]
    };

    var dbHelper = DBHelper();
    if (newFields == null) {
      newFields = [];
    }
    if (update) {
      newFields.addAll(this.fields);
    }
    Map<Symbol, dynamic> oldFieldsSymbolMap = {};
    List<EpisodeField> oldFields = this.fields.toList();
    if (keepExisting) {
      for (EpisodeField field in oldFields) {
        newFields.remove(field);
      }
    } else {
      for (EpisodeField field in newFields) {
        oldFields.remove(field);
      }
    }
    bool populateVersions = newFields.remove(EpisodeField.versionsPopulated);
    EpisodeBrief newEpisode;
    if (newFields.isEmpty) {
      newEpisode = this.copyWith();
    } else {
      for (EpisodeField field in oldFields) {
        oldFieldsSymbolMap[_fieldsMap[field]![0]] = _fieldsMap[field]![1];
      }
      newEpisode = (await dbHelper
              .getEpisodes(episodeIds: [id], optionalFields: newFields))
          .first;
      newEpisode = Function.apply(newEpisode.copyWith, [], oldFieldsSymbolMap);
    }
    if (populateVersions) {
      newEpisode = await dbHelper.populateEpisodeVersions(newEpisode);
    }
    return newEpisode;
  }

  @override
  List<Object?> get props => [id, enclosureUrl];
}
