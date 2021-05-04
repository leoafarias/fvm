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

  /// Returns dart exec file for cache version
  String get dartExec {
    return join(binPath, dartBinFileName);
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
    final version = assignVersionWeight(name);
    final otherVersion = assignVersionWeight(other.name);
    return compareSemver(version, otherVersion);
  }

  String toString() {
    return name;
  }
}
