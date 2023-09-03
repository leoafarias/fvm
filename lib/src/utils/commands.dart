import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/utils/process_manager.dart';

import '../../constants.dart';
import '../../fvm.dart';
import 'helpers.dart';
import 'logger.dart';

/// Runs Flutter cmd
Future<int> runFlutter(
  CacheVersion version,
  List<String> args,
) async {
  // Update environment variables
  final environment = updateEnvironmentVariables([
    version.binPath,
    version.dartBinPath,
  ], ctx.environment);
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
  var environment = ctx.environment;
  if (version != null) {
    environment = updateEnvironmentVariables([
      version.binPath,
      version.dartBinPath,
    ], ctx.environment);
  }

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
  final environment = updateEnvironmentVariables([
    version.binPath,
    version.binPath,
  ], ctx.environment);

  // Run command
  return await _runCmd(
    execPath,
    args: args,
    environment: environment,
  );
}

/// Runs dart from global version
Future<int> runDartGlobal(List<String> args) async {
  logger.detail(
    '$kPackageName: Running using Dart/Flutter version configured in path.\n',
  );

  // Run command
  return await _runCmd(
    'dart',
    args: args,
  );
}

/// Runs flutter from global version
Future<int> runFlutterGlobal(List<String> args) {
  logger.detail(
    '$kPackageName: Running Flutter SDK configured on environment PATH.\n',
  );

  // Run command
  return _runCmd(
    'flutter',
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
    if (!FvmProcessManager.canRun(execPath)) {
      throw FvmError('Cannot execute $execPath');
    }
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
