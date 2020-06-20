import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/confirm.dart';
import 'package:fvm/utils/print.dart';
import 'package:fvm/utils/project_config.dart';
import 'package:fvm/utils/version_installer.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/utils/flutter_tools.dart';

/// Returns true if it's a valid Flutter version number
Future<String> inferFlutterVersion(String version) async {
  final versions = await flutterListAllSdks();
  version = version.toLowerCase();

  // Return if its flutter chacnnel
  if (isFlutterChannel(version)) return version;

  if ((versions).contains(version)) {
    return version;
  }
  final prefixedVersion = 'v$version';

  if ((versions).contains(prefixedVersion)) {
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

/// Checks if version is installed, and installs or exits
Future<void> checkAndInstallVersion(String version) async {
  if (isFlutterVersionInstalled(version)) return null;
  Print.info('Flutter $version is not installed.');

  // Install if input is confirmed
  if (await confirm('Would you like to install it?')) {
    await installFlutterVersion(version);
  } else {
    // If do not install exist
    exit(0);
  }
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
bool isCurrentVersion(String version) {
  final configVersion = getConfigFlutterVersion();
  return version == configVersion;
}

/// The Flutter SDK Path referenced on FVM
String getFlutterSdkPath({String version}) {
  var sdkVersion = version;
  if (version == null) {
    final config = readProjectConfig();
    sdkVersion = config.flutterSdkVersion;
  }
  return path.join(kVersionsDir.path, sdkVersion);
}

String getFlutterSdkExec({String version}) {
  return path.join(getFlutterSdkPath(version: version), 'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter');
}
