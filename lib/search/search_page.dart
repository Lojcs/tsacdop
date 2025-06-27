import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/audio_state.dart';
import '../util/extension_helper.dart';
import 'search_widgets.dart';

class SearchRoute extends ModalRoute {
  final String? barrierLabelText;

  final VoidCallback showIcon;

  final VoidCallback hideIcon;

  final GlobalKey heroKey;

  final Offset initialHeroOffset;

  final Offset finalHeroOffset;

  final Tween<double> heightTween;

  final TweenSequence<double> heroWidthTween;

  late final TweenSequence<Offset> heroTween;

  SearchRoute(BuildContext context, this.heroKey,
      {required this.showIcon, required this.hideIcon})
      : barrierLabelText = context.s.back,
        initialHeroOffset =
            (heroKey.currentContext!.findRenderObject() as RenderBox)
                .localToGlobal(Offset(-6, -12)),
        finalHeroOffset = Offset(
            context.actionBarButtonSizeVertical * 3 / 2,
            (context.audioState.playerRunning
                    ? context.height -
                        context.audioState.playerHeight!.height -
                        105 -
                        context.originalPadding.bottom
                    : context.height - 105 - context.originalPadding.bottom) -
                12),
        heightTween = Tween(
            begin: 0,
            end: 120 +
                context.actionBarIconPadding.vertical +
                (context.audioState.playerRunning
                    ? context.audioState.playerHeight.height
                    : 0)),
        heroWidthTween = TweenSequence([
          TweenSequenceItem(
              tween: Tween(
                  begin: context.actionBarButtonSizeVertical,
                  end: context.width - context.actionBarButtonSizeVertical * 3),
              weight: 4),
          TweenSequenceItem(
              tween: Tween(
                  begin:
                      context.width - context.actionBarButtonSizeVertical * 3,
                  end: context.width - context.actionBarButtonSizeVertical * 3),
              weight: 6),
        ]) {
    heroTween = TweenSequence([
      TweenSequenceItem(
          tween: Tween(
              begin: Offset(initialHeroOffset.dx, initialHeroOffset.dy),
              end: Offset(
                  initialHeroOffset.dx +
                      (finalHeroOffset.dx - initialHeroOffset.dx) * 2 / 5,
                  initialHeroOffset.dy)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(
              begin: Offset(
                  initialHeroOffset.dx +
                      (finalHeroOffset.dx - initialHeroOffset.dx) * 2 / 5,
                  initialHeroOffset.dy),
              end: Offset(
                  finalHeroOffset.dx,
                  initialHeroOffset.dy +
                      (finalHeroOffset.dy - initialHeroOffset.dy) * 3 / 8)),
          weight: 3),
      TweenSequenceItem(
          tween: Tween(
              begin: Offset(
                  finalHeroOffset.dx,
                  initialHeroOffset.dy +
                      (finalHeroOffset.dy - initialHeroOffset.dy) * 3 / 8),
              end: Offset(finalHeroOffset.dx, finalHeroOffset.dy)),
          weight: 5),
    ]);
  }

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => barrierLabelText;

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> _) {
    final cAnimation =
        CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    bool reversed = true;
    double lastAnimationValue = 0;
    return Stack(
      children: [
        GestureDetector(onTap: () => Navigator.of(context).pop()),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) => animation.isCompleted
                  ? Material(
                      color: Colors.transparent,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SearchPanel(hideSearchBar: !cAnimation.isCompleted),
                            Selector<AudioPlayerNotifier,
                                (bool, PlayerHeight?)>(
                              selector: (_, audio) =>
                                  (audio.playerRunning, audio.playerHeight),
                              builder: (_, data, __) {
                                return SizedBox(
                                    height: data.$1 && data.$2 != null
                                        ? data.$2!.height
                                        : 0);
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: heightTween.evaluate(cAnimation),
                      child: Material(
                        color: Colors.transparent,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SearchPanel(
                                  hideSearchBar: !cAnimation.isCompleted),
                              Selector<AudioPlayerNotifier,
                                  (bool, PlayerHeight?)>(
                                selector: (_, audio) =>
                                    (audio.playerRunning, audio.playerHeight),
                                builder: (_, data, __) {
                                  return SizedBox(
                                      height: data.$1 && data.$2 != null
                                          ? data.$2!.height
                                          : 0);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              if (lastAnimationValue - animation.value > 0) {
                if (!reversed) {
                  reversed = true;
                  Future.delayed(transitionDuration, () {
                    if (reversed) showIcon();
                  });
                }
              } else if (reversed) {
                reversed = false;
                Future.microtask(hideIcon);
              }
              lastAnimationValue = animation.value;
              if (animation.value == 0 && reversed) {
                Future.microtask(showIcon);
              }
              return animation.isCompleted
                  ? Center()
                  : Transform.translate(
                      offset: heroTween.evaluate(cAnimation),
                      child: SizedBox(
                        width: heroWidthTween.evaluate(cAnimation),
                        child: Material(
                          color: Colors.transparent,
                          child: SearchBar(
                            (_) {},
                            colorAnimation: animation,
                          ),
                        ),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get maintainState => false;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);
}

class SearchPanel extends StatefulWidget {
  final List<String> urls;
  final bool hideSearchBar;
  const SearchPanel(
      {this.urls = const [], this.hideSearchBar = false, super.key});

  @override
  State<SearchPanel> createState() => SearchPanelState();
}

class SearchPanelState extends State<SearchPanel> {
  ScrollController scrollController = ScrollController();
  int floatCount = 0;
  int urlCount = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (mounted) {
        if (scrollController.offset > 0) {
          if (scrollController.offset <= 0) {
            setState(() => floatCount = 1);
          } else {
            double previewSize = 140 + context.actionBarIconPadding.vertical;
            setState(
                () => floatCount = 1 + scrollController.offset ~/ previewSize);
          }
        } else {
          setState(() => floatCount = 0);
        }
      }
    });
  }

  @override
  void didUpdateWidget(SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (urlCount < widget.urls.length) {
      urlCount = widget.urls.length;
      Future.delayed(
        Duration(milliseconds: 100),
        () {
          if (mounted) {
            scrollController.animateTo(
              scrollController.offset +
                  140 +
                  context.actionBarIconPadding.vertical,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutCirc,
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ListView(
        hitTestBehavior: HitTestBehavior.deferToChild,
        controller: scrollController,
        shrinkWrap: true,
        children: [
          PodcastSearchCard(
            floating: true,
            short: true,
            child: Controls(
              onSearch: (query) {},
              hideSearchBar: widget.hideSearchBar,
            ),
          ),
          ...widget.urls.mapIndexed(
            (i, e) => PodcastSearchCard(
              floating: floatCount > i + 1,
              child: SearchPodcastPreview(e),
            ),
          ),
        ],
      ),
    );
  }
}

class Controls extends StatefulWidget {
  final void Function(String query) onSearch;
  final bool hideSearchBar;
  const Controls({
    required this.onSearch,
    this.hideSearchBar = false,
    super.key,
  });
  @override
  State<Controls> createState() => ControlsState();
}

class ControlsState extends State<Controls> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: context.actionBarIconPadding.vertical),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.hideSearchBar) SearchBar(widget.onSearch),
            ],
          ),
          SizedBox(
            width: context.width - 80,
            child: Text(
              context.s.searchInstructions,
              style: context.textTheme.bodySmall!
                  .copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class WebControls extends StatelessWidget {
  final CustomSearchDelegate delegate;
  final FocusNode searchFocusNode;

  const WebControls(this.delegate, this.searchFocusNode, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: context.actionBarIconPadding.copyWith(right: 0),
          child: Material(
            color: Colors.transparent,
            borderRadius: context.radiusMedium,
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              splashColor: Colors.transparent,
              onTap: () {
                searchFocusNode.unfocus();
                delegate.onBack();
              },
              child: SizedBox(
                width: context.actionBarButtonSizeVertical,
                height: context.actionBarButtonSizeVertical,
                child: Icon(
                  Icons.arrow_back,
                  size: context.actionBarIconSize,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: context.actionBarIconPadding.copyWith(left: 0),
          child: Material(
            color: Colors.transparent,
            borderRadius: context.radiusMedium,
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              splashColor: Colors.transparent,
              onTap: () {
                searchFocusNode.unfocus();
                delegate.onForward();
              },
              child: SizedBox(
                width: context.actionBarButtonSizeVertical,
                height: context.actionBarButtonSizeVertical,
                child: Icon(
                  Icons.arrow_forward,
                  size: context.actionBarIconSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchBar extends StatelessWidget {
  final void Function(String query) onSearch;
  final Animation<double>? colorAnimation;

  const SearchBar(this.onSearch, {this.colorAnimation, super.key});
  @override
  Widget build(BuildContext context) {
    final FocusNode searchFocusNode = FocusNode();
    final TextEditingController searchController = TextEditingController();
    final ColorTween background =
        ColorTween(begin: context.surface, end: context.cardColorSchemeCard);
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        SizedBox(
          width: context.width - context.actionBarButtonSizeVertical * 3,
          height: 48,
          child: colorAnimation != null
              ? AnimatedBuilder(
                  animation: colorAnimation!,
                  builder: (context, _) => TextField(
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: background.evaluate(colorAnimation!),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      hintText: context.s.searchPodcast,
                      hintStyle: TextStyle(fontSize: 18),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: context.accentColor),
                        borderRadius: context.radiusLarge,
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                          borderRadius: context.radiusLarge),
                    ),
                    controller: searchController,
                    onSubmitted: (query) {
                      searchFocusNode.unfocus();
                      onSearch(query);
                    },
                    onTap: () {
                      if (!searchFocusNode.hasFocus) {
                        searchController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: searchController.text.length);
                      }
                    },
                  ),
                )
              : TextField(
                  focusNode: searchFocusNode,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: background.end,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    hintText: context.s.searchPodcast,
                    hintStyle: TextStyle(fontSize: 18),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.accentColor),
                      borderRadius: context.radiusLarge,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: context.radiusLarge),
                  ),
                  controller: searchController,
                  onSubmitted: (query) {
                    searchFocusNode.unfocus();
                    onSearch(query);
                  },
                  onTap: () {
                    if (!searchFocusNode.hasFocus) {
                      searchController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: searchController.text.length);
                    }
                  },
                ),
        ),
        Padding(
          padding: context.actionBarIconPadding,
          child: Material(
            color: Colors.transparent,
            borderRadius: context.radiusMedium,
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                searchFocusNode.unfocus();
                onSearch(searchController.text);
              },
              child: SizedBox(
                width: context.actionBarButtonSizeVertical,
                height: context.actionBarButtonSizeVertical,
                child: Icon(
                  Icons.search,
                  size: context.actionBarIconSize,
                  color: context.actionBarIconColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSearchDelegate {
  final void Function(String query) onSearch;
  final void Function() onBack;
  final void Function() onForward;
  CustomSearchDelegate({
    this.onSearch = _defOnSearch,
    this.onBack = _defOnBack,
    this.onForward = _defOnForward,
  });
  static void _defOnSearch(String _) {}
  static void _defOnBack() {}
  static void _defOnForward() {}
}
