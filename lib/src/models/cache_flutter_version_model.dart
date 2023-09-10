import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/utils/compare_semver.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:path/path.dart';

import '../../constants.dart';

/// Cache Version model
class CacheFlutterVersion extends FlutterVersion {
  /// Constructor
  CacheFlutterVersion(
    FlutterVersion version, {
    required this.directory,
  }) : super(
          version.name,
          releaseChannel: version.releaseChannel,
          isChannel: version.isChannel,
          isRelease: version.isRelease,
          isCommit: version.isCommit,
          isCustom: version.isCustom,
        );

  /// Directory of the cache version
  final String directory;

  /// Get version bin path
  String get binPath => join(directory, 'bin');

  /// Has old dart path structure
  // Last version with the old dart path structure
  bool get hasOldBinPath {
    return compareSemver(assignVersionWeight(version), '1.17.5') <= 0;
  }

  String get _dartSdkCache => join(binPath, 'cache', 'dart-sdk');

  /// Returns dart exec file for cache version
  String get dartBinPath {
    /// Get old bin path
    /// Before version 1.17.5 dart path was bin/cache/dart-sdk/bin
    if (hasOldBinPath) return join(_dartSdkCache, 'bin');
    return binPath;
  }

  /// Returns dart exec file for cache version
  String get dartExec => join(dartBinPath, dartBinFileName);

  /// Returns flutter exec file for cache version
  String get flutterExec => join(binPath, flutterBinFileName);

  /// Gets Flutter SDK version from CacheVersion sync
  String? get flutterSdkVersion {
    final versionFile = File(join(directory, 'version'));
    return versionFile.existsSync() ? versionFile.readAsStringSync() : null;
  }

  String? get dartSdkVersion {
    final versionFile = File(join(_dartSdkCache, 'version'));
    return versionFile.existsSync() ? versionFile.readAsStringSync() : null;
  }

  /// Verifies that cacheVersion has been setup
  bool get notSetup => flutterSdkVersion == null;

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CacheFlutterVersion &&
        other.name == name &&
        other.directory == directory;
  }

  @override
  int get hashCode => name.hashCode ^ directory.hashCode;
}
