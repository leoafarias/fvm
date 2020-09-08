import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:version/version.dart';

class LocalVersion {
  final String name;
  final String sdkVersion;
  final bool isChannel;

  LocalVersion({
    this.name,
    this.sdkVersion,
  }) : isChannel = isFlutterChannel(name);

  int compareTo(LocalVersion other) {
    final version = _assignVersionWeight(name);
    final otherVersion = _assignVersionWeight(other.name);
    return version.compareTo(otherVersion);
  }
}

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
  // // Non semver
  // if (version.contains('+')) {
  //   version = version.substring(0, version.indexOf('+'));
  // }

  if (version.contains('v')) {
    version = version.replaceFirst('v', '');
  }

  return Version.parse(version);
}
