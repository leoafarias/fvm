import 'dart:io';

import 'src/services/settings_service.dart';

import 'package:path/path.dart' as path;

const kFvmDirName = '.fvm';
final kFvmConfigFileName = 'fvm_config.json';
final envVars = Platform.environment;

// Execs
String binExt = Platform.isWindows ? '.bat' : '';
String flutterBinFileName = 'flutter$binExt';
String dartBinFileName = 'dart$binExt';

/// Flutter Repo Address
String get kFlutterRepo {
  return envVars['FVM_GIT_CACHE'] ?? 'https://github.com/flutter/flutter.git';
}

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
String get kGlobalFlutterPath => path.join(kGlobalFlutterLink.path, 'bin');

/// Flutter Channels
const kFlutterChannels = ['master', 'stable', 'dev', 'beta'];
