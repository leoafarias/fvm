import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/helpers.dart';
import 'context.dart';
import 'git_tools.dart';

enum CacheIntegrity {
  valid,
  invalid,
  versionMismatch,
}

/// Service to interact with FVM Cache
class CacheService {
  CacheService._();

  /// Directory where local versions are cached

  /// Returns a [CacheFlutterVersion] from a [version]
  static CacheFlutterVersion? getVersion(
    FlutterVersion version,
  ) {
    final versionDir = getVersionCacheDir(version.name);
    // Return null if version does not exist
    if (!versionDir.existsSync()) return null;
    return CacheFlutterVersion(
      version,
      directory: versionDir.path,
    );
  }

  /// Lists Installed Flutter SDK Version
  static Future<List<CacheFlutterVersion>> getAllVersions() async {
    // Returns empty array if directory does not exist
    if (!await ctx.fvmVersionsDir.exists()) return [];

    final versions = await ctx.fvmVersionsDir.list().toList();

    final cacheVersions = <CacheFlutterVersion>[];

    for (var version in versions) {
      if (isDirectory(version.path)) {
        final name = basename(version.path);
        final cacheVersion = getVersion(FlutterVersion(name));

        if (cacheVersion != null) {
          cacheVersions.add(cacheVersion);
        }
      }
    }

    cacheVersions.sort((a, b) => a.compareTo(b));

    return cacheVersions.reversed.toList();
  }

  /// Removes a Version of Flutter SDK
  static void remove(FlutterVersion version) {
    final versionDir = getVersionCacheDir(version.name);
    if (versionDir.existsSync()) versionDir.deleteSync(recursive: true);
  }

  /// Verifies that cache is correct
  /// returns 'true' if cache is correct 'false' if its not
  static Future<bool> _verifyIsExecutable(CacheFlutterVersion version) async {
    final binExists = File(version.flutterExec).existsSync();

    return binExists && await isExecutable(version.flutterExec);
  }

  // Verifies that the cache version name matches the flutter version
  static Future<bool> _verifyVersionMatch(CacheFlutterVersion version) async {
    // If its a channel return true
    if (version.isChannel) return true;
    // If sdkVersion is not available return true
    if (version.sdkVersion == null) return true;
    return version.sdkVersion == version.name;
  }

  /// Caches version a [validVersion] and returns [CacheFlutterVersion]
  static Future<void> cacheVersion(FlutterVersion validVersion) async {
    await GitTools.cloneVersion(validVersion);
  }

  static Directory getVersionCacheDir(String version) {
    return Directory(join(ctx.fvmVersionsDir.path, version));
  }

  /// Sets a [CacheFlutterVersion] as global
  static void setGlobal(CacheFlutterVersion version) {
    createLink(ctx.globalCacheLink, Directory(version.directory));
  }

  // Verifies that cache can be executed and matches version
  static Future<CacheIntegrity> verifyCacheIntegrity(
      CacheFlutterVersion version) async {
    final isExecutable = await _verifyIsExecutable(version);
    final versionsMatch = await _verifyVersionMatch(version);

    if (!isExecutable) return CacheIntegrity.invalid;
    if (!versionsMatch) return CacheIntegrity.versionMismatch;

    return CacheIntegrity.valid;
  }

  /// Moves a [CacheFlutterVersion] to the cache of [sdkVersion]
  static void moveToSdkVersionDiretory(CacheFlutterVersion version) {
    final sdkVersion = version.sdkVersion;

    if (sdkVersion == null) {
      throw FvmError(
        'Cannot move to SDK version directory without a valid version',
      );
    }
    final versionDir = Directory(version.directory);
    final newDir = CacheService.getVersionCacheDir(sdkVersion);

    if (newDir.existsSync()) {
      newDir.deleteSync(recursive: true);
    }

    if (versionDir.existsSync()) {
      versionDir.renameSync(newDir.path);
    }
  }

  /// Returns a global [CacheFlutterVersion] if exists
  static Future<CacheFlutterVersion?> getGlobal() async {
    if (await ctx.globalCacheLink.exists()) {
      // Get directory name
      final version = basename(await ctx.globalCacheLink.target());
      // Make sure its a valid version
      final validVersion = FlutterVersion(version);
      // Verify version is cached
      return CacheService.getVersion(validVersion);
    } else {
      return null;
    }
  }

  /// Checks if a cached [version] is configured as global
  static Future<bool> isGlobal(CacheFlutterVersion version) async {
    if (await ctx.globalCacheLink.exists()) {
      return await ctx.globalCacheLink.target() == version.directory;
    } else {
      return false;
    }
  }

  /// Returns a global version name if exists
  static String? getGlobalVersionSync() {
    if (ctx.globalCacheLink.existsSync()) {
      // Get directory name
      return basename(ctx.globalCacheLink.targetSync());
    } else {
      return null;
    }
  }
}
