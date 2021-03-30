import 'dart:io' as io;

import 'logger.dart';
import 'package:io/io.dart';

final processManager = ProcessManager(
  stderr: io.IOSink(consoleController.stderrSink),
  stdout: io.IOSink(consoleController.stdoutSink),
);
