import 'dart:io';

import 'package:process_run/shell.dart';

import '../../constants.dart';
import '../../fvm.dart';
import '../services/cache_service.dart';
import 'console_utils.dart';
import 'guards.dart';
import 'helpers.dart';
import 'logger.dart';
import 'process_manager.dart';

/// Runs Flutter cmd
Future<int> flutterCmd(
  CacheVersion version,
  List<String> args,
) async {
  // Get exec path for flutter
  final execPath = version.flutterExec;

  // Update environment variables
  final environment = updateFlutterEnvVariables(execPath);
  // Run command
  return await _runCmd(
    execPath,
    args: args,
    environment: environment,
  );
}

/// Runs dart cmd
Future<int> dartCmd(CacheVersion version, List<String> args) async {
  // Get exec path for dart
  final execPath = version.dartExec;
  // Update environment
  final environment = updateDartEnvVariables(execPath);

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
  final execPath = whichSync('dart');

  // Run command
  return await _runCmd(
    execPath,
    args: args,
  );
}

/// Runs flutter from global version
Future<int> flutterGlobalCmd(List<String> args) async {
  String execPath;
  // Try to get fvm global version
  final cacheVersion = await CacheService.getGlobal();
  // Get exec path for flutter
  if (cacheVersion != null) {
    execPath = cacheVersion.flutterExec;
    FvmLogger.info(
      'FVM: Running global configured version "${cacheVersion.name}"',
    );
  } else {
    execPath = whichSync('flutter');
    FvmLogger.info(
      'FVM: Running Flutter SDK configured on environment PATH. $execPath',
    );
  }
  FvmLogger.spacer();

  // Run command
  return await _runCmd(
    execPath,
    args: args,
  );
}

/// Runs a simple Flutter cmd
Future<String> flutterCmdSimple(
  List<String> args,
) async {
  // Get exec path for flutter
  final execPath = whichSync('flutter');
  final result = await Process.run(execPath, args);
  return result.stdout as String;
}

Future<int> _runCmd(
  String execPath, {
  List<String> args = const [],
  Map<String, String> environment,
}) async {
  // Project again a non executable path
  await Guards.canExecute(execPath);

  // Switch off line mode
  switchLineMode(false, args);

  final process = await processManager.spawn(
    execPath,
    args,
    environment: environment,
    workingDirectory: kWorkingDirectory.path,
  );

  exitCode = await process.exitCode;

  // Switch on line mode
  switchLineMode(true, args);

  if (ConsoleController.isCli) {
    await sharedStdIn.terminate();
  }

  return exitCode;
}
