import 'dart:io';

import 'package:fvm/constants.dart';

import 'package:path/path.dart' as path;

/// Returns true it's a valid installed version
bool isVersionInstalled(String version) {
  return (getInstalledVersions()).contains(version);
}

/// Lists Installed Flutter SDK Version
//TODO replace this with getInstalledReleases
List<String> getInstalledVersions() {
  try {
    // Returns empty array if directory does not exist
    if (!kVersionsDir.existsSync()) {
      return [];
    }

    final versions = kVersionsDir.listSync().toList();

    var installedVersions = <String>[];
    for (var version in versions) {
      if (FileSystemEntity.typeSync(version.path) ==
          FileSystemEntityType.directory) {
        installedVersions.add(path.basename(version.path));
      }
    }

    installedVersions.sort();
    return installedVersions;
  } on Exception {
    throw Exception('Could not list installed versions');
  }
}
