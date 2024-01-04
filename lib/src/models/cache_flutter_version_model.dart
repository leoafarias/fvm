import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/utils/commands.dart';
import 'package:fvm/src/utils/compare_semver.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:path/path.dart';

import '../../constants.dart';

/// Cache Version model
class CacheFlutterVersion extends FlutterVersion {
  /// Directory of the cache version
  final String directory;

  /// Constructor
  CacheFlutterVersion(FlutterVersion version, {required this.directory})
      : super(
          version.name,
          releaseFromChannel: version.releaseFromChannel,
          isChannel: version.isChannel,
          isRelease: version.isRelease,
          isCommit: version.isCommit,
          isCustom: version.isCustom,
        );

  String get _dartSdkCache => join(binPath, 'cache', 'dart-sdk');

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
    if (hasOldBinPath) return join(_dartSdkCache, 'bin');
    return binPath;
  }

  /// Returns dart exec file for cache version
  String get dartExec => join(dartBinPath, dartExecFileName);

  /// Returns flutter exec file for cache version
  String get flutterExec => join(binPath, flutterExecFileName);

  /// Gets Flutter SDK version from CacheVersion sync
  String? get flutterSdkVersion {
    final versionFile = join(directory, 'version');
    return versionFile.file.read()?.trim();
  }

  String? get dartSdkVersion {
    final versionFile = join(_dartSdkCache, 'version');
    return versionFile.file.read()?.trim();
  }

  /// Verifies that cacheVersion has been setup
  bool get notSetup => flutterSdkVersion == null;

  Future<ProcessResult> run(
    String command, {
    bool echoOutput = false,
    bool? throwOnError,
  }) {
    return runFlutter(
      command.split(' '),
      version: this,
      echoOutput: echoOutput,
      throwOnError: throwOnError,
    );
  }

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
