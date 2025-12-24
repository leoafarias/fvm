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

  static String _normalizeVersion(String value) {
    if (value.startsWith('v') || value.startsWith('V')) {
      return value.substring(1);
    }

    return value;
  }

  String? _relativeVersionNameFromCachePath(String targetPath) {
    final cacheRoot = path.normalize(context.versionsCachePath);
    final normalizedTarget = path.normalize(targetPath);
    if (!path.isWithin(cacheRoot, normalizedTarget)) {
      return null;
    }

    final relative = path.relative(normalizedTarget, from: cacheRoot);
    if (relative.isEmpty || relative == '.') {
      return null;
    }

    // Convert to POSIX-style path for consistent fork/version parsing
    return path.posix.joinAll(path.split(relative));
  }

  /// Verifies that cache is correct
  /// returns 'true' if cache is correct 'false' if its not
  Future<bool> _verifyIsExecutable(CacheFlutterVersion version) async {
    final binExists = File(version.flutterExec).existsSync();

    return binExists && await isExecutable(version.flutterExec);
  }

  // Verifies that the cache version name matches the flutter version
  bool _verifyVersionMatch(CacheFlutterVersion version) {
    // If it's a channel return true
    if (version.isChannel) return true;
    // If it's a git commit, return true (commit hash won't match SDK version)
    if (version.isUnknownRef) return true;
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

    // Checks if a directory is a Flutter SDK.
    //
    // Uses bin/flutter existence as the indicator since it's always present
    // in Flutter SDK directories (part of the git repository), regardless of
    // whether setup has been run or which Flutter version is installed.
    bool isFlutterSdkDirectory(Directory dir) {
      final flutterBin = File(path.join(dir.path, 'bin', 'flutter'));

      return flutterBin.existsSync();
    }

    // Process a directory that might be a version directory
    Future<void> processDirectory(Directory dir, {String? forkName}) async {
      if (isFlutterSdkDirectory(dir)) {
        try {
          final name = _relativeVersionNameFromCachePath(dir.path);
          if (name == null) return;
          final version = FlutterVersion.parse(name);

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
              final subDirName = path.basename(entry.path);
              // Skip hidden directories (starting with .)
              if (subDirName.startsWith('.')) continue;
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

    // Scan all top-level directories, skipping hidden directories
    final topLevelEntries = await versionsDir.list().toList();
    for (var entry in topLevelEntries) {
      if (entry.path.isDir()) {
        final dirName = path.basename(entry.path);
        // Skip hidden directories (starting with .)
        if (dirName.startsWith('.')) continue;
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

  Directory _safeCacheDirectory(List<String> segments) {
    final cacheRoot = path.normalize(context.versionsCachePath);
    final targetPath = path.normalize(path.joinAll([cacheRoot, ...segments]));

    if (!path.isWithin(cacheRoot, targetPath) && targetPath != cacheRoot) {
      throw AppException(
        'Invalid cache path computed outside of the cache directory.',
      );
    }

    return Directory(targetPath);
  }

  /// Gets the directory for a specified version
  ///
  /// For standard versions: versionsCachePath/version
  /// For fork versions: versionsCachePath/fork/version
  Directory getVersionCacheDir(FlutterVersion version) {
    if (version.fromFork) {
      // Fork-specific path: versionsCachePath/forkName/versionName
      return _safeCacheDirectory([version.fork!, version.version]);
    } // Standard path: versionsCachePath/version.name

    return _safeCacheDirectory([version.name]);
  }

  // For backward compatibility - used by existing string-based calls
  @Deprecated('Use getVersionCacheDir(FlutterVersion) instead')
  Directory getVersionCacheDirByName(String version) {
    return _safeCacheDirectory([version]);
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
    final version = getGlobalVersion();
    if (version == null) return null;
    // Make sure its a valid version
    try {
      final validVersion = FlutterVersion.parse(version);
      // Verify version is cached
      return getVersion(validVersion);
    } on FormatException catch (e) {
      logger.warn(
        'Global version "$version" could not be parsed: $e. '
        'The global symlink may be corrupted.',
      );
      return null;
    }
  }

  /// Checks if a cached [version] is configured as global
  bool isGlobal(CacheFlutterVersion version) {
    if (!_globalCacheLink.existsSync()) return false;

    try {
      return _globalCacheLink.targetSync() == version.directory;
    } on FileSystemException {
      return false;
    }
  }

  /// Returns a global version name if exists
  String? getGlobalVersion() {
    if (!_globalCacheLink.existsSync()) return null;

    String targetPath;
    try {
      targetPath = _globalCacheLink.targetSync();
    } on FileSystemException catch (e) {
      logger.warn('Failed to resolve global symlink: $e');
      return null;
    }
    final relative = _relativeVersionNameFromCachePath(targetPath);
    if (relative != null) {
      return relative;
    }

    logger.debug(
      'Global symlink target "$targetPath" could not be resolved relative '
      'to the cache directory. Fork information may not be preserved.',
    );

    return path.basename(path.normalize(targetPath));
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

  /// Determines if [configured] and [cached] versions should be considered
  /// matching.
  ///
  /// Matching rules:
  /// 1. Exact string match (after normalizing leading 'v'/'V' prefix)
  /// 2. If either has build metadata (+xxx), both must match exactly
  /// 3. If both have pre-release identifiers (-xxx), both must match exactly
  /// 4. If [configured] has pre-release but [cached] does not, match on
  ///    `major.minor.patch` (allows dev builds to match stable SDKs)
  /// 5. If [cached] has pre-release but [configured] does not, require exact match
  /// 6. For non-semver versions (e.g., git refs), catches [FormatException] and
  ///    falls back to normalized string equality with a warning logged
  ///
  /// This handles Flutter SDK naming where the cached SDK may strip pre-release
  /// suffixes from the configured version.
  @visibleForTesting
  bool versionsMatch(String configured, String cached) {
    if (configured == cached) return true;

    final normConfigured = _normalizeVersion(configured);
    final normCached = _normalizeVersion(cached);

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

      // Remaining case: configured has no pre-release but cached does;
      // require exact match (which will fail because of differing pre-release).
      return configVer == cachedVer;
    } on FormatException catch (e) {
      logger.warn(
        'Unable to parse versions as semantic versions: '
        'configured="$configured", cached="$cached". '
        'Falling back to string comparison. Error: $e',
      );

      return normConfigured == normCached;
    }
  }
}
