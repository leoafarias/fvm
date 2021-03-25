import 'dart:io';

import 'package:fvm/constants.dart';

import 'package:meta/meta.dart';

import 'package:path/path.dart';

import 'package:process_run/which.dart';

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
