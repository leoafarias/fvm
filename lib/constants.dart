import 'dart:io';
import 'package:path/path.dart' as path;

const kFvmDirName = '.fvm';

/// Flutter Repo Address
const kFlutterRepo = 'https://github.com/flutter/flutter.git';

/// Directory that the script is running
final kFvmDirectory = Platform.script.toString();

/// Working Directory for FVM
final kWorkingDirectory = Directory.current;

/// Local Project Directory
final kProjectFvmDir = _getProjectFvmDir();

// Local project look up on nested project folders (monorepo)
Directory _getProjectFvmDir({Directory dir}) {
  dir ??= kWorkingDirectory;

  final isRootDir = path.rootPrefix(dir.path) == dir.path;
  final flutterProjectDir = Directory(path.join(dir.path, kFvmDirName));

  if (flutterProjectDir.existsSync()) return flutterProjectDir;
  // Return working directory if it has reached root
  if (isRootDir) {
    return Directory(path.join(kWorkingDirectory.path, kFvmDirName));
  }
  return _getProjectFvmDir(dir: dir.parent);
}

/// Local Project Config
final kProjectFvmConfigJson =
    File(path.join(kProjectFvmDir.path, 'fvm_config.json'));

/// Local Project Flutter Link
final kProjectFvmSdkSymlink =
    Link(path.join(kProjectFvmDir.path, 'flutter_sdk'));

/// Flutter Project pubspec
final kLocalProjectPubspec =
    File(path.join(kWorkingDirectory.path, 'pubspec.yaml'));

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

/// Config file of fvm's config.
File get kConfigFile => File(path.join(kFvmHome, '.fvm_config'));

/// Where Flutter SDK Versions are stored
Directory get kVersionsDir {
  return Directory(path.join(kFvmHome, 'versions'));
}

/// Where Default Flutter SDK is stored
Link get kDefaultFlutterLink => Link(path.join(kFvmHome, 'default'));
String get kDefaultFlutterPath => path.join(kDefaultFlutterLink.path, 'bin');

/// Flutter Channels
final kFlutterChannels = ['master', 'stable', 'dev', 'beta'];

/// Flutter stored path of config.
const kConfigFlutterStoredKey = 'cache_path';
