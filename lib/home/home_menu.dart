import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../local_storage/key_value_storage.dart';
import '../backup/opml_helper.dart';
import '../settings/settting.dart';
import '../util/extension_helper.dart';
import 'about.dart';

class PopupMenu extends StatefulWidget {
  const PopupMenu({super.key});

  @override
  _PopupMenuState createState() => _PopupMenuState();
}

class _PopupMenuState extends State<PopupMenu> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: 40,
        width: 40,
        child: PopupMenuButton<int>(
          icon: Icon(Icons.more_vert),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1,
          tooltip: s.menu,
          color: context.accentBackground,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Container(
                padding: EdgeInsets.only(left: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(LineIcons.alternateRedo, size: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.homeToprightMenuRefreshAll,
                        ),
                        FutureBuilder<String>(
                            future: _getRefreshDate(context),
                            builder: (_, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  snapshot.data!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                );
                              } else {
                                return Center();
                              }
                            })
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: Row(
                  children: <Widget>[
                    Icon(LineIcons.paperclip),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                    ),
                    Text(s.homeToprightMenuImportOMPL),
                  ],
                ),
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: Container(
                padding: EdgeInsets.only(left: 10),
                child: Row(
                  children: <Widget>[
                    Icon(LineIcons.cog),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                    ),
                    Text(s.settings),
                  ],
                ),
              ),
            ),
            PopupMenuItem(
              value: 4,
              child: Container(
                padding: EdgeInsets.only(left: 10),
                child: Row(
                  children: <Widget>[
                    Icon(LineIcons.infoCircle),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                    ),
                    Text(s.homeToprightMenuAbout),
                  ],
                ),
              ),
            ),
            if (!kReleaseMode)
              PopupMenuItem(
                value: 5,
                child: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children: <Widget>[
                      Icon(LineIcons.scroll),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                      ),
                      Text("Export logs"),
                    ],
                  ),
                ),
              ),
            if (!kReleaseMode)
              PopupMenuItem(
                value: 6,
                child: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children: <Widget>[
                      Icon(LineIcons.trash),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                      ),
                      Text("Delete logs"),
                    ],
                  ),
                ),
              ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 1:
                context.podcastState.syncAllPodcasts();
              case 2:
                _getFilePath();
              case 3:
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Settings()));
              case 4:
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutApp()));
              case 5:
                _exportLogs();
              case 6:
                _deleteLogs();
            }
          },
        ),
      ),
    );
  }

  Future<void> _exportLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = path.join(dir.path, "syncLog.txt");
    if (File(filePath).existsSync()) {
      await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
    }
  }

  Future<void> _deleteLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = path.join(dir.path, "syncLog.txt");
    if (File(filePath).existsSync()) File(filePath).deleteSync();
  }

  Future<String> _getRefreshDate(BuildContext context) async {
    int? refreshDate;
    final refreshstorage = KeyValueStorage('refreshdate');
    final i = await refreshstorage.getInt();
    if (i == 0) {
      final refreshstorage = KeyValueStorage('refreshdate');
      await refreshstorage.saveInt(DateTime.now().millisecondsSinceEpoch);
      refreshDate = DateTime.now().millisecondsSinceEpoch;
    } else {
      refreshDate = i;
    }
    return refreshDate.toDate(context);
  }

  void _saveOmpl(String path) async {
    final s = context.s;
    final file = File(path);
    try {
      final opml = file.readAsStringSync();
      context.podcastState.subscribeOpml(opml);
      showDialog(
        context: context,
        builder: (context) => OpmlImportPopup(),
      );
    } catch (e) {
      developer.log(e.toString(), name: 'OMPL parse error');
      Fluttertoast.showToast(
        msg: s.toastFileError,
        gravity: ToastGravity.TOP,
      );
    }
  }

  void _getFilePath() async {
    final s = context.s;
    try {
      var filePickResult =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (filePickResult == null) {
        return;
      }
      Fluttertoast.showToast(
        msg: s.toastReadFile,
        gravity: ToastGravity.TOP,
      );
      final filePath = filePickResult.files.first.path!;
      _saveOmpl(filePath);
    } on PlatformException catch (e) {
      developer.log(e.toString(), name: 'Get OMPL file');
    }
  }
}
