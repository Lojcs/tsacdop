import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/type/theme_data.dart';
import 'package:tsacdop/util/extension_helper.dart';
import 'package:tuple/tuple.dart';

import 'custom_popupmenu.dart';
import 'custom_widget.dart';

enum ActionBarButtonType { single, onOff, noneOnOff, partialOnOff }

/// General purpose button with flexible state types.
/// Single: State handled outside the button
/// onOff: State swtiched false->true->false
/// noneOnOff: State switched null->true->false->null. False (off) is represented with crossing out of the (false)child.
/// partialOnOff: State switched null->true->false->true.
/// Can shrink to shrunkWidth in off state.
/// Passing color is mandatory either directly or with a [CardColorScheme] [Provider]
class ActionBarButton extends StatefulWidget {
  final Widget child;
  final ExpansionController? expansionController;
  final Widget? shrunkChild;
  final Widget? falseChild;
  final Widget? partialChild;
  final bool? state;
  final ActionBarButtonType buttonType;
  final ValueChanged<bool?> onPressed;
  final double? width;
  final double? shrunkWidth;
  final double? height;
  final EdgeInsets? innerPadding;
  final Color? color;
  final Color? activeColor;
  final String? tooltip;
  final bool enabled;
  final Animation<double>? animation;
  final bool connectLeft;
  final bool connectRight;
  const ActionBarButton({
    required this.child,
    this.expansionController,
    this.shrunkChild,
    this.falseChild,
    this.partialChild,
    this.state,
    this.buttonType = ActionBarButtonType.single,
    required this.onPressed,
    this.width,
    this.shrunkWidth,
    this.height,
    this.innerPadding,
    this.color,
    this.activeColor,
    this.tooltip,
    this.enabled = true,
    this.animation,
    this.connectLeft = false,
    this.connectRight = false,
  });

  @override
  _ActionBarButtonState createState() => _ActionBarButtonState();
}

class _ActionBarButtonState extends State<ActionBarButton>
    with TickerProviderStateMixin {
  late final Animation<double> animation;
  late final AnimationController animationController;
  late final Animation<double>? expandAnimation;
  late final AnimationController? expandAnimationController;

  late bool? state;
  bool get active => widget.buttonType == ActionBarButtonType.noneOnOff
      ? state != null
      : widget.buttonType == ActionBarButtonType.partialOnOff
          ? state != false
          : state!;

  late BorderRadius borderRadius = BorderRadius.horizontal(
    left: !widget.connectLeft ? context.actionBarIconRadius : Radius.zero,
    right: !widget.connectRight ? context.actionBarIconRadius : Radius.zero,
  );

  double get widgetWidthNotNull =>
      widget.width ?? context.actionBarButtonSizeHorizontal;
  double get shrunkWidth => widget.shrunkWidth ?? widgetWidthNotNull;
  late final double minExpandedWidth = min(shrunkWidth * 3, widgetWidthNotNull);
  late Tween<double> widthTween = Tween<double>(
      begin: shrunkWidth,
      end: hasExpansionController ? shrunkWidth : widgetWidthNotNull);
  late void Function(bool) _expand = (shouldExpand) {
    if (shouldExpand) {
      expandAnimationController!.forward();
    } else {
      expandAnimationController!.reverse();
    }
  };
  void expand(bool shouldExpand) {
    if (expands && mounted) _expand(shouldExpand);
  }

  late Expandable expandableItem = Expandable(
    minWidth: shrunkWidth,
    minExpandedWidth: minExpandedWidth,
    maxExpandedWidth: widgetWidthNotNull,
    onWidthChanged: (value) async {
      if (expands && mounted) {
        newWidth = value;
        if (width < value) {
          widthTween = Tween<double>(begin: width, end: value);
          expandAnimationController!.value = 0;
          await expandAnimationController!.forward();
        } else {
          widthTween = Tween<double>(begin: value, end: width);
          expandAnimationController!.value = 1;
          await expandAnimationController!.reverse();
        }
      }
    },
  );

  bool get hasExpansionController => widget.expansionController != null;
  bool get expands => widget.shrunkWidth != null && widget.shrunkChild != null;
  double get width =>
      expands ? widthTween.evaluate(expandAnimation!) : widgetWidthNotNull;
  late double newWidth = widgetWidthNotNull;
  double get expandRatio =>
      ((width - shrunkWidth) / (widgetWidthNotNull - shrunkWidth)).clamp(0, 1);
  Widget get child => Stack(
        alignment: AlignmentDirectional.center,
        children: [
          if (expandRatio != 1)
            Opacity(
              opacity: 1 - expandRatio,
              child: widget.shrunkChild,
            ),
          if (expandRatio != 0)
            Opacity(
              opacity: expandRatio,
              child: widget.child,
            ),
        ],
      );

  bool firstBuild = true;
  @override
  void initState() {
    switch (widget.buttonType) {
      case ActionBarButtonType.single:
        state = widget.state ?? true; // False is allowed in single
        break;
      case ActionBarButtonType.onOff:
        state = widget.state ?? false;
        break;
      case ActionBarButtonType.noneOnOff:
        state = widget.state;
        break;
      case ActionBarButtonType.partialOnOff:
        state = widget.state;
        break;
    }
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animation = widget.animation ?? animationController;
    animation.addListener(() {
      if (mounted) setState(() {});
    });
    if (expands) {
      expandAnimationController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300))
        ..addListener(() {
          if (mounted) setState(() {});
        });
      expandAnimation = CurvedAnimation(
        parent: expandAnimationController!,
        curve: Curves.easeOutExpo,
        reverseCurve: Curves.easeInExpo,
      );
    } else {
      expandAnimationController = null;
      expandAnimation = null;
    }
    if (active) {
      if (widget.buttonType == ActionBarButtonType.single) {
        animationController.value = 1;
      } else {
        animationController.forward();
        expand(true);
      }
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    if (expands) expandAnimationController!.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ActionBarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != state) {
      switch (widget.state) {
        case null:
          if (widget.buttonType == ActionBarButtonType.noneOnOff ||
              widget.buttonType == ActionBarButtonType.partialOnOff) {
            state = null;
          }
          break;
        case false:
          state = false;
          break;
        case true:
          state = true;
          break;
      }
      Future.microtask(
        () {
          if (active && !animationController.isCompleted) {
            animationController.forward();
            expand(true);
          } else if (!active &&
              !(animationController.status == AnimationStatus.reverse ||
                  animationController.value == 0)) {
            animationController.reverse();
            expand(false);
          }
        },
      ); // This is in a microtask since it sets state during build
    }
  }

  @override
  Widget build(BuildContext context) {
    if (firstBuild) {
      firstBuild = false;
      if (hasExpansionController) {
        widget.expansionController!.addWidth(
            (!widget.connectLeft ? context.actionBarIconPadding.left / 2 : 0) +
                (!widget.connectRight
                    ? context.actionBarIconPadding.right / 2
                    : 0));
        if (expands) {
          _expand = widget.expansionController!.addItem(expandableItem);
        } else {
          widget.expansionController!
              .addWidth(widget.width ?? context.actionBarButtonSizeHorizontal);
        }
      }
    }

    return Tooltip(
      message: widget.tooltip ?? "",
      child: Selector<CardColorScheme, Tuple2<Color, Color>>(
        selector: (context, cardColorScheme) => Tuple2(
            widget.color ??
                (context.realDark ? context.surface : cardColorScheme.card),
            widget.activeColor ?? widget.color ?? cardColorScheme.selected),
        builder: (context, data, _) => Container(
          margin: EdgeInsets.only(
            left:
                !widget.connectLeft ? context.actionBarIconPadding.left / 2 : 0,
            right: !widget.connectRight
                ? context.actionBarIconPadding.right / 2
                : 0,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? ColorTween(begin: data.item1, end: data.item2)
                    .evaluate(animation)
                : context.brightness == Brightness.light
                    ? Colors.grey[300]
                    : !context.realDark
                        ? Colors.grey[800]
                        : context.surface,
            borderRadius: borderRadius,
          ),
          width: width,
          height: widget.height ?? context.actionBarButtonSizeVertical,
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.hardEdge,
            borderRadius: borderRadius,
            child: InkWell(
              onTap: widget.enabled
                  ? () {
                      if (mounted) {
                        setState(() {
                          switch (state) {
                            case null:
                              state = true;
                              break;
                            case false:
                              if (widget.buttonType ==
                                  ActionBarButtonType.noneOnOff) {
                                state = null;
                              } else if (widget.buttonType !=
                                  ActionBarButtonType.single) {
                                state = true;
                              }
                              break;
                            case true:
                              if (widget.buttonType !=
                                  ActionBarButtonType.single) {
                                state = false;
                              }
                          }
                        });
                        if (active) {
                          animationController.forward();
                          expand(true);
                        } else {
                          animationController.reverse();
                          expand(false);
                        }
                      }
                      widget.onPressed(state);
                    }
                  : null,
              child: Container(
                margin: widget.innerPadding ?? context.actionBarIconPadding,
                alignment: Alignment.centerLeft,
                width: width,
                height: widget.height ?? context.actionBarButtonSizeVertical,
                child: widget.buttonType == ActionBarButtonType.noneOnOff
                    ? BiStateIndicator(
                        state: state == false,
                        child: state == false && widget.falseChild != null
                            ? widget.falseChild!
                            : child,
                      )
                    : state != null
                        ? state == true
                            ? child
                            : widget.falseChild ?? child
                        : widget.partialChild ?? widget.falseChild ?? child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Doropdown button that can shrink into an icon when not opened
/// Passing color is mandatory either directly or with a [CardColorScheme] [Provider]
class ActionBarDropdownButton<T> extends StatefulWidget {
  final Widget child;
  final T selected;
  final ExpansionController? expansionController;
  final Widget? expandedChild;
  final List<PopupMenuEntry<T>> Function() itemBuilder;
  final ValueChanged<T> onSelected;
  final double? minExpandedWidth;
  final double? maxExpandedWidth;
  final int visibleItemCount;
  final Color? color;
  final Color? activeColor;
  final String? tooltip;
  final bool Function(T) active;
  final bool connectLeft;
  final bool connectRight;
  const ActionBarDropdownButton({
    required this.child,
    required this.selected,
    this.expansionController,
    this.expandedChild,
    required this.itemBuilder,
    required this.onSelected,
    this.minExpandedWidth,
    this.maxExpandedWidth,
    this.visibleItemCount = 10,
    this.color,
    this.activeColor,
    this.tooltip,
    required this.active,
    this.connectLeft = false,
    this.connectRight = false,
  });
  @override
  _ActionBarDropdownButtonState<T> createState() =>
      _ActionBarDropdownButtonState<T>();
}

class _ActionBarDropdownButtonState<T> extends State<ActionBarDropdownButton<T>>
    with TickerProviderStateMixin {
  late final Animation<double> activeAnimation;
  late final Animation<double>? expandAnimation;
  late final Animation<double> openAnimation;
  late final AnimationController activeAnimationController;
  late final AnimationController? expandAnimationController;
  late final AnimationController openAnimationController;

  late T selected = widget.selected;
  bool get active => widget.active(selected);

  late double minExpandedWidth = widget.minExpandedWidth ??
      (widget.maxExpandedWidth != null
          ? widget.maxExpandedWidth!
              .clamp(0, context.actionBarButtonSizeHorizontal * 3)
          : context.actionBarButtonSizeHorizontal);
  late Tween<double> widthTween = Tween<double>(
      begin: context.actionBarButtonSizeHorizontal,
      end: hasExpansionController
          ? context.actionBarButtonSizeHorizontal
          : widget.maxExpandedWidth ?? context.actionBarButtonSizeHorizontal);
  late void Function(bool) _expand = (shouldExpand) {
    if (shouldExpand) {
      expandAnimationController!.forward();
    } else {
      expandAnimationController!.reverse();
    }
  };
  void expand(bool shouldExpand) {
    if (expands && mounted) _expand(shouldExpand);
  }

  late Expandable expandableItem = Expandable(
    minWidth: context.actionBarButtonSizeHorizontal,
    minExpandedWidth: minExpandedWidth,
    maxExpandedWidth:
        widget.maxExpandedWidth ?? context.actionBarButtonSizeHorizontal,
    onWidthChanged: (value) async {
      if (expands && mounted) {
        newWidth = value;
        if (width < value) {
          widthTween = Tween<double>(begin: width, end: value);
          expandAnimationController!.value = 0;
          await expandAnimationController!.forward();
        } else {
          widthTween = Tween<double>(begin: value, end: width);
          expandAnimationController!.value = 1;
          await expandAnimationController!.reverse();
        }
      }
    },
  );

  bool get hasExpansionController => widget.expansionController != null;
  bool get expands => widget.expandedChild != null;
  double get width => expands
      ? widthTween.evaluate(expandAnimation!)
      : context.actionBarButtonSizeHorizontal;
  late double newWidth = context.actionBarButtonSizeHorizontal;

  bool firstBuild = true;
  @override
  void initState() {
    super.initState();
    activeAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() {
        if (mounted) setState(() {});
      });
    activeAnimation = CurvedAnimation(
      parent: activeAnimationController,
      curve: Curves.easeOutExpo,
    );
    if (expands) {
      expandAnimationController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300))
        ..addListener(() {
          if (mounted) setState(() {});
        });
      expandAnimation = CurvedAnimation(
        parent: expandAnimationController!,
        curve: Curves.easeOutExpo,
        reverseCurve: Curves.easeInExpo,
      );
    } else {
      expandAnimationController = null;
      expandAnimation = null;
    }
    openAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() {
        if (mounted) setState(() {});
      });
    openAnimation = CurvedAnimation(
      parent: openAnimationController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInExpo,
    );
    if (active && !activeAnimationController.isCompleted) {
      activeAnimationController.forward();
      expand(true);
    }
  }

  @override
  void dispose() {
    openAnimationController.dispose();
    activeAnimationController.dispose();
    if (expands) expandAnimationController!.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ActionBarDropdownButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minExpandedWidth != oldWidget.minExpandedWidth ||
        widget.maxExpandedWidth != oldWidget.maxExpandedWidth) {
      minExpandedWidth = widget.minExpandedWidth ??
          (widget.maxExpandedWidth != null
              ? widget.maxExpandedWidth!
                  .clamp(0, context.actionBarButtonSizeHorizontal * 3)
              : context.actionBarButtonSizeHorizontal);
      expandableItem.minExpandedWidth = minExpandedWidth;
    }
    if (widget.maxExpandedWidth != oldWidget.maxExpandedWidth) {
      widthTween = Tween<double>(
          begin: context.actionBarButtonSizeHorizontal,
          end: hasExpansionController
              ? context.actionBarButtonSizeHorizontal
              : widget.maxExpandedWidth ??
                  context.actionBarButtonSizeHorizontal);
      expandableItem.maxExpandedWidth =
          widget.maxExpandedWidth ?? context.actionBarButtonSizeHorizontal;
    }
    if (widget.selected != selected && widget.selected != null) {
      selected = widget.selected;
    }
    Future.microtask(
      () async {
        if (active && !activeAnimationController.isCompleted) {
          activeAnimationController.forward();
          expand(true);
        } else if (!active &&
            !(activeAnimationController.status == AnimationStatus.reverse ||
                activeAnimationController.value == 0)) {
          await Future.delayed(Duration(milliseconds: 150));
          activeAnimationController.reverse();
          expand(false);
        }
      },
    ); // This is in a microtask since it sets state during build
  }

  @override
  Widget build(BuildContext context) {
    if (firstBuild) {
      firstBuild = false;
      if (hasExpansionController) {
        widget.expansionController!.addWidth(
            (!widget.connectLeft ? context.actionBarIconPadding.left / 2 : 0) +
                (!widget.connectRight
                    ? context.actionBarIconPadding.right / 2
                    : 0));
        if (expands) {
          _expand = widget.expansionController!.addItem(expandableItem);
        } else {
          widget.expansionController!.addWidth(width);
        }
      }
    }
    var borderRadiusTween = BorderRadiusTween(
      begin: BorderRadius.only(
        topLeft:
            !widget.connectLeft ? context.actionBarIconRadius : Radius.zero,
        topRight:
            !widget.connectRight ? context.actionBarIconRadius : Radius.zero,
        bottomLeft:
            !widget.connectLeft ? context.actionBarIconRadius : Radius.zero,
        bottomRight:
            !widget.connectRight ? context.actionBarIconRadius : Radius.zero,
      ),
      end: BorderRadius.only(
        topLeft:
            !widget.connectLeft ? context.actionBarIconRadius : Radius.zero,
        topRight:
            !widget.connectRight ? context.actionBarIconRadius : Radius.zero,
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
    );
    double expandRatio = ((width - context.actionBarButtonSizeHorizontal) /
            (minExpandedWidth - context.actionBarButtonSizeHorizontal))
        .clamp(0, 1);
    return Selector<CardColorScheme, Tuple2<Color, Color>>(
      selector: (context, cardColorScheme) => Tuple2(
          widget.color ??
              (context.realDark ? context.surface : cardColorScheme.card),
          widget.activeColor ?? widget.color ?? cardColorScheme.selected),
      builder: (context, data, _) => Container(
        margin: EdgeInsets.only(
          left: !widget.connectLeft ? context.actionBarIconPadding.left / 2 : 0,
          right:
              !widget.connectRight ? context.actionBarIconPadding.right / 2 : 0,
        ),
        decoration: BoxDecoration(
          color: ColorTween(begin: data.item1, end: data.item2)
              .evaluate(activeAnimation),
          borderRadius: borderRadiusTween.evaluate(openAnimation),
        ),
        height: context.actionBarButtonSizeVertical,
        width: width,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.hardEdge,
          borderRadius: borderRadiusTween.evaluate(openAnimation),
          child: MyPopupMenuButton<T>(
            splashRadius: 0,
            padding: EdgeInsets.zero,
            menuPadding: EdgeInsets.symmetric(vertical: 0),
            constraints: BoxConstraints(
              minWidth: context.actionBarButtonSizeHorizontal,
              maxWidth: newWidth,
            ),
            visibleItemCount: widget.visibleItemCount,
            itemExtent: context.actionBarButtonSizeVertical,
            position: PopupMenuPosition.under,
            color: data.item2,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: context.actionBarIconRadius)),
            elevation: 1,
            tooltip: widget.tooltip,
            child: Container(
              padding: context.actionBarIconPadding,
              alignment: Alignment.centerLeft,
              child: widget.expandedChild == null
                  ? widget.child
                  : Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        if (expandRatio != 1)
                          Opacity(
                            opacity: 1 - expandRatio,
                            child: widget.child,
                          ),
                        if (expandRatio != 0)
                          Opacity(
                            opacity: expandRatio,
                            child: widget.expandedChild,
                          ),
                      ],
                    ),
            ),
            itemBuilder: (context) {
              return widget.itemBuilder();
            },
            onSelected: (value) {
              if (value != selected) {
                if (mounted) setState(() => selected = value);
                widget.onSelected(value);
              }
            },
            beforeOpened: () async {
              activeAnimationController.forward();
              expand(true);
              openAnimationController.forward();
              await Future.delayed(Duration(milliseconds: 100));
            },
            afterClosed: () async {
              await Future.delayed(Duration(milliseconds: 150));
              if (!active) {
                activeAnimationController.reverse();
                expand(false);
              }
              openAnimationController.reverse();
            },
          ),
        ),
      ),
    );
  }
}

/// Search button that can expand to show an in-place text field.
/// Passing color is mandatory either directly or with a [CardColorScheme] [Provider]
class ActionBarExpandingSearchButton extends StatefulWidget {
  final String query;
  final bool popupSearch;
  final bool expands;
  final ExpansionController? expansionController;
  final ValueChanged<String> onQueryChanged;
  final double expandedWidth;
  final Color? color;
  final Color? activeColor;
  final bool connectLeft;
  final bool connectRight;
  const ActionBarExpandingSearchButton({
    this.query = "",
    this.popupSearch = false,
    this.expands = true,
    this.expansionController,
    required this.onQueryChanged,
    this.expandedWidth = 200,
    this.color,
    this.activeColor,
    this.connectLeft = false,
    this.connectRight = false,
  });
  @override
  _ActionBarExpandingSearchButtonState createState() =>
      _ActionBarExpandingSearchButtonState();
}

class _ActionBarExpandingSearchButtonState
    extends State<ActionBarExpandingSearchButton>
    with TickerProviderStateMixin {
  late final Animation<double> activeAnimation;
  late final AnimationController activeAnimationController;
  late final Animation<double>? expandAnimation;
  late final AnimationController? expandAnimationController;

  late String query = widget.query;

  late final double minExpandedWidth =
      context.actionBarButtonSizeHorizontal * 3;
  late Tween<double> widthTween = Tween<double>(
      begin: context.actionBarButtonSizeHorizontal,
      end: hasExpansionController
          ? context.actionBarButtonSizeHorizontal
          : widget.expandedWidth);
  late void Function(bool) _expand = (shouldExpand) {
    if (shouldExpand) {
      expandAnimationController!.forward();
    } else {
      expandAnimationController!.reverse();
    }
  };
  void expand(bool shouldExpand) {
    if (widget.expands && mounted) _expand(shouldExpand);
  }

  late Expandable expandableItem = Expandable(
    minWidth: context.actionBarButtonSizeHorizontal,
    minExpandedWidth: minExpandedWidth,
    maxExpandedWidth: widget.expandedWidth,
    onWidthChanged: (value) async {
      if (mounted) {
        newWidth = value;
        if (width < value) {
          widthTween = Tween<double>(begin: width, end: value);
          expandAnimationController!.value = 0;
          await expandAnimationController!.forward();
        } else {
          widthTween = Tween<double>(begin: value, end: width);
          expandAnimationController!.value = 1;
          await expandAnimationController!.reverse();
        }
      }
    },
  );

  bool get hasExpansionController => widget.expansionController != null;
  double get width => widget.expands
      ? widthTween.evaluate(expandAnimation!)
      : context.actionBarButtonSizeHorizontal;
  late double newWidth = context.actionBarButtonSizeHorizontal;

  bool firstBuild = true;
  @override
  void initState() {
    super.initState();
    activeAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() {
        if (mounted) setState(() {});
      });
    activeAnimation = CurvedAnimation(
      parent: activeAnimationController,
      curve: Curves.easeOutExpo,
    );
    if (widget.expands) {
      expandAnimationController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300))
        ..addListener(() {
          if (mounted) setState(() {});
        });
      expandAnimation = CurvedAnimation(
        parent: expandAnimationController!,
        curve: Curves.easeOutExpo,
        reverseCurve: Curves.easeInExpo,
      );
    } else {
      expandAnimationController = null;
      expandAnimation = null;
    }
  }

  @override
  void dispose() {
    if (widget.expands) expandAnimationController!.dispose();
    activeAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ActionBarExpandingSearchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != query) {
      query = widget.query;
      widget.onQueryChanged(query);
      activeAnimationController.forward();
      expand(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (firstBuild) {
      firstBuild = false;
      if (hasExpansionController) {
        widget.expansionController!.addWidth(
            (!widget.connectLeft ? context.actionBarIconPadding.left / 2 : 0) +
                (!widget.connectRight
                    ? context.actionBarIconPadding.right / 2
                    : 0));
        if (widget.expands)
          _expand = widget.expansionController!.addItem(expandableItem);
      }
    }
    BorderRadius borderRadius = BorderRadius.horizontal(
      left: !widget.connectLeft ? context.actionBarIconRadius : Radius.zero,
      right: !widget.connectRight ? context.actionBarIconRadius : Radius.zero,
    );
    var borderRadiusTween = BorderRadiusTween(
      begin: BorderRadius.only(
        topLeft:
            !widget.connectLeft ? context.actionBarIconRadius : Radius.zero,
        topRight:
            !widget.connectRight ? context.actionBarIconRadius : Radius.zero,
        bottomLeft:
            !widget.connectLeft ? context.actionBarIconRadius : Radius.zero,
        bottomRight:
            !widget.connectRight ? context.actionBarIconRadius : Radius.zero,
      ),
      end: BorderRadius.all(context.actionBarIconRadius),
    );
    double expandRatio =
        (((width / context.actionBarButtonSizeHorizontal) - 1) / 2).clamp(0, 1);
    return Selector<CardColorScheme, Tuple2<Color, Color>>(
      selector: (context, cardColorScheme) => Tuple2(
          widget.color ??
              (context.realDark ? context.surface : cardColorScheme.card),
          widget.activeColor ?? widget.color ?? cardColorScheme.selected),
      builder: (context, data, _) => Container(
        margin: EdgeInsets.only(
          left: !widget.connectLeft ? context.actionBarIconPadding.left / 2 : 0,
          right:
              !widget.connectRight ? context.actionBarIconPadding.right / 2 : 0,
        ),
        decoration: BoxDecoration(
          color: ColorTween(begin: data.item1, end: data.item2)
              .evaluate(activeAnimation),
          borderRadius: borderRadius,
        ),
        height: context.actionBarButtonSizeVertical,
        width: width,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.hardEdge,
          borderRadius: borderRadiusTween.evaluate(expandAnimation!),
          child: !widget.expands
              ? _SearchIconButton(
                  query: query,
                  onFieldSubmitted: (value) {
                    if (value != query) {
                      if (mounted) setState(() => query = value);
                      widget.onQueryChanged(query);
                    }
                  },
                  activeAnimationController: activeAnimationController,
                  color: data.item1,
                )
              : Stack(
                  alignment: AlignmentDirectional.centerEnd,
                  children: [
                    if (expandRatio != 1)
                      Opacity(
                        opacity: 1 - expandRatio,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          onTap: () async {
                            activeAnimationController.forward();
                            expand(true);
                            if (widget.popupSearch) {
                              await showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: MaterialLocalizations.of(context)
                                    .modalBarrierDismissLabel,
                                barrierColor: Colors.black54,
                                transitionDuration:
                                    const Duration(milliseconds: 200),
                                pageBuilder:
                                    (context, animaiton, secondaryAnimation) =>
                                        SearchEpisode(
                                  onSearch: (value) {
                                    if (value != query) {
                                      if (mounted)
                                        setState(() => query = value);
                                      widget.onQueryChanged(query);
                                    }
                                  },
                                  accentColor: data.item1,
                                  query: query,
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: context.actionBarIconPadding,
                            width: context.actionBarButtonSizeHorizontal,
                            height: context.actionBarButtonSizeVertical,
                            child: Icon(
                              Icons.search,
                              size: context.actionBarIconSize,
                            ),
                          ),
                        ),
                      ),
                    if (expandRatio != 0)
                      Opacity(
                        opacity: expandRatio,
                        child: Row(
                          children: [
                            if (widget.popupSearch)
                              Container(
                                padding: EdgeInsets.only(
                                    top: 5, bottom: 5, left: 2, right: 2),
                                decoration: BoxDecoration(
                                    borderRadius: borderRadius,
                                    border: Border.all(
                                        width: 2,
                                        color: context.textColor
                                            .withValues(alpha: 0.2))),
                                child: InkWell(
                                  child: query == ""
                                      ? Row(
                                          children: [
                                            Text(
                                              context.s.search,
                                              maxLines: 1,
                                              style: TextStyle(
                                                color: context.textColor
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            Spacer()
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                query,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                  onTap: () async {
                                    await showGeneralDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      barrierLabel:
                                          MaterialLocalizations.of(context)
                                              .modalBarrierDismissLabel,
                                      barrierColor: Colors.black54,
                                      transitionDuration:
                                          const Duration(milliseconds: 200),
                                      pageBuilder: (context, animaiton,
                                              secondaryAnimation) =>
                                          SearchEpisode(
                                        onSearch: (value) {
                                          if (value != query) {
                                            if (mounted)
                                              setState(() => query = value);
                                            widget.onQueryChanged(query);
                                          }
                                        },
                                        accentColor: data.item1,
                                        query: query,
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: width -
                                    context.actionBarButtonSizeHorizontal,
                                alignment: Alignment.center,
                                child: TextFormField(
                                  initialValue: query,
                                  decoration: InputDecoration(
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    hintText: context.s.searchEpisode,
                                    hintStyle: context.textTheme.titleMedium,
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide.none),
                                  ),
                                  autofocus: false,
                                  maxLines: 1,
                                  onFieldSubmitted: (value) {
                                    if (value != query) {
                                      if (mounted)
                                        setState(() => query = value);
                                      widget.onQueryChanged(query);
                                    }
                                  },
                                ),
                              ),
                            Container(
                              width: context.actionBarButtonSizeHorizontal,
                              child: Material(
                                color: Colors.transparent,
                                child: IconButton(
                                  padding: context.actionBarIconPadding,
                                  icon: SizedBox(
                                    width:
                                        context.actionBarButtonSizeHorizontal,
                                    height: context.actionBarButtonSizeVertical,
                                    child: Icon(Icons.close,
                                        color: context.actionBarIconColor),
                                  ),
                                  iconSize: context.actionBarIconSize,
                                  onPressed: () async {
                                    if (mounted) setState(() => query = "");
                                    widget.onQueryChanged(query);
                                    activeAnimationController.reverse();
                                    expand(false);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SearchIconButton extends StatelessWidget {
  final String query;
  final void Function(String)? onFieldSubmitted;
  final AnimationController activeAnimationController;
  final Color color;
  _SearchIconButton(
      {required this.query,
      required this.onFieldSubmitted,
      required this.activeAnimationController,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      radius: 0,
      splashColor: Colors.transparent,
      onTap: () async {
        activeAnimationController.forward();
        await showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animaiton, secondaryAnimation) =>
              SearchEpisode(
            onSearch: onFieldSubmitted!,
            accentColor: color,
            query: query,
          ),
        );
      },
      child: Container(
        margin: context.actionBarIconPadding,
        width: context.actionBarButtonSizeHorizontal,
        height: context.actionBarButtonSizeVertical,
        child: Icon(
          Icons.search,
          size: context.actionBarIconSize,
        ),
      ),
    );
  }
}

class SearchEpisode extends StatefulWidget {
  SearchEpisode(
      {required this.onSearch, this.accentColor, this.query, Key? key})
      : super(key: key);
  final ValueChanged<String> onSearch;
  final Color? accentColor;
  final String? query;
  @override
  _SearchEpisodeState createState() => _SearchEpisodeState();
}

class _SearchEpisodeState extends State<SearchEpisode> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlayWithBarrier,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusMedium,
        ),
        backgroundColor: widget.accentColor?.toWeakBackround(context),
        elevation: 1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        titlePadding: const EdgeInsets.all(20),
        actionsPadding: EdgeInsets.zero,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              s.cancel,
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_query.isNotEmpty) {
                widget.onSearch(_query);
                Navigator.of(context).pop();
              }
            },
            child: Text(s.confirm, style: TextStyle(color: widget.accentColor)),
          )
        ],
        title: SizedBox(width: context.width - 160, child: Text(s.search)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              initialValue: widget.query,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                hintText: s.searchEpisode,
                hintStyle: TextStyle(fontSize: 18),
                filled: true,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.accentColor ?? context.accentColor,
                      width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: context.accentColor, width: 2.0),
                ),
              ),
              cursorRadius: Radius.circular(2),
              autofocus: true,
              maxLines: 1,
              onChanged: (value) {
                if (mounted) setState(() => _query = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Controls the width of [Expandable] items to fit within [maxWidth].
class ExpansionController {
  ValueGetter<double> maxWidth;
  ExpansionController({required this.maxWidth});
  List<Expandable> _items = [];
  double _itemsWidth = 0;
  double get _availableWidth => maxWidth() - _itemsWidth;

  List<int> _expandedItems = [];

  /// Use to add the width of non-expandable items.
  void resetWidth() {
    _itemsWidth = 0;
    _items.forEach((item) {
      _itemsWidth += item.currentWidth;
    });
  }

  /// Use to add the width of non-expandable items.
  void addWidth(double width) {
    _itemsWidth += width;
    adjustWidths();
  }

  /// Adds an expandable item. Returns callback used to change shouldExpand property of the item.
  void Function(bool shouldExpand) addItem(Expandable item) {
    int index = _items.length;
    _items.add(item);
    _itemsWidth += item.currentWidth;
    return (shouldExpand) {
      _itemsWidth += item.shouldExpand(shouldExpand);
      if (shouldExpand) {
        _expandedItems.remove(index);
        _expandedItems.add(index);
      } else {
        _expandedItems.remove(index);
      }
      adjustWidths();
    };
  }

  /// Adjusts expandable widths to fit [maxWidth];
  void adjustWidths() {
    int minimize = 0;
    while (_availableWidth < 0) {
      for (int i = 0; i < _expandedItems.length; i++) {
        Expandable item = _items[_expandedItems[i]];
        _itemsWidth +=
            item.changeWidthBy(_availableWidth, minimize: minimize > i);
      }
      minimize++;
      assert(minimize <= _expandedItems.length * _expandedItems.length,
          "Widget widths don't fit. This probably means you're readding widgets that are already added to the controller.");
    }
    for (int i = 0; i < _items.length; i++) {
      Expandable item = _items[i];
      _itemsWidth += item.changeWidthBy(_availableWidth);
    }
  }
}

/// Stores data about an expandable element for an [ExpansionController].
class Expandable {
  /// Width while collapsed
  final double minWidth;

  /// Minimum width while expanded
  double minExpandedWidth;

  /// Maximum necessary width while expanded
  double maxExpandedWidth;

  /// Wheter the item can expand
  bool _shouldExpand = false;

  /// Callback for width change
  final ValueSetter<double> onWidthChanged;

  Expandable({
    required this.minWidth,
    required this.minExpandedWidth,
    required this.maxExpandedWidth,
    required this.onWidthChanged,
  })  : assert(minExpandedWidth >= minWidth),
        assert(maxExpandedWidth >= minExpandedWidth);

  late double _currentWidth = minWidth;
  double get currentWidth => _currentWidth;
  set currentWidth(double width) {
    _currentWidth = width;
    onWidthChanged(currentWidth);
  }

  bool get expanded => currentWidth != minWidth;

  /// Sets [_shouldExpand] to [boo] and returns the width change.
  double shouldExpand(bool boo) {
    double widthChange = 0;
    if (boo != _shouldExpand) {
      if (boo) {
        widthChange = maxExpandedWidth - currentWidth;
        currentWidth = maxExpandedWidth;
      } else {
        widthChange = minWidth - currentWidth;
        currentWidth = minWidth;
      }
    }
    _shouldExpand = boo;
    return widthChange;
  }

  /// Tries changing width to [width] and returns the width change.
  double changeWidthBy(double width, {bool minimize = false}) {
    double widthChange = 0;
    if (currentWidth + width > minExpandedWidth && _shouldExpand) {
      if (currentWidth + width < maxExpandedWidth) {
        widthChange = width;
        currentWidth = currentWidth + width;
      } else {
        widthChange = maxExpandedWidth - currentWidth;
        currentWidth = maxExpandedWidth;
      }
    } else if (currentWidth + width > minWidth &&
        currentWidth + width < minExpandedWidth &&
        _shouldExpand &&
        width < 0 &&
        !minimize) {
      widthChange = minExpandedWidth - currentWidth;
      currentWidth = minExpandedWidth;
    } else if (currentWidth + width <= minWidth || minimize) {
      widthChange = minWidth - currentWidth;
      currentWidth = minWidth;
    }
    return widthChange;
  }
}
