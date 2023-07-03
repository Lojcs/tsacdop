import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../util/extension_helper.dart';

class EpisodeBrief extends Equatable {
  final String? title;
  String description;
  final int? pubDate;
  final int? enclosureLength;
  final String enclosureUrl;
  final String? feedTitle;
  final String? primaryColor;
  bool? liked;
  bool? downloaded;
  final int? duration;
  final int? explicit;
  final String? imagePath;
  String? mediaId;
  bool? isNew;
  int? skipSecondsStart;
  int? skipSecondsEnd;
  int? downloadDate;
  String? episodeImage;
  String? chapterLink;
  String? duplicateStatus;
  bool? played;
  EpisodeBrief(
      this.title,
      this.enclosureUrl,
      this.enclosureLength,
      this.pubDate,
      this.feedTitle,
      this.primaryColor,
      this.duration,
      this.explicit,
      this.imagePath,
      {this.isNew,
      this.duplicateStatus,
      this.mediaId,
      this.liked,
      this.downloaded,
      this.played,
      this.skipSecondsStart,
      this.skipSecondsEnd,
      this.description = '',
      this.downloadDate = 0,
      this.chapterLink = '',
      this.episodeImage = ''})
      : assert(enclosureUrl != null);

  MediaItem toMediaItem() {
    return MediaItem(
        id: mediaId!,
        title: title!,
        artist: feedTitle,
        album: feedTitle,
        duration: Duration.zero,
        artUri:
            Uri.parse(imagePath == '' ? episodeImage! : 'file://$imagePath'),
        extras: {
          'skipSecondsStart': skipSecondsStart,
          'skipSecondsEnd': skipSecondsEnd
        });
  }

  ImageProvider get avatarImage {
    return File(imagePath!).existsSync()
        ? FileImage(File(imagePath!))
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

  EpisodeBrief copyWith({
    String? mediaId,
  }) =>
      EpisodeBrief(title, enclosureUrl, enclosureLength, pubDate, feedTitle,
          primaryColor, duration, explicit, imagePath,
          isNew: isNew,
          duplicateStatus: duplicateStatus,
          mediaId: mediaId ?? this.mediaId,
          downloaded: downloaded,
          skipSecondsStart: skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd,
          description: description,
          downloadDate: downloadDate);

  @override
  List<Object?> get props => [enclosureUrl, title];
}
