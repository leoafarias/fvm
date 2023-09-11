import 'dart:io';

import 'package:fvm/src/utils/context.dart';

import '../../fvm.dart';
import 'helpers.dart';

/// Runs Flutter cmd
Future<int> runFlutter(
  CacheFlutterVersion version,
  List<String> args, {
  bool? showOutput,
}) async {
  // Run command
  return _runOnVersion(
    SdkType.flutter,
    version,
    args,
    showOutput: showOutput,
  );
}

/// Runs flutter from global version
Future<int> runFlutterGlobal(List<String> args) {
  return _runCmd('flutter', args: args);
}

/// Runs dart cmd
Future<int> runDart(
  CacheFlutterVersion version,
  List<String> args, {
  bool? showOutput,
}) async {
  return _runOnVersion(
    SdkType.dart,
    version,
    args,
    showOutput: showOutput,
  );
}

/// Runs dart from global version
Future<int> runDartGlobal(List<String> args) async {
  // Run command
  return await _runCmd('dart', args: args);
}

enum SdkType {
  dart,
  flutter,
}

/// Runs dart cmd
Future<int> _runOnVersion(
  SdkType sdk,
  CacheFlutterVersion version,
  List<String> args, {
  bool? showOutput,
}) async {
  final isFlutter = sdk == SdkType.flutter;
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
    showOutput: showOutput,
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

  ///Show output defaults to true
  bool? showOutput,
}) async {
  showOutput ??= true;
  final process = await Process.start(
    execPath,
    args,
    runInShell: true,
    environment: environment,
    workingDirectory: ctx.workingDirectory,
    mode: showOutput ? ProcessStartMode.inheritStdio : ProcessStartMode.normal,
  );

  exitCode = await process.exitCode;

  return exitCode;
}
