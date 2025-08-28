import 'dart:isolate';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../local_storage/key_value_storage.dart';
import '../service/opml_build.dart';
import '../state/download_state.dart';
import '../state/podcast_state.dart';
import '../type/episodebrief.dart';
import '../type/podcastgroup.dart';
import '../util/extension_helper.dart';
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

OverlayEntry createOverlayEntry(BuildContext context,
    {double leftOffset = 0, double topOffset = -60}) {
  RenderBox renderBox = context.findRenderObject() as RenderBox;
  var offset = renderBox.localToGlobal(Offset.zero);
  return OverlayEntry(
    builder: (constext) => Positioned(
      left: offset.dx + leftOffset,
      top: offset.dy + topOffset,
      child: SizedBox(
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
          height: 28,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0), child: child),
        ),
      ),
    );

/// Launders [Isolate.run] so it doesn't capture unnecessary variables.
/// Also ensures [BackgroundIsolateBinaryMessenger] is initialized.
class Isolater<R, I> {
  Future<R> Function(I input) computation;
  final rootIsolateToken = ServicesBinding.rootIsolateToken!;
  Isolater(this.computation);
  Future<R> run(I input) =>
      Isolate.run(() => runner(rootIsolateToken, computation, input));
  @pragma('vm:entry-point')
  static Future<R> runner<R, I>(RootIsolateToken token,
      Future<R> Function(I input) computation, I input) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    return computation(input);
  }
}
