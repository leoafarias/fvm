import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/src/models/cache_version_model.dart';

import 'package:fvm/src/utils/helpers.dart';
import 'package:path/path.dart';

class CacheService {
  static Future<CacheVersion> getByName(String name) async {
    final versionDir = Directory(join(kVersionsDir.path, name));
    // Return null if version does not exist
    if (!await versionDir.exists()) return null;

    final sdkVersion = await getFlutterSdkVersion(name);

    return CacheVersion(
      name: name,
      sdkVersion: sdkVersion,
      dir: versionDir,
    );
  }

  /// Lists Installed Flutter SDK Version
  static Future<List<CacheVersion>> getAll() async {
    // Returns empty array if directory does not exist
    if (!kVersionsDir.existsSync()) return [];

    final versions = await kVersionsDir.list().toList();

    final cacheVersions = <CacheVersion>[];

    for (var version in versions) {
      if (isDirectory(version.path)) {
        final name = basename(version.path);
        cacheVersions.add(await getByName(name));
      }
    }

    cacheVersions.sort((a, b) => a.compareTo(b));

    return cacheVersions.reversed.toList();
  }

  /// Removes a Version of Flutter SDK
  static Future<void> remove(CacheVersion version) async {
    final versionDir = Directory(join(kVersionsDir.path, version.name));
    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  /// Verifies that cache is correct
  /// returns 'true' if cache is correct 'false' if its not
  static Future<bool> verifyIntegrity(CacheVersion version) async {
    final gitDir = Directory(join(version.dir.path, '.github'));
    final flutterBin = Directory(join(version.dir.path, 'bin'));
    return !await gitDir.exists() || !await flutterBin.exists();
  }

  /// Gets Flutter SDK from CacheVersion
  static Future<String> getFlutterSdkVersion(String version) async {
    final versionDirectory = Directory(join(kVersionsDir.path, version));
    if (!await versionDirectory.exists()) {
      throw Exception('Could not get version from SDK that is not installed');
    }

    final versionFile = File(join(versionDirectory.path, 'version'));
    if (await versionFile.exists()) {
      return await versionFile.readAsString();
    } else {
      return null;
    }
  }

// Checks if isInstalled, and cleans up if its not
  static Future<CacheVersion> isVersionCached(String version) async {
    final cacheVersion = await CacheService.getByName(version);
    // Return false if not cached
    if (cacheVersion == null) return null;

    // Check if version directory is from git
    if (await CacheService.verifyIntegrity(cacheVersion)) {
      print('$version exists but was not setup correctly. Doing cleanup...');
      await CacheService.remove(cacheVersion);
      return null;
    }
    return cacheVersion;
  }

  /// Sets a CacheVersion as global
  static Future<void> setGlobal(CacheVersion version) async {
    final versionDir = Directory(join(kVersionsDir.path, version.name));
    await createLink(kDefaultFlutterLink, versionDir);
  }

  /// Checks if its global version
  static bool isGlobal(CacheVersion version) {
    if (!kDefaultFlutterLink.existsSync()) return false;

    final globalVersion = basename(kDefaultFlutterLink.targetSync());

    return globalVersion == version.name;
  }
}
