import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'menu_bar.dart';
import 'shownote.dart';
import '../util/helpers.dart';
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
  final int episodeId;

  /// Hides the avatar image
  final bool hide;

  const EpisodeDetail(this.episodeId, {this.hide = false, super.key});

  @override
  State<EpisodeDetail> createState() => _EpisodeDetailState();
}

class _EpisodeDetailState extends State<EpisodeDetail> {
  final _dbHelper = DBHelper();

  final textstyle = TextStyle(fontSize: 15.0, color: Colors.black);
  final GlobalKey<AudioPanelState> _playerKey = GlobalKey<AudioPanelState>();

  late final ScrollController _controller;

  late final double _titleBarMinHeight;
  late final double _titleBarMaxHeight;
  late final double _imageTopOffset;
  late final double _sideMargin;

  bool lateInitComplete = false;

  Color get color =>
      context.realDark ? context.surface : episodeItem.cardColor(context);

  late int episodeId = widget.episodeId;

  late EpisodeState episodeState =
      Provider.of<EpisodeState>(context, listen: false);

  /// Only use this for immutable properties or in callbacks.
  EpisodeBrief get episodeItem => episodeState[episodeId];

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
      _sideMargin =
          (context.width - min(context.height - 560, context.width - 120)) / 2;
      _titleBarMaxHeight = context.width - _sideMargin * 2 + 90;
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
  Widget build(BuildContext context) {
    _lateInit();
    return Selector<AudioPlayerNotifier, bool>(
      selector: (_, audio) => audio.playerRunning,
      builder: (_, playerRunning, __) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarIconBrightness: context.iconBrightness,
          systemNavigationBarColor:
              playerRunning ? context.cardColorSchemeCard : color,
          systemNavigationBarIconBrightness: context.iconBrightness,
        ),
        child: PopScope(
          canPop: !(_playerKey.currentState != null &&
              _playerKey.currentState!.size! > 100),
          onPopInvokedWithResult: (_, __) =>
              _playerKey.currentState?.backToMini(),
          child: Scaffold(
            backgroundColor: color,
            extendBody: true,
            body: SafeArea(
              child: ColoredBox(
                color: context.realDark
                    ? context.surface
                    : episodeItem.colorScheme(context).surface,
                child: Stack(
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
                                  text: episodeItem.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                textDirection: TextDirection.ltr);
                            titleLineTest.layout(maxWidth: context.width - 60);

                            double titleHeight =
                                titleLineTest.computeLineMetrics().length * 30 +
                                    15;
                            return <Widget>[
                              _hiddenImage(),
                              // Titlebar
                              SliverAppBar(
                                pinned: true,
                                leading: Center(),
                                toolbarHeight: titleHeight,
                                collapsedHeight: titleHeight,
                                expandedHeight: titleHeight,
                                backgroundColor: color,
                                scrolledUnderElevation: 0,
                                flexibleSpace: Container(
                                  height: titleHeight,
                                  padding: EdgeInsets.only(left: 30, right: 30),
                                  child: Tooltip(
                                    message: episodeItem.title,
                                    child: Text(
                                      episodeItem.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium!
                                          .copyWith(
                                            color: episodeItem
                                                .colorScheme(context)
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              _infoBar(),
                            ];
                          },
                          body: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShowNote(episodeId: widget.episodeId),
                                Selector<AudioPlayerNotifier,
                                        Tuple2<bool, PlayerHeight>>(
                                    selector: (_, audio) => Tuple2(
                                        audio.playerRunning,
                                        audio.playerHeight!),
                                    builder: (_, data, __) {
                                      final height =
                                          kMinPlayerHeight[data.item2.index];
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
                              bottom: data.item1
                                  ? kMinPlayerHeight[data.item2.index]
                                  : 0),
                          child: SizedBox(
                            height: 50,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: EpisodeActionBar(episodeId,
                                  hide: widget.hide),
                            ),
                          ),
                        );
                      },
                    ),
                    Selector<AudioPlayerNotifier, int?>(
                      selector: (_, audio) => audio.episodeId,
                      builder: (_, data, __) => PlayerWidget(
                          playerKey: GlobalKey<AudioPanelState>(),
                          isPlayingPage: data == widget.episodeId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hiddenImage() => SliverAppBar(
        flexibleSpace: LayoutBuilder(
          builder: (context, constraints) {
            double topHeight = constraints.biggest.height;
            double expandRatio =
                ((topHeight - _titleBarMinHeight) / _titleBarMaxHeight)
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
                        (topHeight - _titleBarMinHeight)
                            .clamp(0, _imageTopOffset - _titleBarMinHeight)),
              ),
              expandedTitleScale: 1.1,
              background: Container(
                margin: EdgeInsets.only(
                  left: _sideMargin,
                  right: _sideMargin,
                  top: _imageTopOffset +
                      _titleBarMaxHeight -
                      expandRatio * _titleBarMaxHeight,
                  bottom: 0,
                ),
                color: color,
                child: Image(
                    alignment: Alignment.topCenter,
                    fit: BoxFit.fitWidth,
                    image: episodeItem.episodeOrPodcastImageProvider),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      "${episodeItem.number} | ",
                      style: GoogleFonts.teko(
                          textStyle: context.textTheme.headlineSmall),
                    ),
                  ),
                  Expanded(
                    child: Tooltip(
                      message: episodeItem.podcastTitle,
                      child: Text(
                        episodeItem.podcastTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: episodeItem
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
        backgroundColor: color,
        collapsedHeight: _titleBarMinHeight,
        toolbarHeight: _titleBarMinHeight,
        expandedHeight: _titleBarMinHeight + _titleBarMaxHeight,
        pinned: true,
        // floating: true,
        scrolledUnderElevation: 0,
        leading: CustomBackButton(
          color: episodeItem.colorScheme(context).onSecondaryContainer,
        ),
        elevation: 0,
      );

  Widget _infoBar() => SliverAppBar(
        // pinned: true,
        floating: true,
        leading: Center(),
        toolbarHeight: 100,
        collapsedHeight: 100,
        expandedHeight: 100,
        backgroundColor: color,
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
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: Row(
                      children: [
                        episodeItem.versions == null
                            ? FutureBuilder(
                                future: episodeState
                                    .populateEpisodeVersions(episodeId),
                                builder: (context, snapshot) =>
                                    (episodeItem.versions == null)
                                        ? _versionDateSelector([episodeId])
                                        : _versionDateSelector(
                                            episodeItem.versions!),
                              )
                            : _versionDateSelector(episodeItem.versions!),
                        SizedBox(width: 10),
                        if (episodeItem.isExplicit == true)
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Row(
                      children: <Widget>[
                        Selector<EpisodeState, int>(
                          selector: (_, episodeState) =>
                              episodeState[episodeId].enclosureDuration,
                          builder: (context, value, _) => value != 0
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: context.secondary,
                                      borderRadius: context.radiusHuge),
                                  height: 40.0,
                                  margin: EdgeInsets.only(right: 12.0),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 10.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    context.s.minsCount(
                                      value ~/ 60,
                                    ),
                                    style: TextStyle(color: context.surface),
                                  ),
                                )
                              : Center(),
                        ),
                        Selector<EpisodeState, int>(
                          selector: (_, episodeState) =>
                              episodeState[episodeId].enclosureSize,
                          builder: (context, value, _) => value != 0
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: context.tertiary,
                                      borderRadius: context.radiusHuge),
                                  height: 40.0,
                                  margin: EdgeInsets.only(right: 12.0),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 10.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${value ~/ 1000000}MB',
                                    style: TextStyle(color: context.surface),
                                  ),
                                )
                              : Center(),
                        ),
                        FutureBuilder<PlayHistory>(
                          future: _dbHelper.getPosition(episodeItem),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              developer.log(snapshot.error as String);
                            }
                            if (snapshot.hasData &&
                                snapshot.data!.seekValue! < 0.9 &&
                                snapshot.data!.seconds! > 10) {
                              return Container(
                                height: 40,
                                padding: EdgeInsets.symmetric(horizontal: 0),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: context.radiusHuge,
                                    ),
                                    side: BorderSide(
                                      color: episodeItem
                                          .colorScheme(context)
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                  onPressed: () => Provider.of<
                                              AudioPlayerNotifier>(context,
                                          listen: false)
                                      .loadEpisodeToQueue(episodeId,
                                          startPosition:
                                              (snapshot.data!.seconds! * 1000)
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
                                        snapshot.data!.seconds!.toTime,
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
      );

  Widget _versionDateSelector(List<int> versions) => Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: buttonOnMenu(
              context,
              child: Selector<EpisodeState, bool>(
                selector: (_, episodeState) =>
                    episodeState[episodeId].isDisplayVersion,
                builder: (context, value, _) => value
                    ? Icon(
                        Icons.radio_button_on,
                        size: 24,
                        color: context.accentColor,
                      )
                    : Icon(
                        Icons.radio_button_off,
                        size: 24,
                      ),
              ),
              onTap: () {
                if (!episodeItem.isDisplayVersion) {
                  episodeState.setDisplayVersion(episodeId);
                }
              },
            ),
          ),
          DropdownButton<int>(
            hint: Text(
                context.s.published(
                    "${formateDate(episodeItem.pubDate)} ${((episodeItem.pubDate ~/ 1000) % 1440).toTime}"),
                style: TextStyle(color: context.accentColor)),
            underline: Center(),
            dropdownColor: context.accentBackground,
            borderRadius: context.radiusSmall,
            isDense: true,
            value: episodeId,
            selectedItemBuilder: (context) => versions
                .map(
                  (id) => Text(
                    context.s.published(
                      "${formateDate(episodeState[id].pubDate)} ${((episodeState[id].pubDate ~/ 1000) % 1440).toTime}",
                    ),
                    style: TextStyle(
                      color: context.accentColor,
                    ),
                  ),
                )
                .toList(),
            items: versions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Selector<EpisodeState, bool>(
                      selector: (_, episodeState) =>
                          episodeState[e].isDisplayVersion,
                      builder: (context, value, _) => Text(
                        "${context.s.published(formateDate(episodeState[e].pubDate))} ${((episodeState[e].pubDate ~/ 1000) % 1440).toTime}",
                        style: TextStyle(
                          fontWeight:
                              value ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: versions.length == 1
                ? null
                : (int? id) {
                    if (mounted && id != null) {
                      setState(() => episodeId = id);
                    }
                  },
          ),
        ],
      );
}
