import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../local_storage/key_value_storage.dart';
import '../state/audio_state.dart';
import '../state/download_state.dart';
import '../type/episode_task.dart';
import '../type/episodebrief.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import '../widgets/custom_widget.dart';
import '../widgets/general_dialog.dart';

class DownloadButton extends StatefulWidget {
  final EpisodeBrief? episode;
  DownloadButton({this.episode, Key? key}) : super(key: key);
  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  void _deleteDownload(EpisodeBrief episode) async {
    Provider.of<DownloadState>(context, listen: false).delTask(episode);
    Fluttertoast.showToast(
      msg: context.s.downloadRemovedToast,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _pauseDownload(EpisodeBrief? episode) async {
    Provider.of<DownloadState>(context, listen: false).pauseTask(episode);
  }

  Future<void> _resumeDownload(EpisodeBrief episode) async {
    Provider.of<DownloadState>(context, listen: false).resumeTask(episode);
  }

  Future<void> _retryDownload(EpisodeBrief episode) async {
    Provider.of<DownloadState>(context, listen: false).retryTask(episode);
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
    return Consumer<DownloadState>(builder: (_, downloader, __) {
      var _task = Provider.of<DownloadState>(context, listen: false)
          .episodeToTask(widget.episode);
      return Row(
        // TODO: On emulator this is sometimes unresponsive as _task.status returns undefined even though the task is enqueued. Test real device.
        children: <Widget>[
          _downloadButton(_task, context),
          AnimatedContainer(
              duration: Duration(seconds: 1),
              decoration: BoxDecoration(
                  color: context.accentColor,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              height: 20.0,
              width: (_task.status == DownloadTaskStatus.running ||
                      _task.status == DownloadTaskStatus.enqueued)
                  ? 50.0
                  : 0,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text('${math.max<int>(_task.progress!, 0)}%',
                    style: TextStyle(color: Colors.white)),
              )),
        ],
      );
    });
  }

  Widget _downloadButton(EpisodeTask task, BuildContext context) {
    switch (task.status!.value) {
      case 0: // DownloadTaskStatus.undefined
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
            () => requestDownload([task.episode!], context));
      case 1: // DownloadTaskStatus.enqueued
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (task.progress! > 0) _pauseDownload(task.episode);
            },
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
                        progress: task.progress! / 100),
                  ),
                ),
              ),
            ),
          ),
        );
      case 2: // DownloadTaskStatus.running
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (task.progress! > 0) _pauseDownload(task.episode);
            },
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
                        progress: task.progress! / 100),
                  ),
                ),
              ),
            ),
          ),
        );
      case 3: // DownloadTaskStatus.complete
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _deleteDownload(task.episode!);
            },
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
      case 4: // DownloadTaskStatus.failed
        return _buttonOnMenu(Icon(Icons.refresh, color: Colors.red),
            () => _retryDownload(task.episode!));
      case 6: // DownloadTaskStatus.paused
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _resumeDownload(task.episode!);
            },
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
                        progress: task.progress! / 100,
                        pauseProgress: fraction),
                  ),
                ),
              ),
            ),
          ),
        );
      default: // DownloadTaskStatus.canceled
        return Center();
    }
  }
}
