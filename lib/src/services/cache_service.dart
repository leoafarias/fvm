import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/src/services/git_tools.dart';
import 'package:fvm/src/models/cache_version_model.dart';

import 'package:fvm/src/utils/helpers.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

class CacheService {
  static final cacheDir = kFvmCacheDir;

  static Future<CacheVersion> getByVersionName(String name) async {
    final versionDir = versionCacheDir(name);
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
  static Future<List<CacheVersion>> getAllVersions() async {
    // Returns empty array if directory does not exist
    if (!cacheDir.existsSync()) return [];

    final versions = await cacheDir.list().toList();

    final cacheVersions = <CacheVersion>[];

    for (var version in versions) {
      if (isDirectory(version.path)) {
        final name = basename(version.path);
        cacheVersions.add(await getByVersionName(name));
      }
    }

    cacheVersions.sort((a, b) => a.compareTo(b));

    return cacheVersions.reversed.toList();
  }

  /// Removes a Version of Flutter SDK
  static Future<void> remove(CacheVersion version) async {
    if (await version.dir.exists()) {
      await version.dir.delete(recursive: true);
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
    final versionDir = versionCacheDir(version);
    if (!await versionDir.exists()) {
      throw Exception('Could not get version from SDK that is not installed');
    }

    final versionFile = File(join(versionDir.path, 'version'));
    if (await versionFile.exists()) {
      return await versionFile.readAsString();
    } else {
      return null;
    }
  }

  // Caches version
  static Future<CacheVersion> cacheVersion(String version) async {
    await GitTools.cloneVersion(version);
    return isVersionCached(version);
  }

// Checks if isInstalled, and cleans up if its not
  static Future<CacheVersion> isVersionCached(String version) async {
    final cacheVersion = await CacheService.getByVersionName(version);
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
    final versionDir = Directory(join(kFvmCacheDir.path, version.name));
    await createLink(kGlobalFlutterLink, versionDir);
  }

  /// Checks if its global version
  static Future<bool> isGlobal(CacheVersion version) async {
    return await kGlobalFlutterLink.target() == version.dir.path;
  }

  /// Checks if its global version
  static bool isGlobalSync(CacheVersion version) {
    return kGlobalFlutterLink.targetSync() == version.dir.path;
  }

  /// Checks if global version is configured correctly
  static Future<bool> checkGlobalSetup() async {
    /// Return false if link does not exist
    if (!await kGlobalFlutterLink.exists()) return false;
    return kGlobalFlutterPath == await which('flutter');
  }
}
