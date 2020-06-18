import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/project_config.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/utils/flutter_tools.dart';

/// Returns true if it's a valid Flutter version number
Future<String> inferFlutterVersion(String version) async {
  if ((await flutterListAllSdks()).contains(version)) {
    return version;
  }
  final prefixedVersion = 'v$version';
  if ((await flutterListAllSdks()).contains(prefixedVersion)) {
    return prefixedVersion;
  }
  throw ExceptionNotValidVersion('"$version" is not a valid version');
}

/// Returns true if it's a valid Flutter channel
bool isFlutterChannel(String channel) {
  return kFlutterChannels.contains(channel);
}

// Checks if its flutter project
bool isFlutterProject() {
  return kLocalProjectPubspec.existsSync();
}

/// Returns true it's a valid installed version
Future<bool> isSdkInstalled(String version) async {
  return (await flutterListInstalledSdks()).contains(version);
}

/// Moves assets from theme directory into brand-app
void createLink(
  Link source,
  FileSystemEntity target,
) async {
  try {
    if (source.existsSync()) {
      source.deleteSync();
    }
    source.createSync(target.path);
  } on Exception catch (err) {
    logVerboseError(err);
    throw Exception('Sorry could not link ${target.path}');
  }
}

/// Check if it is the current version.
Future<bool> isCurrentVersion(String version) async {
  final config = readProjectConfig();
  return version == config.flutterSdkVersion;
}

/// The Flutter SDK Path referenced on FVM
String getFlutterSdkPath() {
  try {
    final config = readProjectConfig();
    return path.join(kVersionsDir.path, config.flutterSdkVersion);
  } on Exception catch (e) {
    // TODO: Clean up exception
    throw ExceptionCouldNotReadConfig('$e');
  }
}

String getFlutterSdkExecPath() {
  return path.join(getFlutterSdkPath(), 'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter');
}
