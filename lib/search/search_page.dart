import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/audioplayer.dart';
import '../state/audio_state.dart';
import '../util/extension_helper.dart';
import '../widgets/audiopanel.dart';
import 'search_widgets.dart';

class SearchPanelRoute extends ModalRoute {
  final String? barrierLabelText;

  final VoidCallback showIcon;
  final VoidCallback hideIcon;

  final GlobalKey heroKey;
  final Offset initialHeroOffset;
  final Offset finalHeroOffset;

  late final Tween<Offset> heroOffsetTween;
  final Tween<double> heroWidthTween;
  final Tween<double> heightTween;

  final FocusNode searchFocusNode = FocusNode();

  SearchPanelRoute(BuildContext context, this.heroKey,
      {required this.showIcon, required this.hideIcon})
      : barrierLabelText = context.s.back,
        initialHeroOffset =
            (heroKey.currentContext!.findRenderObject() as RenderBox)
                .localToGlobal(Offset(-6, -12)),
        finalHeroOffset = Offset(
            context.actionBarButtonSizeVertical * 3 / 2,
            context.height -
                105 -
                context.originalPadding.bottom -
                (context.audioState.playerRunning
                    ? context.audioState.playerHeight!.height
                    : 0) -
                12),
        heroWidthTween = Tween(
            begin: context.actionBarButtonSizeVertical,
            end: context.width - context.actionBarButtonSizeVertical * 3),
        heightTween = Tween(
            begin: 0,
            end: 120 +
                context.actionBarIconPadding.vertical +
                (context.audioState.playerRunning
                    ? context.audioState.playerHeight!.height
                    : 0)) {
    heroOffsetTween =
        Tween<Offset>(begin: initialHeroOffset, end: finalHeroOffset);
  }
  @override
  void dispose() {
    showIcon();
    super.dispose();
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => barrierLabelText;

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> _) {
    final panelAnimation =
        CurvedAnimation(parent: animation, curve: Curves.easeInOutCirc);
    final heroOffsetAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
        reverseCurve: Curves.fastEaseInToSlowEaseOut);
    final heroWidthAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuad);
    bool reversed = true;
    double lastAnimationValue = 0;
    return Stack(
      children: [
        GestureDetector(onTap: () {
          if (searchFocusNode.hasFocus) {
            searchFocusNode.unfocus();
          } else {
            Navigator.of(context).pop();
          }
        }),
        Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) => animation.isCompleted
                    ? Material(
                        type: MaterialType.transparency,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SearchPanel(
                                  searchFocusNode: searchFocusNode,
                                  hideSearchBar: !panelAnimation.isCompleted),
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
                        height: heightTween.evaluate(panelAnimation),
                        child: Material(
                          type: MaterialType.transparency,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SearchPanel(
                                    searchFocusNode: searchFocusNode,
                                    hideSearchBar: !panelAnimation.isCompleted),
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
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            if (lastAnimationValue - animation.value > 0) {
              if (!reversed) {
                reversed = true;
              }
            } else if (reversed) {
              reversed = false;
              Future.microtask(hideIcon);
            }
            lastAnimationValue = animation.value;
            if (animation.value < 0.1 && reversed) {
              Future.microtask(showIcon);
            }
            return animation.isCompleted
                ? Center()
                : Transform.translate(
                    // offset: heroTween.evaluate(cAnimation),
                    offset: heroOffsetTween.evaluate(heroOffsetAnimation),
                    child: SizedBox(
                      // width: heroWTween.evaluate(cAnimation),
                      width: heroWidthTween.evaluate(heroWidthAnimation),
                      child: Material(
                        type: MaterialType.transparency,
                        child: SearchBar(
                          (_) {},
                          searchFocusNode,
                          colorAnimation: animation,
                        ),
                      ),
                    ),
                  );
          },
        ),
        Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: PlayerWidget(playerKey: GlobalKey<AudioPanelState>()),
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
  Duration get transitionDuration => const Duration(milliseconds: 400);
}

class SearchPanel extends StatefulWidget {
  final FocusNode searchFocusNode;
  final List<String> urls;
  final bool hideSearchBar;
  const SearchPanel(
      {required this.searchFocusNode,
      this.urls = const [],
      this.hideSearchBar = false,
      super.key});

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
              searchFocusNode: widget.searchFocusNode,
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
  final FocusNode searchFocusNode;
  final bool hideSearchBar;
  const Controls({
    required this.onSearch,
    required this.searchFocusNode,
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
              if (!widget.hideSearchBar)
                SearchBar(widget.onSearch, widget.searchFocusNode),
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
            type: MaterialType.transparency,
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
            type: MaterialType.transparency,
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
  final FocusNode searchFocusNode;
  final Animation<double> colorAnimation;

  const SearchBar(this.onSearch, this.searchFocusNode,
      {this.colorAnimation = const DummyAnimation(), super.key});
  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final ColorTween background =
        ColorTween(begin: context.surface, end: context.cardColorSchemeCard);
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        SizedBox(
          width: context.width - context.actionBarButtonSizeVertical * 3,
          height: 48,
          child: AnimatedBuilder(
            animation: colorAnimation,
            builder: (context, _) => TextField(
              autofocus: false,
              focusNode: searchFocusNode,
              decoration: InputDecoration(
                filled: true,
                fillColor: background.evaluate(colorAnimation),
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
        ),
        Padding(
          padding: context.actionBarIconPadding,
          child: Material(
            type: MaterialType.transparency,
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

class DummyAnimation extends Animation<double> {
  const DummyAnimation();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}

  @override
  AnimationStatus get status => AnimationStatus.completed;

  @override
  get value => 1.0;
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
