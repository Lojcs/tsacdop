import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher_string.dart';
import '../generated/l10n.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../state/episode_state.dart';
import '../state/podcast_state.dart';
import '../state/setting_state.dart';
import '../type/theme_data.dart';

extension ContextExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get accentColor => Theme.of(this).colorScheme.primary;
  Color get primaryColor => Theme.of(this).colorScheme.onPrimary;
  Color get priamryContainer => Theme.of(this).colorScheme.primaryContainer;
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get tertiary => colorScheme.tertiary;
  Color get tertiaryContainer => colorScheme.tertiaryContainer;
  Color get onTertiary => colorScheme.onTertiary;
  Color get secondary => colorScheme.secondary;
  Color get onsecondary => colorScheme.onSecondary;
  Color get error => colorScheme.error;
  Color get shadowColor => colorScheme.shadow;
  Color get primaryColorDark => Theme.of(this).primaryColorDark;
  Color get textColor => textTheme.bodyLarge!.color!;
  Color get dialogBackgroundColor => Theme.of(this).dialogBackgroundColor;
  Color get accentBackgroundWeak => accentColor.toWeakBackround(this);
  Color get accentBackground => accentColor.toStrongBackround(this);
  Color get accentBackgroundHighlight => accentColor.toHighlightBackround(this);
  Brightness get brightness => Theme.of(this).brightness;
  Brightness get iconBrightness =>
      brightness == Brightness.dark ? Brightness.light : Brightness.dark;
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get paddingTop => MediaQuery.of(this).padding.top;
  TextTheme get textTheme => Theme.of(this).textTheme;
  List<BoxShadow> boxShadowSmall({Color? color}) => realDark
      ? [
          BoxShadow(
              blurRadius: 4, spreadRadius: -1, color: color ?? shadowColor)
        ]
      : [
          BoxShadow(
              blurRadius: 4, spreadRadius: -2, color: color ?? shadowColor)
        ];
  List<BoxShadow> boxShadowMedium({Color? color}) => realDark
      ? [BoxShadow(blurRadius: 4, spreadRadius: 0, color: color ?? shadowColor)]
      : [
          BoxShadow(
              blurRadius: 3, spreadRadius: -1, color: color ?? shadowColor)
        ];
  List<BoxShadow> boxShadowLarge({Color? color}) => realDark
      ? [
          BoxShadow(
              blurRadius: 6, spreadRadius: 0.5, color: color ?? shadowColor)
        ]
      : [
          BoxShadow(
              blurRadius: 4, spreadRadius: -1, color: color ?? shadowColor)
        ];
  SystemUiOverlayStyle get overlay => SystemUiOverlayStyle(
        statusBarColor: surface,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: surface,
        systemNavigationBarIconBrightness: iconBrightness,
      );
  bool get realDark =>
      Provider.of<SettingState>(this, listen: false).realDark! &&
      brightness == Brightness.dark;
  EdgeInsets get originalPadding =>
      Provider.of<SettingState>(this, listen: false).originalPadding ??
      EdgeInsets.all(0);
  set originalPadding(EdgeInsets padding) {
    Provider.of<SettingState>(this, listen: false).originalPadding = padding;
  }

  BorderRadius get radiusTiny => BorderRadius.circular(5);
  BorderRadius get radiusSmall => BorderRadius.circular(12);
  BorderRadius get radiusMedium => BorderRadius.circular(16);
  BorderRadius get radiusLarge => BorderRadius.circular(20);
  BorderRadius get radiusHuge => BorderRadius.circular(100);

  CardColorScheme get cardColorScheme =>
      Theme.of(this).extension<CardColorScheme>()!;
  Color get cardColorSchemeCard => realDark ? surface : cardColorScheme.card;
  Color get cardColorSchemeSelected =>
      realDark ? surface : cardColorScheme.selected;
  Color get cardColorSchemeSaturated =>
      realDark ? surface : cardColorScheme.saturated;
  Color get cardColorSchemeFaded =>
      realDark ? surface : cardColorScheme.progress;
  Color get cardColorSchemeShadow =>
      realDark ? surface : cardColorScheme.shadow;

  ActionBarTheme get actionBarTheme =>
      Theme.of(this).extension<ActionBarTheme>()!;
  Color get actionBarIconColor => actionBarTheme.iconColor!;
  double get actionBarIconSize => actionBarTheme.size!;
  double get actionBarButtonSizeVertical => actionBarTheme.buttonSizeVertical!;
  double get actionBarButtonSizeHorizontal =>
      actionBarTheme.buttonSizeHorizontal!;
  Radius get actionBarIconRadius => actionBarTheme.radius!;
  EdgeInsets get actionBarIconPadding => actionBarTheme.padding!;
}

extension IntExtension on int {
  String toDate(BuildContext context) {
    final s = context.s;
    final date = DateTime.fromMillisecondsSinceEpoch(this, isUtc: true);
    final difference = DateTime.now().toUtc().difference(date);
    if (difference.inMinutes < 30) {
      return s.minsAgo(difference.inMinutes);
    } else if (difference.inMinutes < 60) {
      return s.hoursAgo(0);
    } else if (difference.inHours < 24) {
      return s.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return s.daysAgo(difference.inDays);
    } else {
      return DateFormat.yMMMd().format(
          DateTime.fromMillisecondsSinceEpoch(this, isUtc: true).toLocal());
    }
  }

  String get toTime =>
      '${(this ~/ 60).toString().padLeft(2, '0')}:${(truncate() % 60).toString().padLeft(2, '0')}';

  String toInterval(BuildContext context) {
    if (isNegative) return '';
    final s = context.s;
    var interval = Duration(milliseconds: this);
    if (interval.inHours <= 48) {
      return s.publishedDaily;
    } else if (interval.inDays > 2 && interval.inDays <= 14) {
      return s.publishedWeekly;
    } else if (interval.inDays > 14 && interval.inDays < 60) {
      return s.publishedMonthly;
    } else {
      return s.publishedYearly;
    }
  }
}

/// Convenience getters for state objects.
/// Still do assign these to local vars since Provider.of isn't free.
extension StateExtension on BuildContext {
  S get s => S.of(this);
  SettingState get settingState =>
      Provider.of<SettingState>(this, listen: false);
  EpisodeState get episodeState =>
      Provider.of<EpisodeState>(this, listen: false);
  PodcastState get podcastState =>
      Provider.of<PodcastState>(this, listen: false);
  AudioPlayerNotifier get audioState =>
      Provider.of<AudioPlayerNotifier>(this, listen: false);
  SuperDownloadState get downloadState =>
      Provider.of<SuperDownloadState>(this, listen: false);
}

extension StringExtension on String {
  Future get launchUrl async {
    if (await canLaunchUrlString(this)) {
      await launchUrlString(this, mode: LaunchMode.externalApplication);
    } else {
      developer.log('Could not launch $this');
      Fluttertoast.showToast(
        msg: '$this Invalid Link',
        gravity: ToastGravity.TOP,
      );
    }
  }

  Color colorizedark() {
    Color c;
    var color = json.decode(this);
    if (color[0] > 200 && color[1] > 200 && color[2] > 200) {
      c = Color.fromRGBO(255 - color[0] as int, 255 - color[1] as int,
          255 - color[2] as int, 1.0);
    } else {
      c = Color.fromRGBO(color[0], color[1] > 200 ? 190 : color[1],
          color[2] > 200 ? 190 : color[2], 1);
    }
    return c;
  }

  Color colorizeLight() {
    Color c;
    var color = json.decode(this);
    if (color[0] < 50 && color[1] < 50 && color[2] < 50) {
      c = Color.fromRGBO(255 - color[0] as int, 255 - color[1] as int,
          255 - color[2] as int, 1.0);
    } else {
      c = Color.fromRGBO(color[0] < 50 ? 100 : color[0],
          color[1] < 50 ? 100 : color[1], color[2] < 50 ? 100 : color[2], 1.0);
    }
    return c;
  }

  Color toColor() {
    var color = json.decode(this);
    return Color.fromRGBO(color[0], color[1], color[2], 1);
  }

  Color torgbColor() {
    if (isNotEmpty) {
      var color = int.parse('FF${toUpperCase()}', radix: 16);
      return Color(color).withValues(alpha: 1.0);
    } else {
      return Colors.teal[500]!;
    }
  }

  bool isXimalaya() {
    var ximalaya = RegExp(r"ximalaya.com");
    return ximalaya.hasMatch(this);
  }
}

extension ColorExtension on Color {
  String torgbString() {
    // // color.toString() is different in debug mode vs release! // TODO: Is this still the case?
    // String colorString =
    //     _accentSetColor!.value.toRadixString(16).substring(2, 8);
    int red = (r * 255.0).round() & 0xff;
    int green = (g * 255.0).round() & 0xff;
    int blue = (b * 255.0).round() & 0xff;
    return (red << 16 | green << 8 | blue).toRadixString(16).padLeft(6, "0");
  }

  /// Blend the color with background, less accent
  Color toWeakBackround(BuildContext context) {
    return context.realDark
        ? context.surface
        : Color.lerp(
            context.surface,
            ColorScheme.fromSeed(
              seedColor: this,
              brightness: context.brightness,
            ).secondaryContainer,
            0.5)!;
  }

  /// Blend the color with background, mid accent
  Color toStrongBackround(BuildContext context) {
    return context.realDark
        ? context.surface
        : Color.lerp(
            ColorScheme.fromSeed(
              seedColor: this,
              brightness: context.brightness,
            ).secondaryContainer,
            this,
            0.2)!;
  }

  /// Blend the color with background, most accent
  Color toHighlightBackround(BuildContext context, {Brightness? brightness}) {
    brightness = brightness ?? context.brightness;
    return context.realDark
        ? context.surface
        : Color.lerp(
            ColorScheme.fromSeed(
              seedColor: this,
              brightness: brightness,
            ).surfaceContainerHighest,
            this,
            0.5)!;
  }
}

// extension ColorSchemeExtension on ColorScheme {
//   Color get weakBackround {
//     return Color.lerp(context.background, this.secondaryContainer, 0.5)!;
//   }

//   Color get strongBackround {
//     return Color.lerp(this.secondaryContainer, this.primary, 0.00)!;
//   }
// }
