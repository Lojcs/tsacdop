import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../episode/detail/widget/episode_detail.dart';
import '../../download/state/download_state.dart';
import '../../download/state/episode_task.dart';
import '../../../core/extension/extension_helper.dart';
import '../../../core/route/page_route.dart';

class DownloadList extends StatefulWidget {
  const DownloadList({super.key});

  @override
  State<DownloadList> createState() => _DownloadListState();
}

Widget _downloadButton(EpisodeTask task, BuildContext context) {
  var downloader = Provider.of<DownloadState>(context, listen: false);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      switch (task.status?.status) {
        null || .enqueued || .waitingToRetry => IconButton(
          splashRadius: 20,
          icon: Icon(Icons.pause_circle_filled),
          onPressed: () => downloader.pauseDownload(task.episodeId),
        ),
        .running => IconButton(
          splashRadius: 20,
          icon: Icon(Icons.pause_circle_filled),
          onPressed: () => downloader.pauseDownload(task.episodeId),
        ),
        .complete => Center(),
        .failed || .canceled || .notFound => IconButton(
          splashRadius: 20,
          icon: Icon(Icons.refresh, color: Colors.red),
          onPressed: () => downloader.retryDownload(task.episodeId),
        ),
        .paused => IconButton(
          splashRadius: 20,
          icon: Icon(Icons.play_circle_filled),
          onPressed: () => downloader.resumeDownload(task.episodeId),
        ),
      },
      IconButton(
        splashRadius: 20,
        icon: Icon(Icons.close),
        onPressed: () => downloader.removeOngoingDownload(task.episodeId),
      ),
    ],
  );
}

class _DownloadListState extends State<DownloadList> {
  @override
  Widget build(BuildContext context) {
    return Selector<DownloadState, List<int>>(
      selector: (_, dState) => dState.ongoingEpisodeTasks.keys.toList(),
      builder: (context, ids, __) => ids.isNotEmpty
          ? SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Selector<DownloadState, EpisodeTask>(
                    selector: (_, dState) =>
                        dState.ongoingEpisodeTasks[ids[index]]!,
                    builder: (context, task, __) {
                      final episode = context.episodeState[task.episodeId];
                      return ListTile(
                        onTap: () => Navigator.push(
                          context,
                          ScaleRoute(page: EpisodeDetail(task.episodeId)),
                        ),
                        title: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                flex: 5,
                                child: Text(
                                  episode.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child:
                                    task.progress != null &&
                                        task.progress!.progress >= 0
                                    ? Container(
                                        width: 40.0,
                                        height: 20.0,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(6),
                                          ),
                                          color: Colors.red,
                                        ),
                                        child: Text(
                                          '${(task.progress!.progress * 100).toInt()}%',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : Container(height: 40),
                              ),
                            ],
                          ),
                        ),
                        subtitle: SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            value: task.progress?.progress ?? 0,
                          ),
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: episode.avatarImage,
                        ),
                        trailing: _downloadButton(task, context),
                      );
                    },
                  );
                }, childCount: ids.length),
              ),
            )
          : SliverToBoxAdapter(child: Center()),
    );
  }
}
