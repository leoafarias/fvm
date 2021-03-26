import 'package:console/console.dart';
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
  if (CacheService.isGlobal(version)) {
    printVersion = '$printVersion (global)';
  }
  FvmLogger.info(printVersion);
}

/// Allows you to pass a versions for selecction.
String versionChooser(List<CacheVersion> versions) {
  final versionsList = versions.map((version) => version.name).toList();

  var chooser = Chooser<String>(
    versionsList,
    message: 'Select a version: ',
  );

  final version = chooser.chooseSync();
  return version;
}
