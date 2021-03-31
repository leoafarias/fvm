import 'dart:io' as io;

import 'package:io/io.dart';

import 'logger.dart';

final processManager = ProcessManager(
  stderr: io.IOSink(consoleController.stderrSink),
  stdout: io.IOSink(consoleController.stdoutSink),
);
