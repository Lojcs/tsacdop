import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';

import '../episodes/episode_detail.dart';
import '../state/download_state.dart';
import '../type/episode_task.dart';
import '../util/extension_helper.dart';
import '../util/pageroute.dart';

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
      switch (task.status) {
        DownloadTaskStatus.undefined => SizedBox(width: 10, height: 10),
        DownloadTaskStatus.enqueued => IconButton(
            splashRadius: 20,
            icon: Icon(
              Icons.pause_circle_filled,
            ),
            onPressed: () => downloader.pauseDownload(task.episodeId),
          ),
        DownloadTaskStatus.running => IconButton(
            splashRadius: 20,
            icon: Icon(
              Icons.pause_circle_filled,
            ),
            onPressed: () => downloader.pauseDownload(task.episodeId),
          ),
        DownloadTaskStatus.complete => Center(),
        DownloadTaskStatus.failed || DownloadTaskStatus.canceled => IconButton(
            splashRadius: 20,
            icon: Icon(Icons.refresh, color: Colors.red),
            onPressed: () => downloader.retryDownload(task.episodeId),
          ),
        DownloadTaskStatus.paused => IconButton(
            splashRadius: 20,
            icon: Icon(Icons.play_circle_filled),
            onPressed: () => downloader.resumeDownload(task.episodeId),
          ),
      },
      IconButton(
        splashRadius: 20,
        icon: Icon(Icons.close),
        onPressed: () => downloader.removeDownload(task.episodeId),
      ),
    ],
  );
}

class _DownloadListState extends State<DownloadList> {
  @override
  Widget build(BuildContext context) {
    return Selector<DownloadState, double>(
      selector: (_, dState) => dState.listsUpdate,
      builder: (context, _, __) {
        final tasks = context.downloadState.allDownloads
            .where((eTask) => eTask.status != DownloadTaskStatus.complete)
            .toList();
        return tasks.isNotEmpty
            ? SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 5.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      final episode = context.episodeState[task.episodeId];
                      return ListTile(
                        onTap: () => Navigator.push(
                          context,
                          ScaleRoute(
                            page: EpisodeDetail(task.episodeId),
                          ),
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
                                child: tasks[index].progress >= 0 &&
                                        (tasks[index].status !=
                                                DownloadTaskStatus.failed &&
                                            tasks[index].status !=
                                                DownloadTaskStatus.canceled)
                                    ? Container(
                                        width: 40.0,
                                        height: 20.0,
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 2),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(6)),
                                            color: Colors.red),
                                        child: Text(
                                          '${tasks[index].progress}%',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : Container(
                                        height: 40,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            value: tasks[index].progress / 100,
                          ),
                        ),
                        leading: CircleAvatar(
                            radius: 20, backgroundImage: episode.avatarImage),
                        trailing: _downloadButton(tasks[index], context),
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
              )
            : SliverToBoxAdapter(
                child: Center(),
              );
      },
    );
  }
}
