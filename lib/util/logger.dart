import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'extension_helper.dart';
import 'helpers.dart';

const bool loggingActive = true;

abstract class Logger {
  static Logger? _instance;
  static Logger get instance =>
      _instance ??= loggingActive ? FileLogger() : NoopLogger();

  Future<void> log(String text);
  Future<void> runLogged(Future<void> Function() computation);
  Future<void> save();
  Future<void> run(Future<void> Function() computation) async {
    if (kDebugMode) {
      await computation();
    } else {
      await runLogged(computation);
    }
  }
}

class NoopLogger extends Logger {
  @override
  Future<void> log(String text) async {}

  @override
  Future<void> runLogged(Future<void> Function() computation) => computation();

  @override
  Future<void> save() async {}
}

class FileLogger extends Logger {
  String logText = "";

  @override
  Future<void> log(String text) async {
    logText += "${DateTime.now().toIntString(true)} - $text\n";
  }

  @override
  Future<void> save([bool crash = false]) async {
    final logFile = await datedSaveFile(crash ? "crashLog" : "log", "txt");
    await logFile.writeAsString(logText);
    await saveExternalFile(logFile);
  }

  @override
  Future<void> runLogged(Future<void> Function() computation) async {
    try {
      await computation();
    } on Exception catch (e) {
      await log("Exception uncaught:\n${e.toString()}");
      await save(true);
      rethrow;
    } on Error catch (e) {
      await log(
        "Error occurred:\n${e.toString()}\nStack trace:\n${e.stackTrace.toString()}",
      );
      await save(true);
      rethrow;
    } catch (e) {
      await log("Something happened:\n${e.toString()}");
      await save(true);
      rethrow;
    }
  }
}
