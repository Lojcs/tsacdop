import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../state/download_state.dart';
import '../state/episode_task.dart';
import '../../../core/extension/extension_helper.dart';
import '../../../core/misc/custom_widget.dart';

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
        child: widget,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Selector<DownloadState, EpisodeTask?>(
      selector: (_, dState) => dState[widget.episodeId],
      builder: (context, task, _) {
        return Row(
          children: <Widget>[
            _downloadButton(task, context),
            AnimatedContainer(
              duration: Duration(seconds: 1),
              curve: Curves.ease,
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
              ),
              height: 20.0,
              width:
                  (task?.status?.status == .running ||
                      task?.status?.status == .enqueued)
                  ? 50.0
                  : 0,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  '${((task?.progress?.progress ?? 0) * 100).toInt()}%',
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
    switch (task?.status?.status) {
      case null:
        return _buttonOnMenu(
          Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CustomPaint(
                painter: DownloadPainter(
                  color: Colors
                      .grey[context.brightness == Brightness.light ? 700 : 500],
                  fraction: 0,
                  progressColor: context.primaryColor,
                ),
              ),
            ),
          ),
          () =>
              context.downloadState.manualDownload(context, [widget.episodeId]),
        );
      case .enqueued || .running || .waitingToRetry:
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
                      color: context.primaryColor,
                      fraction: fraction,
                      progressColor: context.primaryColor,
                      progress: (task!.progress?.progress ?? 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case .complete:
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
                    color: context.primaryColor,
                    fraction: 1,
                    progressColor: context.primaryColor,
                    progress: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      case .failed || .canceled || .notFound:
        return _buttonOnMenu(
          Icon(Icons.refresh, color: Colors.red),
          () => context.downloadState.pauseDownload(widget.episodeId),
        );
      case .paused:
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
                      color: context.primaryColor,
                      fraction: 1,
                      progressColor: context.primaryColor,
                      progress: (task!.progress?.progress ?? 0),
                      pauseProgress: fraction,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
