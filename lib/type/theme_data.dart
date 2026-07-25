import 'dart:ui';

import 'package:flutter/material.dart';

enum TBrightness { light, dark, black }

ColorScheme getColorScheme(Color seed, TBrightness brightness) =>
    switch (brightness) {
      .light => ColorScheme.fromSeed(
        seedColor: seed,
        primary: seed,
        brightness: .light,
      ),
      .dark => ColorScheme.fromSeed(
        seedColor: seed,
        primary: seed,
        brightness: .dark,
      ),
      .black => ColorScheme.fromSeed(
        seedColor: seed,
        primary: seed,
        brightness: .dark,
        surface: Colors.black,
      ),
    };

class TsacdopTheme extends ThemeExtension<TsacdopTheme> {
  final TBrightness brightness;

  const TsacdopTheme(this.brightness);

  @override
  ThemeExtension<TsacdopTheme> copyWith({TBrightness? brightness}) =>
      TsacdopTheme(brightness ?? this.brightness);

  @override
  ThemeExtension<TsacdopTheme> lerp(
    covariant ThemeExtension<TsacdopTheme>? other,
    double t,
  ) {
    if (other is! TsacdopTheme) {
      return this;
    }
    if (identical(this, other)) {
      return this;
    }
    return TsacdopTheme(t < 0.5 ? brightness : other.brightness);
  }
}

/// Non accent color related theme parameters of action bars.
class ActionBarTheme extends ThemeExtension<ActionBarTheme> {
  final Color? iconColor;
  final double? size;
  final List<Shadow>? shadows;
  final Radius? radius;
  final EdgeInsets? padding;

  double? get buttonSizeVertical =>
      size != null && padding != null ? size! + padding!.vertical : null;
  double? get buttonSizeHorizontal =>
      size != null && padding != null ? size! + padding!.horizontal : null;

  const ActionBarTheme({
    this.iconColor,
    this.size,
    this.shadows,
    this.radius,
    this.padding,
  });

  ActionBarTheme.light()
    : iconColor = Colors.grey[800],
      size = 24,
      radius = const Radius.circular(16),
      padding = const EdgeInsets.all(6),
      shadows = null;
  ActionBarTheme.dark()
    : iconColor = Colors.grey[200],
      size = 24,
      radius = const Radius.circular(16),
      padding = const EdgeInsets.all(6),
      shadows = null;

  @override
  ThemeExtension<ActionBarTheme> copyWith({
    Color? iconColor,
    double? size,
    List<Shadow>? shadows,
    Radius? radius,
    EdgeInsets? padding,
  }) => ActionBarTheme(
    iconColor: iconColor ?? this.iconColor,
    size: size ?? this.size,
    shadows: shadows ?? this.shadows,
    radius: radius ?? this.radius,
    padding: padding ?? this.padding,
  );

  @override
  ThemeExtension<ActionBarTheme> lerp(
    covariant ThemeExtension<ActionBarTheme>? other,
    double t,
  ) {
    if (other is! ActionBarTheme) {
      return this;
    }
    if (identical(this, other)) {
      return this;
    }
    return ActionBarTheme(
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      size: lerpDouble(size, other.size, t),
      shadows: Shadow.lerpList(shadows, other.shadows, t),
      radius: Radius.lerp(radius, other.radius, t),
      padding: EdgeInsets.lerp(padding, other.padding, t),
    );
  }
}

class CardColorScheme extends ThemeExtension<CardColorScheme> {
  final ColorScheme colorScheme;
  final bool trueBlack;
  CardColorScheme(
    this.colorScheme,
    this.trueBlack, {
    Color? card,
    Color? selected,
    Color? saturated,
    Color? progress,
    Color? shadow,
  }) : card =
           card ??
           (colorScheme.brightness == Brightness.light
               ? Color.lerp(
                   colorScheme.surfaceContainerLow,
                   colorScheme.primary,
                   0.05,
                 )!
               : trueBlack
               ? colorScheme.surface
               : Color.lerp(
                   colorScheme.surfaceContainerLow,
                   colorScheme.primary,
                   0.1,
                 )!),
       selected =
           selected ??
           (colorScheme.brightness == Brightness.light
               ? Color.lerp(
                   colorScheme.secondaryContainer,
                   colorScheme.primaryFixedDim,
                   0.1,
                 )!
               : Color.lerp(
                   colorScheme.surfaceContainerLow,
                   colorScheme.secondaryContainer,
                   0.8,
                 )!),
       saturated =
           saturated ??
           (colorScheme.brightness == Brightness.light
               ? Color.lerp(
                   colorScheme.surfaceContainerHigh,
                   colorScheme.primaryFixedDim,
                   0.6,
                 )!
               : Color.lerp(
                   colorScheme.surfaceContainerLow,
                   colorScheme.primaryContainer,
                   0.5,
                 )!),
       progress =
           progress ??
           (colorScheme.brightness == Brightness.light
               ? Color.lerp(
                   colorScheme.surface,
                   colorScheme.surfaceContainerLowest,
                   0.25,
                 )!
               : trueBlack
               ? colorScheme.surface
               : Color.lerp(
                   colorScheme.surfaceContainerHighest,
                   colorScheme.surfaceContainerLowest,
                   0.8,
                 )!),
       shadow =
           shadow ??
           (colorScheme.brightness == Brightness.light
               ? colorScheme.tertiary
               : Colors.black);

  late final Color card;
  late final Color selected;
  late final Color saturated;
  late final Color progress;
  late final Color shadow;

  @override
  ThemeExtension<CardColorScheme> copyWith({
    ColorScheme? colorScheme,
    bool? trueBlack,
    Color? card,
    Color? selected,
    Color? saturated,
    Color? progress,
    Color? shadow,
  }) => CardColorScheme(
    colorScheme ?? this.colorScheme,
    trueBlack ?? this.trueBlack,
    card: card ?? this.card,
    selected: selected ?? this.selected,
    saturated: saturated ?? this.saturated,
    progress: progress ?? this.progress,
    shadow: shadow ?? this.shadow,
  );

  @override
  ThemeExtension<CardColorScheme> lerp(
    covariant ThemeExtension<CardColorScheme>? other,
    double t,
  ) {
    if (other is! CardColorScheme) {
      return this;
    }
    if (identical(this, other)) {
      return this;
    }
    return CardColorScheme(
      ColorScheme.lerp(colorScheme, other.colorScheme, t),
      other.trueBlack,
    );
  }
}
