import 'dart:developer' as developer;
import 'dart:io';

import 'package:color_thief_dart/color_thief_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../state/podcast_group.dart';
import '../type/play_histroy.dart';
import '../type/podcastlocal.dart';
import '../util/extension_helper.dart';
import '../util/helpers.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_widget.dart';
import '../widgets/duraiton_picker.dart';

enum MarkStatus { start, complete, none }

enum RefreshCoverStatus { start, complete, error, none }

class PodcastSetting extends StatefulWidget {
  const PodcastSetting({required this.podcastLocal, Key? key})
      : super(key: key);
  final PodcastLocal? podcastLocal;

  @override
  _PodcastSettingState createState() => _PodcastSettingState();
}

class _PodcastSettingState extends State<PodcastSetting> {
  final _dbHelper = DBHelper();
  MarkStatus _markStatus = MarkStatus.none;
  RefreshCoverStatus _coverStatus = RefreshCoverStatus.none;
  int? _secondsStart;
  int? _secondsEnd;
  late bool _markConfirm;
  late bool _removeConfirm;
  late bool _showStartTimePicker;
  late bool _showEndTimePicker;

  @override
  void initState() {
    super.initState();
    _secondsStart = 0;
    _secondsEnd = 0;
    _markConfirm = false;
    _removeConfirm = false;
    _showStartTimePicker = false;
    _showEndTimePicker = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final groupList = context.watch<GroupList>();
    final textStyle = context.textTheme.bodyText2!;
    final colorScheme = ColorScheme.fromSeed(
        seedColor: widget.podcastLocal!.primaryColor!.toColor(),
        brightness: context.brightness);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FutureBuilder<bool>(
            future: _getAutoDownload(widget.podcastLocal!.id),
            initialData: false,
            builder: (context, snapshot) {
              return ListTile(
                onTap: () => _setAutoDownload(!snapshot.data!),
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
                      value: snapshot.data!,
                      activeColor: colorScheme.primary,
                      onChanged: _setAutoDownload),
                ),
              );
            }),
        FutureBuilder<bool>(
            future: _getNeverUpdate(widget.podcastLocal!.id),
            initialData: false,
            builder: (context, snapshot) {
              return ListTile(
                dense: true,
                onTap: () => _setNeverUpdate(!snapshot.data!),
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
                      value: snapshot.data!,
                      activeColor: colorScheme.primary,
                      onChanged: _setNeverUpdate),
                ),
              );
            }),
        FutureBuilder<bool>(
            future: _getHideNewMark(widget.podcastLocal!.id),
            initialData: false,
            builder: (context, snapshot) {
              return ListTile(
                dense: true,
                onTap: () => _setHideNewMark(!snapshot.data!),
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
                      value: snapshot.data!,
                      activeColor: colorScheme.primary,
                      onChanged: _setHideNewMark),
                ),
              );
            }),
        FutureBuilder<VersionPolicy>(
          future: _getVersionPolicy(widget.podcastLocal!.id),
          builder: (context, snapshot) {
            return Column(
              children: <Widget>[
                ListTile(
                    title: Row(
                      children: [
                        Icon(Icons.onetwothree_outlined, size: 18),
                        SizedBox(width: 20),
                        Text(s.settingsEpisodeVersioning, style: textStyle),
                      ],
                    ),
                    dense: true),
                Container(
                  child: MyDropdownButton(
                    hint: FutureBuilder<String>(
                      future: _getVersionPolicyText(VersionPolicy.Default),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data!,
                            style: textStyle,
                          );
                        } else {
                          return Center();
                        }
                      },
                    ),
                    underline: Center(),
                    dropdownColor:
                        colorScheme.primary.toStrongBackround(context),
                    displayItemCount: 4,
                    value: snapshot.data,
                    onChanged: (VersionPolicy policy) async {
                      _setVersionPolicy(widget.podcastLocal!.id, policy);
                    },
                    items: <VersionPolicy>[
                      VersionPolicy.Default,
                      VersionPolicy.New,
                      VersionPolicy.Old,
                      VersionPolicy.NewIfNoDownloaded
                    ].map<DropdownMenuItem<VersionPolicy>>((e) {
                      return DropdownMenuItem<VersionPolicy>(
                          value: e,
                          child: FutureBuilder<String>(
                            future: _getVersionPolicyText(e),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  snapshot.data!,
                                  style: textStyle,
                                );
                              } else {
                                return Center();
                              }
                            },
                          ));
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
        FutureBuilder<int?>(
          future: _getSkipSecondStart(widget.podcastLocal!.id),
          initialData: 0,
          builder: (context, snapshot) => ListTile(
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
              child: Text(snapshot.data!.toTime),
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
              onChange: (value) => _secondsStart = value.inSeconds),
        FutureBuilder<int?>(
          future: _getSkipSecondEnd(widget.podcastLocal!.id),
          initialData: 0,
          builder: (context, snapshot) => ListTile(
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
              child: Text(snapshot.data!.toTime),
            ),
          ),
        ),
        if (_showEndTimePicker)
          _TimePicker(
              color: colorScheme.primary,
              onCancel: () {
                _secondsStart = 0;
                setState(() => _showEndTimePicker = false);
              },
              onConfirm: () async {
                await _saveSkipSecondsStart(_secondsStart);
                if (mounted) setState(() => _showEndTimePicker = false);
              },
              onChange: (value) => _secondsStart = value.inSeconds),
        ListTile(
          onTap: () {
            if (_coverStatus != RefreshCoverStatus.start) {
              _refreshArtWork();
            }
          },
          dense: true,
          title: Row(
            children: [
              Icon(Icons.refresh, size: 18),
              SizedBox(width: 20),
              Text(s.refreshArtwork, style: textStyle),
            ],
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: _getRefreshStatusIcon(_coverStatus,
                  color: colorScheme.primary),
            ),
          ),
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
                  painter: ListenedAllPainter(colorScheme.onSecondaryContainer,
                      stroke: 2),
                ),
              ),
              SizedBox(width: 20),
              Text(s.menuMarkAllListened,
                  style: textStyle.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold)),
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
                    )),
                TextButton(
                    onPressed: () {
                      if (_markStatus != MarkStatus.start) {
                        _markListened(widget.podcastLocal!.id);
                      }
                      setState(() {
                        _markConfirm = false;
                      });
                    },
                    child: Text(s.confirm,
                        style: TextStyle(color: colorScheme.primary))),
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
              Text(s.remove,
                  style: textStyle.copyWith(
                      color: Colors.red, fontWeight: FontWeight.bold)),
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
                  child:
                      Text(s.cancel, style: TextStyle(color: Colors.grey[600])),
                ),
                TextButton(
                    onPressed: () async {
                      await groupList.removePodcast(widget.podcastLocal!);
                      Navigator.of(context).pop();
                    },
                    child:
                        Text(s.confirm, style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _setAutoDownload(bool boo) async {
    var permission = await _checkPermmison();
    if (permission) {
      await _dbHelper.saveAutoDownload(widget.podcastLocal!.id, boo: boo);
    }
    if (mounted) setState(() {});
  }

  Future<void> _setNeverUpdate(bool boo) async {
    await _dbHelper.saveNeverUpdate(widget.podcastLocal!.id, boo: boo);
    if (mounted) setState(() {});
  }

  Future<void> _setHideNewMark(bool boo) async {
    await _dbHelper.saveHideNewMark(widget.podcastLocal!.id, boo: boo);
    if (mounted) setState(() {});
  }

  Future<void> _setVersionPolicy(
      String? id, VersionPolicy versionPolicy) async {
    await _dbHelper.saveVersionPolicy(id, versionPolicy);
    if (mounted) setState(() {});
  }

  Future<void> _saveSkipSecondsStart(int? seconds) async {
    await _dbHelper.saveSkipSecondsStart(widget.podcastLocal!.id, seconds);
  }

  Future<void> _saveSkipSecondsEnd(int seconds) async {
    await _dbHelper.saveSkipSecondsEnd(widget.podcastLocal!.id, seconds);
  }

  Future<bool> _getAutoDownload(String? id) async {
    return await _dbHelper.getAutoDownload(id);
  }

  Future<bool> _getNeverUpdate(String? id) async {
    return await _dbHelper.getNeverUpdate(id);
  }

  Future<bool> _getHideNewMark(String? id) async {
    return await _dbHelper.getHideNewMark(id);
  }

  Future<VersionPolicy> _getVersionPolicy(String? id) async {
    return await _dbHelper.getPodcastVersionPolicy(id);
  }

  Future<int?> _getSkipSecondStart(String? id) async {
    return await _dbHelper.getSkipSecondsStart(id);
  }

  Future<int?> _getSkipSecondEnd(String id) async {
    return await _dbHelper.getSkipSecondsEnd(id);
  }

  Future<void> _markListened(String? podcastId) async {
    setState(() {
      _markStatus = MarkStatus.start;
    });
    final episodes =
        await _dbHelper.getEpisodes(feedIds: [podcastId!], filterPlayed: 1);
    for (var episode in episodes) {
      final history = PlayHistory(episode.title, episode.enclosureUrl, 0, 1);
      await _dbHelper.saveHistory(history);
    }
    if (mounted) {
      setState(() {
        _markStatus = MarkStatus.complete;
      });
    }
  }

  Future<void> _refreshArtWork() async {
    setState(() => _coverStatus = RefreshCoverStatus.start);
    var options = BaseOptions(
      connectTimeout: 30000,
      receiveTimeout: 90000,
    );
    var dir = await getApplicationDocumentsDirectory();
    var filePath = "${dir.path}/${widget.podcastLocal!.id}.png";
    var dio = Dio(options);
    String? imageUrl;

    try {
      var response = await dio.get(widget.podcastLocal!.rssUrl);
      try {
        var p = RssFeed.parse(response.data);
        imageUrl = p.itunes!.image!.href ?? p.image!.url;
      } catch (e) {
        developer.log(e.toString());
        if (mounted) setState(() => _coverStatus = RefreshCoverStatus.error);
      }
    } catch (e) {
      developer.log(e.toString());
      if (mounted) setState(() => _coverStatus = RefreshCoverStatus.error);
    }
    if (imageUrl != null && imageUrl.contains('http')) {
      try {
        img.Image thumbnail;
        var imageResponse = await dio.get<List<int>>(imageUrl,
            options: Options(
              responseType: ResponseType.bytes,
            ));
        var image = img.decodeImage(imageResponse.data!)!;
        thumbnail = img.copyResize(image, width: 300);
        File(filePath).writeAsBytesSync(img.encodePng(thumbnail));
        final imageProvider = FileImage(File(filePath));
        var colorImage = await getImageFromProvider(imageProvider);
        var color = await getColorFromImage(colorImage);
        var primaryColor = color.toString();
        _dbHelper.updatePodcastImage(
            id: widget.podcastLocal!.id,
            filePath: filePath,
            color: primaryColor);
        if (mounted) {
          Fluttertoast.showToast(
            msg: context.s.restartAppForEffect,
            gravity: ToastGravity.TOP,
          );
          setState(() => _coverStatus = RefreshCoverStatus.complete);
        }
      } catch (e) {
        developer.log(e.toString());
        if (mounted) {
          if (e is DioError &&
              e.error is SocketException &&
              e.message.substring(17, 35) == "Failed host lookup") {
            Fluttertoast.showToast(
              msg: context.s.networkErrorDNS,
              gravity: ToastGravity.TOP,
            );
          }
          setState(() => _coverStatus = RefreshCoverStatus.error);
        }
      }
    } else if (_coverStatus == RefreshCoverStatus.start) {
      if (mounted) {
        setState(() => _coverStatus = RefreshCoverStatus.complete);
      }
    }
  }

  Future<bool> _checkPermmison() async {
    var permission = await Permission.storage.status;
    if (permission != PermissionStatus.granted) {
      var permissions = await [Permission.storage].request();
      if (permissions[Permission.storage] == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
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
      default:
        return Center();
    }
  }

  Future<String> _getVersionPolicyText(VersionPolicy versionPolicy) async {
    final s = context.s;
    switch (versionPolicy) {
      case VersionPolicy.New:
        return s.episodeVersioningNew;
      case VersionPolicy.Old:
        return s.episodeVersioningOld;
      case VersionPolicy.NewIfNoDownloaded:
        return s.episodeVersioningNewIfNotDownloaded;
      case VersionPolicy.Default:
        var storage = KeyValueStorage(versionPolicyKey);
        var globalVersionPolicy = await storage.getString(defaultValue: "DON");
        return "${s.capitalDefault} (${await _getVersionPolicyText(versionPolicyFromString(globalVersionPolicy))})";
    }
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker(
      {this.onConfirm, this.onCancel, this.onChange, this.color, Key? key})
      : super(key: key);
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
          DurationPicker(
            color: color,
            onChange: onChange,
          ),
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
                    surfaceTintColor: context.priamryContainer),
                onPressed: onConfirm,
                child: Text(
                  s.confirm,
                  style: TextStyle(color: color ?? context.accentColor),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
