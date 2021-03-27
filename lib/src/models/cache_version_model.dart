import 'dart:io';

import 'package:fvm/src/services/flutter_tools.dart';
import 'package:meta/meta.dart';
import 'package:version/version.dart';

class CacheVersion {
  @required
  final String name;
  @required
  final String sdkVersion;
  @required
  final Directory dir;
  final bool isChannel;

  CacheVersion({
    this.name,
    this.sdkVersion,
    this.dir,
  }) : isChannel = FlutterTools.isChannel(name);

  int compareTo(CacheVersion other) {
    final version = _assignVersionWeight(name);
    final otherVersion = _assignVersionWeight(other.name);
    return version.compareTo(otherVersion);
  }
}

// Assigns weight to [version] for proper comparison
Version _assignVersionWeight(String version) {
  /// Assign version number to continue to work with semver
  switch (version) {
    case 'master':
      version = '400';
      break;
    case 'stable':
      version = '300';
      break;
    case 'beta':
      version = '200';
      break;
    case 'dev':
      version = '100';
      break;
    default:
  }

  if (version.contains('v')) {
    version = version.replaceFirst('v', '');
  }

  return Version.parse(version);
}
