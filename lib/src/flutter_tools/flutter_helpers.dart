import 'dart:async';
import 'dart:io';

import 'package:fvm/constants.dart';

import 'package:path/path.dart';
import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:process_run/which.dart';

/// Returns true if it's a valid Flutter version number
Future<String> inferFlutterVersion(String version) async {
  assert(version != null);
  final releases = await fetchFlutterReleases();

  version = version.toLowerCase();

  // Return if its flutter channel
  if (isFlutterChannel(version) || releases.containsVersion(version)) {
    return version;
  }
  // Try prefixing the version
  final prefixedVersion = 'v$version';
  if (releases.containsVersion(prefixedVersion)) {
    return prefixedVersion;
  } else {
    throw Exception('Could not infer Flutter Version');
  }
}

/// Returns true if it's a valid Flutter channel
bool isFlutterChannel(String channel) {
  return kFlutterChannels.contains(channel);
}

/// Checks if its global version
bool isGlobalVersion(String version) {
  if (!kDefaultFlutterLink.existsSync()) return false;

  final globalVersion = basename(kDefaultFlutterLink.targetSync());

  return globalVersion == version;
}

String getFlutterSdkExec(String version) {
  // If version not provided find it within a project
  if (version == null || version.isEmpty) {
    return whichSync('flutter');
  }
  final sdkPath = join(kVersionsDir.path, version, 'bin', 'flutter');

  return join(sdkPath, Platform.isWindows ? '.bat' : '');
}
