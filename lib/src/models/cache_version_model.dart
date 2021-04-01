import 'dart:io';

import 'package:path/path.dart';

import '../../constants.dart';
import '../utils/helpers.dart';

/// Cache Version model
class CacheVersion {
  /// Name of the version
  final String name;

  /// Constructor
  CacheVersion(this.name);

  /// Returns dart exec file for cache version
  String get dartExec {
    return join(dir.path, 'bin', dartBinFileName);
  }

  /// Returns flutter exec file for cache version
  String get flutterExec {
    return join(dir.path, 'bin', flutterBinFileName);
  }

  /// Returns CacheVersion directory
  Directory get dir {
    return Directory(join(kFvmCacheDir.path, name));
  }

  /// Is CacheVersion a channel
  bool get isChannel {
    return checkIsChannel(name);
  }

  /// Compares CacheVersion with [other]
  int compareTo(CacheVersion other) {
    final version = assignVersionWeight(name);
    final otherVersion = assignVersionWeight(other.name);
    return version.compareTo(otherVersion);
  }

  String toString() {
    return name;
  }
}
