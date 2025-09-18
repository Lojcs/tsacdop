import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../state/download_state.dart';
import '../type/episode_task.dart';
import '../util/extension_helper.dart';
import '../widgets/custom_widget.dart';

class DownloadButton extends StatefulWidget {
  final int episodeId;
  const DownloadButton({required this.episodeId, super.key});
  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  void _deleteDownload(int episodeId) async {
    context.downloadState.removeDownload(episodeId);
    Fluttertoast.showToast(
      msg: context.s.downloadRemovedToast,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Widget _buttonOnMenu(Widget widget, Function() onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
              height: 50.0,
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: widget),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Selector<DownloadState, EpisodeTask?>(
      selector: (_, dState) {
        var task = dState[widget.episodeId];
        return task;
      },
      builder: (context, task, _) {
        return Row(
          children: <Widget>[
            _downloadButton(task, context),
            AnimatedContainer(
              duration: Duration(seconds: 1),
              curve: Curves.ease,
              decoration: BoxDecoration(
                  color: context.accentColor,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              height: 20.0,
              width: (task?.status == DownloadTaskStatus.running ||
                      task?.status == DownloadTaskStatus.enqueued)
                  ? 50.0
                  : 0,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  '${math.max<int>(task?.progress ?? 0, 0)}%',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _downloadButton(EpisodeTask? task, BuildContext context) {
    switch (task?.status) {
      case null || DownloadTaskStatus.undefined:
        return _buttonOnMenu(
            Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CustomPaint(
                  painter: DownloadPainter(
                    color: Colors.grey[
                        context.brightness == Brightness.light ? 700 : 500],
                    fraction: 0,
                    progressColor: context.accentColor,
                  ),
                ),
              ),
            ),
            () => context.downloadState
                .requestDownload(context, [widget.episodeId]));
      case DownloadTaskStatus.enqueued || DownloadTaskStatus.running:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.downloadState.pauseDownload(widget.episodeId),
            child: Container(
              height: 50.0,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, dynamic fraction, child) => SizedBox(
                  height: 20,
                  width: 20,
                  child: CustomPaint(
                    painter: DownloadPainter(
                        color: context.accentColor,
                        fraction: fraction,
                        progressColor: context.accentColor,
                        progress: task!.progress / 100),
                  ),
                ),
              ),
            ),
          ),
        );
      case DownloadTaskStatus.complete:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _deleteDownload(widget.episodeId),
            child: Container(
              height: 50.0,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CustomPaint(
                  painter: DownloadPainter(
                    color: context.accentColor,
                    fraction: 1,
                    progressColor: context.accentColor,
                    progress: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      case DownloadTaskStatus.failed || DownloadTaskStatus.canceled:
        return _buttonOnMenu(Icon(Icons.refresh, color: Colors.red),
            () => context.downloadState.pauseDownload(widget.episodeId));
      case DownloadTaskStatus.paused:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.downloadState.resumeDownload(widget.episodeId),
            child: Container(
              height: 50.0,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 500),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, dynamic fraction, child) => SizedBox(
                  height: 20,
                  width: 20,
                  child: CustomPaint(
                    painter: DownloadPainter(
                        color: context.accentColor,
                        fraction: 1,
                        progressColor: context.accentColor,
                        progress: task!.progress / 100,
                        pauseProgress: fraction),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
