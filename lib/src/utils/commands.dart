import 'dart:io';

import 'package:io/io.dart';
import 'package:process_run/shell.dart';

import '../../constants.dart';
import '../../fvm.dart';
import 'console_utils.dart';
import 'guards.dart';
import 'helpers.dart';
import 'logger.dart';

/// Runs Flutter cmd
Future<int> flutterCmd(
  CacheVersion version,
  List<String> args,
) async {
  // Update environment variables
  final environment = updateFlutterEnvVariables(version.binPath);
  // Run command
  return await _runCmd(
    version.flutterExec,
    args: args,
    environment: environment,
  );
}

/// Exec commands with the Flutter env
Future<int> execCmd(
  String execPath,
  CacheVersion? version,
  List<String> args,
) async {
  // Update environment variables
  final binPath = version?.binPath ?? whichSync('flutter') ?? '';
  final dartBinPath = version?.dartBinPath ?? whichSync('dart') ?? '';

  var environment = updateFlutterEnvVariables(binPath);

  // Update environment with dart exec path
  environment = updateDartEnvVariables(dartBinPath, environment);

  // Run command
  return await _runCmd(
    execPath,
    args: args,
    environment: environment,
    checkIfExecutable: false,
  );
}

/// Runs dart cmd
Future<int> dartCmd(CacheVersion version, List<String> args) async {
  // Get exec path for dart
  final execPath = version.dartExec;
  // Update environment
  final environment = updateDartEnvVariables(version.dartBinPath);

  // Run command
  return await _runCmd(
    execPath,
    args: args,
    environment: environment,
  );
}

/// Runs dart from global version
Future<int> dartGlobalCmd(List<String> args) async {
  // Get exec path for dart
  final execPath = whichSync('dart') ?? '';

  // Run command
  return await _runCmd(
    execPath,
    args: args,
  );
}

/// Runs flutter from global version
Future<int> flutterGlobalCmd(List<String> args) async {
  final execPath = whichSync('flutter') ?? '';
  logger.trace(
    'FVM: Running Flutter SDK configured on environment PATH. $execPath',
  );

  // Run command
  return await _runCmd(
    execPath,
    args: args,
  );
}

Future<int> _runCmd(
  String execPath, {
  List<String> args = const [],
  Map<String, String>? environment,
  // Checks if path can be executed
  bool checkIfExecutable = true,
}) async {
  // Project again a non executable path

  if (checkIfExecutable) {
    await Guards.canExecute(execPath, args);
  }

  final processManager = ProcessManager();

  // Switch off line mode
  switchLineMode(false, args);
  final process = await processManager.spawn(
    execPath,
    args,
    environment: environment,
    workingDirectory: kWorkingDirectory.path,
  );

  if (!ConsoleController.isCli) {
    process.stdout.listen(consoleController.stdout.add);
    process.stderr.listen(consoleController.stderr.add);
  }

  exitCode = await process.exitCode;

  // Switch on line mode
  switchLineMode(true, args);

  return exitCode;
}
