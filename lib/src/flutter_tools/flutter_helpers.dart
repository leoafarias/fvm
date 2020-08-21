import 'dart:async';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'package:path/path.dart';
import 'package:fvm/src/releases_api/releases_client.dart';

/// Returns true if it's a valid Flutter version number
Future<String> inferFlutterVersion(String version) async {
  final releases = await fetchFlutterReleases();

  version = version.toLowerCase();

  // Return if its flutter chacnnel
  if (isFlutterChannel(version)) return version;

  // Return version
  if (releases.containsVersion(version)) return version;

  final prefixedVersion = 'v$version';

  if (releases.containsVersion(prefixedVersion)) {
    return prefixedVersion;
  }

  throw ExceptionNotValidVersion(
      '"$version" is not a valid Flutter SDK version');
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
  final sdkPath = join(kVersionsDir.path, version);
  return join(sdkPath, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
}
