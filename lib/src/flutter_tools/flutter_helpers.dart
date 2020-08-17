import 'dart:async';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/flutter_project/project_config.repo.dart';
import 'package:path/path.dart' as path;
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

  final globalVersion = path.basename(kDefaultFlutterLink.targetSync());

  return globalVersion == version;
}

String getFlutterSdkExec({String version}) {
  return path.join(getFlutterSdkPath(version: version), 'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter');
}

/// The Flutter SDK Path referenced on FVM
String getFlutterSdkPath({String version}) {
  var sdkVersion = version;
  sdkVersion ??= readProjectConfig().flutterSdkVersion;
  return path.join(kVersionsDir.path, sdkVersion);
}
