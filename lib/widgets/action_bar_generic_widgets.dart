import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tsacdop/util/extension_helper.dart';

import 'custom_popupmenu.dart';
import 'custom_widget.dart';

enum ActionBarButtonType { single, onOff, noneOnOff, partialOnOff }

/// General purpose button with flexible state types.
/// Single: State handled outside the button
/// onOff: State swtiched false->true->false
/// noneOnOff: State switched null->true->false->null. False (off) is represented with crossing out of the child.
/// partialOnOff: State switched null->true->false->true.
class ActionBarButton extends StatefulWidget {
  final Widget child;
  final Widget? falseChild;
  final Widget? partialChild;
  final bool? state;
  final ActionBarButtonType buttonType;
  final ValueChanged<bool?> onPressed;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final EdgeInsets? innerPadding;
  final Color color;
  final Color? activeColor;
  final BorderRadius? borderRadius;
  final String? tooltip;
  final bool enabled;
  final Animation<double>? animation;
  final bool connectLeft;
  final bool connectRight;
  const ActionBarButton({
    required this.child,
    this.falseChild,
    this.partialChild,
    this.state,
    this.buttonType = ActionBarButtonType.single,
    required this.onPressed,
    this.decoration,
    this.width,
    this.height,
    this.innerPadding,
    required this.color,
    this.activeColor,
    this.borderRadius,
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
    with SingleTickerProviderStateMixin {
  late final Animation<double> animation;
  late final AnimationController animationController;

  late bool? state;

  bool get active => widget.buttonType == ActionBarButtonType.noneOnOff
      ? state != null
      : widget.buttonType == ActionBarButtonType.partialOnOff
          ? state != false
          : state!;

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
    if (active) {
      if (widget.buttonType == ActionBarButtonType.single) {
        animationController.value = 1;
      } else {
        animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    animationController.dispose();
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
      if (active) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = widget.borderRadius ??
        BorderRadius.horizontal(
          left: !widget.connectLeft ? context.iconRadius : Radius.zero,
          right: !widget.connectRight ? context.iconRadius : Radius.zero,
        );
    return Container(
      margin: EdgeInsets.only(
        left: !widget.connectLeft ? context.iconPadding.left / 2 : 0,
        right: !widget.connectRight ? context.iconPadding.right / 2 : 0,
      ),
      decoration: widget.decoration ??
          BoxDecoration(
            color: widget.enabled
                ? ColorTween(
                        begin: widget.color.toWeakBackround(context),
                        end: widget.activeColor ?? widget.color)
                    .evaluate(animation)
                : context.brightness == Brightness.light
                    ? Colors.grey[300]
                    : !context.realDark
                        ? Colors.grey[800]
                        : context.background,
            borderRadius: borderRadius,
          ),
      width: widget.width ?? context.iconButtonSizeHorizontal,
      height: widget.height ?? context.iconButtonSizeVertical,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.hardEdge,
        borderRadius: borderRadius,
        child: IconButton(
          padding: widget.innerPadding ?? context.iconPadding,
          icon: SizedBox(
            width: widget.width ?? context.iconButtonSizeHorizontal,
            height: widget.height ?? context.iconButtonSizeVertical,
            child: widget.buttonType == ActionBarButtonType.noneOnOff
                ? BiStateIndicator(
                    state: state == false,
                    child: state == false && widget.falseChild != null
                        ? widget.falseChild!
                        : widget.child,
                  )
                : state != null
                    ? state == true
                        ? widget.child
                        : widget.falseChild ?? widget.child
                    : widget.partialChild ?? widget.falseChild ?? widget.child,
          ),
          iconSize: context.iconSize,
          onPressed: widget.enabled
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
                          if (widget.buttonType != ActionBarButtonType.single) {
                            state = false;
                          }
                      }
                    });
                    if (active) {
                      animationController.forward();
                    } else {
                      animationController.reverse();
                    }
                  }
                  widget.onPressed(state);
                }
              : null,
        ),
      ),
    );
  }
}

/// Doropdown button that can shrink into an icon when not opened
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
  final Color color;
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
    required this.color,
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
  late Animation<double>? expandRatioAnimation;
  late final Animation<double> openAnimation;
  late final AnimationController activeAnimationController;
  late final AnimationController? expandAnimationController;
  late final AnimationController openAnimationController;

  late T selected = widget.selected;
  bool get active => widget.active(selected);

  late final double minExpandedWidth = widget.minExpandedWidth ??
      (widget.maxExpandedWidth != null
          ? widget.maxExpandedWidth!
              .clamp(0, context.iconButtonSizeHorizontal * 3)
          : context.iconButtonSizeHorizontal);
  late Tween<double> widthTween = Tween<double>(
      begin: context.iconButtonSizeHorizontal,
      end: hasExpansionController
          ? context.iconButtonSizeHorizontal
          : widget.maxExpandedWidth ?? context.iconButtonSizeHorizontal);
  late void Function(bool) _expand = hasExpansionController
      ? widget.expansionController!.addItem(expandableItem)
      : (shouldExpand) {
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
    minWidth: context.iconButtonSizeHorizontal,
    minExpandedWidth: minExpandedWidth,
    maxExpandedWidth:
        widget.maxExpandedWidth ?? context.iconButtonSizeHorizontal,
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
      : context.iconButtonSizeHorizontal;
  late double newWidth = context.iconButtonSizeHorizontal;

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
      expandRatioAnimation = expandAnimation;
    } else {
      expandAnimationController = null;
      expandAnimation = null;
      expandRatioAnimation = null;
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
    if (active) {
      activeAnimationController.forward();
      expand(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (expands && expandRatioAnimation != null) {
      expandRatioAnimation = CurvedAnimation(
          parent: widthTween.animate(expandAnimation!),
          curve: Interval(context.iconButtonSizeHorizontal, minExpandedWidth));
    }
    var borderRadiusTween = BorderRadiusTween(
      begin: BorderRadius.only(
        topLeft: !widget.connectLeft ? context.iconRadius : Radius.zero,
        topRight: !widget.connectRight ? context.iconRadius : Radius.zero,
        bottomLeft: !widget.connectLeft ? context.iconRadius : Radius.zero,
        bottomRight: !widget.connectRight ? context.iconRadius : Radius.zero,
      ),
      end: BorderRadius.only(
        topLeft: !widget.connectLeft ? context.iconRadius : Radius.zero,
        topRight: !widget.connectRight ? context.iconRadius : Radius.zero,
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
    );
    return Container(
      margin: EdgeInsets.only(
        left: !widget.connectLeft ? context.iconPadding.left / 2 : 0,
        right: !widget.connectRight ? context.iconPadding.right / 2 : 0,
      ),
      decoration: BoxDecoration(
        color: ColorTween(
                begin: widget.color.toWeakBackround(context),
                end: widget.activeColor ?? widget.color)
            .evaluate(activeAnimation),
        borderRadius: borderRadiusTween.evaluate(openAnimation),
      ),
      height: context.iconButtonSizeVertical,
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
            minWidth: context.iconButtonSizeHorizontal,
            maxWidth: newWidth,
          ),
          visibleItemCount: widget.visibleItemCount,
          itemExtent: context.iconButtonSizeVertical,
          position: PopupMenuPosition.under,
          color: widget.activeColor ?? widget.color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: context.iconRadius)),
          elevation: 1,
          tooltip: widget.tooltip,
          child: Container(
            padding: context.iconPadding,
            alignment: Alignment.centerLeft,
            child: widget.expandedChild == null
                ? widget.child
                : Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      FadeTransition(
                        opacity: ReverseAnimation(expandRatioAnimation!),
                        child: widget.child,
                      ),
                      FadeTransition(
                        opacity: expandRatioAnimation!,
                        child: widget.expandedChild,
                      )
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
    );
  }
}

/// Search button that can expand to show an in-place text field.
class ActionBarExpandingSearchButton extends StatefulWidget {
  final String query;
  final bool popupSearch;
  final bool expands;
  final ExpansionController? expansionController;
  final ValueChanged<String> onQueryChanged;
  final double expandedWidth;
  final Color color;
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
    required this.color,
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
  late Animation<double>? expandRatioAnimation;
  late final AnimationController? expandAnimationController;

  late String query = widget.query;

  late final double minExpandedWidth = context.iconButtonSizeHorizontal * 3;
  late Tween<double> widthTween = Tween<double>(
      begin: context.iconButtonSizeHorizontal,
      end: hasExpansionController
          ? context.iconButtonSizeHorizontal
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
    minWidth: context.iconButtonSizeHorizontal,
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
      : context.iconButtonSizeHorizontal;
  late double newWidth = context.iconButtonSizeHorizontal;

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
      expandRatioAnimation = expandAnimation;
    } else {
      expandAnimationController = null;
      expandAnimation = null;
      expandRatioAnimation = null;
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
    if (query != "") {
      activeAnimationController.forward();
      expand(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (firstBuild) {
      firstBuild = false;
      if (widget.expands && expandRatioAnimation != null) {
        expandRatioAnimation = CurvedAnimation(
            parent: expandAnimation!,
            curve: Interval(
                0, widthTween.end! / context.iconButtonSizeHorizontal));
      }
      if (hasExpansionController) {
        _expand = widget.expansionController!.addItem(expandableItem);
      }
    }
    BorderRadius borderRadius = BorderRadius.horizontal(
      left: !widget.connectLeft ? context.iconRadius : Radius.zero,
      right: !widget.connectRight ? context.iconRadius : Radius.zero,
    );
    return Container(
      margin: EdgeInsets.only(
        left: !widget.connectLeft ? context.iconPadding.left / 2 : 0,
        right: !widget.connectRight ? context.iconPadding.right / 2 : 0,
      ),
      decoration: BoxDecoration(
        color: ColorTween(
                begin: widget.color.toWeakBackround(context),
                end: widget.activeColor ?? widget.color)
            .evaluate(activeAnimation),
        borderRadius: borderRadius,
      ),
      height: context.iconButtonSizeVertical,
      width: width,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.hardEdge,
        borderRadius: borderRadius,
        child: expandRatioAnimation == null
            ? _SearchIconButton(
                query: query,
                onFieldSubmitted: (value) {
                  if (value != query) {
                    if (mounted) setState(() => query = value);
                    widget.onQueryChanged(query);
                  }
                },
                activeAnimationController: activeAnimationController,
                color: widget.color)
            : Stack(
                alignment: AlignmentDirectional.centerEnd,
                children: [
                  if (expandRatioAnimation!.value != 1)
                    FadeTransition(
                      opacity: expandRatioAnimation!,
                      child: IconButton(
                        splashColor: Colors.transparent,
                        padding: context.iconPadding,
                        icon: SizedBox(
                          width: context.iconButtonSizeHorizontal,
                          height: context.iconButtonSizeVertical,
                          child: Icon(Icons.search),
                        ),
                        iconSize: context.iconSize,
                        onPressed: () async {
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
                                    if (mounted) setState(() => query = value);
                                    widget.onQueryChanged(query);
                                  }
                                },
                                accentColor: widget.color,
                                query: query,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  if (expandRatioAnimation!.value != 0)
                    FadeTransition(
                      opacity: expandRatioAnimation!,
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
                                      color:
                                          context.textColor.withOpacity(0.2))),
                              child: InkWell(
                                child: query == ""
                                    ? Row(
                                        children: [
                                          Text(
                                            context.s.search,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: context.textColor
                                                  .withOpacity(0.4),
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
                                      accentColor: widget.color,
                                      query: query,
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              width: width - context.iconButtonSizeHorizontal,
                              alignment: Alignment.center,
                              child: TextFormField(
                                initialValue: query,
                                decoration: InputDecoration(
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8),
                                  hintText: context.s.searchEpisode,
                                  hintStyle: TextStyle(fontSize: 18),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                ),
                                autofocus: false,
                                maxLines: 1,
                                onFieldSubmitted: (value) {
                                  if (value != query) {
                                    if (mounted) setState(() => query = value);
                                    widget.onQueryChanged(query);
                                  }
                                },
                              ),
                            ),
                          Container(
                            width: context.iconButtonSizeHorizontal,
                            child: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                padding: context.iconPadding,
                                icon: SizedBox(
                                  width: context.iconButtonSizeHorizontal,
                                  height: context.iconButtonSizeVertical,
                                  child: Icon(Icons.close),
                                ),
                                iconSize: context.iconSize,
                                onPressed: () async {
                                  if (mounted) setState(() => query = "");
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
    return IconButton(
        splashColor: Colors.transparent,
        padding: context.iconPadding,
        icon: SizedBox(
          width: context.iconButtonSizeHorizontal,
          height: context.iconButtonSizeVertical,
          child: Icon(Icons.search),
        ),
        iconSize: context.iconSize,
        onPressed: () async {
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
        });
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
  void addWidth(double width) => _itemsWidth += width;

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
      assert(minimize < _expandedItems.length * _expandedItems.length,
          "Widget widths don't fit");
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
  final double minExpandedWidth;

  /// Maximum necessary width while expanded
  final double maxExpandedWidth;

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
