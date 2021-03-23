import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';

import 'package:meta/meta.dart';

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
    throw UsageException(
        '$version is not a valid Flutter channel or release', '');
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

String getDartSdkExec(String version) {
  // If version not provided find it within a project
  if (version == null || version.isEmpty) {
    return whichSync('dart');
  }
  final sdkPath = join(kVersionsDir.path, version, 'bin');

  return join(sdkPath, Platform.isWindows ? 'dart.bat' : 'dart');
}

String getFlutterSdkExec(String version) {
  // If version not provided find it within a project
  if (version == null || version.isEmpty) {
    return whichSync('flutter');
  }
  final sdkPath = join(kVersionsDir.path, version, 'bin');

  return join(sdkPath, Platform.isWindows ? 'flutter.bat' : 'flutter');
}

Map<String, String> replaceFlutterPathEnv(String version) => _replacePathEnv(
      version: version,
      flutterOrDart: 'flutter',
    );

Map<String, String> replaceDartPathEnv(String version) => _replacePathEnv(
      version: version,
      flutterOrDart: 'dart',
    );

// TODO: Implement tests
Map<String, String> _replacePathEnv({
  @required String version,
  @required String flutterOrDart,
}) {
  assert(flutterOrDart != null);
  if (version == null || version.isEmpty) {
    return envVars;
  }

  final pathEnvList = envVars['PATH']
      .split(':')
      .where((e) => '$e/$flutterOrDart' != whichSync(flutterOrDart))
      .toList();

  final binPath = join(kVersionsDir.path, version, 'bin');

  final newEnv = pathEnvList.join(':');

  return Map<String, String>.from(envVars)
    ..addAll({'PATH': '$newEnv:$binPath'});
}
