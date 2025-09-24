import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../home/audioplayer.dart';
import '../state/audio_state.dart';
import '../util/extension_helper.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_dropdown.dart';
import 'search_api_helper.dart';
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
  final Tween<double> heroWidthTween;
  Tween<double> heightTween;

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
        finalHeroOffset =
            (villainKey.currentContext!.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero);
        heroOffsetTween =
            Tween<Offset>(begin: initialHeroOffset, end: finalHeroOffset);
        final searchCardOffset = panelKey.currentState!.controller.offset +
            120 +
            context.actionBarIconPadding.vertical +
            (context.audioState.playerRunning
                ? context.audioState.playerHeight!.height
                : 0);
        heightTween = Tween(begin: 0, end: searchCardOffset);
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
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (searchFocusNode.hasFocus) {
              searchFocusNode.unfocus();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: AnimatedBuilder(
            animation: animation,
            child: Container(color: context.surface.withAlpha(64)),
            builder: (context, child) => Opacity(
              opacity: animation.value,
              child: child,
            ),
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
                          key: panelKey,
                        ),
                      ),
                    ),
                  ));
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
                          colorAnimation: animation,
                          key: villainKey,
                          width: context.width -
                              context.actionBarButtonSizeVertical * 3,
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
}

class SearchPanel extends StatefulWidget {
  final FocusNode searchFocusNode;
  final bool hide;
  final GlobalKey searchBarKey;
  const SearchPanel(
      {required this.searchFocusNode,
      this.hide = false,
      required this.searchBarKey,
      super.key});

  @override
  State<SearchPanel> createState() => SearchPanelState();
}

class SearchPanelState extends State<SearchPanel> {
  late RemoteSearch searchProvider =
      PodcastIndexSearch(context.podcastState, context.episodeState);

  double get initialTopPadding =>
      context.height -
      MediaQuery.of(context).padding.vertical -
      (120 +
          context.actionBarIconPadding.vertical +
          (context.audioState.playerRunning
              ? context.audioState.playerHeight!.height
              : 0));

  late final ScrollController controller = ScrollController();
  int searchItemCount = 2;

  @override
  void didUpdateWidget(covariant SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hide && widget.hide) {
      final double target =
          math.max(0, controller.offset - initialTopPadding + 5);
      controller.jumpTo(target);
      if (target != 0) {
        controller.animateTo(0,
            duration: Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: searchProvider,
      child: Selector<RemoteSearch, int>(
        selector: (_, search) => search.itemCount,
        builder: (context, itemCount, _) {
          if (controller.hasClients && (searchItemCount < itemCount + 2)) {
            controller.animateTo(
                initialTopPadding +
                    (120 + context.actionBarIconPadding.vertical) +
                    (140 + context.actionBarIconPadding.vertical) *
                        (searchItemCount - 3),
                duration: Durations.medium2,
                curve: Curves.easeOut);
          }
          searchItemCount = itemCount + 2;

          return ListView.builder(
            hitTestBehavior: HitTestBehavior.deferToChild,
            shrinkWrap: true,
            itemCount: searchItemCount,
            itemExtentBuilder: (index, dimensions) => switch (index) {
              0 => widget.hide ? 5 : initialTopPadding,
              1 => 120 + context.actionBarIconPadding.vertical,
              var i when i < searchItemCount =>
                140 + context.actionBarIconPadding.vertical,
              _ => null
            },
            controller: controller,
            itemBuilder: (context, index) =>
                switch ((index, searchProvider.episodeIds.isNotEmpty)) {
              (0, _) => Center(),
              (1, _) => Controls(
                  searchFocusNode: widget.searchFocusNode,
                  hideSearchBar: widget.hide,
                  searchBarKey: widget.searchBarKey),
              (2, true) => SearchEpisodeGrid(searchProvider.episodeIds),
              (_, true) => podcastCard(index - 3),
              (_, false) => podcastCard(index - 2),
            },
          );
        },
      ),
    );
  }

  Widget podcastCard(int index) => Selector<RemoteSearch, bool>(
        selector: (_, search) => search.podcastIds.length > index,
        builder: (context, value, _) => value
            ? SearchPodcastPreview(
                searchProvider.podcastIds[index],
                searchProvider
                    .getPodcastEpisodes(searchProvider.podcastIds[index]),
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
  const Controls({
    required this.searchFocusNode,
    this.hideSearchBar = false,
    required this.searchBarKey,
    super.key,
  });
  @override
  State<Controls> createState() => ControlsState();
}

class ControlsState extends State<Controls> {
  bool webMode = false;
  @override
  Widget build(BuildContext context) {
    return SearchPanelCard(
      short: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: context.actionBarIconPadding.vertical),
        child: webMode
            ? WebControls(
                CustomSearchDelegate(),
                searchFocusNode: widget.searchFocusNode,
                switchMode: () => setState(() => webMode = false),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.hideSearchBar)
                        SearchBar(widget.searchFocusNode,
                            text: Provider.of<RemoteSearch>(context,
                                    listen: false)
                                .queryText,
                            key: widget.searchBarKey,
                            width: context.width -
                                context.actionBarButtonSizeVertical * 3 -
                                4),
                      SizedBox(
                        width: 4,
                      ),
                      IconButton.filled(
                          onPressed: () => setState(() => webMode = true),
                          icon: Icon(LineIcons.globe))
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
      ),
    );
  }
}

class WebControls extends StatelessWidget {
  final CustomSearchDelegate delegate;
  final FocusNode searchFocusNode;
  final VoidCallback switchMode;

  const WebControls(this.delegate,
      {required this.searchFocusNode, required this.switchMode, super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            SearchBar(searchFocusNode,
                width: context.width -
                    context.actionBarButtonSizeVertical * 5 -
                    4),
            SizedBox(
              width: 4,
            ),
            IconButton.filled(onPressed: switchMode, icon: Icon(Icons.list))
          ],
        ),
        SizedBox(
          width: context.width - 80,
          child: Text(
            context.s.searchInstructions,
            style:
                context.textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class SearchBar extends StatelessWidget {
  final FocusNode searchFocusNode;
  final String text;
  final Animation<double> colorAnimation;
  final double width;

  const SearchBar(this.searchFocusNode,
      {this.text = "",
      this.colorAnimation = const DummyAnimation(),
      required this.width,
      super.key});
  void search(BuildContext context, String query) {
    final searchProvider = Provider.of<RemoteSearch>(context, listen: false);
    searchProvider.clear();
    searchProvider.query(query);
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController =
        TextEditingController(text: text);
    final ColorTween background =
        ColorTween(begin: context.surface, end: context.cardColorSchemeCard);
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        SizedBox(
          width: width,
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
                search(context, query);
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
