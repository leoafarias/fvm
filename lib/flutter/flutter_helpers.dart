import 'dart:async';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'flutter_releases.dart';
import 'flutter_tools.dart';

/// Returns true if it's a valid Flutter version number
// TODO: Make sure this is called only on command input
Future<String> inferFlutterVersion(String version) async {
  final releases = await getReleases();

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

/// Returns true it's a valid installed version
bool isFlutterVersionInstalled(String version) {
  return (flutterListInstalledSdks()).contains(version);
}
