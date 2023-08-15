import 'dart:io';

import 'package:process_run/shell.dart';

import '../../constants.dart';
import '../../fvm.dart';
import 'guards.dart';
import 'helpers.dart';
import 'logger.dart';

/// Runs Flutter cmd
Future<int> runFlutter(
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
  List<String> args,
  CacheVersion? version,
) async {
  // Update environment variables
  // If execPath is not provided will get the path configured version
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
Future<int> runDart(CacheVersion version, List<String> args) async {
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
Future<int> runDartGlobal(List<String> args) async {
  // Get exec path for dart
  final execPath = whichSync('dart') ?? '';

  logger.trace(
    'fvm: Running using Dart/Flutter version configured in path.\n',
  );

  // Run command
  return await _runCmd(
    execPath,
    args: args,
  );
}

/// Runs flutter from global version
Future<int> runFlutterGlobal(List<String> args) {
  final execPath = whichSync('flutter') ?? '';
  logger.trace(
    'fvm: Running Flutter SDK configured on environment PATH. $execPath',
  );

  // Run command
  return _runCmd(
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

  final process = await Process.start(
    execPath,
    args,
    runInShell: true,
    environment: environment,
    workingDirectory: kWorkingDirectory.path,
    mode: ProcessStartMode.inheritStdio,
  );

  exitCode = await process.exitCode;

  return exitCode;
}
