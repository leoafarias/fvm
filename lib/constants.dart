import 'dart:io';
import 'package:fvm/src/utils/settings.dart';
import 'package:path/path.dart' as path;

const kFvmDirName = '.fvm';
final kFvmConfigFileName = 'fvm_config.json';
final envVars = Platform.environment;

/// Flutter Repo Address
final kFlutterRepo =
    envVars['FVM_GIT_CACHE'] ?? 'https://github.com/flutter/flutter.git';

/// Working Directory for FVM

var kWorkingDirectory = Directory.current;

/// FVM Home directory
String get kFvmHome {
  var home = envVars['FVM_HOME'];
  if (home != null) {
    return path.normalize(home);
  }

  if (Platform.isWindows) {
    home = envVars['UserProfile'];
  } else {
    home = envVars['HOME'];
  }

  return path.join(home, 'fvm');
}

File get kFvmSettings {
  return File(path.join(kFvmHome, '.settings'));
}

/// Where Flutter SDK Versions are stored
Directory get kVersionsDir {
  final settings = Settings.readSync();
  if (settings.cachePath != null && settings.cachePath.isNotEmpty) {
    return Directory(path.normalize(settings.cachePath));
  }
  return Directory(path.join(kFvmHome, 'versions'));
}

/// Where Default Flutter SDK is stored
Link get kDefaultFlutterLink => Link(path.join(kFvmHome, 'default'));
String get kDefaultFlutterPath => path.join(kDefaultFlutterLink.path, 'bin');

/// Flutter Channels
final kFlutterChannels = ['master', 'stable', 'dev', 'beta'];
