import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../home/audioplayer.dart';
import '../state/audio_state.dart';
import '../util/extension_helper.dart';
import '../widgets/action_bar_generic_widgets.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_popupmenu.dart';
import 'search_api.dart';
import 'search_controller.dart';
import 'search_web.dart';
import 'search_widgets.dart';

class SearchPanelRoute extends ModalRoute {
  final String? barrierLabelText;

  final VoidCallback showIcon;
  final VoidCallback hideIcon;

  final GlobalKey heroKey;
  final GlobalKey villainKey = GlobalKey();
  final GlobalKey<SearchPanelState> panelKey = GlobalKey<SearchPanelState>();
  final Offset initialHeroOffset;
  Offset finalHeroOffset;

  late Tween<Offset> heroOffsetTween;
  Tween<double> heroWidthTween;
  Tween<double> heightTween;

  final FocusNode searchFocusNode = FocusNode();

  final JointSearch searchProvider;
  SearchPanelRoute(BuildContext context, this.heroKey,
      {required this.showIcon, required this.hideIcon})
      : barrierLabelText = context.s.back,
        initialHeroOffset =
            (heroKey.currentContext!.findRenderObject() as RenderBox)
                .localToGlobal(Offset(-6, -12)),
        finalHeroOffset = Offset(
            context.actionBarButtonSizeVertical +
                context.actionBarIconPadding.left / 2,
            context.height -
                (140 + context.actionBarIconPadding.vertical) + // Card height
                context.actionBarIconPadding.top * 3 - // Card inner padding
                context.originalPadding.bottom -
                (context.audioState.playerRunning
                    ? context.audioState.playerHeight!.height
                    : 0)),
        heroWidthTween = Tween(
            begin: context.actionBarButtonSizeVertical,
            end: SearchBar.barWidth(context)),
        heightTween = Tween(
            begin: 0,
            end: 140 +
                context.actionBarIconPadding.vertical +
                (context.audioState.playerRunning
                    ? context.audioState.playerHeight!.height
                    : 0)),
        searchProvider =
            JointSearch(context.podcastState, context.episodeState) {
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
  bool get maintainState => false;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  bool reversed = true;
  double lastAnimationValue = 0;
  bool lastAnimationComplete = false;

  void animationListener(Animation<double> animation, BuildContext context) {
    if (lastAnimationComplete == animation.isCompleted &&
        lastAnimationValue == animation.value) {
      return;
    }
    if (lastAnimationComplete && !animation.isCompleted ||
        lastAnimationValue - animation.value > 0) {
      if (!reversed) {
        reversed = true;
        final villainBox =
            villainKey.currentContext!.findRenderObject() as RenderBox;
        finalHeroOffset = villainBox.localToGlobal(Offset.zero);
        heroOffsetTween =
            Tween<Offset>(begin: initialHeroOffset, end: finalHeroOffset);
        final searchCardOffset =
            panelKey.currentState!.scrollController.offset +
                140 +
                context.actionBarIconPadding.vertical +
                (context.audioState.playerRunning
                    ? context.audioState.playerHeight!.height
                    : 0);
        heightTween = Tween(begin: 0, end: searchCardOffset);
        heroWidthTween = Tween(
            begin: context.actionBarButtonSizeVertical,
            end: villainBox.size.width);
      }
    } else if (reversed) {
      reversed = false;
      Future.microtask(hideIcon);
    }
    lastAnimationValue = animation.value;
    lastAnimationComplete = animation.isCompleted;
    if (animation.value < 0.1 && reversed) {
      Future.microtask(showIcon);
    }
  }

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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) searchProvider.searchWeb = false;
      },
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: animation,
            child: Container(color: context.surface.withAlpha(64)),
            builder: (context, child) => Opacity(
              opacity: animation.value,
              child: child,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                animationListener(animation, context);
                final panel = ScrollConfiguration(
                  behavior: NoOverscrollScrollBehavior(),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Selector<AudioPlayerNotifier, (bool, PlayerHeight?)>(
                      selector: (_, audio) =>
                          (audio.playerRunning, audio.playerHeight),
                      builder: (_, data, __) => Padding(
                        padding: EdgeInsetsGeometry.only(
                            bottom: data.$1 && data.$2 != null
                                ? data.$2!.height
                                : 0),
                        child: SearchPanel(
                          searchFocusNode: searchFocusNode,
                          hide: !panelAnimation.isCompleted,
                          searchBarKey: villainKey,
                          searchProvider: searchProvider,
                          key: panelKey,
                        ),
                      ),
                    ),
                  ),
                );
                return animation.isCompleted
                    ? panel
                    : SafeArea(
                        child: SizedBox(
                          height: heightTween.evaluate(panelAnimation) + 5,
                          child: panel,
                        ),
                      );
              },
            ),
          ),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              animationListener(animation, context);
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
                            searchFocusNode,
                            width: heroWidthTween.end,
                            colorAnimation: animation,
                            key: villainKey,
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
      ),
    );
  }
}

class SearchPanel extends StatefulWidget {
  final FocusNode searchFocusNode;
  final bool hide;
  final GlobalKey searchBarKey;
  final JointSearch searchProvider;
  const SearchPanel(
      {required this.searchFocusNode,
      this.hide = false,
      required this.searchBarKey,
      required this.searchProvider,
      super.key});

  @override
  State<SearchPanel> createState() => SearchPanelState();
}

class SearchPanelState extends State<SearchPanel>
    with SingleTickerProviderStateMixin {
  double get initialTopPadding =>
      context.height -
      MediaQuery.of(context).viewInsets.vertical -
      MediaQuery.of(context).viewPadding.vertical -
      (140 +
          context.actionBarIconPadding.vertical +
          (context.audioState.playerRunning
              ? context.audioState.playerHeight!.height
              : 0));

  late final ScrollController scrollController = ScrollController();
  late final animationComtroller =
      AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  late final animation = CurvedAnimation(
      parent: animationComtroller,
      curve: Curves.easeOutQuad,
      reverseCurve: Curves.easeInQuad);
  int searchItemCount = 2;

  @override
  void didUpdateWidget(covariant SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hide && widget.hide) {
      final double target =
          math.max(0, scrollController.offset - initialTopPadding + 5);
      scrollController.jumpTo(target);
      if (target != 0) {
        scrollController.animateTo(0,
            duration: Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.searchProvider,
      child: Selector<JointSearch, (int, bool)>(
        selector: (_, search) => (search.itemCount, search.searchWeb),
        builder: (context, value, _) {
          var (itemCount, searchWeb) = value;
          if (scrollController.hasClients &&
              (searchItemCount < itemCount + 2)) {
            scrollController.animateTo(
                initialTopPadding +
                    (140 + context.actionBarIconPadding.vertical) +
                    (140 + context.actionBarIconPadding.vertical) *
                        (searchItemCount - 3),
                duration: Durations.medium2,
                curve: Curves.easeOut);
          }
          searchItemCount = itemCount + 2;
          if (searchWeb) {
            animationComtroller.forward();
          } else {
            animationComtroller.reverse();
          }
          return Stack(
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) => Stack(
                  children: [
                    if (animation.value != 0)
                      Opacity(
                        opacity: animation.value,
                        child: widget.searchProvider.webSearch.background,
                      ),
                    if (animation.value != 1)
                      Opacity(
                        opacity: 1 - animation.value,
                        child: widget.searchProvider.apiSearch.background,
                      ),
                  ],
                ),
              ),
              ListView.builder(
                hitTestBehavior: HitTestBehavior.opaque,
                shrinkWrap: true,
                itemCount: searchItemCount,
                itemExtentBuilder: (index, dimensions) => switch (index) {
                  0 => widget.hide ? 5 : initialTopPadding,
                  1 => 140 + context.actionBarIconPadding.vertical,
                  var i when i < searchItemCount =>
                    140 + context.actionBarIconPadding.vertical,
                  _ => null
                },
                controller: scrollController,
                itemBuilder: (context, index) => switch ((
                  index,
                  widget.searchProvider.episodeIds.isNotEmpty
                )) {
                  (0, _) => GestureDetector(
                      onTap: () {
                        if (widget.searchFocusNode.hasFocus) {
                          widget.searchFocusNode.unfocus();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  (1, _) => Controls(
                      searchFocusNode: widget.searchFocusNode,
                      hideSearchBar: widget.hide,
                      searchBarKey: widget.searchBarKey,
                      animation: animation,
                    ),
                  (2, true) =>
                    SearchEpisodeGrid(widget.searchProvider.episodeIds),
                  (_, true) => podcastCard(index - 3),
                  (_, false) => podcastCard(index - 2),
                },
              )
            ],
          );
        },
      ),
    );
  }

  Widget podcastCard(int index) => Selector<JointSearch, bool>(
        selector: (_, search) => search.podcastIds.length > index,
        builder: (context, value, _) => value
            ? SearchPodcastPreview(
                widget.searchProvider.podcastIds[index],
                widget.searchProvider.getPodcastEpisodes(
                    widget.searchProvider.podcastIds[index])!,
              )
            : SearchPanelCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.all(12),
                      height: 20,
                      decoration:
                          BoxDecoration(borderRadius: context.radiusSmall),
                      clipBehavior: Clip.antiAlias,
                      child: LinearProgressIndicator(),
                    )
                  ],
                ),
              ),
      );
}

class Controls extends StatefulWidget {
  final FocusNode searchFocusNode;
  final bool hideSearchBar;
  final GlobalKey searchBarKey;
  final Animation<double> animation;
  const Controls({
    required this.searchFocusNode,
    this.hideSearchBar = false,
    required this.searchBarKey,
    required this.animation,
    super.key,
  });
  @override
  State<Controls> createState() => ControlsState();
}

class ControlsState extends State<Controls> {
  late final bottomBarExpansionController =
      ExpansionController(maxWidth: maxWidth);
  double maxWidth() =>
      context.width - context.actionBarIconPadding.horizontal * 5;
  final alignmentTween =
      AlignmentTween(begin: Alignment.center, end: Alignment.centerRight);
  late final paddingTween = EdgeInsetsTween(
      begin: EdgeInsets.only(
          left: context.actionBarIconPadding.left / 2,
          right: context.actionBarIconPadding.right / 2),
      end: EdgeInsets.only(right: context.actionBarIconPadding.right / 2));
  @override
  Widget build(BuildContext context) {
    final search = Provider.of<JointSearch>(context, listen: false);
    return Provider.value(
      value: context.cardColorScheme,
      builder: (context, child) => SearchPanelCard(
        short: false,
        child: Selector<JointSearch, bool>(
          selector: (_, search) => search.searchWeb,
          builder: (context, searchWeb, _) => Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        AnimatedBuilder(
                          animation: widget.animation,
                          builder: (context, child) => Opacity(
                            opacity: widget.animation.value,
                            child: ActionBarButton(
                              height: 40,
                              width: 40,
                              connectRight: true,
                              tooltip: context.s.back,
                              // enabled: webMode,
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back,
                                  size: context.actionBarIconSize,
                                ),
                              ),
                              onPressed: (value) {
                                widget.searchFocusNode.unfocus();
                                search.webSearch.goBack();
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsGeometry.only(right: 0),
                          child: AnimatedBuilder(
                            animation: widget.animation,
                            builder: (context, child) => Opacity(
                              opacity: widget.animation.value,
                              child: ActionBarButton(
                                height: 40,
                                width: 40,
                                connectLeft: true,
                                tooltip: context.s.forward,
                                // enabled: webMode,
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: context.actionBarIconSize,
                                  ),
                                ),
                                onPressed: (value) {
                                  widget.searchFocusNode.unfocus();
                                  search.webSearch.goForward();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.hideSearchBar)
                    AnimatedBuilder(
                      animation: widget.animation,
                      builder: (context, child) => Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: paddingTween.evaluate(widget.animation),
                          child: SearchBar(
                            widget.searchFocusNode,
                            width: SearchBar.barWidth(context) -
                                context.actionBarButtonSizeHorizontal *
                                    (widget.animation.value * 2.5),
                            text:
                                Provider.of<JointSearch>(context, listen: false)
                                    .queryText,
                            key: widget.searchBarKey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Selector<JointSearch, SearchApi>(
                    selector: (_, search) => search.searchApi,
                    builder: (context, searchApi, _) =>
                        ActionBarDropdownButton<SearchApi>(
                      expansionController: bottomBarExpansionController,
                      tooltip: context.s.searchApi,
                      connectRight: true,
                      selected: searchApi,
                      dropsUp: true,
                      itemBuilder: () => SearchApi.values
                          .map(
                            (e) => MyPopupMenuItem(
                              width: 120,
                              value: e,
                              child: Tooltip(
                                message: e.name,
                                child: Center(
                                  child: Text(
                                    e.name,
                                    style: context.textTheme.bodyLarge!,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onSelected: (value) => search.searchApi = value,
                      active: (_) => !searchWeb,
                      onInactiveTap: () {
                        search.clear();
                        search.searchWeb = false;
                      },
                      maxExpandedWidth: 120,
                      expandedChild: Center(
                        child: Text(
                          searchApi.name,
                          style: context.textTheme.bodyLarge!,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                      child: Icon(Icons.api_rounded),
                    ),
                  ),
                  Selector<JointSearch, int>(
                    selector: (_, search) => search.itemCount,
                    builder: (context, itemCount, _) => ActionBarButton(
                      expansionController: bottomBarExpansionController,
                      state: false,
                      buttonType: ActionBarButtonType.single,
                      onPressed: (value) {
                        search.clear();
                      },
                      tooltip: context.s.clear,
                      connectLeft: true,
                      connectRight: true,
                      enabled: itemCount != 0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.check_box_outline_blank),
                          Text("$itemCount")
                        ],
                      ),
                    ),
                  ),
                  Selector<JointSearch, SearchEngine>(
                    selector: (_, search) => search.searchEngine,
                    builder: (context, searchEngine, _) =>
                        ActionBarDropdownButton<SearchEngine>(
                      expansionController: bottomBarExpansionController,
                      tooltip: context.s.searchEngine,
                      connectLeft: true,
                      selected: searchEngine,
                      dropsUp: true,
                      itemBuilder: () => SearchEngine.values
                          .map(
                            (e) => MyPopupMenuItem(
                              width: 120,
                              value: e,
                              child: Tooltip(
                                message: e.name,
                                child: Center(
                                  child: Text(
                                    e.name,
                                    style: context.textTheme.bodyLarge!,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onSelected: (value) => search.searchEngine = value,
                      active: (_) => searchWeb,
                      onInactiveTap: () {
                        search.clear();
                        search.searchWeb = true;
                      },
                      maxExpandedWidth: 120,
                      expandedChild: Center(
                        child: Text(
                          searchEngine.name,
                          style: context.textTheme.bodyLarge!,
                        ),
                      ),
                      child: Icon(LineIcons.globe),
                    ),
                  ),
                ],
              ),
              // SizedBox(
              //   width: context.width - 80,
              //   child: Text(
              //     context.s.searchInstructions,
              //     style: context.textTheme.bodySmall!
              //         .copyWith(color: Colors.grey[600]),
              //     textAlign: TextAlign.center,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final FocusNode searchFocusNode;
  final double? width;
  final String text;
  final Animation<double> colorAnimation;

  const SearchBar(this.searchFocusNode,
      {this.width,
      this.text = "",
      this.colorAnimation = const DummyAnimation(),
      super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
  static double barWidth(BuildContext context) =>
      SearchPanelCard.innerWidth(context) -
      context.actionBarIconPadding.horizontal / 2;
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController searchController =
      TextEditingController(text: widget.text);
  late double width = widget.width ?? 0;
  @override
  void didUpdateWidget(covariant SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.width != width && widget.width != null) {
      width = widget.width!;
    }
  }

  void search(BuildContext context, String query) {
    final searchProvider = Provider.of<JointSearch>(context, listen: false);
    searchProvider.clear();
    searchProvider.query(query);
  }

  @override
  Widget build(BuildContext context) {
    final ColorTween background =
        ColorTween(begin: context.surface, end: context.cardColorSchemeCard);
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        SizedBox(
          width: width,
          height: 48,
          child: AnimatedBuilder(
            animation: widget.colorAnimation,
            builder: (context, _) => TextField(
              autofocus: false,
              focusNode: widget.searchFocusNode,
              decoration: InputDecoration(
                filled: true,
                fillColor: background.evaluate(widget.colorAnimation),
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
                widget.searchFocusNode.unfocus();
                search(context, query);
              },
              onTap: () {
                if (!widget.searchFocusNode.hasFocus) {
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
                widget.searchFocusNode.unfocus();
                search(context, searchController.text);
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
