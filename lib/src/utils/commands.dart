import 'dart:io';

import '../../constants.dart';
import '../../fvm.dart';
import 'console_utils.dart';
import 'guards.dart';
import 'helpers.dart';
import 'logger.dart';
import 'process_manager.dart';
import 'package:io/io.dart';
import 'package:process_run/shell.dart';

/// Runs Flutter cmd
Future<int> flutterCmd(
  CacheVersion version,
  List<String> args,
) async {
  // Get exec path for flutter
  final execPath = version.flutterExec;

  FvmLogger.info('fvm: running version "$version"');
  FvmLogger.spacer();
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

/// Runs dart cmd
Future<int> flutterGlobalCmd(List<String> args) async {
  String execPath;
  // Try to get fvm global version
  final cacheVersion = await CacheService.getGlobal();
  // Get exec path for flutter
  if (cacheVersion != null) {
    execPath = cacheVersion.dartExec;
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

  await sharedStdIn.terminate();

  return exitCode;
}
