import 'dart:async';

import 'dart:io' as io;

import 'package:io/io.dart';

final processManager = ProcessManager(
  stderr: io.IOSink(consoleController.stderrSink),
  stdout: io.IOSink(consoleController.stdoutSink),
);

final consoleController = ConsoleController();

class ConsoleController {
  bool isCli;

  final stdout = StreamController<List<int>>();
  final stderr = StreamController<List<int>>();
  ConsoleController() {
    isCli = io.stdin.hasTerminal;
  }

  StreamSink<List<int>> get stdoutSink {
    return isCli ? io.stdout : stdout.sink;
  }

  StreamSink<List<int>> get stderrSink {
    return isCli ? io.stderr : stderr.sink;
  }
}
