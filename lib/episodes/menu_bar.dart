import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../state/episode_state.dart';
import 'package:tuple/tuple.dart';
import 'package:provider/provider.dart';
import 'episode_download.dart';
import '../state/audio_state.dart';
import '../type/episodebrief.dart';
import '../util/extension_helper.dart';
import '../widgets/custom_widget.dart';

import '../util/helpers.dart';

class EpisodeActionBar extends StatefulWidget {
  final EpisodeBrief episodeItem;
  final bool? hide;
  const EpisodeActionBar({required this.episodeItem, this.hide, super.key});
  @override
  EpisodeActionBarState createState() => EpisodeActionBarState();
}

class EpisodeActionBarState extends State<EpisodeActionBar> {
  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerNotifier>(context, listen: false);
    final episodeState = Provider.of<EpisodeState>(context, listen: false);
    final s = context.s;
    return Container(
      height: 50.0,
      decoration: BoxDecoration(
        color: context.realDark
            ? context.surface
            : widget.episodeItem.cardColor(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: SizedBox(
                      height: 30.0,
                      width: 30.0,
                      child: widget.hide!
                          ? Center()
                          : CircleAvatar(
                              radius: 15,
                              backgroundImage: widget.episodeItem.avatarImage),
                    ),
                  ),
                  (widget.episodeItem.isLiked!)
                      ? _buttonOnMenu(
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          onTap: () =>
                              episodeState.unsetLiked([widget.episodeItem]))
                      : _buttonOnMenu(
                          child: Icon(
                            Icons.favorite_border,
                            color: Colors.grey[
                                context.brightness == Brightness.light
                                    ? 700
                                    : 500],
                          ),
                          onTap: () async {
                            episodeState.setLiked([widget.episodeItem]);
                            OverlayEntry overlayEntry;
                            overlayEntry =
                                createOverlayEntry(context, leftOffset: 50);
                            Overlay.of(context).insert(overlayEntry);
                            await Future.delayed(Duration(seconds: 2));
                            overlayEntry.remove();
                          }),
                  DownloadButton(episode: widget.episodeItem),
                  Selector<AudioPlayerNotifier, List<EpisodeBrief?>>(
                    selector: (_, audio) => audio.playlist.episodes,
                    builder: (_, data, __) {
                      final inPlaylist = data.contains(widget.episodeItem);
                      return inPlaylist
                          ? _buttonOnMenu(
                              child: Icon(Icons.playlist_add_check,
                                  color: context.accentColor),
                              onTap: () async {
                                await audio
                                    .removeFromPlaylist([widget.episodeItem]);
                                await Fluttertoast.showToast(
                                  msg: s.toastRemovePlaylist,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              })
                          : _buttonOnMenu(
                              child: Icon(Icons.playlist_add,
                                  color: Colors.grey[
                                      context.brightness == Brightness.light
                                          ? 700
                                          : 500]),
                              onTap: () async {
                                await audio.addToPlaylist([widget.episodeItem]);
                                await Fluttertoast.showToast(
                                  msg: s.toastAddPlaylist,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              });
                    },
                  ),
                  _buttonOnMenu(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: widget.episodeItem.isPlayed!
                          ? CustomPaint(
                              size: Size(25, 20),
                              painter: ListenedAllPainter(context.accentColor,
                                  stroke: 2.0),
                            )
                          : CustomPaint(
                              size: Size(25, 20),
                              painter: MarkListenedPainter(
                                  Colors.grey[
                                      context.brightness == Brightness.light
                                          ? 700
                                          : 500]!,
                                  stroke: 2.0),
                            ),
                    ),
                    onTap: () {
                      widget.episodeItem.isPlayed!
                          ? episodeState.unsetListened([widget.episodeItem])
                          : episodeState.setListened([widget.episodeItem]);
                      Fluttertoast.showToast(
                        msg: widget.episodeItem.isPlayed!
                            ? s.markNotListened
                            : s.markListened,
                        gravity: ToastGravity.BOTTOM,
                      );
                    },
                  )
                ],
              ),
            ),
          ),
          Selector<AudioPlayerNotifier, Tuple2<EpisodeBrief?, bool>>(
            selector: (_, audio) => Tuple2(audio.episode, audio.playerRunning),
            builder: (_, data, __) {
              return (widget.episodeItem == data.item1 && data.item2)
                  ? Padding(
                      padding: EdgeInsets.only(right: 30),
                      child: SizedBox(
                          width: 20,
                          height: 15,
                          child: WaveLoader(color: context.accentColor)))
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await audio.loadEpisodeToQueue(widget.episodeItem);
                          if (!audio.playing) {
                            await audio.resumeAudio();
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 50.0,
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: <Widget>[
                              Text(
                                s.play.toUpperCase(),
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.play_arrow,
                                color: context.accentColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buttonOnMenu({Widget? child, VoidCallback? onTap}) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0), child: child),
          ),
        ),
      );
}
