import 'dart:io';

import '../../constants.dart';
import '../services/flutter_tools.dart';
import '../utils/helpers.dart';

import 'package:path/path.dart';

class CacheVersion {
  final String name;

  CacheVersion(
    this.name,
  );

  String get dartExec {
    return join(dir.path, 'bin', dartBinFileName);
  }

  String get flutterExec {
    return join(dir.path, 'bin', flutterBinFileName);
  }

  Directory get dir {
    return Directory(join(kFvmCacheDir.path, name));
  }

  bool get isChannel {
    return FlutterTools.isChannel(name);
  }

  int compareTo(CacheVersion other) {
    final version = assignVersionWeight(name);
    final otherVersion = assignVersionWeight(other.name);
    return version.compareTo(otherVersion);
  }
}
