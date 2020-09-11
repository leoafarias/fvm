import 'dart:async';

import 'dart:io' as io;

final consoleController = ConsoleController();

class ConsoleController {
  bool isCli;

  final stdout = StreamController<List<int>>();
  final stderr = StreamController<List<int>>();
  ConsoleController() {
    isCli = io.stdin.hasTerminal;
  }

  io.Stdin get stdinSink {
    return isCli ? io.stdin : null;
  }

  StreamSink<List<int>> get stdoutSink {
    return isCli ? io.stdout : stdout.sink;
  }

  StreamSink<List<int>> get stderrSink {
    return isCli ? io.stderr : stderr.sink;
  }
}
