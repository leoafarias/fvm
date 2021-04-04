import 'dart:io';

import 'package:path/path.dart' as path;

import 'src/services/settings_service.dart';

/// Project directory for fvm
const kFvmDirName = '.fvm';

/// Project fvm config file name
final kFvmConfigFileName = 'fvm_config.json';

/// Environment variables
final kEnvVars = Platform.environment;

// Extension per platform
String _binExt = Platform.isWindows ? '.bat' : '';

/// Flutter executable file name
String flutterBinFileName = 'flutter$_binExt';

/// Dart executable file name
String dartBinFileName = 'dart$_binExt';

/// Flutter Repo Address
String get kFlutterRepo {
  return kEnvVars['FVM_GIT_CACHE'] ?? 'https://github.com/flutter/flutter.git';
}

/// Working Directory for FVM
/// Cannot be a const because it is modified
Directory kWorkingDirectory = Directory.current;

/// User Home Path
String get kUserHome {
  var home = kEnvVars['FVM_HOME'];
  if (home != null) {
    return path.normalize(home);
  }

  if (Platform.isWindows) {
    home = kEnvVars['UserProfile'];
  } else {
    home = kEnvVars['HOME'];
  }

  return home;
}

/// FVM Home directory
String get kFvmHome {
  var home = kEnvVars['FVM_HOME'];
  if (home != null) {
    return path.normalize(home);
  }

  if (Platform.isWindows) {
    // TODO: Check APPDATA
    home = kEnvVars['UserProfile'];
  } else {
    home = kEnvVars['HOME'];
  }

  return path.join(home, 'fvm');
}

/// File for FVM Settings
File get kFvmSettings {
  return File(path.join(kFvmHome, '.settings'));
}

/// Where Flutter SDK Versions are stored
Directory get kFvmCacheDir {
  /// Loads settings file
  final settings = SettingsService.readSync();
  if (settings.cachePath != null && settings.cachePath.isNotEmpty) {
    return Directory(path.normalize(settings.cachePath));
  }
  return Directory(path.join(kFvmHome, 'versions'));
}

/// Directory for Flutter repo git cache
Directory get kGitCacheDir {
  return Directory(path.join(kFvmHome, 'git-cache'));
}

/// Where Default Flutter SDK is stored
Link get kGlobalFlutterLink => Link(path.join(kFvmHome, 'default'));

/// Path for Default Flutter SDK
String get kGlobalFlutterPath => path.join(kGlobalFlutterLink.path, 'bin');

/// Flutter Channels
const kFlutterChannels = ['master', 'stable', 'dev', 'beta'];
