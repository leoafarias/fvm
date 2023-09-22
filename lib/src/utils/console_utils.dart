import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';

import '../../exceptions.dart';
import '../services/logger_service.dart';

Table createTable() {
  return Table()
    ..borderColor = ConsoleColor.blue
    ..borderType = BorderType.grid
    ..borderStyle = BorderStyle.square
    ..headerStyle = FontStyle.bold;
}

/// Allows to select from cached sdks.
Future<String> cacheVersionSelector(List<CacheFlutterVersion> versions) async {
  // Return message if no cached versions
  if (versions.isEmpty) {
    throw const AppException(
      'No versions installed. Please install'
      ' a version. "fvm install {version}". ',
    );
  }

  /// Ask which version to select

  final versionsList = versions.map((version) => version.name).toList();

  final choise = logger.select(
    'Select a version:',
    options: versionsList,
  );

  return choise;
}

/// Select from project flavors
Future<String?> projectFlavorSelector(Project project) async {
  // Gets environment version
  final envs = project.flavors;

  final envList = envs.keys.toList();

  // Check if there are no environments configured
  if (envList.isEmpty) {
    return null;
  }

  logger
    ..success('Project flavors configured for "${project.name}":')
    ..spacer;

  final choise = logger.select(
    'Select an environment',
    options: envList,
  );

  return choise;
}

/// Replicate Flutter cli behavior during run
/// Allows to add commands without ENTER after
// ignore: avoid_positional_boolean_parameters
void switchLineMode(bool active, List<String> args) {
  // Don't do anything if its not terminal
  // or if it's not run command

  if (args.isEmpty || args.first != 'run') {
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
    logger.detail(err.toString());
    return;
  }
}

Future<bool> isCommandAvailable(String command) async {
  try {
    final result = await Process.run(command, ['--version']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}
