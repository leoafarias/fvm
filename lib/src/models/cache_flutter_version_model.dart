import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart';

import '../utils/compare_semver.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'flutter_version_model.dart';

part 'cache_flutter_version_model.mapper.dart';

/// Cache Version model
@MappableClass()
class CacheFlutterVersion
    with CacheFlutterVersionMappable
    implements FlutterVersion {
  /// Directory of the cache version
  final String directory;
  final FlutterVersion version;

  static final fromMap = CacheFlutterVersionMapper.fromMap;
  static final fromJson = CacheFlutterVersionMapper.fromJson;

  const CacheFlutterVersion(this.version, {required this.directory});

  String get _dartSdkCache => join(binPath, 'cache', 'dart-sdk');

  /// Get version bin path
  @MappableField()
  String get binPath => join(directory, 'bin');

  /// Has old dart path structure
  // Last version with the old dart path structure
  @MappableField()
  bool get hasOldBinPath {
    return compareSemver(versionWeight, '1.17.5') <= 0;
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

  @override
  int compareTo(FlutterVersion other) {
    return version.compareTo(other);
  }

  @override
  String get branch => version.branch;

  /// Get version bin path
  @override
  @MappableField()
  VersionType get type => version.type;

  @override
  @MappableField()
  String get name => version.name;

  @override
  @MappableField()
  String get friendlyName => version.friendlyName;

  @override
  @MappableField()
  String get versionWeight => version.versionWeight;

  @override
  bool get isChannel => version.isChannel;

  @override
  bool get isCommit => version.isCommit;

  @override
  bool get isCustom => version.isCustom;

  @override
  bool get isMaster => version.isMaster;

  @override
  bool get isRelease => version.isRelease;
}
