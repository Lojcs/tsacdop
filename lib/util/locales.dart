import 'dart:ui';

import 'package:flutter/material.dart';

import '../generated/l10n.dart';

List<Locale?> supportedLocales = [
  null,
  Locale('en'),
  Locale('tr'),
  Locale('pt'),
  Locale('es'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: "Hans"),
  Locale('it'),
  Locale('el'),
  Locale('ru'),
  Locale('fr'),
  Locale('de'),
];

String localeNameOf(Locale? locale) {
  S s = S.current;
  return switch (locale) {
    null =>
      "${s.systemDefault} (${basicLocaleListResolution(PlatformDispatcher.instance.locales, S.delegate.supportedLocales).toString()})",
    Locale(languageCode: "en") => "English",
    Locale(languageCode: "tr") => "Türkçe",
    Locale(languageCode: "pt") => "Português",
    Locale(languageCode: "es") => "Español",
    Locale(languageCode: "zh", scriptCode: "Hans") => "简体中文",
    Locale(languageCode: "it") => "Italiano",
    Locale(languageCode: "el") => "Ελληνικά",
    Locale(languageCode: "ru") => "Русский",
    Locale(languageCode: "fr") => "Français",
    Locale(languageCode: "de") => "Deutsch",
    _ => s.unsupported,
  };
}
