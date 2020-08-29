import 'dart:async';
import 'dart:io';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_run.dart';

/// Runs a process
Future<void> runFlutter(String exec, List<String> args,
    {String workingDirectory}) async {
  final pr = await run(
    exec,
    args,
    workingDirectory: workingDirectory,
    stdout: stdout,
    stderr: stderr,
    runInShell: Platform.isWindows,
  );
  // Cancel subscription before close
  await stdout.close();
  await stderr.close();

  exitCode = pr.exitCode;
}

Future<void> setupFlutterSdk(String version) async {
  final flutterExec = getFlutterSdkExec(version);
  await runFlutter(flutterExec, ['--version']);
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
