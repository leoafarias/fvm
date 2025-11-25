import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

import '../utils/compare_semver.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';
import 'flutter_root_version_file.dart';
import 'flutter_version_model.dart';

part 'cache_flutter_version_model.mapper.dart';

/// Cache Version model
@MappableClass()
class CacheFlutterVersion extends FlutterVersion
    with CacheFlutterVersionMappable {
  /// Directory of the cache version
  final String directory;

  static final fromMap = CacheFlutterVersionMapper.fromMap;
  static final fromJson = CacheFlutterVersionMapper.fromJson;

  // Cached metadata to avoid repeated file reads
  FlutterRootVersionFile? _cachedMetadata;
  bool _metadataLoaded = false;

  @protected
  @MappableConstructor()
  CacheFlutterVersion(
    super.name, {
    super.releaseChannel,
    required super.type,
    super.fork,
    required this.directory,
  });

  CacheFlutterVersion.fromVersion(
    FlutterVersion version, {
    required this.directory,
  }) : super(
          version.name,
          releaseChannel: version.releaseChannel,
          type: version.type,
          fork: version.fork,
        );

  /// Attempts to get version from git tags (for pre-setup SDKs).
  ///
  /// Uses `git describe --tags --abbrev=0` to find the nearest tag.
  /// Returns null if git is unavailable or directory is not a git repo.
  String? _getVersionFromGit() {
    try {
      final result = Process.runSync(
        'git',
        ['describe', '--tags', '--abbrev=0'],
        workingDirectory: directory,
      );
      if (result.exitCode == 0) {
        final tag = (result.stdout as String).trim();

        return tag.isNotEmpty ? tag : null;
      }
    } catch (_) {
      // Git not available or not a git directory - return null
    }

    return null;
  }

  String get _dartSdkCache => join(binPath, 'cache', 'dart-sdk');

  /// Lazily loads and caches the JSON metadata file.
  FlutterRootVersionFile? get _rootMetadata {
    if (!_metadataLoaded) {
      _cachedMetadata =
          FlutterRootVersionFile.tryLoadFromRoot(Directory(directory));
      _metadataLoaded = true;
    }

    return _cachedMetadata;
  }

  /// The bin directory path for this cached version.
  @MappableField()
  String get binPath => join(directory, 'bin');

  /// Whether this version uses the old Dart path structure.
  ///
  /// Versions 1.17.5 and earlier stored the Dart SDK at `bin/cache/dart-sdk`.
  @MappableField()
  bool get hasOldBinPath {
    return compareSemver(assignVersionWeight(version), '1.17.5') <= 0;
  }

  /// The Dart bin directory path for this cached version.
  @MappableField()
  String get dartBinPath {
    // Before version 1.17.5, the Dart path was bin/cache/dart-sdk/bin
    if (hasOldBinPath) return join(_dartSdkCache, 'bin');

    return binPath;
  }

  /// The Dart executable path for this cached version.
  @MappableField()
  String get dartExec => join(dartBinPath, dartExecFileName);

  /// The Flutter executable path for this cached version.
  @MappableField()
  String get flutterExec => join(binPath, flutterExecFileName);

  /// The Flutter SDK version string, or `null` if it cannot be determined.
  ///
  /// Detection order:
  /// 1. JSON metadata file (`bin/cache/flutter.version.json`) - Flutter 3.13+
  /// 2. Legacy version file (`version`) - Flutter <3.33
  /// 3. Git tag via `git describe --tags` - for pre-setup SDKs
  @MappableField()
  String? get flutterSdkVersion {
    // 1. Prefer JSON metadata file (introduced in Flutter 3.13, required in 3.33+)
    final jsonVersion = _rootMetadata?.primaryVersion;
    if (jsonVersion != null) return jsonVersion;

    // 2. Fall back to legacy version file (Flutter <3.33)
    final versionFile = join(directory, 'version');
    final versionFromFile = versionFile.file.read()?.trim();
    if (versionFromFile != null) return versionFromFile;

    // 3. Final fallback: git describe for pre-setup SDKs
    return _getVersionFromGit();
  }

  @MappableField()
  String? get dartSdkVersion {
    // Prefer new JSON metadata file when present
    final jsonVersion = _rootMetadata?.dartSdkVersion?.trim();
    if (jsonVersion != null && jsonVersion.isNotEmpty) return jsonVersion;

    final versionFile = join(_dartSdkCache, 'version');

    return versionFile.file.read()?.trim();
  }

  /// Whether this cached version has not been set up.
  ///
  /// A version is set up once the Dart SDK cache has been downloaded.
  bool get isNotSetup => dartSdkVersion == null;

  /// Whether this cached version has been set up.
  @MappableField()
  bool get isSetup => dartSdkVersion != null;

  FlutterVersion toFlutterVersion() =>
      FlutterVersion(name, releaseChannel: releaseChannel, type: type);
}
