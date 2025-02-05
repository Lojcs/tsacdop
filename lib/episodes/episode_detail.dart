import 'dart:async';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/episodes/menu_bar.dart';
import 'package:tsacdop/episodes/shownote.dart';
import 'package:tsacdop/util/helpers.dart';
import 'package:tuple/tuple.dart';

import '../home/audioplayer.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../util/extension_helper.dart';
import '../widgets/audiopanel.dart';
import '../widgets/custom_widget.dart';

class EpisodeDetail extends StatefulWidget {
  final EpisodeBrief episodeItem;
  final bool hide;
  final VoidCallback? onClosed;
  EpisodeDetail(
      {required this.episodeItem, this.hide = false, this.onClosed, Key? key})
      : super(key: key);

  @override
  _EpisodeDetailState createState() => _EpisodeDetailState();
}

class _EpisodeDetailState extends State<EpisodeDetail> {
  final textstyle = TextStyle(fontSize: 15.0, color: Colors.black);
  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();
  double? downloadProgress;

  late EpisodeBrief _episodeItem = widget.episodeItem;
  String? path;

  @override
  void deactivate() {
    context.statusBarColor = null;
    context.navBarColor = null;
    if (widget.onClosed != null) widget.onClosed!();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final Color color =
        context.realDark ? context.surface : _episodeItem.cardColor(context);
    context.statusBarColor = color;
    context.navBarColor = color;
    return Selector<EpisodeState, bool?>(
      selector: (_, episodeState) => episodeState.globalChange,
      builder: (_, __, ___) => FutureBuilder<EpisodeBrief>(
        future: _episodeItem.copyWithFromDB(newFields: [
          EpisodeField.episodeImage,
          EpisodeField.podcastImage,
          EpisodeField.versions,
        ], update: true),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _episodeItem = snapshot.data!;
          }
          return Selector<AudioPlayerNotifier, bool>(
            selector: (_, audio) => audio.playerRunning,
            builder: (_, playerRunning, __) =>
                AnnotatedRegion<SystemUiOverlayStyle>(
              value: playerRunning
                  ? context.overlay.copyWith(
                      systemNavigationBarColor: context.cardColorSchemeCard)
                  : context.overlay,
              child: PopScope(
                canPop: !(_playerKey.currentState != null &&
                    _playerKey.currentState!.size! > 100),
                onPopInvokedWithResult: (_, __) =>
                    _playerKey.currentState?.backToMini(),
                child: Scaffold(
                  backgroundColor: context.realDark
                      ? context.surface
                      : widget.episodeItem.colorScheme(context).surface,
                  body: SafeArea(
                      child: _EpisodeDetailInner(
                          _episodeItem, color, widget.hide)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EpisodeDetailInner extends StatefulWidget {
  final EpisodeBrief episodeItem;
  final Color color;
  final bool hide;

  _EpisodeDetailInner(this.episodeItem, this.color, this.hide);

  @override
  __EpisodeDetailInnerState createState() => __EpisodeDetailInnerState();
}

class __EpisodeDetailInnerState extends State<_EpisodeDetailInner> {
  final _dbHelper = DBHelper();

  late EpisodeBrief _episodeItem = widget.episodeItem;

  late final ScrollController _controller;

  late final double _titleBarMinHeight;
  late final double _titleBarMaxHeight;
  late final double _imageTopOffset;

  bool lateInitComplete = false;

  bool forceDisplayVersionIndicator = false;

  bool _scrollListener(ScrollNotification notification) {
    // In debug mode manually scrolling before animateTo has finished
    // causes an uncatchable assertion failure and freezes the page.
    // Tried other ways to do this, wasn't satisfied with them.

    // Hide image
    if (_controller.position.userScrollDirection == ScrollDirection.reverse &&
        _controller.offset <
            _titleBarMaxHeight + _titleBarMinHeight - _imageTopOffset &&
        _controller.offset > _titleBarMinHeight - 30) {
      _controller.animateTo(_titleBarMaxHeight,
          duration: Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    }
    // Reveal image
    else if (_controller.position.userScrollDirection ==
            ScrollDirection.forward &&
        _controller.offset <
            _titleBarMaxHeight + _titleBarMinHeight - _imageTopOffset &&
        _controller.offset > _titleBarMinHeight - 30) {
      _controller.animateTo(0,
          duration: Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    }
    // Bounce back to image hidden
    else if (notification is ScrollEndNotification &&
        _controller.offset < _titleBarMaxHeight &&
        _controller.offset >
            _titleBarMaxHeight + _titleBarMinHeight - _imageTopOffset &&
        _controller.offset != _titleBarMaxHeight) {
      _controller.animateTo(_titleBarMaxHeight,
          duration: Duration(milliseconds: 100), curve: Curves.decelerate);
    }
    // Bounce back to image revealed
    else if (notification is ScrollEndNotification &&
        _controller.offset < _titleBarMinHeight - 30 &&
        _controller.offset != 0) {
      _controller.animateTo(0,
          duration: Duration(milliseconds: 100), curve: Curves.decelerate);
    }
    return false;
  }

  _lateInit() {
    if (!lateInitComplete) {
      _titleBarMaxHeight = context.width - 30;
      _titleBarMinHeight = 56;
      _imageTopOffset = 120;
      _controller = ScrollController(initialScrollOffset: _titleBarMaxHeight);
      lateInitComplete = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_EpisodeDetailInner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.episodeItem.versions != null) {
      for (EpisodeBrief version in widget.episodeItem.versions!) {
        if (_episodeItem == version) {
          _episodeItem = version;
        }
      }
      if (_episodeItem.isDisplayVersion!) {
        forceDisplayVersionIndicator = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _lateInit();
    return Stack(
      children: <Widget>[
        StretchingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          child: NotificationListener<ScrollNotification>(
            onNotification: _scrollListener,
            child: NestedScrollView(
              scrollDirection: Axis.vertical,
              controller: _controller,
              headerSliverBuilder: (context, innerBoxScrolled) {
                final titleLineTest = TextPainter(
                    maxLines: 3,
                    text: TextSpan(
                      text: _episodeItem.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    textDirection: TextDirection.ltr);
                titleLineTest.layout(maxWidth: context.width - 60);

                double titleHeight =
                    titleLineTest.computeLineMetrics().length * 30 + 15;
                return <Widget>[
                  SliverAppBar(
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        double topHeight = constraints.biggest.height;
                        double expandRatio = ((topHeight - _titleBarMinHeight) /
                                (-30 + context.width))
                            .clamp(0, 1);
                        // print(_episodeItem.episodeImage);
                        return FlexibleSpaceBar(
                          collapseMode: CollapseMode.pin,
                          titlePadding: EdgeInsets.only(
                            left: 45,
                            right: 45,
                            top: 13,
                            bottom: topHeight -
                                (40 +
                                    (topHeight - _titleBarMinHeight).clamp(0,
                                        _imageTopOffset - _titleBarMinHeight)),
                          ),
                          expandedTitleScale: 1.1,
                          background: Container(
                            // alignment:
                            //     Alignment.bottomCenter,
                            padding: EdgeInsets.only(
                              left: 60,
                              right: 60,
                              top: _imageTopOffset +
                                  context.width -
                                  30 -
                                  expandRatio * (context.width - 30),
                              bottom: 0,
                            ),
                            child: Container(
                              clipBehavior: Clip.hardEdge,
                              height: (context.width - 120) *
                                  ((expandRatio - 0.4).clamp(0, 0.6) + 0.4),
                              width: (context.width - 120) *
                                  ((expandRatio - 0.4).clamp(0, 0.6) + 0.4),
                              decoration: BoxDecoration(
                                color: widget.color,
                                // border: Border.all(
                                //     color: Colors.white,
                                //     width: 2),
                              ),
                              child: Image(
                                  alignment: Alignment.topCenter,
                                  fit: BoxFit.fitWidth,
                                  image: _episodeItem
                                      .episodeOrPodcastImageProvider),
                            ),
                          ),
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  _episodeItem.number.toString() + " | ",
                                  style: GoogleFonts.teko(
                                      textStyle:
                                          context.textTheme.headlineSmall),
                                ),
                              ),
                              Expanded(
                                child: Tooltip(
                                  message: _episodeItem.podcastTitle,
                                  child: Text(
                                    _episodeItem.podcastTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.headlineSmall!
                                        .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _episodeItem
                                          .colorScheme(context)
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    backgroundColor: widget.color,
                    collapsedHeight: _titleBarMinHeight,
                    toolbarHeight: _titleBarMinHeight,
                    expandedHeight: _titleBarMinHeight + _titleBarMaxHeight,
                    pinned: true,
                    // floating: true,
                    scrolledUnderElevation: 0,
                    leading: CustomBackButton(
                      color: _episodeItem
                          .colorScheme(context)
                          .onSecondaryContainer,
                    ),
                    elevation: 0,
                  ),
                  // Infobar
                  SliverAppBar(
                    pinned: true,
                    leading: Center(),
                    toolbarHeight: titleHeight,
                    collapsedHeight: titleHeight,
                    expandedHeight: titleHeight,
                    backgroundColor: widget.color,
                    scrolledUnderElevation: 0,
                    flexibleSpace: Container(
                      height: titleHeight,
                      padding: EdgeInsets.only(left: 30, right: 30),
                      child: Tooltip(
                        message: _episodeItem.title,
                        child: Text(
                          _episodeItem.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                color: _episodeItem
                                    .colorScheme(context)
                                    .onSecondaryContainer,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SliverAppBar(
                    // pinned: true,
                    floating: true,
                    leading: Center(),
                    toolbarHeight: 100,
                    collapsedHeight: 100,
                    expandedHeight: 100,
                    backgroundColor: widget.color,
                    scrolledUnderElevation: 0,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: 100,
                          padding: EdgeInsets.only(left: 10, right: 10),
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            // mainAxisSize:
                            //     MainAxisSize
                            //         .max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 5, 20, 5),
                                child: Row(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        if (_episodeItem.versions != null) {
                                          List<EpisodeBrief?> versions =
                                              _episodeItem.versions!.toList();
                                          versions.sort((a, b) =>
                                              b!.pubDate.compareTo(a!.pubDate));
                                          return _versionDateSelector(versions);
                                        } else {
                                          return _versionDateSelector(
                                              [_episodeItem]);
                                        }
                                      },
                                    ),
                                    SizedBox(width: 10),
                                    if (_episodeItem.isExplicit == true)
                                      Text(
                                        'E',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: context.error),
                                      )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                child: Row(
                                  children: <Widget>[
                                    if (_episodeItem.enclosureDuration != 0)
                                      Container(
                                          decoration: BoxDecoration(
                                              color: context.secondary,
                                              borderRadius: context.radiusHuge),
                                          height: 40.0,
                                          margin: EdgeInsets.only(right: 12.0),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0),
                                          alignment: Alignment.center,
                                          child: Text(
                                            context.s.minsCount(
                                              _episodeItem.enclosureDuration! ~/
                                                  60,
                                            ),
                                            style: TextStyle(
                                                color: context.surface),
                                          )),
                                    if (_episodeItem.enclosureSize != null &&
                                        _episodeItem.enclosureSize != 0)
                                      Container(
                                        decoration: BoxDecoration(
                                            color: context.tertiary,
                                            borderRadius: context.radiusHuge),
                                        height: 40.0,
                                        margin: EdgeInsets.only(right: 12.0),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${_episodeItem.enclosureSize! ~/ 1000000}MB',
                                          style:
                                              TextStyle(color: context.surface),
                                        ),
                                      ),
                                    FutureBuilder<PlayHistory>(
                                      future:
                                          _dbHelper.getPosition(_episodeItem),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          developer
                                              .log(snapshot.error as String);
                                        }
                                        if (snapshot.hasData &&
                                            snapshot.data!.seekValue! < 0.9 &&
                                            snapshot.data!.seconds! > 10) {
                                          return Container(
                                            height: 40,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 0),
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      context.radiusHuge,
                                                ),
                                                side: BorderSide(
                                                  color: _episodeItem
                                                      .colorScheme(context)
                                                      .onSecondaryContainer,
                                                ),
                                              ),
                                              onPressed: () => Provider.of<
                                                          AudioPlayerNotifier>(
                                                      context,
                                                      listen: false)
                                                  .loadEpisodeToQueue(
                                                      _episodeItem,
                                                      startPosition: (snapshot
                                                                  .data!
                                                                  .seconds! *
                                                              1000)
                                                          .toInt()),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CustomPaint(
                                                      painter: ListenedPainter(
                                                          context.textColor,
                                                          stroke: 2.0),
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    snapshot
                                                        .data!.seconds!.toTime,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Center();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ];
              },
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShowNote(episode: _episodeItem),
                    Selector<AudioPlayerNotifier, Tuple2<bool, PlayerHeight>>(
                        selector: (_, audio) =>
                            Tuple2(audio.playerRunning, audio.playerHeight!),
                        builder: (_, data, __) {
                          final height = kMinPlayerHeight[data.item2.index];
                          return SizedBox(
                            height: data.item1 ? height : 0,
                          );
                        }),
                  ],
                ),
              ),
            ),
          ),
        ),
        Selector<AudioPlayerNotifier, Tuple2<bool, PlayerHeight>>(
          selector: (_, audio) =>
              Tuple2(audio.playerRunning, audio.playerHeight!),
          builder: (_, data, __) {
            return Container(
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(
                  bottom: data.item1 ? kMinPlayerHeight[data.item2.index] : 0),
              child: SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: EpisodeActionBar(
                      episodeItem: _episodeItem, hide: widget.hide),
                ),
              ),
            );
          },
        ),
        Selector<AudioPlayerNotifier, EpisodeBrief?>(
          selector: (_, audio) => audio.episode,
          builder: (_, data, __) => Container(
            child: PlayerWidget(
                playerKey: GlobalKey<AudioPanelState>(),
                isPlayingPage: data == _episodeItem),
          ),
        ),
      ],
    );
  }

  Widget _versionDateSelector(List<EpisodeBrief?> versions) => Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: buttonOnMenu(
              context,
              child: (forceDisplayVersionIndicator ||
                      _episodeItem.isDisplayVersion!)
                  ? Icon(
                      Icons.radio_button_on,
                      size: 24,
                      color: context.accentColor,
                    )
                  : Icon(
                      Icons.radio_button_off,
                      size: 24,
                    ),
              onTap: () {
                if (!_episodeItem.isDisplayVersion!) {
                  _setEpisodeDisplayVersion(_episodeItem);
                }
              },
            ),
          ),
          DropdownButton(
            hint: Text(
                context.s.published(formateDate(_episodeItem.pubDate) +
                    " " +
                    ((_episodeItem.pubDate ~/ 1000) % 1440).toTime),
                style: TextStyle(color: context.accentColor)),
            underline: Center(),
            dropdownColor: context.accentBackground,
            borderRadius: context.radiusSmall,
            isDense: true,
            value: _episodeItem,
            selectedItemBuilder: (context) => versions
                .map(
                  (e) => Text(
                    context.s.published(
                      formateDate(e!.pubDate) +
                          " " +
                          ((_episodeItem.pubDate ~/ 1000) % 1440).toTime,
                    ),
                    style: TextStyle(
                      color: context.accentColor,
                    ),
                  ),
                )
                .toList(),
            items: versions
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Text(
                          context.s.published(formateDate(e!.pubDate)) +
                              " " +
                              ((_episodeItem.pubDate ~/ 1000) % 1440).toTime,
                          style: TextStyle(
                            fontWeight: e.isDisplayVersion!
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    )))
                .toList(),
            onChanged: versions.length == 1
                ? null
                : (EpisodeBrief? episode) {
                    if (mounted && episode != null) {
                      setState(() {
                        forceDisplayVersionIndicator = false;
                        _episodeItem = episode;
                      });
                    }
                  },
          ),
        ],
      );
  Future<void> _setEpisodeDisplayVersion(EpisodeBrief episode) async {
    await Provider.of<EpisodeState>(context, listen: false)
        .setDisplayVersion(episode);
    forceDisplayVersionIndicator = true;
  }
}
