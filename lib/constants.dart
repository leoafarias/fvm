import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:fvm/utils/config_utils.dart';

final _configUtils = ConfigUtils();

const kFvmDirName = '.fvm';

/// Flutter Repo Address
const kFlutterRepo = 'https://github.com/flutter/flutter.git';

/// Directory that the script is running
final kFvmDirectory = Platform.script.toString();

/// Working Directory for FVM
final kWorkingDirectory = Directory.current;

/// Local Project Directory
final kProjectFvmDir =
    Directory(path.join(kWorkingDirectory.path, kFvmDirName));

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
String get fvmHome {
  var home = '';
  final envVars = Platform.environment;
  if (Platform.isWindows) {
    home = envVars['UserProfile'];
  } else {
    home = envVars['HOME'];
  }

  return path.join(home, 'fvm');
}

/// Config file of fvm's config.
File get kConfigFile => File(path.join(fvmHome, '.fvm_config'));

/// Where Flutter SDK Versions are stored
Directory get kVersionsDir {
  final flutterPath = _configUtils.getStoredPath();
  if (flutterPath != null) {
    return Directory(flutterPath);
  }
  return Directory(path.join(fvmHome, 'versions'));
}

/// Where Default Flutter SDK is stored
Link get kDefaultFlutterLink => Link(path.join(fvmHome, 'default'));
String get kDefaultFlutterPath => path.join(kDefaultFlutterLink.path, 'bin');

/// Flutter Channels
final kFlutterChannels = ['master', 'stable', 'dev', 'beta'];

/// Flutter stored path of config.
const kConfigFlutterStoredKey = 'cache_path';
