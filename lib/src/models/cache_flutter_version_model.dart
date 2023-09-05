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
          isMaster: version.isMaster,
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

  /// Returns dart exec file for cache version
  String get dartBinPath {
    /// Get old bin path
    /// Before version 1.17.5 dart path was bin/cache/dart-sdk/bin
    if (hasOldBinPath) return join(binPath, 'cache', 'dart-sdk', 'bin');
    return binPath;
  }

  /// Returns dart exec file for cache version
  String get dartExec => join(dartBinPath, dartBinFileName);

  /// Returns flutter exec file for cache version
  String get flutterExec => join(binPath, flutterBinFileName);

  /// Gets Flutter SDK version from CacheVersion sync
  String? get sdkVersion {
    final versionFile = File(join(directory, 'version'));

    if (versionFile.existsSync()) return versionFile.readAsStringSync();
    return null;
  }

  /// Verifies that cacheVersion has been setup
  bool get notSetup => sdkVersion == null;

  @override
  String toString() {
    return name;
  }
}
