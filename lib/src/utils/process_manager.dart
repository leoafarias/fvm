import 'dart:io' as io;

import 'package:io/io.dart';

import 'logger.dart';

/// Process manager
final processManager = ProcessManager(
  stderr: io.IOSink(consoleController.stderrSink),
  stdout: io.IOSink(consoleController.stdoutSink),
);
