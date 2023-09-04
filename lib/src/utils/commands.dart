import 'dart:io';

import 'package:fvm/src/services/context.dart';

import '../../constants.dart';
import '../../fvm.dart';
import 'helpers.dart';

/// Runs Flutter cmd
Future<int> runFlutter(
  CacheFlutterVersion version,
  List<String> args,
) async {
  // Run command
  return _runOnVersion(
    CmdType.flutter,
    version,
    args,
  );
}

/// Runs flutter from global version
Future<int> runFlutterGlobal(List<String> args) {
  return _runCmd('flutter', args: args);
}

/// Runs dart cmd
Future<int> runDart(CacheFlutterVersion version, List<String> args) async {
  return _runOnVersion(
    CmdType.dart,
    version,
    args,
  );
}

/// Runs dart from global version
Future<int> runDartGlobal(List<String> args) async {
  // Run command
  return await _runCmd('dart', args: args);
}

enum CmdType {
  dart,
  flutter,
}

/// Runs dart cmd
Future<int> _runOnVersion(
  CmdType cmdType,
  CacheFlutterVersion version,
  List<String> args,
) async {
  final isFlutter = cmdType == CmdType.flutter;
  // Get exec path for dart
  final execPath = isFlutter ? version.flutterExec : version.dartExec;

  // Update environment
  final environment = updateEnvironmentVariables([
    version.binPath,
    version.dartBinPath,
  ], ctx.environment);

  // Run command
  return await _runCmd(
    execPath,
    args: args,
    environment: environment,
  );
}

/// Exec commands with the Flutter env
Future<int> execCmd(
  String execPath,
  List<String> args,
  CacheFlutterVersion? version,
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
  );
}

Future<int> _runCmd(
  String execPath, {
  List<String> args = const [],
  Map<String, String>? environment,
}) async {
  // Project again a non executable path

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
