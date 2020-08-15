import 'dart:io';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_run.dart';

/// Runs a process
Future<void> runFlutter(String exec, List<String> args,
    {String workingDirectory}) async {
  var pr = await run(
    exec,
    args,
    workingDirectory: workingDirectory,
    stdout: stdout,
    stderr: stderr,
    runInShell: Platform.isWindows,
    stdin: stdin,
  );
  exitCode = pr.exitCode;
}

Future<void> setupFlutterSdk(String version) async {
  final flutterExec = getFlutterSdkExec(version: version);
  await runFlutter(flutterExec, ['--version']);
}
