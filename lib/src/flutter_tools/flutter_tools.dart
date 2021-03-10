import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/utils/logger.dart';

import 'package:fvm/src/utils/process_manager.dart';

import 'package:io/io.dart';

/// Runs a process
Future<int> runFlutterCmd(
  String version,
  List<String> args,
) async {
  final execPath = getFlutterSdkExec(version);
  args ??= [];
  // Check if can execute path first
  if (!await isExecutable(execPath)) {
    throw UsageException('Flutter version $version is not installed', '');
  }

  _switchLineMode(false, args);

  final process = await processManager.spawn(
    execPath,
    args,
    environment: replaceFlutterPathEnv(version),
    workingDirectory: kWorkingDirectory.path,
  );

  exitCode = await process.exitCode;

  _switchLineMode(true, args);

  await sharedStdIn.terminate();

  return exitCode;
}

// Replicate Flutter cli behavior during run
// Allows to add commands without ENTER after
void _switchLineMode(bool active, List<String> args) {
  // Don't do anything if its not terminal
  // or if it's not run command
  if (!ConsoleController.isTerminal || args.isEmpty || args.first != 'run') {
    return;
  }

  // Seems incompatible with different shells. Silent error
  try {
    // Don't be smart about passing [active].
    // The commands need to be called in different order
    if (active) {
      // echoMode needs to come after lineMode
      // Error on windows
      // https://github.com/dart-lang/sdk/issues/28599
      stdin.lineMode = true;
      stdin.echoMode = true;
    } else {
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  } on Exception catch (err) {
    // Trace but silent the error
    logger.trace(err.toString());
    return;
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
