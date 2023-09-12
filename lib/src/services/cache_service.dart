import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/io_utils.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/context.dart';

enum CacheIntegrity {
  valid,
  invalid,
  versionMismatch,
}

/// Service to interact with FVM Cache
class CacheService {
  CacheService();
  static CacheService get instance => ctx.get<CacheService>();

  /// Directory where local versions are cached

  /// Returns a [CacheFlutterVersion] from a [version]
  CacheFlutterVersion? getVersion(
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
  Future<List<CacheFlutterVersion>> getAllVersions() async {
    final versionsDir = Directory(ctx.fvmVersionsDir);
    // Returns empty array if directory does not exist
    if (!await versionsDir.exists()) return [];

    final versions = await versionsDir.list().toList();

    final cacheVersions = <CacheFlutterVersion>[];

    for (var version in versions) {
      if (isDirectory(version.path)) {
        final name = basename(version.path);
        final cacheVersion = getVersion(FlutterVersion.parse(name));

        if (cacheVersion != null) {
          cacheVersions.add(cacheVersion);
        }
      }
    }

    cacheVersions.sort((a, b) => a.compareTo(b));

    return cacheVersions.reversed.toList();
  }

  /// Removes a Version of Flutter SDK
  void remove(FlutterVersion version) {
    final versionDir = getVersionCacheDir(version.name);
    if (versionDir.existsSync()) versionDir.deleteSync(recursive: true);
  }

  /// Verifies that cache is correct
  /// returns 'true' if cache is correct 'false' if its not
  Future<bool> _verifyIsExecutable(CacheFlutterVersion version) async {
    final binExists = File(version.flutterExec).existsSync();

    return binExists && await isExecutable(version.flutterExec);
  }

  // Verifies that the cache version name matches the flutter version
  Future<bool> _verifyVersionMatch(CacheFlutterVersion version) async {
    // If its a channel return true
    if (version.isChannel) return true;
    // If sdkVersion is not available return true
    if (version.flutterSdkVersion == null) return true;
    return version.flutterSdkVersion == version.version;
  }

  /// Caches version a [validVersion] and returns [CacheFlutterVersion]
  Future<void> cacheVersion(FlutterVersion validVersion) async {
    await FlutterTools.instance.install(validVersion);
  }

  Directory getVersionCacheDir(String version) {
    return Directory(join(ctx.fvmVersionsDir, version));
  }

  /// Sets a [CacheFlutterVersion] as global
  void setGlobal(CacheFlutterVersion version) {
    createLink(ctx.globalCacheLink, Directory(version.directory));
  }

  // Verifies that cache can be executed and matches version
  Future<CacheIntegrity> verifyCacheIntegrity(
      CacheFlutterVersion version) async {
    final isExecutable = await _verifyIsExecutable(version);
    final versionsMatch = await _verifyVersionMatch(version);

    if (!isExecutable) return CacheIntegrity.invalid;
    if (!versionsMatch) return CacheIntegrity.versionMismatch;

    return CacheIntegrity.valid;
  }

  /// Moves a [CacheFlutterVersion] to the cache of [sdkVersion]
  void moveToSdkVersionDiretory(CacheFlutterVersion version) {
    final sdkVersion = version.flutterSdkVersion;

    if (sdkVersion == null) {
      throw AppException(
        'Cannot move to SDK version directory without a valid version',
      );
    }
    final versionDir = Directory(version.directory);
    final newDir = CacheService.instance.getVersionCacheDir(sdkVersion);

    if (newDir.existsSync()) {
      newDir.deleteSync(recursive: true);
    }

    if (versionDir.existsSync()) {
      versionDir.renameSync(newDir.path);
    }
  }

  /// Returns a global [CacheFlutterVersion] if exists
  CacheFlutterVersion? getGlobal() {
    if (ctx.globalCacheLink.existsSync()) {
      // Get directory name
      final version = basename(ctx.globalCacheLink.targetSync());
      // Make sure its a valid version
      final validVersion = FlutterVersion.parse(version);
      // Verify version is cached
      return CacheService.instance.getVersion(validVersion);
    } else {
      return null;
    }
  }

  /// Checks if a cached [version] is configured as global
  bool isGlobal(CacheFlutterVersion version) {
    if (ctx.globalCacheLink.existsSync()) {
      return ctx.globalCacheLink.targetSync() == version.directory;
    } else {
      return false;
    }
  }

  /// Returns a global version name if exists
  String? getGlobalVersionSync() {
    if (ctx.globalCacheLink.existsSync()) {
      // Get directory name
      return basename(ctx.globalCacheLink.targetSync());
    } else {
      return null;
    }
  }
}
