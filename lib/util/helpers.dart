import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../util/extension_helper.dart';
import '../widgets/custom_widget.dart';

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

OverlayEntry createOverlayEntry(
  BuildContext context, {
  double leftOffset = 0,
  double topOffset = -60,
}) {
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
        child: HeartOpen(width: 50, height: 80),
      ),
    ),
  );
}

Widget buttonOnMenu(
  BuildContext context, {
  Widget? child,
  VoidCallback? onTap,
  bool rounded = true,
}) => Material(
  color: Colors.transparent,
  child: InkWell(
    borderRadius: rounded ? context.radiusLarge : null,
    onTap: onTap,
    child: SizedBox(
      height: 28,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: child,
      ),
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
  static Future<R> runner<R, I>(
    RootIsolateToken token,
    Future<R> Function(I input) computation,
    I input,
  ) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    return computation(input);
  }
}

String resultToString(ConnectivityResult result) => switch (result) {
  .bluetooth => "bluetooth",
  .wifi => "wifi",
  .ethernet => "ethernet",
  .mobile => "mobile",
  .none => "none",
  .vpn => "vpn",
  .satellite => "satellite",
  .other => "other",
};

ConnectivityResult stringToResult(String string) => switch (string) {
  "bluetooth" => .bluetooth,
  "wifi" => .wifi,
  "ethernet" => .ethernet,
  "mobile" => .mobile,
  "none" => .none,
  "vpn" => .vpn,
  "satellite" => .satellite,
  "other" => .other,
  _ => .other,
};

TimeOfDay minutesToTimeOfDay(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

Future<void> saveExternalFile(File file) async {
  final params = SaveFileDialogParams(sourceFilePath: file.path);
  await FlutterFileDialog.saveFile(params: params);
}

Future<void> shareFile(File file) async {
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String description,
  Color? color,
}) async =>
    (await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animaiton, secondaryAnimation) =>
          ConfirmationDialog(description: description, color: color),
    )) ==
    true;

Future<Uint8List> encryptWithPassword(List<int> data, String password) async {
  final aes = FlutterAesGcm.with256bits();
  final passwordHash = await Sha256().hash(password.codeUnits);
  final key = SecretKey(passwordHash.bytes);
  final eBox = await aes.encrypt(data, secretKey: key);
  return eBox.concatenation();
}

Future<List<int>> decryptWithPassword(
  Uint8List encrypted,
  String password,
) async {
  final aes = FlutterAesGcm.with256bits();
  final box = SecretBox.fromConcatenation(
    encrypted,
    nonceLength: aes.nonceLength,
    macLength: aes.macAlgorithm.macLength,
  );
  final passwordHash = await Sha256().hash(password.codeUnits);
  final key = SecretKey(passwordHash.bytes);
  return aes.decrypt(box, secretKey: key);
}

Future<File> datedSaveFile(String type, String extension) async {
  var tempdir = await getTemporaryDirectory();
  var datePlus = DateTime.now().toIntString();
  var file = File(
    path.join(tempdir.path, 'tsacdop_${type}_$datePlus.$extension'),
  );
  return file;
}
