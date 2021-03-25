import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/logger.dart';

import 'package:fvm/src/utils/process_manager.dart';

import 'package:io/io.dart';

class FlutterTools {
  /// Upgrades a cached channel
  static Future<void> upgradeChannel(CacheVersion version) async {
    if (version.isChannel) {
      await runFlutterCmd(version.name, ['upgrade']);
    } else {
      throw Exception('Can only upgrade Flutter Channels');
    }
  }

  /// Disables tracking for Flutter SDK
  static Future<void> disableTracking(String version) async {
    await runFlutterCmd(version, ['config', '--no-analytics']);
  }

  /// Returns true if it's a valid Flutter channel
  static bool isChannel(String channel) {
    return kFlutterChannels.contains(channel);
  }

  /// Tries to infer a correct flutter version number
  static Future<String> inferVersion(String version) async {
    assert(version != null);
    final releases = await fetchFlutterReleases();

    version = version.toLowerCase();

    // Return if its flutter channel
    if (isChannel(version) || releases.containsVersion(version)) {
      return version;
    }
    // Try prefixing the version
    final prefixedVersion = 'v$version';
    if (releases.containsVersion(prefixedVersion)) {
      return prefixedVersion;
    } else {
      /// Fallback if cannot verify version
      throw UsageException(
          '$version is not a valid Flutter channel or release', '');
    }
  }
}

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

  final environment = replaceFlutterPathEnv(version);
  return await _runFlutterOrDartCmd(execPath, args, environment);
}

/// Runs a process
Future<int> runDartCmd(
  String version,
  List<String> args,
) async {
  final execPath = getDartSdkExec(version);
  args ??= [];
  // Check if can execute path first
  if (!await isExecutable(execPath)) {
    throw UsageException('Flutter version $version is not installed', '');
  }

  final environment = replaceDartPathEnv(version);
  return await _runFlutterOrDartCmd(execPath, args, environment);
}

Future<int> _runFlutterOrDartCmd(
  String execPath,
  List<String> args,
  Map<String, String> environment,
) async {
  _switchLineMode(false, args);

  final process = await processManager.spawn(
    execPath,
    args,
    environment: environment,
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
