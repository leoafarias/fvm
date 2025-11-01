import 'dart:io';

import 'package:io/io.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

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
  const CacheService(super.context);

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
    final cached = version.flutterSdkVersion;
    if (cached == null) return true;

    return versionsMatch(version.version, cached);
  }

  Link get _globalCacheLink => Link(context.globalCacheLink);

  /// Returns a [CacheFlutterVersion] from a [version]
  CacheFlutterVersion? getVersion(FlutterVersion version) {
    final versionDir = getVersionCacheDir(version);
    // Return null if version does not exist
    if (!versionDir.existsSync()) return null;

    return CacheFlutterVersion.fromVersion(version, directory: versionDir.path);
  }

  /// Lists Installed Flutter SDK Version
  Future<List<CacheFlutterVersion>> getAllVersions() async {
    final versionsDir = Directory(context.versionsCachePath);
    // Returns empty array if directory does not exist
    if (!await versionsDir.exists()) return [];

    final cacheVersions = <CacheFlutterVersion>[];

    // Process a directory that might be a version directory
    Future<void> processDirectory(Directory dir, {String? forkName}) async {
      final versionFile = File(path.join(dir.path, 'version'));
      if (versionFile.existsSync()) {
        // This is a version directory
        final name = path.basename(dir.path);

        try {
          FlutterVersion version;
          if (forkName != null) {
            // This is a forked version
            version = FlutterVersion.parse('$forkName/$name');
          } else {
            // This is a regular version
            version = FlutterVersion.parse(name);
          }

          final cacheVersion = getVersion(version);
          if (cacheVersion != null) {
            cacheVersions.add(cacheVersion);
          }
        } catch (e) {
          // Skip if we can't parse as a version
        }
      } else {
        // This might be a fork directory containing version directories
        // Only check top-level directories without a fork name
        if (forkName == null) {
          final entries = await dir.list().toList();
          for (var entry in entries) {
            if (entry.path.isDir()) {
              // Check subdirectories with this directory as the fork
              await processDirectory(
                Directory(entry.path),
                forkName: path.basename(dir.path),
              );
            }
          }
        }
      }
    }

    // Scan all top-level directories
    final topLevelEntries = await versionsDir.list().toList();
    for (var entry in topLevelEntries) {
      if (entry.path.isDir()) {
        await processDirectory(Directory(entry.path));
      }
    }

    cacheVersions.sort((a, b) => a.compareTo(b));

    return cacheVersions.reversed.toList();
  }

  /// Removes a Version of Flutter SDK
  void remove(FlutterVersion version) {
    final versionDir = getVersionCacheDir(version);
    if (versionDir.existsSync()) versionDir.deleteSync(recursive: true);

    // If this is a fork version and the fork directory is now empty, clean it up
    if (version.fromFork) {
      final forkDir = Directory(
        path.join(context.versionsCachePath, version.fork!),
      );
      if (forkDir.existsSync()) {
        final entries = forkDir.listSync();
        if (entries.isEmpty) {
          forkDir.deleteSync(recursive: true);
        }
      }
    }
  }

  /// Gets the directory for a specified version
  ///
  /// For standard versions: versionsCachePath/version
  /// For fork versions: versionsCachePath/fork/version
  Directory getVersionCacheDir(FlutterVersion version) {
    if (version.fromFork) {
      // Fork-specific path: versionsCachePath/forkName/versionName
      return Directory(
        path.join(context.versionsCachePath, version.fork!, version.version),
      );
    } // Standard path (unchanged): versionsCachePath/versionName

    return Directory(path.join(context.versionsCachePath, version.name));
  }

  // For backward compatibility - used by existing string-based calls
  @Deprecated('Use getVersionCacheDir(FlutterVersion) instead')
  Directory getVersionCacheDirByName(String version) {
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
    _globalCacheLink.createLink(version.directory);
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
    FlutterVersion targetVersion = FlutterVersion.parse(sdkVersion);

    // If the original version is from a fork, maintain the fork information
    if (version.fromFork) {
      targetVersion = FlutterVersion.parse('${version.fork}/$sdkVersion');
    }

    final newDir = getVersionCacheDir(targetVersion);

    if (newDir.existsSync()) {
      newDir.deleteSync(recursive: true);
    }

    // Ensure parent directory exists for fork versions
    if (targetVersion.fromFork) {
      final forkDir = Directory(
        path.join(context.versionsCachePath, targetVersion.fork!),
      );
      if (!forkDir.existsSync()) {
        forkDir.createSync(recursive: true);
      }
    }

    if (versionDir.existsSync()) {
      versionDir.renameSync(newDir.path);
    }
  }
}

@visibleForTesting
String normalizeVersion(String value) {
  if (value.startsWith('v') || value.startsWith('V')) {
    return value.substring(1);
  }
  return value;
}

@visibleForTesting
bool versionsMatch(String configured, String cached) {
  if (configured == cached) return true;

  final normConfigured = normalizeVersion(configured);
  final normCached = normalizeVersion(cached);

  if (normConfigured == normCached) return true;

  try {
    final configVer = Version.parse(normConfigured);
    final cachedVer = Version.parse(normCached);

    if (configVer.build.isNotEmpty || cachedVer.build.isNotEmpty) {
      return configVer == cachedVer;
    }

    if (configVer.preRelease.isNotEmpty && cachedVer.preRelease.isNotEmpty) {
      return configVer == cachedVer;
    }

    if (configVer.preRelease.isNotEmpty && cachedVer.preRelease.isEmpty) {
      return configVer.major == cachedVer.major &&
          configVer.minor == cachedVer.minor &&
          configVer.patch == cachedVer.patch;
    }

    // All other cases require exact semantic equality.
    return configVer == cachedVer;
  } on FormatException {
    return normConfigured == normCached;
  }
}
