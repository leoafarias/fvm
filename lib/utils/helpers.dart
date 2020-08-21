import 'dart:async';

import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/confirm.dart';
import 'package:fvm/utils/print.dart';
import 'package:fvm/utils/project_config.dart';

import 'package:fvm/utils/installer.dart';
import 'package:path/path.dart' as path;

import '../flutter/flutter_helpers.dart';
import 'print.dart';

/// Checks if version is installed, and installs or exits
Future<void> checkAndInstallVersion(String version) async {
  if (isFlutterVersionInstalled(version)) return null;
  PrettyPrint.info('Flutter $version is not installed.');

  // Install if input is confirmed
  if (await confirm('Would you like to install it?')) {
    await installRelease(version);
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

/// Checks if its global version
bool isGlobalVersion(String version) {
  if (!kDefaultFlutterLink.existsSync()) return false;

  final globalVersion = path.basename(kDefaultFlutterLink.targetSync());

  return globalVersion == version;
}

/// The Flutter SDK Path referenced on FVM
String getFlutterSdkPath({String version}) {
  var sdkVersion = version;
  sdkVersion ??= getConfigFlutterVersion();
  if (sdkVersion == null) {
    return null;
  }
  return path.join(kVersionsDir.path, sdkVersion);
}

String getFlutterSdkExec({String version}) {
  var sdkPath = getFlutterSdkPath(version: version);
  if (sdkPath == null) {
    return '';
  }
  return path.join(
    sdkPath,
    'bin',
    Platform.isWindows ? 'flutter.bat' : 'flutter',
  );
}

String camelCase(String subject) {
  final _splittedString = subject.split('_');

  if (_splittedString.isEmpty) return '';

  final _firstWord = _splittedString[0].toLowerCase();
  final _restWords = _splittedString.sublist(1).map(capitalize).toList();

  return _firstWord + _restWords.join('');
}

String capitalize(String word) {
  return '${word[0].toUpperCase()}${word.substring(1)}';
}
