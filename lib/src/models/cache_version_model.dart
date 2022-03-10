import 'dart:io';

import 'package:path/path.dart';

import '../../constants.dart';
import '../services/context.dart';
import '../utils/helpers.dart';

/// Cache Version model
class CacheVersion {
  /// Name of the version
  final String name;

  /// Constructor
  CacheVersion(this.name);

  /// Get version bin path
  String get binPath {
    return join(dir.path, 'bin');
  }

  /// Has old dart path structure
  bool get hasOldBinPath {
    // Last version with the old dart path structure
    return compareSemver(versionWeight, '1.17.5') <= 0;
  }

  /// Returns dart exec file for cache version
  String get dartBinPath {
    /// Get old bin path
    /// Before version 1.17.5 dart path was bin/cache/dart-sdk/bin
    if (hasOldBinPath) {
      return join(binPath, 'cache', 'dart-sdk', 'bin');
    } else {
      return binPath;
    }
  }

  /// Returns dart exec file for cache version
  String get dartExec {
    return join(dartBinPath, dartBinFileName);
  }

  /// Returns flutter exec file for cache version
  String get flutterExec {
    return join(binPath, flutterBinFileName);
  }

  /// Returns CacheVersion directory
  Directory get dir {
    return Directory(join(ctx.cacheDir.path, name));
  }

  /// Is CacheVersion a channel
  bool get isChannel {
    return checkIsChannel(name);
  }

  /// Compares CacheVersion with [other]
  int compareTo(CacheVersion other) {
    final otherVersion = assignVersionWeight(other.name);
    return compareSemver(versionWeight, otherVersion);
  }

  /// Returns true if CacheVersion is compatible with [other]
  String get versionWeight {
    return assignVersionWeight(name);
  }

  String toString() {
    return name;
  }
}
