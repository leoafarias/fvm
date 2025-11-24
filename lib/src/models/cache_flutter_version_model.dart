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

  /// Get version bin path
  @MappableField()
  String get binPath => join(directory, 'bin');

  /// Has old dart path structure
  // Last version with the old dart path structure
  @MappableField()
  bool get hasOldBinPath {
    return compareSemver(assignVersionWeight(version), '1.17.5') <= 0;
  }

  /// Returns dart exec file for cache version
  @MappableField()
  String get dartBinPath {
    /// Get old bin path
    /// Before version 1.17.5 dart path was bin/cache/dart-sdk/bin
    if (hasOldBinPath) return join(_dartSdkCache, 'bin');

    return binPath;
  }

  /// Returns dart exec file for cache version
  @MappableField()
  String get dartExec => join(dartBinPath, dartExecFileName);

  /// Returns flutter exec file for cache version
  @MappableField()
  String get flutterExec => join(binPath, flutterExecFileName);

  /// Gets Flutter SDK version from CacheVersion sync.
  ///
  /// Checks JSON metadata file first (available since Flutter 3.13), then falls
  /// back to legacy version file. Returns null if neither exists.
  @MappableField()
  String? get flutterSdkVersion {
    // Prefer JSON metadata file (introduced in Flutter 3.13, required in 3.33+)
    final jsonVersion = _rootMetadata?.primaryVersion;
    if (jsonVersion != null) return jsonVersion;

    // Fall back to legacy version file
    final versionFile = join(directory, 'version');
    final versionFromFile = versionFile.file.read()?.trim();
    if (versionFromFile != null) return versionFromFile;

    return null;
  }

  @MappableField()
  String? get dartSdkVersion {
    // Prefer new JSON metadata file when present
    final jsonVersion = _rootMetadata?.dartSdkVersion?.trim();
    if (jsonVersion != null && jsonVersion.isNotEmpty) return jsonVersion;

    final versionFile = join(_dartSdkCache, 'version');

    return versionFile.file.read()?.trim();
  }

  /// Verifies that cacheVersion has been setup
  /// Setup means dependencies (Dart SDK cache) have been downloaded
  bool get isNotSetup => dartSdkVersion == null;

  /// Returns bool if version is setup
  @MappableField()
  bool get isSetup => dartSdkVersion != null;

  FlutterVersion toFlutterVersion() =>
      FlutterVersion(name, releaseChannel: releaseChannel, type: type);
}
