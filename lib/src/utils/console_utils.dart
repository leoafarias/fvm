import 'dart:io';

import 'package:console/console.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/logger.dart';

/// Displays notice for confirmation
Future<bool> confirm(String message) async {
  final response = await readInput('$message Y/n: ');
  // Return true unless 'n'
  return !response.contains('n');
}

/// Prints out versions on FVM and it's status
void printVersionStatus(CacheVersion version, FlutterApp project) {
  var printVersion = version.name;

  if (project != null && project.pinnedVersion == version.name) {
    printVersion = '$printVersion ${Icon.HEAVY_CHECKMARK}';
  }
  if (CacheService.isGlobalSync(version)) {
    printVersion = '$printVersion (global)';
  }
  FvmLogger.info(printVersion);
}

/// Allows you to pass a versions for selecction.
Future<String> cacheVersionSelector() async {
  final cacheVersions = await CacheService.getAllVersions();
  // Return message if no cached versions
  if (cacheVersions.isEmpty) {
    throw const FvmUsageException(
        'No versions installed. Please install a version. "fvm install <version>". ');
  }

  /// Ask which version to select

  final versionsList = cacheVersions.map((version) => version.name).toList();

  var chooser = Chooser<String>(
    versionsList,
    message: 'Select a version: ',
  );

  final version = chooser.chooseSync();
  return version;
}

// Replicate Flutter cli behavior during run
// Allows to add commands without ENTER after
void switchLineMode(bool active, List<String> args) {
  // Don't do anything if its not terminal
  // or if it's not run command
  // TODO: Check this for other commands like dart:migrate
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
