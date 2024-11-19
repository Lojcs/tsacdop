import 'package:flutter/widgets.dart';

class MyIconThemeData extends IconThemeData {
  final Radius? radius;
  final EdgeInsets? padding;
  double? get buttonSizeVertical =>
      size != null && padding != null ? size! + padding!.vertical : null;
  double? get buttonSizeHorizontal =>
      size != null && padding != null ? size! + padding!.horizontal : null;
  const MyIconThemeData({
    Color? color,
    double? opacity,
    double? size,
    List<Shadow>? shadows,
    this.radius,
    this.padding,
  }) : super(color: color, opacity: opacity, size: size, shadows: shadows);
}
