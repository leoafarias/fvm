import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// Gets SDK Version
Future<String> getFlutterSdkVersion(String version) async {
  final versionDirectory = Directory(path.join(kVersionsDir.path, version));
  if (!await versionDirectory.exists()) {
    throw Exception('Could not get version from SDK that is not installed');
  }

  final versionFile = File(path.join(versionDirectory.path, 'version'));
  if (await versionFile.exists()) {
    return await versionFile.readAsString();
  } else {
    return null;
  }
}

void setAsGlobalVersion(String version) {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  createLink(kDefaultFlutterLink, versionDir);

  FvmLogger.fine('The global Flutter version is now $version');
  FvmLogger.fine(
      'Make sure to add $kDefaultFlutterPath to your PATH environment variable');
}
