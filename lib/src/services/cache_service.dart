import 'dart:io';
import '../../constants.dart';
import '../models/valid_version_model.dart';
import 'flutter_tools.dart';
import 'git_tools.dart';
import '../models/cache_version_model.dart';
import '../utils/helpers.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

class CacheService {
  static final cacheDir = kFvmCacheDir;

  static Future<CacheVersion> getByVersionName(String name) async {
    final versionDir = versionCacheDir(name);
    // Return null if version does not exist
    if (!await versionDir.exists()) return null;

    return CacheVersion(name);
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

  // Caches version
  static Future<CacheVersion> cacheVersion(ValidVersion validVersion) async {
    await GitTools.cloneVersion(validVersion.version);
    return isVersionCached(validVersion);
  }

// Checks if isInstalled, and cleans up if its not
  static Future<CacheVersion> isVersionCached(ValidVersion validVersion) async {
    final cacheVersion =
        await CacheService.getByVersionName(validVersion.version);
    // Return false if not cached
    if (cacheVersion == null) return null;

    // Check if version directory is from git
    if (await CacheService.verifyIntegrity(cacheVersion)) {
      print(
          '$validVersion exists but was not setup correctly. Doing cleanup...');
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

  /// Gets the global version
  static Future<CacheVersion> getGlobal() async {
    if (await kGlobalFlutterLink.exists()) {
      // Get directory name
      final version = basename(await kGlobalFlutterLink.target());
      // Make sure its a valid version
      final validVersion = await FlutterTools.inferVersion(version);
      // Verify version is cached
      return await CacheService.isVersionCached(validVersion);
    } else {
      return null;
    }
  }

  /// Checks if its global version
  static Future<bool> isGlobal(CacheVersion version) async {
    if (await kGlobalFlutterLink.exists()) {
      return await kGlobalFlutterLink.target() == version.dir.path;
    } else {
      return false;
    }
  }

  /// Checks if global version is configured correctly
  static Future<bool> isGlobalConfigured() async {
    /// Return false if link does not exist
    if (!await kGlobalFlutterLink.exists()) return false;
    return join(kGlobalFlutterPath, 'flutter') == await which('flutter');
  }
}
