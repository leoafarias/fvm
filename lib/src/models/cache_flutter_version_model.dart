import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

import '../utils/compare_semver.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';
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

  @protected
  @MappableConstructor()
  const CacheFlutterVersion(
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

  /// Gets Flutter SDK version from CacheVersion sync
  @MappableField()
  String? get flutterSdkVersion {
    final versionFile = join(directory, 'version');

    return versionFile.file.read()?.trim();
  }

  @MappableField()
  String? get dartSdkVersion {
    final versionFile = join(_dartSdkCache, 'version');

    return versionFile.file.read()?.trim();
  }

  /// Verifies that cacheVersion has been setup
  bool get isNotSetup => flutterSdkVersion == null;

  /// Returns bool if version is setup
  @MappableField()
  bool get isSetup => flutterSdkVersion != null;

  FlutterVersion toFlutterVersion() => FlutterVersion(
        name,
        releaseChannel: releaseChannel,
        type: type,
      );
}
