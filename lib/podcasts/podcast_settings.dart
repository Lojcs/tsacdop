import 'dart:developer' as developer;
import 'dart:io';

import 'package:color_thief_dart/color_thief_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../state/podcast_group.dart';
import '../state/podcast_state.dart';
import '../type/play_histroy.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import '../widgets/custom_widget.dart';
import '../widgets/duraiton_picker.dart';

enum MarkStatus { start, complete, none }

enum RefreshCoverStatus { start, complete, error, none }

class PodcastSetting extends StatefulWidget {
  const PodcastSetting({required this.podcastId, super.key});
  final String podcastId;

  @override
  State<PodcastSetting> createState() => _PodcastSettingState();
}

class _PodcastSettingState extends State<PodcastSetting> {
  final _dbHelper = DBHelper();
  late final _pState = context.podcastState;
  MarkStatus _markStatus = MarkStatus.none;
  RefreshCoverStatus _coverStatus = RefreshCoverStatus.none;
  int _secondsStart = 0;
  int _secondsEnd = 0;
  late bool _markConfirm;
  late bool _removeConfirm;
  late bool _showStartTimePicker;
  late bool _showEndTimePicker;

  @override
  void initState() {
    super.initState();
    _markConfirm = false;
    _removeConfirm = false;
    _showStartTimePicker = false;
    _showEndTimePicker = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final textStyle = context.textTheme.bodyMedium!;
    return Selector<PodcastState, ColorScheme>(
      selector: (context, pState) =>
          pState[widget.podcastId].colorScheme(context),
      builder: (context, colorScheme, _) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Selector<PodcastState, bool>(
            selector: (_, pState) => pState[widget.podcastId].autoDownload,
            builder: (context, autoDownload, _) => ListTile(
              onTap: () => _setAutoDownload(!autoDownload),
              dense: true,
              title: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CustomPaint(
                      painter: DownloadPainter(
                        color: context.textColor,
                        fraction: 0,
                        progressColor: colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(s.autoDownload, style: textStyle),
                ],
              ),
              trailing: Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: autoDownload,
                  activeThumbColor: colorScheme.primary,
                  onChanged: _setAutoDownload,
                ),
              ),
            ),
          ),
          Selector<PodcastState, bool>(
            selector: (_, pState) => pState[widget.podcastId].noAutoSync,
            builder: (context, noAutoSync, _) => ListTile(
              dense: true,
              onTap: () => _setNeverUpdate(!noAutoSync),
              title: Row(
                children: [
                  Icon(Icons.lock_outlined, size: 18),
                  SizedBox(width: 20),
                  Text(s.neverAutoUpdate, style: textStyle),
                ],
              ),
              trailing: Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: noAutoSync,
                  activeThumbColor: colorScheme.primary,
                  onChanged: _setNeverUpdate,
                ),
              ),
            ),
          ),
          Selector<PodcastState, bool>(
            selector: (_, pState) => pState[widget.podcastId].hideNewMark,
            builder: (context, hideNewMark, _) => ListTile(
              dense: true,
              onTap: () => _setHideNewMark(!hideNewMark),
              title: Row(
                children: [
                  Icon(LineIcons.eraser, size: 18),
                  SizedBox(width: 20),
                  Text('Always hide new mark', style: textStyle),
                ],
              ),
              trailing: Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: hideNewMark,
                  activeThumbColor: colorScheme.primary,
                  onChanged: _setHideNewMark,
                ),
              ),
            ),
          ),
          Selector<PodcastState, int>(
            selector: (_, pState) => pState[widget.podcastId].skipSecondsStart,
            builder: (context, skipSecondsStart, _) => ListTile(
              onTap: () {
                _secondsStart = 0;
                setState(() {
                  _removeConfirm = false;
                  _markConfirm = false;
                  _showEndTimePicker = false;
                  _showStartTimePicker = !_showStartTimePicker;
                });
              },
              dense: true,
              title: Row(
                children: [
                  Icon(Icons.fast_forward_outlined, size: 18),
                  SizedBox(width: 20),
                  Text(s.skipSecondsAtStart, style: textStyle),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text(skipSecondsStart.toTime),
              ),
            ),
          ),
          if (_showStartTimePicker)
            _TimePicker(
              color: colorScheme.primary,
              onCancel: () {
                _secondsStart = 0;
                setState(() => _showStartTimePicker = false);
              },
              onConfirm: () async {
                await _saveSkipSecondsStart(_secondsStart);
                if (mounted) setState(() => _showStartTimePicker = false);
              },
              onChange: (value) => _secondsStart = value.inSeconds,
            ),
          Selector<PodcastState, int>(
            selector: (_, pState) => pState[widget.podcastId].skipSecondsEnd,
            builder: (context, skipSecondsEnd, _) => ListTile(
              onTap: () {
                _secondsStart = 0;
                setState(() {
                  _removeConfirm = false;
                  _markConfirm = false;
                  _showStartTimePicker = false;
                  _showEndTimePicker = !_showEndTimePicker;
                });
              },
              dense: true,
              title: Row(
                children: [
                  Icon(Icons.fast_rewind_outlined, size: 18),
                  SizedBox(width: 20),
                  Text(s.skipSecondsAtEnd, style: textStyle),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text(skipSecondsEnd.toTime),
              ),
            ),
          ),
          if (_showEndTimePicker)
            _TimePicker(
              color: colorScheme.primary,
              onCancel: () {
                _secondsEnd = 0;
                setState(() => _showEndTimePicker = false);
              },
              onConfirm: () async {
                await _saveSkipSecondsEnd(_secondsEnd);
                if (mounted) setState(() => _showEndTimePicker = false);
              },
              onChange: (value) => _secondsEnd = value.inSeconds,
            ),
          Divider(height: 1),
          ListTile(
            onTap: () {
              setState(() {
                _removeConfirm = false;
                _showStartTimePicker = false;
                _showEndTimePicker = false;
                _markConfirm = !_markConfirm;
              });
            },
            dense: true,
            title: Row(
              children: [
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CustomPaint(
                    painter: ListenedAllPainter(
                      colorScheme.onSecondaryContainer,
                      stroke: 2,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Text(
                  s.menuMarkAllListened,
                  style: textStyle.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: _markStatus == MarkStatus.none
                    ? Center()
                    : _markStatus == MarkStatus.start
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          )
                        : Icon(Icons.done),
              ),
            ),
          ),
          if (_markConfirm)
            Container(
              width: double.infinity,
              color: colorScheme.primary.toStrongBackround(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _markConfirm = false;
                    }),
                    child: Text(
                      s.cancel,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_markStatus != MarkStatus.start) {
                        _markListened(widget.podcastId);
                      }
                      setState(() {
                        _markConfirm = false;
                      });
                    },
                    child: Text(
                      s.confirm,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ListTile(
            onTap: () {
              setState(() {
                _markConfirm = false;
                _showStartTimePicker = false;
                _showEndTimePicker = false;
                _removeConfirm = !_removeConfirm;
              });
            },
            dense: true,
            title: Row(
              children: [
                Icon(Icons.delete_outlined, color: Colors.red, size: 18),
                SizedBox(width: 20),
                Text(
                  s.remove,
                  style: textStyle.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_removeConfirm)
            Container(
              width: double.infinity,
              color: context.primaryColorDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _removeConfirm = false;
                    }),
                    child: Text(
                      s.cancel,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _pState.unsubscribePodcast(widget.podcastId);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(s.confirm, style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _setAutoDownload(bool boo) async {
    await _pState.changePodcastProperty([widget.podcastId], autoDownload: boo);
  }

  Future<void> _setNeverUpdate(bool boo) async {
    await _pState.changePodcastProperty([widget.podcastId], noAutoSync: boo);
  }

  Future<void> _setHideNewMark(bool boo) async {
    await _pState.changePodcastProperty([widget.podcastId], hideNewMark: boo);
  }

  Future<void> _saveSkipSecondsStart(int seconds) async {
    await _pState.changePodcastProperty([
      widget.podcastId,
    ], skipSecondsStart: seconds);
  }

  Future<void> _saveSkipSecondsEnd(int seconds) async {
    await _pState.changePodcastProperty([
      widget.podcastId,
    ], skipSecondsEnd: seconds);
  }

  Future<void> _markListened(String? podcastId) async {
    setState(() {
      _markStatus = MarkStatus.start;
    });
    final eState = context.episodeState;
    final episodes = await eState.getEpisodes(
      feedIds: [podcastId!],
      filterPlayed: false,
    );
    for (var episode in episodes.map((id) => eState[id])) {
      final history = PlayHistory(episode.title, episode.enclosureUrl, 0, 1);
      await _dbHelper.saveHistory(history);
    }
    if (mounted) {
      setState(() {
        _markStatus = MarkStatus.complete;
      });
    }
  }

  Widget _getRefreshStatusIcon(RefreshCoverStatus status, {Color? color}) {
    switch (status) {
      case RefreshCoverStatus.none:
        return Center();
      case RefreshCoverStatus.start:
        return CircularProgressIndicator(strokeWidth: 2, color: color);
      case RefreshCoverStatus.complete:
        return Icon(Icons.done);
      case RefreshCoverStatus.error:
        return Icon(Icons.refresh, color: Colors.red);
    }
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({this.onConfirm, this.onCancel, this.onChange, this.color});
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ValueChanged<Duration>? onChange;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      color: color?.toStrongBackround(context) ?? context.primaryColorDark,
      child: Column(
        children: [
          SizedBox(height: 10),
          DurationPicker(color: color, onChange: onChange),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(
                  s.cancel,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  surfaceTintColor: context.priamryContainer,
                ),
                onPressed: onConfirm,
                child: Text(
                  s.confirm,
                  style: TextStyle(color: color ?? context.accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
