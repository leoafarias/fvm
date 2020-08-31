import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/pretty_print.dart';
import 'package:path/path.dart' as path;

/// Gets SDK Version
Future<String> getFlutterSdkVersion(String version) async {
  final versionDirectory = Directory(path.join(kVersionsDir.path, version));
  if (!await versionDirectory.exists()) {
    throw Exception('Could not get version from SDK that is not installed');
  }
  try {
    final versionFile = File(path.join(versionDirectory.path, 'version'));
    final semver = await versionFile.readAsString();
    return semver;
  } on Exception {
    // If version file does not exist return null for flutter version.
    // Means setup was completed yet
    return null;
  }
}

void setAsGlobalVersion(String version) {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  createLink(kDefaultFlutterLink, versionDir);

  PrettyPrint.success('The global Flutter version is now $version');
  PrettyPrint.success(
      'Make sure sure to add $kDefaultFlutterPath to your PATH environment variable');
}
