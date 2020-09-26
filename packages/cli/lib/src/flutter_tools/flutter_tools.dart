import 'dart:async';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:fvm/src/utils/process_manager.dart';

import 'package:io/io.dart';

/// Runs a process
Future<void> runFlutterCmd(
  String version,
  List<String> arguments,
) async {
  if (isCli) {
    stdin.echoMode = false;
    stdin.lineMode = false;
  }

  final execPath = getFlutterSdkExec(version);
  // Check if can execute path first
  if (!await isExecutable(execPath)) {
    throw UsageError('Flutter version $version is not installed');
  }

  final process = await processManager.spawn(
    execPath,
    arguments,
    workingDirectory: kWorkingDirectory.path,
  );

  exitCode = await process.exitCode;

  if (isCli) {
    stdin.lineMode = true;
    // echoMode needs to come after lineMode
    // Error on windows
    // https://github.com/dart-lang/sdk/issues/28599
    stdin.echoMode = true;
    await sharedStdIn.terminate();
  }
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
