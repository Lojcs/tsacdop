import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';
import '../type/episodebrief.dart';

import '../episodes/episode_detail.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/download_state.dart';
import '../type/episode_task.dart';
import '../util/pageroute.dart';

class DownloadList extends StatefulWidget {
  const DownloadList({super.key});

  @override
  _DownloadListState createState() => _DownloadListState();
}

Widget _downloadButton(EpisodeTask task, BuildContext context) {
  var downloader = Provider.of<DownloadState>(context, listen: false);
  switch (task.status!) {
    case DownloadTaskStatus.running:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            splashRadius: 20,
            icon: Icon(
              Icons.pause_circle_filled,
            ),
            onPressed: () => downloader.pauseTask(task.episode),
          ),
          IconButton(
            splashRadius: 20,
            icon: Icon(Icons.close),
            onPressed: () => downloader.delTask(task.episode!),
          ),
        ],
      );
    case DownloadTaskStatus.failed:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: Icon(Icons.refresh, color: Colors.red),
            onPressed: () => downloader.retryTask(task.episode!),
          ),
          IconButton(
            splashRadius: 20,
            icon: Icon(Icons.close),
            onPressed: () => downloader.delTask(task.episode!),
          ),
        ],
      );
    case DownloadTaskStatus.canceled:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: Icon(Icons.refresh, color: Colors.red),
            onPressed: () => downloader.retryTask(task.episode!),
          ),
          IconButton(
            splashRadius: 20,
            icon: Icon(Icons.close),
            onPressed: () => downloader.delTask(task.episode!),
          ),
        ],
      );
    case DownloadTaskStatus.paused:
      return Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          splashRadius: 20,
          icon: Icon(Icons.play_circle_filled),
          onPressed: () => downloader.resumeTask(task.episode!),
        ),
        IconButton(
          splashRadius: 20,
          icon: Icon(Icons.close),
          onPressed: () => downloader.delTask(task.episode!),
        ),
      ]);
    default:
      return SizedBox(
        width: 10,
        height: 10,
      );
  }
}

class _DownloadListState extends State<DownloadList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadState>(builder: (_, downloader, __) {
      final tasks = downloader.episodeTasks
          .where((task) => task.status != DownloadTaskStatus.complete)
          .toList();
      return tasks.isNotEmpty
          ? SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        ScaleRoute(
                            page: FutureBuilder(
                                future: tasks[index]
                                    .episode!
                                    .copyWithFromDB(newFields: [
                                  EpisodeField.description,
                                  EpisodeField.number,
                                  EpisodeField.enclosureDuration,
                                  EpisodeField.enclosureSize,
                                  EpisodeField.isDownloaded,
                                  EpisodeField.episodeImage,
                                  EpisodeField.podcastImage,
                                  EpisodeField.primaryColor,
                                  EpisodeField.isLiked,
                                  EpisodeField.isNew,
                                  EpisodeField.isPlayed,
                                  EpisodeField.isDisplayVersion
                                ]),
                                builder: ((context, snapshot) =>
                                    snapshot.hasData
                                        ? EpisodeDetail(
                                            episodeItem:
                                                snapshot.data as EpisodeBrief,
                                          )
                                        : Center()))),
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
                                tasks[index].episode!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: tasks[index].progress! >= 0 &&
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
                                      ))
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
                          value: tasks[index].progress! / 100,
                        ),
                      ),
                      leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: tasks[index].episode!.avatarImage),
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
    });
  }
}
