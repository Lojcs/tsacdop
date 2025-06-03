import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../state/audio_state.dart';
import '../state/episode_state.dart';
import '../type/episodebrief.dart';
import '../type/playlist.dart';
import '../util/extension_helper.dart';
import 'custom_widget.dart';

class DismissibleContainer extends StatefulWidget {
  final Playlist playlist;
  final int episodeId;
  final int index;
  final VoidCallback? onRemove;
  final bool selectMode;
  const DismissibleContainer(
      {required this.playlist,
      required this.episodeId,
      required this.index,
      this.onRemove,
      this.selectMode = false,
      super.key});

  @override
  _DismissibleContainerState createState() => _DismissibleContainerState();
}

class _DismissibleContainerState extends State<DismissibleContainer> {
  late bool _delete;

  @override
  void initState() {
    _delete = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AudioPlayerNotifier audio = context.read<AudioPlayerNotifier>();
    final s = context.s;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInSine,
      alignment: Alignment.center,
      // height: _delete ? 0 : 91.0,
      child: _delete
          ? Container(
              color: Colors.transparent,
            )
          : Column(
              children: [
                Dismissible(
                  key: ValueKey('${widget.episodeId}dis'),
                  background: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.red),
                          padding: EdgeInsets.all(5),
                          alignment: Alignment.center,
                          child: Icon(
                            LineIcons.alternateTrash,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.red),
                          padding: EdgeInsets.all(5),
                          alignment: Alignment.center,
                          child: Icon(
                            LineIcons.alternateTrash,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (direction) async {
                    setState(() {
                      _delete = true;
                    });
                    await audio.removeFromPlaylistAt(widget.index,
                        playlist: widget.playlist);
                    widget.onRemove!();
                    final episodeRemoved = widget.episodeId;
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.grey[800],
                      content: Text(s.toastRemovePlaylist,
                          style: TextStyle(color: Colors.white)),
                      action: SnackBarAction(
                          textColor: context.accentColor,
                          label: s.undo,
                          onPressed: () async {
                            await audio.addToPlaylist([episodeRemoved],
                                playlist: widget.playlist, index: widget.index);
                            widget.onRemove!();
                          }),
                    ));
                  },
                  child: EpisodeTile(
                    widget.episodeId,
                    isPlaying: false,
                    canReorder: true,
                    showDivider: false,
                    onTap: () async {
                      await context
                          .read<AudioPlayerNotifier>()
                          .loadEpisodeFromCurrentPlaylist(widget.index);
                      widget.onRemove!();
                    },
                  ),
                ),
                Divider(height: 1)
              ],
            ),
    );
  }
}

class EpisodeTile extends StatelessWidget {
  final int episodeId;
  final Color? tileColor;
  final VoidCallback? onTap;
  final bool? isPlaying;
  final bool canReorder;
  final bool showDivider;
  final bool havePadding;
  const EpisodeTile(this.episodeId,
      {this.tileColor,
      this.onTap,
      this.isPlaying,
      this.canReorder = false,
      this.showDivider = true,
      this.havePadding = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    final episode =
        Provider.of<EpisodeState>(context, listen: false)[episodeId];
    // return Container(
    //   height: context.width / 4,
    //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    //   child: EpisodeCard(
    //     context,
    //     episode,
    //     Layout.large,
    //     selected: isPlaying!,
    //     showLiked: false,
    //     showPlayedAndDownloaded: false,
    //   ),
    // );
    final s = context.s;
    final c = episode.backgroudColor(context);
    return SizedBox(
      height: 100.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Expanded(
            child: ListTile(
              tileColor:
                  tileColor, // This doesn't respect layout boundaries for some reason.
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              onTap: onTap,
              title: Container(
                child: Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              leading: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canReorder && !havePadding)
                    Icon(Icons.unfold_more, color: c),
                  SizedBox(width: canReorder && !havePadding ? 0 : 24),
                  CircleAvatar(
                      backgroundColor: c.withValues(alpha: 0.5),
                      backgroundImage: episode.episodeOrPodcastImageProvider),
                ],
              ),
              subtitle: Container(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                height: 35,
                child: Row(
                  children: <Widget>[
                    if (episode.isExplicit)
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.red[800], shape: BoxShape.circle),
                        height: 25.0,
                        width: 25.0,
                        margin: EdgeInsets.only(right: 10.0),
                        alignment: Alignment.center,
                        child: Text('E', style: TextStyle(color: Colors.white)),
                      ),
                    Selector<EpisodeState, int>(
                      selector: (_, eState) =>
                          eState[episodeId].enclosureDuration,
                      builder: (context, value, _) => value != 0
                          ? episodeTag(
                              s.minsCount(value ~/ 60), Colors.cyan[300])
                          : Center(),
                    ),
                    Selector<EpisodeState, int>(
                      selector: (_, eState) => eState[episodeId].enclosureSize,
                      builder: (context, value, _) => value != 0
                          ? episodeTag(
                              '${value ~/ 1000000}MB', Colors.lightBlue[300])
                          : Center(),
                    ),
                  ],
                ),
              ),
              trailing: isPlaying!
                  ? Container(
                      height: 20,
                      width: 20,
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: WaveLoader(color: context.accentColor))
                  : SizedBox(width: 1),
            ),
          ),
          if (showDivider) Divider(height: 1),
        ],
      ),
    );
  }
}
