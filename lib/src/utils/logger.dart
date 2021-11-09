import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cli_util/cli_logging.dart';
import 'package:io/ansi.dart';

/// Sets default logger mode
Logger logger = Logger.standard();

/// Logger for FVM
class FvmLogger {
  FvmLogger._();

  /// Prints sucess message
  static void fine(String message) {
    print(cyan.wrap(message));
    consoleController.fine.add(utf8.encode(message));
  }

  /// Prints [message] with warning formatting
  static void warning(String message) {
    print(yellow.wrap(message));
    consoleController.warning.add(utf8.encode(message));
  }

  /// Prints [message] with info formatting
  static void info(String message) {
    print(message);
    consoleController.info.add(utf8.encode(message));
  }

  /// Prints [message] with error formatting
  static void error(String message) {
    print(red.wrap(message));
    consoleController.error.add(utf8.encode(message));
  }

  /// Prints a line space
  static void spacer() {
    print('');
    consoleController.info.add(utf8.encode(''));
  }

  /// Prints a divider
  static void divider() {
    const line = '___________________________________________________\n';

    print(line);
    consoleController.info.add(utf8.encode(line));
  }
}

/// Console controller instance
final consoleController = ConsoleController();

/// Console Controller
class ConsoleController {
  /// stdout stream
  final stdout = StreamController<List<int>>();

  /// sderr stream
  final stderr = StreamController<List<int>>();

  /// warning stream
  final warning = StreamController<List<int>>();

  /// fine stream
  final fine = StreamController<List<int>>();

  /// info stream
  final info = StreamController<List<int>>();

  /// error stream
  final error = StreamController<List<int>>();

  /// Is running on CLI
  static bool isCli = false;

  /// Checks if its running on terminal
  static bool get isTerminal => isCli && io.stdin.hasTerminal;

  /// stdout stream sink
  StreamSink<List<int>> get stdoutSink {
    return isCli ? io.stdout : stdout.sink;
  }

  /// stderr stream sink
  StreamSink<List<int>> get stderrSink {
    return isCli ? io.stderr : stderr.sink;
  }
}
