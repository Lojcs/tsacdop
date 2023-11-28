import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/class/settingstate.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../generated/l10n.dart';

extension ContextExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get accentColor => Theme.of(this).colorScheme.primary;
  Color get primaryColor => Theme.of(this).colorScheme.onPrimary;
  Color get priamryContainer => Theme.of(this).colorScheme.primaryContainer;
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get background => Theme.of(this).colorScheme.background;
  Color get tertiary => colorScheme.tertiary;
  Color get tertiaryContainer => colorScheme.tertiaryContainer;
  Color get onTertiary => colorScheme.onTertiary;
  Color get secondary => colorScheme.secondary;
  Color get onsecondary => colorScheme.onSecondary;
  Color get error => colorScheme.error;
  Color get primaryColorDark => Theme.of(this).primaryColorDark;
  Color get textColor => textTheme.bodyLarge!.color!;
  Color get dialogBackgroundColor => Theme.of(this).dialogBackgroundColor;
  Color get accentBackgroundWeak => accentColor.toWeakBackround(this);
  Color get accentBackground => accentColor.toStrongBackround(this);
  Brightness get brightness => Theme.of(this).brightness;
  Brightness get iconBrightness =>
      brightness == Brightness.dark ? Brightness.light : Brightness.dark;
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get paddingTop => MediaQuery.of(this).padding.top;
  TextTheme get textTheme => Theme.of(this).textTheme;
  SystemUiOverlayStyle get overlay => SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: iconBrightness,
      );
  SystemUiOverlayStyle get overlayWithBarrier => SystemUiOverlayStyle(
        statusBarColor: Color.alphaBlend(Colors.black54, (statusBarColor)),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor:
            Color.alphaBlend(Colors.black54, (navBarColor)),
        systemNavigationBarIconBrightness: Brightness.light,
      );
  S get s => S.of(this);
  bool get realDark =>
      Provider.of<SettingState>(this, listen: false).realDark! &&
      brightness == Brightness.dark;
  EdgeInsets get originalPadding =>
      Provider.of<SettingState>(this, listen: false).originalPadding ??
      EdgeInsets.all(0);
  set originalPadding(EdgeInsets padding) {
    Provider.of<SettingState>(this, listen: false).originalPadding = padding;
  }

  /// Returns the last item from the statusBarColor stack. Useful for keeping track of the current
  Color get statusBarColor =>
      Provider.of<SettingState>(this, listen: false).statusBarColor.isEmpty
          ? background
          : Provider.of<SettingState>(this, listen: false).statusBarColor.last;

  /// Adds the color to the statusBarColor stack if it's not already the last item. Pass null when exiting the page to pop the last item.
  set statusBarColor(Color? color) {
    // TODO: Fix: If an EpisodeDetail is opened while a PodcastDetail is in its closing animation and hasn't called deactivate yet, the color of the PodcastDetail gets stuck in the stack, leading to incorrect colors for eg. mobile data confirmation dialog in home screen.
    SettingState setting = Provider.of<SettingState>(this, listen: false);
    // print("$color, ${setting.statusBarColor}");
    if (color == null) {
      if (setting.statusBarColor.isNotEmpty) {
        setting.statusBarColor.removeLast();
      }
    } else if (setting.statusBarColor.isEmpty ||
        setting.statusBarColor.last != color) {
      Provider.of<SettingState>(this, listen: false).statusBarColor.add(color);
    }
  }

  /// Returns the last item from the statusBarColor stack. Useful for keeping track of the current
  Color get navBarColor =>
      Provider.of<SettingState>(this, listen: false).navBarColor.isEmpty
          ? background
          : Provider.of<SettingState>(this, listen: false).navBarColor.last;

  /// Adds the color to the statusBarColor stack if it's not already the last item. Pass null when exiting the page to pop the last item.
  set navBarColor(Color? color) {
    SettingState setting = Provider.of<SettingState>(this, listen: false);
    if (color == null) {
      if (setting.navBarColor.isNotEmpty) {
        setting.navBarColor.removeLast();
      }
    } else if (setting.navBarColor.isEmpty ||
        setting.navBarColor.last != color) {
      Provider.of<SettingState>(this, listen: false).navBarColor.add(color);
    }
  }

  BorderRadius get radiusSmall => BorderRadius.circular(12);
  BorderRadius get radiusMedium => BorderRadius.circular(16);
  BorderRadius get radiusLarge => BorderRadius.circular(20);
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
}

extension ColorExtension on Color {
  Color toWeakBackround(BuildContext context) {
    return context.realDark
        ? context.background
        : Color.lerp(
            context.background,
            ColorScheme.fromSeed(
              seedColor: this,
              brightness: context.brightness,
            ).secondaryContainer,
            0.5)!;
  }

  Color toStrongBackround(BuildContext context) {
    return context.realDark
        ? context.background
        : Color.lerp(
            ColorScheme.fromSeed(
              seedColor: this,
              brightness: context.brightness,
            ).secondaryContainer,
            this,
            0.2)!;
  }

  Color toHighlightBackround(BuildContext context) {
    return Color.lerp(context.background, this, 0.40)!;
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
