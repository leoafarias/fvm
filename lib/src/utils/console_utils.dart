import 'dart:io';

import 'package:console/console.dart';

import '../../exceptions.dart';
import '../models/cache_version_model.dart';
import '../models/project_model.dart';
import '../services/cache_service.dart';
import 'logger.dart';

/// Displays notice for confirmation
Future<bool> confirm(String message, {bool defaultConfirmation = true}) async {
  final choices = defaultConfirmation ? 'Y/n' : 'y/N';
  final response = await readInput('$message ($choices): ');
  final lowercase = response.toLowerCase();

  if (response.isEmpty) {
    return defaultConfirmation;
  }

  if (lowercase == 'n') {
    return false;
  }

  if (lowercase == 'y') {
    return true;
  }

  return false;
}

/// Prints out versions on FVM and it's status
Future<void> printVersionStatus(CacheVersion version, Project project) async {
  var printVersion = version.name;

  if (project.pinnedVersion == version.name) {
    printVersion = '$printVersion ✓';
  }

  logger.info(printVersion);
}

/// Allows to select from cached sdks.
Future<String> cacheVersionSelector() async {
  final cacheVersions = await CacheService.getAllVersions();
  // Return message if no cached versions
  if (cacheVersions.isEmpty) {
    throw const FvmUsageException(
      'No versions installed. Please install'
      ' a version. "fvm install {version}". ',
    );
  }

  /// Ask which version to select

  final versionsList = cacheVersions.map((version) => version.name).toList();

  final choise = logger.chooseOne(
    'Select a veresion:',
    choices: versionsList,
  );

  return choise;
}

/// Select from project flavors
Future<String?> projectFlavorSelector(Project project) async {
  // Gets environment version
  final envs = project.config.flavors;

  final envList = envs.keys.toList();

  // Check if there are no environments configured
  if (envList.isEmpty) {
    return null;
  }

  logger.success('Project flavors configured for "${project.name}":\n');

  final choise = logger.chooseOne(
    'Select an environment',
    choices: envList,
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
