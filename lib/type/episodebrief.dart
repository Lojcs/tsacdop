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
  final Map<int, EpisodeBrief?>? versions;
  final int skipSecondsStart;
  final int skipSecondsEnd;
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
      this.versions, // Could auto polpulate maybe
      this.skipSecondsStart = 0,
      this.skipSecondsEnd = 0,
      this.chapterLink});

  MediaItem toMediaItem() {
    return MediaItem(
        id: mediaId!,
        title: title,
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

  Color backgroudColor(BuildContext context) {
    return getColorScheme(context).onSecondaryContainer;
  }

  Color cardColor(BuildContext context) {
    return getColorScheme(context).secondaryContainer;
  }

  late final ColorScheme _colorSchemeLight = ColorScheme.fromSeed(
    seedColor: primaryColor!.toColor(),
    brightness: Brightness.light,
  );
  late final ColorScheme _colorSchemeDark = ColorScheme.fromSeed(
    seedColor: primaryColor!.toColor(),
    brightness: Brightness.dark,
  );
  ColorScheme getColorScheme(BuildContext context) {
    return context.brightness == Brightness.light
        ? _colorSchemeLight
        : _colorSchemeDark;
  }

  late final List<EpisodeField> fields = getfields();

  dynamic _getFieldValue(EpisodeField episodeField) {
    switch (episodeField) {
      case EpisodeField.description:
        return description;
      case EpisodeField.enclosureDuration:
        return enclosureDuration;
      case EpisodeField.enclosureSize:
        return enclosureSize;
      case EpisodeField.downloaded:
        return downloaded;
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
        return versions;
      case EpisodeField.skipSecondsStart:
        return skipSecondsStart;
      case EpisodeField.skipSecondsEnd:
        return skipSecondsEnd;
      case EpisodeField.chapterLink:
        return chapterLink;
    }
  }

  List<EpisodeField> getfields() {
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
          versions: versions ?? this.versions,
          skipSecondsStart: skipSecondsStart ?? this.skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd ?? this.skipSecondsEnd,
          chapterLink: chapterLink ?? this.chapterLink);

  /// Returns a copy with the [newFields] filled from the database.
  /// [keepExisting] disables overwriting existing fields.
  Future<EpisodeBrief> copyWithFromDB(List<EpisodeField> newFields,
      {bool keepExisting = false}) async {
    Map<EpisodeField, List> _fieldsMap = {
      // I'm so sorry this is so ugly
      EpisodeField.description: [const Symbol("description"), description],
      EpisodeField.enclosureDuration: [
        const Symbol("enclosureDuration"),
        enclosureDuration
      ],
      EpisodeField.enclosureSize: [
        const Symbol("enclosureSize"),
        enclosureSize
      ],
      EpisodeField.downloaded: [const Symbol("downloaded"), downloaded],
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
    Map<Symbol, dynamic> oldFields = {};
    List<EpisodeField> fields = this.fields;
    if (keepExisting) {
      for (EpisodeField field in newFields) {
        fields.remove(field);
      }
    } else {
      for (EpisodeField field in fields) {
        newFields.remove(field);
      }
    }
    for (EpisodeField field in fields) {
      oldFields[_fieldsMap[field]![0]] = _fieldsMap[field]![1];
    }
    bool populateVersions = newFields.remove(EpisodeField.versionsPopulated);
    EpisodeBrief newEpisode = (await dbHelper
            .getEpisodes(episodeIds: [id], optionalFields: newFields))
        .first;
    newEpisode = Function.apply(newEpisode.copyWith, [], oldFields);
    if (populateVersions) {
      newEpisode = await dbHelper.populateEpisodeVersions(newEpisode);
    }
    return newEpisode;
  }

  @override
  List<Object?> get props => [id];
}
