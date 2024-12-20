import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../state/audio_state.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../type/playlist.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import 'custom_widget.dart';

class MultiSelectMenuBar extends StatefulWidget {
  MultiSelectMenuBar(
      {this.selectedList,
      this.selectAll,
      this.onSelectAll,
      required this.onClose,
      this.onSelectAfter,
      this.onSelectBefore,
      this.hideFavorite = false,
      this.color,
      Key? key})
      : super(key: key);
  final List<EpisodeBrief>? selectedList;
  final bool? selectAll;
  final ValueChanged<bool>? onSelectAll;
  final ValueChanged<bool> onClose;
  final ValueChanged<bool>? onSelectBefore;
  final ValueChanged<bool>? onSelectAfter;
  final bool hideFavorite;
  final Color? color;

  @override
  _MultiSelectMenuBarState createState() => _MultiSelectMenuBarState();
}

///Multi select menu bar.
class _MultiSelectMenuBarState extends State<MultiSelectMenuBar> {
  late bool _liked;
  late bool _marked;
  late bool _inPlaylist;
  late bool _downloaded;
  late bool _showPlaylists;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _marked = false;
    _downloaded = false;
    _inPlaylist = false;
    _showPlaylists = false;
  }

  @override
  void didUpdateWidget(MultiSelectMenuBar oldWidget) {
    if (oldWidget.selectedList != widget.selectedList) {
      setState(() {
        _liked = false;
        _marked = false;
        _downloaded = false;
        _inPlaylist = false;
        _showPlaylists = false;
      });
      super.didUpdateWidget(oldWidget);
    }
  }

  Future<void> _setLiked() async {
    EpisodeState episodeState =
        Provider.of<EpisodeState>(context, listen: false);
    for (var episode in widget.selectedList!) {
      await episodeState.setLiked(episode);
    }
    if (mounted) {
      setState(() => _liked = true);
      widget.onClose(false);
    }
  }

  Future<void> _setUnliked() async {
    EpisodeState episodeState =
        Provider.of<EpisodeState>(context, listen: false);
    for (var episode in widget.selectedList!) {
      await episodeState.unsetLiked(episode);
    }
    if (mounted) {
      setState(() => _liked = false);
      widget.onClose(false);
    }
  }

  Future<void> _markListened() async {
    EpisodeState episodeState =
        Provider.of<EpisodeState>(context, listen: false);
    for (var episode in widget.selectedList!) {
      await episodeState.setListened(episode);
    }
    if (mounted) {
      setState(() => _marked = true);
      widget.onClose(false);
    }
  }

  Future<void> _markNotListened() async {
    EpisodeState episodeState =
        Provider.of<EpisodeState>(context, listen: false);
    for (var episode in widget.selectedList!) {
      await episodeState.unsetListened(episode);
    }
    if (mounted) {
      setState(() => _marked = false);
      widget.onClose(false);
    }
  }

  Future<EpisodeBrief?> _getEpisode(String url) async {
    var dbHelper = DBHelper();
    var episode;
    var episodes = await dbHelper.getEpisodes(episodeUrls: [
      url
    ], optionalFields: [
      EpisodeField.mediaId,
      EpisodeField.isNew,
      EpisodeField.skipSecondsStart,
      EpisodeField.skipSecondsEnd,
      EpisodeField.episodeImage,
      EpisodeField.chapterLink
    ]);
    if (episodes.isEmpty)
      episode = null;
    else
      episode = episodes[0];
    return episode;
  }

  Widget _buttonOnMenu({Widget? child, VoidCallback? onTap}) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0), child: child),
          ),
        ),
      );

  Widget _playlistList() => SizedBox(
      height: 40,
      child: Selector<AudioPlayerNotifier, List<Playlist>>(
        selector: (_, audio) => audio.playlists,
        builder: (_, data, child) {
          return Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (var p in data)
                    if (p.name == 'Queue')
                      _buttonOnMenu(
                        child: Row(
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 5),
                            Text('New')
                          ],
                        ),
                        onTap: () {
                          setState(() => _showPlaylists = false);
                          showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: MaterialLocalizations.of(context)
                                  .modalBarrierDismissLabel,
                              barrierColor: Colors.black54,
                              transitionDuration:
                                  const Duration(milliseconds: 200),
                              pageBuilder:
                                  (context, animaiton, secondaryAnimation) =>
                                      _NewPlaylist(widget.selectedList,
                                          color: widget.color));
                        },
                      )
                    else
                      _buttonOnMenu(
                        child: Row(
                          children: [
                            Container(
                              height: 30,
                              width: 30,
                              color:
                                  widget.color?.toHighlightBackround(context) ??
                                      context.primaryColorDark,
                              child: p.episodeList.isEmpty
                                  ? Center()
                                  : FutureBuilder<EpisodeBrief?>(
                                      future: _getEpisode(p.episodeList.first),
                                      builder: (_, snapshot) {
                                        if (snapshot.data != null) {
                                          return SizedBox(
                                              height: 30,
                                              width: 30,
                                              child: Image(
                                                  image: snapshot
                                                      .data!.avatarImage));
                                        }
                                        return Center();
                                      }),
                            ),
                            SizedBox(width: 10),
                            Text(p.name!),
                          ],
                        ),
                        onTap: () async {
                          await context
                              .read<AudioPlayerNotifier>()
                              .addToPlaylist(widget.selectedList!, playlist: p);
                          setState(() {
                            _showPlaylists = false;
                          });
                        },
                      )
                ],
              ),
            ),
          );
        },
      ));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    var audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, double value, child) => Container(
        height: widget.selectAll == null
            ? _showPlaylists
                ? 80
                : 40
            : _showPlaylists
                ? 130
                : 90 * value,
        decoration: BoxDecoration(
            color: widget.color?.toStrongBackround(context) ??
                context.accentBackground),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.selectAll != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                                '${widget.selectedList!.length} selected',
                                style: context.textTheme.titleLarge!.copyWith(
                                    color:
                                        widget.color ?? context.accentColor))),
                      ),
                    ),
                    Spacer(),
                    if (widget.selectedList!.length == 1)
                      SizedBox(
                        height: 25,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: context.textColor,
                                  side: BorderSide(
                                      color:
                                          widget.color ?? context.accentColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(100)))),
                              onPressed: () {
                                widget.onSelectBefore!(true);
                              },
                              child: Text('Before')),
                        ),
                      ),
                    if (widget.selectedList!.length == 1)
                      SizedBox(
                        height: 25,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: context.textColor,
                                  side: BorderSide(
                                      color:
                                          widget.color ?? context.accentColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(100)))),
                              onPressed: () {
                                widget.onSelectAfter!(true);
                              },
                              child: Text('After')),
                        ),
                      ),
                    SizedBox(
                      height: 25,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: widget.selectAll!
                                    ? Colors.white
                                    : context.textColor,
                                side: BorderSide(
                                    color: widget.color ?? context.accentColor),
                                backgroundColor: widget.selectAll!
                                    ? widget.color ?? context.accentColor
                                    : null,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(100)))),
                            onPressed: () {
                              widget.onSelectAll!(!widget.selectAll!);
                            },
                            child: Text('All')),
                      ),
                    )
                  ],
                ),
              if (_showPlaylists) _playlistList(),
              Row(
                children: [
                  if (!widget.hideFavorite)
                    _buttonOnMenu(
                        child: _liked
                            ? Icon(Icons.favorite, color: Colors.red)
                            : Icon(
                                Icons.favorite_border,
                                color: Colors.grey[
                                    context.brightness == Brightness.light
                                        ? 700
                                        : 500],
                              ),
                        onTap: () async {
                          if (widget.selectedList!.isNotEmpty) {
                            if (!_liked) {
                              await _setLiked();
                              Fluttertoast.showToast(
                                msg: s.liked,
                                gravity: ToastGravity.BOTTOM,
                              );
                              OverlayEntry _overlayEntry;
                              _overlayEntry = createOverlayEntry(context);
                              Overlay.of(context).insert(_overlayEntry);
                              await Future.delayed(Duration(seconds: 2));
                              _overlayEntry.remove();
                            } else {
                              await _setUnliked();
                              Fluttertoast.showToast(
                                msg: s.unlike,

                                /// TODO: String consistency
                                gravity: ToastGravity.BOTTOM,
                              );
                            }
                          }
                        }),
                  _buttonOnMenu(
                    child: _downloaded
                        ? Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CustomPaint(
                                painter: DownloadPainter(
                                    color: widget.color ?? context.accentColor,
                                    fraction: 1,
                                    progressColor: context.accentColor,
                                    progress: 1),
                              ),
                            ),
                          )
                        : Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CustomPaint(
                                painter: DownloadPainter(
                                  color: Colors.grey[
                                      context.brightness == Brightness.light
                                          ? 700
                                          : 500],
                                  fraction: 0,
                                  progressColor:
                                      widget.color ?? context.accentColor,
                                ),
                              ),
                            ),
                          ),
                    onTap: () {
                      if (widget.selectedList!.isNotEmpty) {
                        if (!_downloaded)
                          requestDownload(
                            widget.selectedList!,
                            context,
                            onSuccess: () {
                              if (mounted) {
                                setState(() {
                                  _downloaded = true;
                                });
                              }
                            },
                          );
                      }
                    },
                  ),
                  _buttonOnMenu(
                      child: _inPlaylist
                          ? Icon(Icons.playlist_add_check,
                              color: widget.color ?? context.accentColor)
                          : Icon(
                              Icons.playlist_add,
                              color: Colors.grey[
                                  context.brightness == Brightness.light
                                      ? 700
                                      : 500],
                            ),
                      onTap: () async {
                        if (widget.selectedList!.isNotEmpty) {
                          if (!_inPlaylist) {
                            for (var episode in widget.selectedList!) {
                              await audio.addToPlaylist([episode]);
                              await Fluttertoast.showToast(
                                msg: s.toastAddPlaylist,
                                gravity: ToastGravity.BOTTOM,
                              );
                            }
                            setState(() => _inPlaylist = true);
                          } else {
                            for (var episode in widget.selectedList!) {
                              await audio.removeFromPlaylist([episode]);
                              await Fluttertoast.showToast(
                                msg: s.toastRemovePlaylist,
                                gravity: ToastGravity.BOTTOM,
                              );
                            }
                            setState(() => _inPlaylist = false);
                          }
                        }
                      }),
                  _buttonOnMenu(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CustomPaint(
                          size: Size(25, 25),
                          painter: ListenedAllPainter(
                              _marked
                                  ? context.accentColor
                                  : Colors.grey[
                                      context.brightness == Brightness.light
                                          ? 700
                                          : 500],
                              stroke: 2.0),
                        ),
                      ),
                      onTap: () async {
                        if (widget.selectedList!.isNotEmpty) {
                          if (!_marked) {
                            await _markListened();
                            Fluttertoast.showToast(
                              msg: s.markListened,
                              gravity: ToastGravity.BOTTOM,
                            );
                          } else {
                            await _markNotListened();
                            Fluttertoast.showToast(
                              msg: s.markNotListened,
                              gravity: ToastGravity.BOTTOM,
                            );
                          }
                        }
                      }),
                  _buttonOnMenu(
                      child: Icon(
                        Icons.add_box_outlined,
                        color: Colors.grey[
                            context.brightness == Brightness.light ? 700 : 500],
                      ),
                      onTap: () {
                        if (widget.selectedList!.isNotEmpty) {
                          setState(() {
                            _showPlaylists = !_showPlaylists;
                          });
                        }
                      }),
                  Spacer(),
                  if (widget.selectAll == null)
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                                '${widget.selectedList!.length} selected',
                                style: context.textTheme.titleLarge!.copyWith(
                                    color:
                                        widget.color ?? context.accentColor))),
                      ),
                    ),
                  _buttonOnMenu(
                      child: Icon(Icons.close),
                      onTap: () => widget.onClose(true))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPlaylist extends StatefulWidget {
  final List<EpisodeBrief>? episodes;
  final Color? color;
  _NewPlaylist(this.episodes, {this.color, Key? key}) : super(key: key);

  @override
  __NewPlaylistState createState() => __NewPlaylistState();
}

class __NewPlaylistState extends State<_NewPlaylist> {
  String? _playlistName;
  int? _error;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor:
            Theme.of(context).brightness == Brightness.light
                ? Color.fromRGBO(113, 113, 113, 1)
                : Color.fromRGBO(5, 5, 5, 1),
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        backgroundColor: widget.color?.toWeakBackround(context) ??
            context.accentBackgroundWeak,
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        titlePadding: EdgeInsets.all(20),
        actionsPadding: EdgeInsets.zero,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              s.cancel,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (context
                  .read<AudioPlayerNotifier>()
                  .playlistExists(_playlistName)) {
                setState(() => _error = 1);
              } else {
                final episodesList =
                    widget.episodes!.map((e) => e.enclosureUrl).toList();
                final playlist = Playlist(_playlistName,
                    episodeList: episodesList, episodes: widget.episodes);
                context.read<AudioPlayerNotifier>().addPlaylist(playlist);
                Navigator.of(context).pop();
              }
            },
            child: Text(s.confirm,
                style: TextStyle(color: widget.color ?? context.accentColor)),
          )
        ],
        title:
            SizedBox(width: context.width - 160, child: Text('New playlist')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                hintText: 'New playlist',
                hintStyle: TextStyle(fontSize: 18),
                filled: true,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.color ?? context.accentColor, width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: widget.color ?? context.accentColor, width: 2.0),
                ),
              ),
              cursorRadius: Radius.circular(2),
              autofocus: true,
              maxLines: 1,
              onChanged: (value) {
                _playlistName = value;
              },
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: (_error == 1)
                  ? Text(
                      'Playlist existed',
                      style: TextStyle(color: Colors.red[400]),
                    )
                  : Center(),
            ),
          ],
        ),
      ),
    );
  }
}
