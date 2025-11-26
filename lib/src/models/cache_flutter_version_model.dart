import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart';

import '../utils/compare_semver.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';
import 'flutter_root_version_file.dart';
import 'flutter_version_model.dart';

part 'cache_flutter_version_model.mapper.dart';

/// A cached Flutter SDK version with metadata loaded from disk.
///
/// This class is immutable - all metadata is loaded once at construction time.
/// Use [CacheFlutterVersion.fromVersion] factory for production code paths
/// that need to load metadata from disk.
@MappableClass()
class CacheFlutterVersion extends FlutterVersion
    with CacheFlutterVersionMappable {
  /// The directory path where this cached version is stored.
  final String directory;

  /// The Flutter SDK version string, or `null` if it cannot be determined.
  ///
  /// Detection order (at construction time):
  /// 1. JSON metadata file (`bin/cache/flutter.version.json`) - Flutter 3.13+
  /// 2. Legacy version file (`version`) - Flutter <3.38
  /// 3. Git tag via `git describe --tags` - for pre-setup SDKs
  @MappableField()
  final String? flutterSdkVersion;

  /// The Dart SDK version string, or `null` if not available.
  ///
  /// Detection order (at construction time):
  /// 1. JSON metadata file (`bin/cache/flutter.version.json`)
  /// 2. Dart SDK version file (`bin/cache/dart-sdk/version`)
  @MappableField()
  final String? dartSdkVersion;

  /// Whether this cached version has been set up.
  ///
  /// A version is considered set up when the `dart-sdk/bin` directory exists,
  /// indicating the Dart SDK has been downloaded. This is more robust than
  /// checking version files which could be removed in future Flutter versions.
  @MappableField()
  final bool isSetup;

  static final fromMap = CacheFlutterVersionMapper.fromMap;
  static final fromJson = CacheFlutterVersionMapper.fromJson;

  /// Creates a [CacheFlutterVersion] from pre-loaded field values.
  ///
  /// Used by the mapper for deserialization. All fields are stored directly;
  /// no I/O operations happen here.
  @MappableConstructor()
  const CacheFlutterVersion(
    super.name, {
    super.releaseChannel,
    required super.type,
    super.fork,
    required this.directory,
    this.flutterSdkVersion,
    this.dartSdkVersion,
    this.isSetup = false,
  });

  /// Creates a [CacheFlutterVersion] by loading metadata from disk.
  ///
  /// This factory is the single point for I/O operations related to version
  /// metadata. Production code should use this via [CacheService.getVersion].
  factory CacheFlutterVersion.fromVersion(
    FlutterVersion version, {
    required String directory,
  }) {
    final metadata = _loadMetadata(directory);
    return CacheFlutterVersion(
      version.name,
      releaseChannel: version.releaseChannel,
      type: version.type,
      fork: version.fork,
      directory: directory,
      flutterSdkVersion: metadata.flutterVersion,
      dartSdkVersion: metadata.dartVersion,
      isSetup: metadata.isSetup,
    );
  }

  // Loads all version metadata from the given directory.
  static ({String? flutterVersion, String? dartVersion, bool isSetup})
      _loadMetadata(String directory) {
    // Load JSON metadata file: $FLUTTER_ROOT/bin/cache/flutter.version.json
    // This file exists after setup on Flutter 3.13+
    final rootMetadata =
        FlutterRootVersionFile.tryLoadFromRoot(Directory(directory));

    final dartSdkCache = join(directory, 'bin', 'cache', 'dart-sdk');

    // --- Setup detection ---
    // Check if dart-sdk/bin/ directory exists (most reliable indicator)
    // This is more robust than checking version files which could be removed
    final dartSdkBinDir = Directory(join(dartSdkCache, 'bin'));
    final isSetup = dartSdkBinDir.existsSync();

    // --- Flutter SDK version detection ---
    // Priority: JSON → legacy version file → git describe
    String? flutterVersion = rootMetadata?.primaryVersion;

    if (flutterVersion == null) {
      // Legacy file: $FLUTTER_ROOT/version (exists in git repo for Flutter <3.38)
      final versionFile = join(directory, 'version');
      flutterVersion = versionFile.file.read()?.trim();
    }

    if (flutterVersion == null) {
      // Fallback: git describe for pre-setup SDKs
      flutterVersion = _getVersionFromGit(directory);
    }

    // --- Dart SDK version detection ---
    // Priority: JSON → dart-sdk version file
    // Note: Can be null even if isSetup=true (if version files are removed)
    String? dartVersion = rootMetadata?.dartSdkVersion?.trim();

    if (dartVersion == null || dartVersion.isEmpty) {
      // Dart SDK version file: $FLUTTER_ROOT/bin/cache/dart-sdk/version
      final versionFile = join(dartSdkCache, 'version');
      dartVersion = versionFile.file.read()?.trim();
    }

    return (
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      isSetup: isSetup
    );
  }

  // Attempts to get version from git tags (for pre-setup SDKs).
  static String? _getVersionFromGit(String directory) {
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

  /// The bin directory path for this cached version.
  @MappableField()
  String get binPath => join(directory, 'bin');

  /// Whether this version uses the old Dart path structure.
  ///
  /// Versions 1.17.5 and earlier had Dart executables in `bin/cache/dart-sdk/bin`.
  /// Later versions moved them to `bin` for easier access.
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

  /// Whether this cached version has not been set up.
  bool get isNotSetup => !isSetup;

  FlutterVersion toFlutterVersion() =>
      FlutterVersion(name, releaseChannel: releaseChannel, type: type);
}
