import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cli_util/cli_logging.dart';
import 'package:io/ansi.dart';

/// Log
Logger logger = Logger.standard();

class FvmLogger {
  /// Prints sucess message
  static void fine(String message) {
    print(green.wrap(message));
    consoleController.fine.add(utf8.encode(message));
  }

  static void warning(String message) {
    print(yellow.wrap(message));
    consoleController.warning.add(utf8.encode(message));
  }

  static void info(String message) {
    print(cyan.wrap(message));
    consoleController.info.add(utf8.encode(message));
  }

  static void error(String message) {
    print(red.wrap(message));
    consoleController.error.add(utf8.encode(message));
  }
}

final consoleController = ConsoleController();

class ConsoleController {
  final stdout = StreamController<List<int>>();
  final stderr = StreamController<List<int>>();
  final warning = StreamController<List<int>>();
  final fine = StreamController<List<int>>();
  final info = StreamController<List<int>>();
  final error = StreamController<List<int>>();
  static bool isCli = false;

  static bool get isTerminal => isCli && io.stdin.hasTerminal;

  StreamSink<List<int>> get stdoutSink {
    return isCli ? io.stdout : stdout.sink;
  }

  StreamSink<List<int>> get stderrSink {
    return isCli ? io.stderr : stderr.sink;
  }
}
