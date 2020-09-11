import 'dart:async';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/utils/console_stream_controller.dart';
import 'package:process_run/cmd_run.dart';

class FlutterCmd extends ProcessCmd {
  // Somehow flutter requires runInShell on Linux, does not hurt on windows
  FlutterCmd(String version, List<String> arguments)
      : super(getFlutterSdkExec(version), arguments,
            workingDirectory: kWorkingDirectory.path);
}

/// Runs a process
Future<void> runFlutterCmd(
  String version,
  List<String> args,
) async {
  if (stdin.hasTerminal) {
    stdin.lineMode = false;
  }

  final result = await runCmd(
    FlutterCmd(version, args),
    stdout: consoleController.stdoutSink,
    stderr: consoleController.stderrSink,
    stdin: consoleController.stdinSink,
  );

  if (stdin.hasTerminal) {
    stdin.lineMode = true;
  }

  exitCode = result.exitCode;
}

Future<void> upgradeFlutterChannel(String version) async {
  if (!isFlutterChannel(version)) {
    throw Exception('Can only upgrade Flutter Channels');
  }
  await runFlutterCmd(version, ['upgrade']);
}

Future<void> disableTracking(String version) async {
  await runFlutterCmd(version, ['config', '--no-analytics']);
}
