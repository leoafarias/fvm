import 'dart:async';
import 'dart:io';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/utils/console_stream_controller.dart';
import 'package:process_run/cmd_run.dart';

import 'package:process_run/process_run.dart';

/// Runs a process
Future<void> runFlutter(String exec, List<String> args,
    {String workingDirectory}) async {
  if (stdin.hasTerminal) {
    stdin.lineMode = false;
  }

  final pr = await run(
    exec,
    args,
    workingDirectory: workingDirectory,
    stdout: consoleController.stdoutSink,
    stderr: consoleController.stderrSink,
    stdin: consoleController.stdinSink,
    runInShell: Platform.isWindows,
  );

  if (stdin.hasTerminal) {
    stdin.lineMode = true;
  }

  await stdout.close();
  await stderr.close();

  exitCode = pr.exitCode;
}

Future<void> upgradeFlutterChannel(String version) async {
  if (!isFlutterChannel(version)) {
    throw Exception('Can only upgrade Flutter Channels');
  }
  final flutterExec = getFlutterSdkExec(version);
  await runFlutter(flutterExec, ['upgrade']);
}

Future<void> disableTracking(String version) async {
  final flutterExec = getFlutterSdkExec(version);
  await runFlutter(flutterExec, ['config', '--no-analytics']);
}
