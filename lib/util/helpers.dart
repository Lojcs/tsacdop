import 'dart:ui' as ui;
import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tsacdop/util/extension_helper.dart';

import '../local_storage/key_value_storage.dart';
import '../state/download_state.dart';
import '../type/episodebrief.dart';
import '../widgets/custom_widget.dart';
import '../widgets/general_dialog.dart';

Future<ui.Image> getImageFromProvider(ImageProvider imageProvider) async {
  final ImageStream stream = imageProvider.resolve(
    ImageConfiguration(devicePixelRatio: 1.0),
  );
  final Completer<ui.Image> imageCompleter = Completer<ui.Image>();
  late ImageStreamListener listener;
  listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
    stream.removeListener(listener);
    imageCompleter.complete(info.image);
  });
  stream.addListener(listener);
  final image = await imageCompleter.future;
  return image;
}

String formateDate(int timeStamp) {
  return DateFormat.yMMMd().format(
    DateTime.fromMillisecondsSinceEpoch(timeStamp),
  );
}

Future<void> requestDownload(List<EpisodeBrief> episodes, BuildContext context,
    {VoidCallback? onSuccess}) async {
  final downloadUsingData = await KeyValueStorage(downloadUsingDataKey)
      .getBool(defaultValue: true, reverse: true);
  final permissionGranted;
  var permission = await Permission.storage.status;
  if (permission != PermissionStatus.granted) {
    var permissions = await [Permission.storage].request();
    if (permissions[Permission.storage] == PermissionStatus.granted) {
      permissionGranted = true;
    } else {
      permissionGranted = false;
    }
  } else {
    permissionGranted = true;
  }
  final result = await Connectivity().checkConnectivity();
  final usingData = result == ConnectivityResult.mobile;
  var useData = false;
  final s = context.s;
  if (permissionGranted) {
    if (downloadUsingData && usingData) {
      await generalDialog(
        context,
        title: Text(s.cellularConfirm),
        content: Text(s.cellularConfirmDes),
        actions: <Widget>[
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(
              s.cancel,
              style: TextStyle(color: context.colorScheme.onSecondaryContainer),
            ),
          ),
          TextButton(
            onPressed: () {
              useData = true;
              Navigator.of(context).pop();
            },
            child: Text(
              s.confirm,
              style: TextStyle(color: context.error),
            ),
          )
        ],
      );
    }
    if (useData || !usingData) {
      for (var episode in episodes) {
        Provider.of<DownloadState>(context, listen: false).startTask(episode);
      }
      Fluttertoast.showToast(
        msg: context.s.downloadStart,
        gravity: ToastGravity.BOTTOM,
      );
      if (onSuccess != null) {
        onSuccess();
      }
    }
  }
}

OverlayEntry createOverlayEntry(BuildContext context,
    {double leftOffset = 0, double topOffset = -60}) {
  RenderBox renderBox = context.findRenderObject() as RenderBox;
  var offset = renderBox.localToGlobal(Offset.zero);
  return OverlayEntry(
    builder: (constext) => Positioned(
      left: offset.dx + leftOffset,
      top: offset.dy + topOffset,
      child: Container(
          width: 70,
          height: 100,
          //color: Colors.grey[200],
          child: HeartOpen(width: 50, height: 80)),
    ),
  );
}

Widget buttonOnMenu(BuildContext context,
        {Widget? child, VoidCallback? onTap, bool rounded = true}) =>
    Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: rounded ? context.radiusLarge : null,
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0), child: child),
        ),
      ),
    );
