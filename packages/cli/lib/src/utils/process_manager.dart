import 'dart:io' as io;

import 'package:fvm/src/utils/logger.dart';
import 'package:io/io.dart';

final processManager = ProcessManager(
  stderr: io.IOSink(consoleController.stderrSink),
  stdout: io.IOSink(consoleController.stdoutSink),
);
