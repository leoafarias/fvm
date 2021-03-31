import 'dart:io';

import 'package:console/console.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import 'logger.dart';

/// Displays notice for confirmation
Future<bool> confirm(String message) async {
  final response = await readInput('$message Y/n: ');
  // Return true unless 'n'
  return !response.contains('n');
}

/// Prints out versions on FVM and it's status
Future<void> printVersionStatus(CacheVersion version, Project project) async {
  var printVersion = version.name;

  if (project != null && project.pinnedVersion == version.name) {
    printVersion = '$printVersion (active)';
  }
  if (await CacheService.isGlobal(version)) {
    printVersion = '$printVersion (global)';
  }
  FvmLogger.info(printVersion);
}

/// Allows to select from cached sdks.
Future<String> cacheVersionSelector() async {
  final cacheVersions = await CacheService.getAllVersions();
  // Return message if no cached versions
  if (cacheVersions.isEmpty) {
    throw const FvmUsageException(
        '''No versions installed. Please install a version. "fvm install <version>". ''');
  }

  /// Ask which version to select

  final versionsList = cacheVersions.map((version) => version.name).toList();

  // Better legibility
  FvmLogger.spacer();

  final chooser = Chooser<String>(
    versionsList,
    message: '\nSelect a version:',
  );

  final version = chooser.chooseSync();
  return version;
}

/// Select from project environments
Future<String> projectEnvSeletor() async {
  final project = await FlutterAppService.findAncestor();

  // If project use check that is Flutter project
  if (project == null) {
    throw const FvmUsageException(
      'Cannot find any FVM config.',
    );
  }

  // Gets environment version
  final envs = project.config.environment;

  final envList = envs.keys.toList();

  // Check if there are no environments configured
  if (envList.isEmpty) {
    throw const FvmUsageException(
      'Could not find any environment configuration.',
    );
  }
  FvmLogger.spacer();
  FvmLogger.fine('Project Environments confopigured for "${project.name}":');
  FvmLogger.spacer();

  final chooser = Chooser<String>(
    envList,
    message: '\nSelect an environment: ',
  );

  final version = chooser.chooseSync();
  return version;
}

/// Replicate Flutter cli behavior during run
/// Allows to add commands without ENTER after
// ignore: avoid_positional_boolean_parameters
void switchLineMode(bool active, List<String> args) {
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
