import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import '../models/cache_version_model.dart';
import '../models/valid_version_model.dart';
import '../utils/helpers.dart';
import 'context.dart';
import 'flutter_tools.dart';
import 'git_tools.dart';

/// Service to interact with FVM Cache
class CacheService {
  CacheService._();

  /// Directory where local versions are cached

  /// Returns a [CacheVersion] from a [versionName]
  /// TODO: Remove directory check in favor of getAllVersions
  static Future<CacheVersion> getByVersionName(String versionName) async {
    final versionDir = versionCacheDir(versionName);
    // Return null if version does not exist
    if (!await versionDir.exists()) return null;

    return CacheVersion(versionName);
  }

  /// Lists Installed Flutter SDK Version
  static Future<List<CacheVersion>> getAllVersions() async {
    // Returns empty array if directory does not exist
    if (!await ctx.cacheDir.exists()) return [];

    final versions = await ctx.cacheDir.list().toList();

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
    return await gitDir.exists() && await flutterBin.exists();
  }

  /// Caches version a [validVersion] and returns [CacheVersion]
  static Future<CacheVersion> cacheVersion(ValidVersion validVersion) async {
    await GitTools.cloneVersion(validVersion.name);
    return isVersionCached(validVersion);
  }

  /// Gets Flutter SDK version from CacheVersion sync
  static String getSdkVersionSync(CacheVersion version) {
    final versionFile = File(join(version.dir.path, 'version'));
    if (versionFile.existsSync()) {
      return versionFile.readAsStringSync();
    } else {
      return null;
    }
  }

  /// Checks if a [validVersion] is cached correctly, and cleans up if its not
  static Future<CacheVersion> isVersionCached(ValidVersion validVersion) async {
    final cacheVersion = await CacheService.getByVersionName(validVersion.name);
    // Return false if not cached
    if (cacheVersion == null) return null;

    // Check if version directory is from git
    if (!await CacheService.verifyIntegrity(cacheVersion)) {
      print(
          '$validVersion exists but was not setup correctly. Doing cleanup...');
      await CacheService.remove(cacheVersion);
      return null;
    }
    return cacheVersion;
  }

  /// Sets a [CacheVersion] as global
  static Future<void> setGlobal(CacheVersion version) async {
    final versionDir = versionCacheDir(version.name);

    await createLink(ctx.globalCacheLink, versionDir);
  }

  /// Returns a global [CacheVersion] if exists
  static Future<CacheVersion> getGlobal() async {
    if (await ctx.globalCacheLink.exists()) {
      // Get directory name
      final version = basename(await ctx.globalCacheLink.target());
      // Make sure its a valid version
      final validVersion = await FlutterTools.inferValidVersion(version);
      // Verify version is cached
      return await CacheService.isVersionCached(validVersion);
    } else {
      return null;
    }
  }

  /// Checks if a cached [version] is configured as global
  static Future<bool> isGlobal(CacheVersion version) async {
    if (await ctx.globalCacheLink.exists()) {
      return await ctx.globalCacheLink.target() == version.dir.path;
    } else {
      return false;
    }
  }

  /// Returns a global [CacheVersion] if exists
  static String getGlobalVersionSync() {
    if (ctx.globalCacheLink.existsSync()) {
      // Get directory name
      return basename(ctx.globalCacheLink.targetSync());
    } else {
      return null;
    }
  }

  /// Checks if global version is configured correctly
  static Future<GlobalConfigured> isGlobalConfigured() async {
    final currentPath = await which('flutter');
    final binPath = await getParentDirPath(currentPath);

    /// Return false if link does not exist
    if (!await ctx.globalCacheLink.exists()) {
      return GlobalConfigured(
        isSetup: false,
        currentPath: binPath,
        correctPath: null,
      );
    }

    return GlobalConfigured(
      // Check if flutter path is the exec path
      isSetup: ctx.globalCacheBinPath == binPath,
      currentPath: binPath,
      // Path configuration should link into bin directory
      correctPath: ctx.globalCacheBinPath,
    );
  }
}

///Data returned from global configured
class GlobalConfigured {
  /// Is setup correctly
  final bool isSetup;

  /// Current path configured
  final String currentPath;

  /// Correct path to be configured
  final String correctPath;

  /// Constructor
  const GlobalConfigured({
    this.isSetup,
    this.currentPath,
    this.correctPath,
  });
}
