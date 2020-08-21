import 'dart:io';
import 'package:path/path.dart' as path;

const kFvmDirName = '.fvm';
final kFvmConfigFileName = 'fvm_config.json';

/// Flutter Repo Address
const kFlutterRepo = 'https://github.com/flutter/flutter.git';

/// Working Directory for FVM
final kWorkingDirectory = Directory.current;

/// FVM Home directory
String get kFvmHome {
  final envVars = Platform.environment;

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

/// Where Flutter SDK Versions are stored
Directory get kVersionsDir {
  return Directory(path.join(kFvmHome, 'versions'));
}

/// Where Default Flutter SDK is stored
Link get kDefaultFlutterLink => Link(path.join(kFvmHome, 'default'));
String get kDefaultFlutterPath => path.join(kDefaultFlutterLink.path, 'bin');

/// Flutter Channels
final kFlutterChannels = ['master', 'stable', 'dev', 'beta'];
