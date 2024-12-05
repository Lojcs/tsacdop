import 'dart:ui';

import 'package:flutter/material.dart';

class ActionBarTheme extends ThemeExtension<ActionBarTheme> {
  final Color? iconColor;
  final double? size;
  final List<Shadow>? shadows;
  final Radius? radius;
  final EdgeInsets? padding;

  double? get sizeVertical =>
      size != null && padding != null ? size! + padding!.vertical : null;
  double? get sizeHorizontal =>
      size != null && padding != null ? size! + padding!.horizontal : null;

  const ActionBarTheme({
    this.iconColor,
    this.size,
    this.shadows,
    this.radius,
    this.padding,
  });

  @override
  ThemeExtension<ActionBarTheme> copyWith({
    Color? iconColor,
    double? size,
    List<Shadow>? shadows,
    Radius? radius,
    EdgeInsets? padding,
  }) {
    return ActionBarTheme(
      iconColor: iconColor ?? this.iconColor,
      size: size ?? this.size,
      shadows: shadows ?? this.shadows,
      radius: radius ?? this.radius,
      padding: padding ?? this.padding,
    );
  }

  @override
  ThemeExtension<ActionBarTheme> lerp(
      covariant ThemeExtension<ActionBarTheme>? other, double t) {
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
