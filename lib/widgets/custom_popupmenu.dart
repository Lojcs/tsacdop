import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import '../util/extension_helper.dart';

const Duration _kMenuDuration = Duration(milliseconds: 300);
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuVerticalPadding = 8.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuScreenPadding = 8.0;

class _MenuItem extends SingleChildRenderObjectWidget {
  const _MenuItem({
    required this.onLayout,
    super.child,
  });

  final ValueChanged<Size> onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMenuItem(onLayout);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderMenuItem extends RenderShiftedBox {
  _RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  ValueChanged<Size> onLayout;

  @override
  void performLayout() {
    if (child == null) {
      size = Size.zero;
    } else {
      child!.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child!.size);
    }
    final childParentData = child!.parentData as BoxParentData;
    childParentData.offset = Offset.zero;
    onLayout(size);
  }
}

class _PopupMenu<T> extends StatelessWidget {
  const _PopupMenu({
    super.key,
    required this.route,
    this.semanticLabel,
    this.constraints,
    this.direction,
    this.padding,
    this.visibleItemCount,
    this.itemExtent,
    this.animateOpacity = true,
    this.animateHeight = true,
    this.animateWidth = true,
  });

  final _PopupMenuRoute<T> route;
  final String? semanticLabel;
  final BoxConstraints? constraints;
  final AxisDirection? direction;
  final EdgeInsetsGeometry? padding;
  final int? visibleItemCount;
  final double? itemExtent;
  final bool animateOpacity;
  final bool animateHeight;
  final bool animateWidth;

  @override
  Widget build(BuildContext context) {
    final int itemCount;
    final BoxConstraints? adjustedConstraints;
    if (visibleItemCount != null) {
      itemCount = visibleItemCount!.clamp(0, route.items.length);
      final fullHeight =
          itemCount * itemExtent! + (padding != null ? padding!.vertical : 0);
      adjustedConstraints = constraints?.tighten(height: fullHeight);
    } else {
      itemCount = route.items.length;
      adjustedConstraints = constraints;
    }
    final unit = 1.0 /
        (itemCount +
            1.5); // 1.0 for the width and 0.5 for the last item's fade.
    final children = <Widget>[];
    final popupMenuTheme = PopupMenuTheme.of(context);

    for (var i = 0; i < itemCount; i += 1) {
      final start = (i + 1) * unit;
      final end = (start + 1.5 * unit).clamp(0.0, 1.0);
      final opacity = CurvedAnimation(
        parent: route.animation!,
        curve: Interval(start, end),
      );
      Widget item = route.items[i];
      if (route.initialValue != null &&
          route.items[i].represents(route.initialValue)) {
        item = Container(
          color: Theme.of(context).highlightColor,
          child: item,
        );
      }
      children.add(
        _MenuItem(
          onLayout: (size) {
            route.itemSizes[i] = size;
          },
          child: FadeTransition(
            opacity: opacity,
            child: item,
          ),
        ),
      );
    }
    for (var i = itemCount; i < route.items.length; i += 1) {
      Widget item = route.items[i];
      if (route.initialValue != null &&
          route.items[i].represents(route.initialValue)) {
        item = Container(
          color: Theme.of(context).highlightColor,
          child: item,
        );
      }
      children.add(
        _MenuItem(
          onLayout: (size) {
            route.itemSizes[i] = size;
          },
          child: item,
        ),
      );
    }

    final opacity = CurveTween(curve: const Interval(0.0, 1.0 / 3.0));
    final width = CurveTween(curve: Interval(0.0, unit));
    final height = CurveTween(curve: Interval(0.0, 1 - 1.5 * unit));

    final Widget child = ConstrainedBox(
        constraints: adjustedConstraints ??
            const BoxConstraints(
              minWidth: _kMenuMinWidth,
              maxWidth: _kMenuMaxWidth,
            ),
        child: Stack(
          alignment: direction == AxisDirection.down
              ? Alignment.bottomCenter
              : Alignment.topCenter,
          children: [
            IntrinsicWidth(
              stepWidth: _kMenuWidthStep,
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: semanticLabel,
                child: SingleChildScrollView(
                  padding: padding,
                  child: ListBody(
                      reverse: direction == AxisDirection.down ? false : true,
                      children: children),
                ),
              ),
            ),
            if (visibleItemCount != null &&
                visibleItemCount! < route.items.length)
              Icon(
                Icons.arrow_drop_down,
                color: context.textColor.withValues(alpha: 0.4),
              )
          ],
        ));

    return AnimatedBuilder(
      animation: route.animation!,
      builder: (context, child) {
        return Opacity(
          opacity: animateOpacity ? opacity.evaluate(route.animation!) : 1,
          child: Material(
            shape: route.shape ?? popupMenuTheme.shape,
            clipBehavior: Clip.hardEdge,
            color: route.color ?? popupMenuTheme.color,
            type: MaterialType.card,
            elevation: route.elevation ?? popupMenuTheme.elevation ?? 8.0,
            child: Align(
              alignment: direction == AxisDirection.down
                  ? AlignmentDirectional.topEnd
                  : AlignmentDirectional.bottomEnd,
              widthFactor: animateWidth ? width.evaluate(route.animation!) : 1,
              heightFactor:
                  animateHeight ? height.evaluate(route.animation!) : 1,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _PopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _PopupMenuRouteLayout(
      this.position, this.direction, this.itemSizes, this.textDirection);

  final Offset? position;
  final AxisDirection? direction;

  List<Size?> itemSizes;

  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(
      constraints.biggest -
              const Offset(_kMenuScreenPadding * 2.0, _kMenuScreenPadding * 2.0)
          as Size,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var y =
        position!.dy - (direction == AxisDirection.up ? childSize.height : 0);

    late double x;
    x = position!.dx;

    if (x < _kMenuScreenPadding) {
      x = _kMenuScreenPadding;
    } else if (x + childSize.width > size.width - _kMenuScreenPadding) {
      x = size.width - childSize.width - _kMenuScreenPadding;
    }
    if (y < _kMenuScreenPadding) {
      y = _kMenuScreenPadding;
    } else if (y + childSize.height > size.height - _kMenuScreenPadding) {
      y = size.height - childSize.height - _kMenuScreenPadding;
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    assert(itemSizes.length == oldDelegate.itemSizes.length);

    return position != oldDelegate.position ||
        textDirection != oldDelegate.textDirection ||
        !listEquals(itemSizes, oldDelegate.itemSizes);
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    this.position,
    required this.items,
    this.initialValue,
    this.elevation,
    this.theme,
    this.popupMenuTheme,
    this.barrierLabel,
    this.semanticLabel,
    this.shape,
    this.color,
    this.showMenuContext,
    this.captureInheritedThemes,
    this.constraints,
    this.direction,
    this.padding,
    this.visibleItemCount,
    this.itemExtent,
    this.animateOpacity = true,
    this.animateHeight = true,
    this.animateWidth = true,
  }) : itemSizes = List<Size?>.filled(items.length, null, growable: false);

  final Offset? position;
  final List<MyPopupMenuItem<T>> items;
  final List<Size?> itemSizes;
  final T? initialValue;
  final double? elevation;
  final ThemeData? theme;
  final String? semanticLabel;
  final ShapeBorder? shape;
  final Color? color;
  final PopupMenuThemeData? popupMenuTheme;
  final BuildContext? showMenuContext;
  final bool? captureInheritedThemes;
  final BoxConstraints? constraints;
  final AxisDirection? direction;
  final EdgeInsetsGeometry? padding;
  final int? visibleItemCount;
  final double? itemExtent;
  final bool animateOpacity;
  final bool animateHeight;
  final bool animateWidth;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linear,
      reverseCurve: const Interval(1 / 3, 1),
    );
  }

  @override
  Duration get transitionDuration => _kMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    Widget menu = _PopupMenu<T>(
      route: this,
      semanticLabel: semanticLabel,
      constraints: constraints,
      direction: direction,
      padding: padding,
      visibleItemCount: visibleItemCount,
      itemExtent: itemExtent,
      animateOpacity: animateOpacity,
      animateHeight: animateHeight,
      animateWidth: animateWidth,
    );
    if (captureInheritedThemes!) {
      menu = InheritedTheme.captureAll(showMenuContext!, menu);
    } else {
      if (theme != null) menu = Theme(data: theme!, child: menu);
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (context) {
          return CustomSingleChildLayout(
            delegate: _PopupMenuRouteLayout(
              position,
              direction,
              itemSizes,
              Directionality.of(context),
            ),
            child: menu,
          );
        },
      ),
    );
  }
}

Future<T?> _showMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<MyPopupMenuItem<T>> items,
  T? initialValue,
  double? elevation,
  String? semanticLabel,
  ShapeBorder? shape,
  Color? color,
  bool captureInheritedThemes = true,
  bool useRootNavigator = false,
  BoxConstraints? constraints,
  AxisDirection? direction,
  EdgeInsetsGeometry? padding,
  int? visibleItemCount,
  double? itemExtent,
  bool animateOpacity = true,
  bool animateHeight = true,
  bool animateWidth = true,
}) {
  assert(items.isNotEmpty);
  assert(debugCheckHasMaterialLocalizations(context));

  var label = semanticLabel;
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      label = semanticLabel;
      break;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      label = semanticLabel ?? MaterialLocalizations.of(context).popupMenuLabel;
  }

  return Navigator.of(context, rootNavigator: useRootNavigator)
      .push(_PopupMenuRoute<T>(
    position: position,
    items: items,
    initialValue: initialValue,
    elevation: elevation,
    semanticLabel: label,
    theme: Theme.of(context),
    popupMenuTheme: PopupMenuTheme.of(context),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    shape: shape,
    color: color,
    showMenuContext: context,
    captureInheritedThemes: captureInheritedThemes,
    constraints: constraints,
    direction: direction,
    padding: padding,
    visibleItemCount: visibleItemCount,
    itemExtent: itemExtent,
    animateOpacity: animateOpacity,
    animateHeight: animateHeight,
    animateWidth: animateWidth,
  ));
}

class MyPopupMenuButton<T> extends StatefulWidget {
  /// Creates a button that shows a popup menu.
  ///
  /// The [itemBuilder] argument must not be null.
  const MyPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.onCanceled,
    this.beforeOpened,
    this.afterClosed,
    this.tooltip,
    this.elevation,
    this.padding = const EdgeInsets.all(8.0),
    this.child,
    this.splashRadius,
    this.icon,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
    this.enableFeedback,
    this.constraints,
    this.position = MyPopupMenuPosition.over,
    this.menuPadding = const EdgeInsets.symmetric(vertical: 8),
    this.visibleItemCount,
    this.itemExtent,
    this.captureInheritedThemes = true,
  })  : assert(!(child != null && icon != null),
            'You can only pass [child] or [icon], not both.'),
        assert(visibleItemCount == null || itemExtent != null,
            '[itemExtent] is required if [visibleItemCount] is set.');

  final List<MyPopupMenuItem<T>> Function(BuildContext context) itemBuilder;

  final T? initialValue;
  final void Function(T value)? onSelected;

  final PopupMenuCanceled? onCanceled;

  /// Cancels opening if false is received.
  final Future<bool> Function()? beforeOpened;

  final Future<void> Function()? afterClosed;

  final String? tooltip;

  final double? elevation;

  final EdgeInsetsGeometry padding;

  final double? splashRadius;

  final Widget? child;

  final Widget? icon;

  final Offset offset;
  final bool enabled;
  final ShapeBorder? shape;

  final Color? color;

  final bool? enableFeedback;

  final BoxConstraints? constraints;

  final MyPopupMenuPosition position;

  final EdgeInsetsGeometry menuPadding;

  final int? visibleItemCount;

  final double? itemExtent;

  final bool captureInheritedThemes;

  @override
  MyPopupMenuButtonState<T> createState() => MyPopupMenuButtonState<T>();
}

class MyPopupMenuButtonState<T> extends State<MyPopupMenuButton<T>> {
  void showButtonMenu() async {
    if (widget.beforeOpened != null) {
      final result = await widget.beforeOpened!();
      if (!result) return;
    }
    final popupMenuTheme = PopupMenuTheme.of(context);
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset offset;
    switch (widget.position) {
      case MyPopupMenuPosition.over:
        offset = widget.offset;
        break;
      case MyPopupMenuPosition.under:
        offset =
            Offset(0.0, button.size.height - (widget.padding.vertical / 2)) +
                widget.offset;
      case MyPopupMenuPosition.above:
        offset = Offset(0.0, (widget.padding.vertical / 2)) + widget.offset;
        break;
    }
    final Offset position = button.localToGlobal(offset, ancestor: overlay);
    final List<MyPopupMenuItem<T>> items = widget.itemBuilder(context);
    // Only show the menu if there is something to show
    if (items.isNotEmpty) {
      _showMenu<T>(
        context: context,
        elevation: widget.elevation ?? popupMenuTheme.elevation,
        items: items,
        initialValue: widget.initialValue,
        position: position,
        shape: widget.shape ?? popupMenuTheme.shape,
        color: widget.color ?? popupMenuTheme.color,
        constraints: widget.constraints,
        direction: widget.position == MyPopupMenuPosition.above
            ? AxisDirection.up
            : AxisDirection.down,
        padding: widget.menuPadding,
        visibleItemCount: widget.visibleItemCount,
        itemExtent: widget.itemExtent,
        captureInheritedThemes: widget.captureInheritedThemes,
        animateWidth: widget.position == PopupMenuPosition.over,
      ).then<void>((newValue) async {
        if (!mounted) return;
        if (newValue == null) {
          if (widget.onCanceled != null) widget.onCanceled!();
        } else {
          if (widget.onSelected != null) widget.onSelected!(newValue);
        }
        await widget.afterClosed?.call();
        return;
      });
    }
  }

  Icon? _getIcon(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const Icon(Icons.more_vert);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const Icon(Icons.more_horiz);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enableFeedback = widget.enableFeedback ??
        PopupMenuTheme.of(context).enableFeedback ??
        true;
    assert(debugCheckHasMaterialLocalizations(context));

    if (widget.child != null) {
      return Tooltip(
        message:
            widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
        child: InkWell(
          onTap: widget.enabled ? showButtonMenu : null,
          canRequestFocus: widget.enabled,
          radius: widget.splashRadius,
          enableFeedback: enableFeedback,
          child: widget.child,
        ),
      );
    }

    return IconButton(
      icon: widget.icon ?? _getIcon(Theme.of(context).platform)!,
      padding: widget.padding,
      splashRadius: widget.splashRadius,
      tooltip:
          widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
      onPressed: widget.enabled ? showButtonMenu : null,
      enableFeedback: enableFeedback,
    );
  }
}

enum MyPopupMenuPosition {
  /// Menu is positioned over the anchor.
  over,

  /// Menu is positioned under the anchor.
  under,

  /// Menu is positioned above the anchor.
  above,
}

class MyPopupMenuItem<T> extends StatefulWidget {
  const MyPopupMenuItem({
    super.key,
    this.value,
    this.enabled = true,
    this.height,
    this.width,
    this.textStyle,
    this.padding,
    required this.child,
  });

  final T? value;

  final bool enabled;

  final double? height;
  final double? width;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  final Widget child;

  @override
  bool represents(T? value) => value == this.value;

  @override
  State<MyPopupMenuItem<T>> createState() => _MyPopupMenuItemState<T>();
}

class _MyPopupMenuItemState<T> extends State<MyPopupMenuItem<T>> {
  @protected
  Widget buildChild() => widget.child;

  void handleTap() {
    Navigator.pop<T>(context, widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final popupMenuTheme = PopupMenuTheme.of(context);
    var style = widget.textStyle ??
        popupMenuTheme.textStyle ??
        theme.textTheme.titleMedium!;
    return AnimatedDefaultTextStyle(
      style: style,
      duration: kThemeChangeDuration,
      child: InkWell(
        onTap: widget.enabled ? handleTap : null,
        canRequestFocus: widget.enabled,
        child: Container(
          height: widget.height ?? context.actionBarButtonSizeVertical,
          width: widget.width,
          // alignment: AlignmentDirectional.centerStart,
          //  constraints: BoxConstraints(minHeight: widget.height),
          padding: widget.padding ?? context.actionBarIconPadding,
          child: buildChild(),
        ),
      ),
    );
  }
}
