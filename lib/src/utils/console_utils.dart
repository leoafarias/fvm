import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';

import '../../exceptions.dart';
import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../services/cache_service.dart';
import 'logger.dart';

Table createTable() {
  return Table()
    ..borderColor = ConsoleColor.blue
    ..borderType = BorderType.grid
    ..borderStyle = BorderStyle.square
    ..headerStyle = FontStyle.bold;
}

Future<void> printVersionStatus(
  CacheFlutterVersion version,
) async {
  final releases = await FlutterReleasesClient.get();
  var printVersion = version.name;

  final release = releases.getReleaseFromVersion(version.name);

  if (release != null) {
    final table = Table()
      ..insertColumn(header: 'Information', alignment: TextAlignment.left)
      ..insertColumn(header: 'Value', alignment: TextAlignment.left)
      ..insertRows([
        ['Channel', release.channel],
        ['Version', release.version],
        ['Release Date', release.releaseDate],
        ['Archive', release.archive],
        ['Sha256', release.sha256],
        ['Dart SDK Arch', release.dartSdkArch ?? 'N/A'],
        ['Dart SDK Version', release.dartSdkVersion ?? 'N/A'],
      ])
      ..borderStyle = BorderStyle.square
      ..borderColor = ConsoleColor.blue
      ..borderType = BorderType.vertical
      ..headerStyle = FontStyle.bold;

    print(table);
  }

  if (CacheService.instance.isGlobal(version)) {
    printVersion = '$printVersion (global)';
  }

  print('Flutter Version: $printVersion');
}

/// Allows to select from cached sdks.
Future<String> cacheVersionSelector() async {
  final cacheVersions = await CacheService.instance.getAllVersions();
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
    'Select a version:',
    choices: versionsList,
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
