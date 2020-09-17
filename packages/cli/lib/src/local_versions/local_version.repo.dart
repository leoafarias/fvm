import 'dart:io';

import 'package:fvm/constants.dart';

import 'package:fvm/src/local_versions/local_version.model.dart';
import 'package:fvm/src/local_versions/local_versions_tools.dart';

import 'package:fvm/src/utils/helpers.dart';

import 'package:path/path.dart';

class LocalVersionRepo {
  static Future<LocalVersion> getByName(String name) async {
    final versionDir = Directory(join(kVersionsDir.path, name));
    final sdkVersion = await getFlutterSdkVersion(name);

    // Return null if version does not exist
    if (await versionDir.exists()) {
      return null;
    }

    return LocalVersion(
      name: name,
      sdkVersion: sdkVersion,
    );
  }

  /// Lists Installed Flutter SDK Version
  static Future<List<LocalVersion>> getAll() async {
    try {
      // Returns empty array if directory does not exist
      if (!kVersionsDir.existsSync()) {
        return [];
      }

      final versions = await kVersionsDir.list().toList();

      var installedVersions = <LocalVersion>[];
      for (var version in versions) {
        if (isDirectory(version.path)) {
          final name = basename(version.path);
          final sdkVersion = await getFlutterSdkVersion(name);

          installedVersions.add(
            LocalVersion(
              name: name,
              sdkVersion: sdkVersion,
            ),
          );
        }
      }

      installedVersions.sort((a, b) => a.compareTo(b));
      return installedVersions.reversed.toList();
    } on Exception {
      rethrow;
    }
  }

  /// Removes a Version of Flutter SDK
  // TODO: Change this to LocalVersion model
  static Future<void> remove(String version) async {
    final versionDir = Directory(join(kVersionsDir.path, version));
    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  // Checks if isInstalled, and cleans up if its not
  static Future<bool> isInstalled(String version) async {
    final versionDir = Directory(join(kVersionsDir.path, version));
    final gitDir = Directory(join(versionDir.path, '.github'));
    final flutterBin = Directory(join(versionDir.path, 'bin'));
    // Check if version directory exists
    if (!await versionDir.exists()) return false;

    // Check if version directory is from git
    if (!await gitDir.exists() || !await flutterBin.exists()) {
      print('$version exists but was not setup correctly. Doing cleanup...');
      await remove(version);
      return false;
    }
    return true;
  }
}
