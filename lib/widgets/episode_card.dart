import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/state/download_state.dart';
import 'package:tsacdop/type/episodebrief.dart';
import 'package:tsacdop/util/extension_helper.dart';
import 'package:tuple/tuple.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../podcasts/podcast_detail.dart';
import '../state/audio_state.dart';
import '../state/setting_state.dart';
import '../type/play_histroy.dart';
import '../util/pageroute.dart';
import 'custom_widget.dart';
import 'episodegrid.dart';
import 'general_dialog.dart';

Widget interactiveEpisodeCard(
  BuildContext context,
  EpisodeBrief episode,
  Layout layout, {
  bool openPodcast = true,
  bool showFavorite = true,
  bool showDownload = true,
  bool showNumber = false,
  bool useEpisodeImage = false,
  String? numberText,
  bool hide = false, // TODO: What does this do?
  bool selectMode = false,
  VoidCallback? onSelect,
}) {
  assert(!showNumber || numberText != null);
  assert(!showDownload || episode.fields.contains(EpisodeField.isDownloaded));
  assert(!showFavorite || episode.fields.contains(EpisodeField.isLiked));
  assert(episode.fields.contains(EpisodeField.enclosureDuration));
  assert(episode.fields.contains(EpisodeField.enclosureSize));
  assert(
      !useEpisodeImage || episode.fields.contains(EpisodeField.episodeImage));
  assert(useEpisodeImage || episode.fields.contains(EpisodeField.podcastImage));
  assert(episode.fields.contains(EpisodeField.primaryColor));
  assert(episode.fields.contains(EpisodeField.isNew));
  assert(episode.fields.contains(EpisodeField.isPlayed));
  assert(!selectMode || onSelect != null);
  var settings = Provider.of<SettingState>(context, listen: false);
  var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
  bool selected = false;
  var s = context.s;
  DBHelper dbHelper = DBHelper();
  return Selector<AudioPlayerNotifier,
          Tuple4<EpisodeBrief?, List<String>, bool, bool>>(
      selector: (_, audio) => Tuple4(
          audio.episode,
          audio.queue.episodes.map((e) => e!.enclosureUrl).toList(),
          audio.episodeState,
          audio.playerRunning),
      builder: (_, data, __) => OpenContainerWrapper(
          avatarSize:
              layout == Layout.large ? context.width / 8 : context.width / 16,
          episode: episode,
          closedBuilder: (context, action, boo) => FutureBuilder<
                  Tuple2<bool, List<int>>>(
              future: _initData(episode),
              initialData: Tuple2(false, []),
              builder: (context, snapshot) {
                final tapToOpen = snapshot.data!.item1;
                final menuList = snapshot.data!.item2;
                return FocusedMenuHolder(
                    blurSize: 0.0,
                    menuItemExtent: 45,
                    menuBoxDecoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20.0)),
                    childDecoration: _cardDecoration(context, episode),
                    childHighlightColor: context.brightness == Brightness.light
                        ? episode.colorSchemeLight.primary
                        : episode.colorSchemeLight.onSecondaryContainer,
                    childOverlay: _progressOverlay(episode, layout),
                    duration: Duration(milliseconds: 100),
                    openWithTap: tapToOpen,
                    animateMenuItems: false,
                    blurBackgroundColor: context.brightness == Brightness.light
                        ? Colors.white38
                        : Colors.black38,
                    bottomOffsetHeight: 10,
                    menuOffset: 6,
                    menuItems: <FocusedMenuItem>[
                      FocusedMenuItem(
                          backgroundColor: context.priamryContainer,
                          highlightColor: context.accentColor,
                          title: Text(data.item1 != episode || !data.item4
                              ? s.play
                              : s.playing),
                          trailing: Icon(
                            LineIcons.playCircle,
                            color: context.accentColor,
                          ),
                          onPressed: () {
                            if (data.item1 != episode || !data.item4) {
                              audio.episodeLoad(episode);
                            }
                          }),
                      if (menuList.contains(1))
                        FocusedMenuItem(
                            backgroundColor: context.priamryContainer,
                            highlightColor: Colors.cyan,
                            title: data.item2.contains(episode.enclosureUrl)
                                ? Text(s.remove)
                                : Text(s.later),
                            trailing: Icon(
                              LineIcons.clock,
                              color: Colors.cyan,
                            ),
                            onPressed: () {
                              if (!data.item2.contains(episode.enclosureUrl)) {
                                audio.addToPlaylist(episode);
                                Fluttertoast.showToast(
                                  msg: s.toastAddPlaylist,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              } else {
                                audio.delFromPlaylist(episode);
                                Fluttertoast.showToast(
                                  msg: s.toastRemovePlaylist,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              }
                            }),
                      if (menuList.contains(2))
                        FocusedMenuItem(
                            backgroundColor: context.priamryContainer,
                            highlightColor: Colors.red,
                            title: episode.isLiked!
                                ? Text(s.unlike)
                                : Text(s.like),
                            trailing: Icon(LineIcons.heart,
                                color: Colors.red, size: 21),
                            onPressed: () async {
                              if (episode.isLiked!) {
                                await dbHelper.setUniked(episode.enclosureUrl);
                                audio.setEpisodeState = true;
                                Fluttertoast.showToast(
                                  msg: s.unliked,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              } else {
                                await dbHelper.setLiked(episode.enclosureUrl);
                                audio.setEpisodeState = true;
                                Fluttertoast.showToast(
                                  msg: s.liked,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              }
                            }),
                      if (menuList.contains(3))
                        FocusedMenuItem(
                            backgroundColor: context.priamryContainer,
                            highlightColor: Colors.blue,
                            title: episode.isPlayed!
                                ? Text(s.markNotListened,
                                    style: TextStyle(
                                        color:
                                            context.textColor.withOpacity(0.5)))
                                : Text(
                                    s.markListened,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: SizedBox(
                              width: 23,
                              height: 23,
                              child: CustomPaint(
                                  painter: ListenedAllPainter(Colors.blue,
                                      stroke: 1.5)),
                            ),
                            onPressed: () async {
                              if (episode.isPlayed!) {
                                await dbHelper
                                    .markNotListened(episode.enclosureUrl);
                                audio.setEpisodeState = true;
                                Fluttertoast.showToast(
                                  msg: s.markNotListened,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              } else {
                                await dbHelper.saveHistory(PlayHistory(
                                    episode.title, episode.enclosureUrl, 0, 1));
                                audio.setEpisodeState = true;
                                Fluttertoast.showToast(
                                  msg: s.markListened,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              }
                            }),
                      if (menuList.contains(4))
                        FocusedMenuItem(
                            backgroundColor: context.priamryContainer,
                            highlightColor: Colors.green,
                            title: episode.isDownloaded!
                                ? Text(s.downloaded,
                                    style: TextStyle(
                                        color:
                                            context.textColor.withOpacity(0.5)))
                                : Text(s.download),
                            trailing:
                                Icon(LineIcons.download, color: Colors.green),
                            onPressed: () async {
                              if (!episode.isDownloaded!) {
                                await _requestDownload(context,
                                    episode: episode);
                              }
                            }),
                      if (menuList.contains(5))
                        FocusedMenuItem(
                          backgroundColor: context.priamryContainer,
                          highlightColor: Colors.amber,
                          title: Text(s.playNext),
                          trailing: Icon(
                            LineIcons.lightningBolt,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            audio.moveToTop(episode);
                            Fluttertoast.showToast(
                              msg: s.playNextDes,
                              gravity: ToastGravity.BOTTOM,
                            );
                          },
                        ),
                    ],
                    onPressed: selectMode ? onSelect! : action,
                    child: episodeCard(context, episode, layout, tapToOpen,
                        action, data, useEpisodeImage,
                        numberText: numberText,
                        openPodcast: openPodcast,
                        showFavorite: showFavorite,
                        showDownload: showDownload,
                        showNumber: showNumber,
                        decorate: false));
              })));
}

Widget episodeCard(BuildContext context, EpisodeBrief episode, Layout layout,
    bool tapToOpen, VoidCallback action, data, bool useEpisodeImage,
    {String? numberText,
    bool openPodcast = true,
    bool showFavorite = true,
    bool showDownload = true,
    bool showNumber = false,
    bool hide = false,
    bool decorate = true}) {
  var settings = Provider.of<SettingState>(context, listen: false);
  DBHelper dbHelper = DBHelper();
  int tileCount = layout == Layout.small
      ? 3
      : layout == Layout.medium
          ? 2
          : 1;
  if (false) {
    return _layoutOneCard(context, episode, layout, useEpisodeImage,
        numberText: numberText!,
        openPodcast: openPodcast,
        showDownload: showDownload,
        showFavorite: showFavorite,
        showNumber: showNumber,
        boo: hide);
  } else {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          decorate
              ? Container(decoration: _cardDecoration(context, episode))
              : Center(),
          decorate ? _progressOverlay(episode, layout) : Center(),
          Padding(
            padding: EdgeInsets.all(layout == Layout.small ? 5 : 8)
                .copyWith(bottom: layout == Layout.small ? 10 : 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  flex: layout == Layout.small
                      ? 2
                      : layout == Layout.medium
                          ? 3
                          : 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      layout != Layout.large
                          ? _circleImage(context, openPodcast, useEpisodeImage,
                              episode: episode,
                              color: episode.getColorScheme(context).primary,
                              boo: hide)
                          : _pubDate(
                              context,
                              episode,
                            ),
                      Spacer(),
                      _isNewIndicator(episode),
                      if ((showFavorite || layout != Layout.small) &&
                          episode.isLiked!)
                        Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: context.width / 35,
                        ),
                      _numberIndicator(context, showNumber,
                          numberText: numberText,
                          color: episode.getColorScheme(context).primary)
                    ],
                  ),
                ),
                Expanded(
                  flex: layout == Layout.large ? 4 : 7,
                  child: layout != Layout.large
                      ? _title(episode, layout)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _circleImage(context, openPodcast, useEpisodeImage,
                                episode: episode,
                                color: episode.getColorScheme(context).primary,
                                boo: hide),
                            SizedBox(
                              width: 5,
                            ),
                            Expanded(child: _title(episode, layout))
                          ],
                        ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      if (layout != Layout.large)
                        Expanded(
                          flex: layout == Layout.small ? 100000 : 0,
                          child: _pubDate(context, episode,
                              small: layout == Layout.small),
                        ),
                      Spacer(),
                      if (episode.enclosureDuration != 0)
                        Stack(
                          alignment: AlignmentDirectional.centerEnd,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(5),
                                      right: episode.enclosureSize == 0
                                          ? Radius.circular(5)
                                          : Radius.zero),
                                  border: Border.all(
                                      color: context.realDark
                                          ? Colors.transparent
                                          : episode
                                              .getColorScheme(context)
                                              .onSecondaryContainer,
                                      width: 1),
                                  color: context.realDark
                                      ? episode.isPlayed!
                                          ? episode
                                              .getColorScheme(context)
                                              .secondaryContainer
                                          : Colors.transparent
                                      : episode.isPlayed!
                                          ? episode
                                              .getColorScheme(context)
                                              .onSecondaryContainer
                                          : Colors.transparent),
                              alignment: Alignment.center,
                              child: Text(
                                episode.enclosureDuration!.toTime,
                                style: TextStyle(
                                    fontSize: layout == Layout.small
                                        ? context.width / 40
                                        : context.width / 35,
                                    color: context.realDark
                                        ? episode
                                            .getColorScheme(context)
                                            .onSecondaryContainer
                                        : episode.isPlayed!
                                            ? episode
                                                .getColorScheme(context)
                                                .secondaryContainer
                                            : episode
                                                .getColorScheme(context)
                                                .onSecondaryContainer),
                              ),
                            ),
                            Container(
                                width: 1,
                                height:
                                    16, // TODO: Hardcoded height might break.
                                color: context.realDark &&
                                        !episode.isDownloaded! &&
                                        !episode.isPlayed!
                                    ? episode
                                        .getColorScheme(context)
                                        .onSecondaryContainer
                                    : Colors.transparent)
                          ],
                        ),
                      if (episode.enclosureSize != 0)
                        Stack(
                            alignment: AlignmentDirectional.centerStart,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(5),
                                        left: episode.enclosureDuration == 0
                                            ? Radius.circular(5)
                                            : Radius.zero),
                                    // border: episode.enclosureDuration == 0
                                    //     ? Border.all(
                                    //         color: episode
                                    //             .getColorScheme(context)
                                    //             .onSecondaryContainer,
                                    //       )
                                    //     : Border(
                                    //         right: BorderSide(
                                    //             color: episode
                                    //                 .getColorScheme(context)
                                    //                 .onSecondaryContainer),
                                    //         top: BorderSide(
                                    //             color: episode
                                    //                 .getColorScheme(context)
                                    //                 .onSecondaryContainer),
                                    //         bottom: BorderSide(
                                    //             color: episode
                                    //                 .getColorScheme(context)
                                    //                 .onSecondaryContainer),
                                    // ),
                                    // This doesn't work currently due to flutter barf https://github.com/flutter/flutter/issues/12583
                                    // TODO: Find workaround (solid color overlay with stack doesn't work as background is transparent and might mismatch if the episode is half played)
                                    border: Border.all(
                                        color: context.realDark
                                            ? Colors.transparent
                                            : episode
                                                .getColorScheme(context)
                                                .onSecondaryContainer,
                                        width: 1),
                                    color: context.realDark
                                        ? episode.isDownloaded!
                                            ? episode
                                                .getColorScheme(context)
                                                .secondaryContainer
                                            : Colors.transparent
                                        : episode.isDownloaded!
                                            ? episode
                                                .getColorScheme(context)
                                                .onSecondaryContainer
                                            : Colors.transparent),
                                alignment: Alignment.center,
                                child: Text(
                                  '${episode.enclosureSize! ~/ 1000000}MB',
                                  style: TextStyle(
                                      fontSize: layout == Layout.small
                                          ? context.width / 40
                                          : context.width / 35,
                                      color: context.realDark
                                          ? episode
                                              .getColorScheme(context)
                                              .onSecondaryContainer
                                          : episode.isDownloaded!
                                              ? episode
                                                  .getColorScheme(context)
                                                  .secondaryContainer
                                              : episode
                                                  .getColorScheme(context)
                                                  .onSecondaryContainer),
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height:
                                      16, // TODO: Hardcoded height might break.
                                  color: context.realDark &&
                                          !episode.isDownloaded! &&
                                          !episode.isPlayed!
                                      ? episode
                                          .getColorScheme(context)
                                          .onSecondaryContainer
                                      : Colors.transparent)
                            ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _progressOverlay(EpisodeBrief episode, Layout layout) {
  DBHelper dbHelper = DBHelper();
  return FutureBuilder<PlayHistory>(
    future: dbHelper.getPosition(episode),
    builder: (context, snapshot) {
      if (snapshot.hasData)
        return Container(
          width: context.width *
              snapshot.data!.seekValue! /
              (layout == Layout.small
                  ? 3
                  : layout == Layout.medium
                      ? 2
                      : 1),
          color: context.realDark
              ? context.background.withOpacity(0.7)
              : context.realDark
                  ? context.background.withOpacity(0.8)
                  : context.background.withOpacity(0.6),
        );
      else
        return Center();
    },
  );
}

BoxDecoration _cardDecoration(BuildContext context, EpisodeBrief episode) {
  return BoxDecoration(
    color: context.realDark
        ? Colors.black
        : episode.getColorScheme(context).secondaryContainer,
    borderRadius: BorderRadius.circular(20.0),
    border: Border.all(
      color: context.realDark
          ? episode.getColorScheme(context).primary
          : context.background,
      width: 1.0,
    ),
    // boxShadow: [
    //   BoxShadow(
    //     color: Color.fromRGBO(40, 40, 40, 1),
    //     blurRadius: 0.5,
    //     spreadRadius: 0.5,
    //     offset: Offset.fromDirection(0, 3),
    //   )]
  );
}

Widget _layoutOneCard(BuildContext context, EpisodeBrief episode, Layout layout,
    bool useEpisodeImage,
    {String? numberText,
    required bool openPodcast,
    required bool showFavorite,
    required bool showDownload,
    required bool showNumber,
    required bool boo}) {
  var width = context.width;
  return Container(
    decoration: BoxDecoration(
      color: episode.getColorScheme(context).tertiary,
      borderRadius: BorderRadius.circular(15.0),
    ),
    clipBehavior: Clip.hardEdge,
    child: Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        if (episode.isPlayed!)
          Container(
            height: 4,
            color: context.accentColor,
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: _circleImage(context, openPodcast, useEpisodeImage,
                      episode: episode,
                      color: episode.getColorScheme(context).primary,
                      boo: boo,
                      radius: context.width / 8),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Text(episode.podcastTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: episode
                                        .getColorScheme(context)
                                        .primary)),
                          ),
                          _isNewIndicator(episode),
                          _downloadIndicator(context, layout, showDownload,
                              isDownloaded: episode.isDownloaded),
                          _numberIndicator(context, showNumber,
                              numberText: numberText,
                              color: episode.getColorScheme(context).primary)
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: _title(episode, layout))),
                    Expanded(
                      flex: 1,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            if (episode.enclosureDuration != 0)
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  episode.enclosureDuration!.toTime,
                                  style: TextStyle(fontSize: width / 35),
                                ),
                              ),
                            if (episode.enclosureDuration != 0 &&
                                episode.enclosureSize != null &&
                                episode.enclosureSize != 0 &&
                                layout != Layout.small)
                              Text(
                                '|',
                                style: TextStyle(
                                  fontSize: width / 35,
                                ),
                              ),
                            if (episode.enclosureSize != null &&
                                episode.enclosureSize != 0)
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '${episode.enclosureSize! ~/ 1000000}MB',
                                  style: TextStyle(fontSize: width / 35),
                                ),
                              ),
                            SizedBox(width: 4),
                            if (episode.isLiked!)
                              Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: width / 35,
                              ),
                            Spacer(),
                            _pubDate(
                              context,
                              episode,
                            ),
                          ]),
                    )
                  ],
                ),
              ),
              SizedBox(width: 8)
            ],
          ),
        ),
      ],
    ),
  );
}

/// Episode title widget.
Widget _title(EpisodeBrief episode, Layout layout) => Container(
      alignment:
          layout == Layout.large ? Alignment.centerLeft : Alignment.topLeft,
      padding: EdgeInsets.only(top: 2.0),
      child: Text(
        episode.title,
        maxLines: layout == Layout.large ? 1 : 4,
        overflow:
            layout == Layout.large ? TextOverflow.ellipsis : TextOverflow.fade,
      ),
    );

/// Circel avatar widget.
Widget _circleImage(
        BuildContext context, bool openPodcast, bool useEpisodeImage,
        {EpisodeBrief? episode,
        Color? color,
        required bool boo,
        double? radius}) =>
    InkWell(
      onTap: () async {
        DBHelper dbHelper = DBHelper();
        if (openPodcast) {
          Navigator.push(
            context,
            SlideLeftRoute(
                page: PodcastDetail(
              podcastLocal:
                  await dbHelper.getPodcastWithUrl(episode!.enclosureUrl),
            )),
          );
        }
      },
      child: Container(
        height: radius ?? context.width / 16,
        width: radius ?? context.width / 16,
        child: boo
            ? Center()
            : CircleAvatar(
                backgroundColor: color!.withOpacity(0.5),
                backgroundImage: useEpisodeImage
                    ? episode!.episodeImageProvider
                    : episode!.podcastImageProvider),
      ),
    );

Widget _downloadIndicator(
        BuildContext context, Layout layout, bool showDownload,
        {bool? isDownloaded}) =>
    showDownload && layout != Layout.small
        ? isDownloaded!
            ? Container(
                height: 20,
                width: 20,
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 5),
                padding: EdgeInsets.fromLTRB(2, 2, 2, 3),
                decoration: BoxDecoration(
                  color: context.accentColor,
                  shape: BoxShape.circle,
                ),
                child: CustomPaint(
                  size: Size(12, 12),
                  painter: DownloadPainter(
                    stroke: 1.0,
                    color: context.accentColor,
                    fraction: 1,
                    progressColor: Colors.white,
                    progress: 1,
                  ),
                ),
              )
            : Center()
        : Center();

/// New indicator widget.
Widget _isNewIndicator(EpisodeBrief episode) => episode.isNew!
    ? Container(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text('New',
            style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
      )
    : Center();

/// Count indicator widget.
Widget _numberIndicator(BuildContext context, bool showNumber,
        {String? numberText, Color? color}) =>
    showNumber
        ? Container(
            alignment: Alignment.topRight,
            child: Text(
              numberText!,
              style: GoogleFonts.teko(
                textStyle: TextStyle(
                  fontSize: context.width / 24,
                  color: color,
                ),
              ),
            ),
          )
        : Center();

/// Pubdate widget
Widget _pubDate(BuildContext context, EpisodeBrief episode,
        {bool small = false}) =>
    Text(
      episode.pubDate.toDate(context),
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: small ? context.width / 40 : context.width / 35,
          color: episode.getColorScheme(context).primary,
          fontStyle: FontStyle.italic),
    );

Future<void> _requestDownload(BuildContext context,
    {EpisodeBrief? episode}) async {
  final permissionReady = await _checkPermmison();
  final downloadUsingData =
      Provider.of<SettingState>(context, listen: false).downloadUsingData!;
  final result = await Connectivity().checkConnectivity();
  final usingData = result == ConnectivityResult.mobile;
  var dataConfirm = true;
  if (permissionReady) {
    if (downloadUsingData && usingData) {
      dataConfirm = await _useDataConfirm(context);
    }
    if (dataConfirm) {
      Provider.of<DownloadState>(context, listen: false).startTask(episode!);
      Fluttertoast.showToast(
        msg: context.s.downloadStart,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}

Future<bool> _checkPermmison() async {
  var permission = await Permission.storage.status;
  if (permission != PermissionStatus.granted) {
    var permissions = await [Permission.storage].request();
    if (permissions[Permission.storage] == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  } else {
    return true;
  }
}

Future<bool> _useDataConfirm(BuildContext context) async {
  var ifUseData = false;
  final s = context.s;
  await generalDialog(
    context,
    title: Text(s.cellularConfirm),
    content: Text(s.cellularConfirmDes),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(
          s.cancel,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
      TextButton(
        onPressed: () {
          ifUseData = true;
          Navigator.of(context).pop();
        },
        child: Text(
          s.confirm,
          style: TextStyle(color: Colors.red),
        ),
      )
    ],
  );
  return ifUseData;
}

Future<Tuple2<bool, List<int>>> _initData(EpisodeBrief episode) async {
  final menuList = await _getEpisodeMenu();
  final tapToOpen = await _getTapToOpenPopupMenu();
  return Tuple2(tapToOpen, menuList);
}

Future<List<int>> _getEpisodeMenu() async {
  final popupMenuStorage = KeyValueStorage(
      episodePopupMenuKey); // TODO: These should be obtainable from SettingState.
  final list = await popupMenuStorage.getMenu();
  return list;
}

Future<bool> _getTapToOpenPopupMenu() async {
  final tapToOpenPopupMenuStorage = KeyValueStorage(tapToOpenPopupMenuKey);
  final boo = await tapToOpenPopupMenuStorage.getBool(defaultValue: false);
  return boo;
}
