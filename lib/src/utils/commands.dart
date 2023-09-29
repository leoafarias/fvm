import 'dart:io';

import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/run_command.dart';

import '../../fvm.dart';
import 'helpers.dart';

final _dartCmd = 'dart';
final _flutterCmd = 'flutter';

/// Runs Flutter cmd
Future<ProcessResult> runFlutter(
  List<String> args, {
  CacheFlutterVersion? version,
  bool? echoOutput,
}) async {
  if (version == null) {
    return _runCmd(_flutterCmd, args: args);
  }
  return _runOnVersion(
    _flutterCmd,
    version,
    args,
    echoOutput: echoOutput,
  );
}

/// Runs dart cmd
Future<ProcessResult> runDart(
  List<String> args, {
  CacheFlutterVersion? version,
  bool? echoOutput,
}) async {
  if (version == null) {
    return _runCmd(_dartCmd, args: args);
  }
  return _runOnVersion(
    _dartCmd,
    version,
    args,
    echoOutput: echoOutput,
  );
}

/// Runs dart cmd
Future<ProcessResult> _runOnVersion(
  String cmd,
  CacheFlutterVersion version,
  List<String> args, {
  bool? echoOutput,
}) async {
  final isFlutter = cmd == _flutterCmd;
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
    echoOutput: echoOutput,
  );
}

/// Exec commands with the Flutter env
Future<ProcessResult> execCmd(
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

Future<ProcessResult> _runCmd(
  String execPath, {
  List<String> args = const [],
  Map<String, String>? environment,
  bool? echoOutput,
}) async {
  echoOutput ??= true;
  return await runCommand(
    execPath,
    args: args,
    environment: environment,
    throwOnError: false,
    echoOutput: echoOutput,
  );
}
