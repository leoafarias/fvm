import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as path;

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';
import 'base_service.dart';

enum CacheIntegrity {
  valid,
  invalid,
  versionMismatch;

  bool get notValid => !isValid;

  bool get isValid => this == valid;
}

/// Service to interact with FVM Cache
class CacheService extends ContextualService {
  CacheService(super.context);

  /// Verifies that cache is correct
  /// returns 'true' if cache is correct 'false' if its not
  Future<bool> _verifyIsExecutable(CacheFlutterVersion version) async {
    final binExists = File(version.flutterExec).existsSync();

    return binExists && await isExecutable(version.flutterExec);
  }

  // Verifies that the cache version name matches the flutter version
  bool _verifyVersionMatch(CacheFlutterVersion version) {
    // If its a channel return true
    if (version.isChannel) return true;
    // If sdkVersion is not available return true
    if (version.flutterSdkVersion == null) return true;

    return version.flutterSdkVersion == version.version;
  }

  Link get _globalCacheLink => Link(context.globalCacheLink);

  /// Returns a [CacheFlutterVersion] from a [version]
  CacheFlutterVersion? getVersion(FlutterVersion version) {
    final versionDir = getVersionCacheDir(version.name);
    // Return null if version does not exist
    if (!versionDir.existsSync()) return null;

    return CacheFlutterVersion(version, directory: versionDir.path);
  }

  /// Lists Installed Flutter SDK Version
  Future<List<CacheFlutterVersion>> getAllVersions() async {
    final versionsDir = Directory(context.versionsCachePath);
    // Returns empty array if directory does not exist
    if (!await versionsDir.exists()) return [];

    final versions = await versionsDir.list().toList();

    final cacheVersions = <CacheFlutterVersion>[];

    for (var version in versions) {
      if (version.path.isDir()) {
        final name = path.basename(version.path);
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

  Directory getVersionCacheDir(String version) {
    return Directory(path.join(context.versionsCachePath, version));
  }

  // Verifies that cache can be executed and matches version
  Future<CacheIntegrity> verifyCacheIntegrity(
    CacheFlutterVersion version,
  ) async {
    final isExecutable = await _verifyIsExecutable(version);
    final versionsMatch = _verifyVersionMatch(version);

    if (!isExecutable) return CacheIntegrity.invalid;
    if (!versionsMatch) return CacheIntegrity.versionMismatch;

    return CacheIntegrity.valid;
  }

  /// Sets a [CacheFlutterVersion] as global
  void setGlobal(CacheFlutterVersion version) {
    context.globalCacheLink.link.createLink(version.directory);
  }

  /// Unlinks global version
  void unlinkGlobal() {
    if (_globalCacheLink.existsSync()) {
      _globalCacheLink.deleteSync();
    }
  }

  /// Returns a global [CacheFlutterVersion] if exists
  CacheFlutterVersion? getGlobal() {
    if (!_globalCacheLink.existsSync()) return null;
    // Get directory name
    final version = path.basename(_globalCacheLink.targetSync());
    // Make sure its a valid version
    final validVersion = FlutterVersion.parse(version);

    // Verify version is cached
    return getVersion(validVersion);
  }

  /// Checks if a cached [version] is configured as global
  bool isGlobal(CacheFlutterVersion version) {
    if (!_globalCacheLink.existsSync()) return false;

    return _globalCacheLink.targetSync() == version.directory;
  }

  /// Returns a global version name if exists
  String? getGlobalVersion() {
    if (!_globalCacheLink.existsSync()) return null;

    // Get directory name
    return path.basename(_globalCacheLink.targetSync());
  }

  /// Moves a [CacheFlutterVersion] to the cache of [sdkVersion]
  void moveToSdkVersionDirectory(CacheFlutterVersion version) {
    final sdkVersion = version.flutterSdkVersion;

    if (sdkVersion == null) {
      throw AppException(
        'Cannot move to SDK version directory without a valid version',
      );
    }
    final versionDir = Directory(version.directory);
    final newDir = getVersionCacheDir(sdkVersion);

    if (newDir.existsSync()) {
      newDir.deleteSync(recursive: true);
    }

    if (versionDir.existsSync()) {
      versionDir.renameSync(newDir.path);
    }
  }
}
