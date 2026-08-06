import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../backup/opml_helper.dart';
import '../settings/settings.dart';
import '../util/extension_helper.dart';
import '../util/logger.dart';
import 'about.dart';

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 1,
          tooltip: s.menu,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Container(
                padding: EdgeInsets.only(left: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(LineIcons.alternateRedo, size: 20),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 5.0)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(s.homeToprightMenuRefreshAll),
                        Text(
                          context.settingState.lastSyncTime
                              .get()
                              .toRelativeString(context),
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
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
                    Padding(padding: EdgeInsets.symmetric(horizontal: 5.0)),
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
                    Padding(padding: EdgeInsets.symmetric(horizontal: 5.0)),
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
                    Padding(padding: EdgeInsets.symmetric(horizontal: 5.0)),
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
                      Padding(padding: EdgeInsets.symmetric(horizontal: 5.0)),
                      Text("Export sync logs"),
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
                      Padding(padding: EdgeInsets.symmetric(horizontal: 5.0)),
                      Text("Delete logs"),
                    ],
                  ),
                ),
              ),
            if (loggingActive)
              PopupMenuItem(
                value: 7,
                child: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.save),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 5.0)),
                      Text("Save logger log"),
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
                var filePickResult = await FilePicker.pickFiles(
                  type: FileType.any,
                );
                if (filePickResult != null && context.mounted) {
                  importOpml(context, File(filePickResult.files.first.path!));
                }
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutApp()),
                );
              case 5:
                await _exportLogs();
              case 6:
                await _deleteLogs();
              case 7:
                await Logger.instance.save();
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
}
