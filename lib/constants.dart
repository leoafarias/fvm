import 'dart:io';

import 'package:fvm/utils/config_utils.dart';

final _configUtils = ConfigUtils();

/// Flutter Repo Address
const kFlutterRepo = "https://github.com/flutter/flutter.git";

/// Working Directory for FVM
final kWorkingDirectory = Directory.current;

/// Local Project Flutter Link
final kLocalFlutterLink = Link('${kWorkingDirectory.path}/fvm');

/// FVM Home directory
String get fvmHome {
  var home = "";
  final envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }

  return '$home/fvm';
}

/// Config file of fvm's config.
File get kConfigFile => File('$fvmHome/.fvm_config');

/// Where Flutter SDK Versions are stored
Directory get kVersionsDir {
  final flutterPath = _configUtils.getStoredPath();
  if (flutterPath != null) {
    return Directory(flutterPath);
  }
  return Directory('$fvmHome/versions');
}

/// Flutter Channels
final kFlutterChannels = ['master', 'stable', 'dev', 'beta'];

/// Flutter stored path of config.
const kConfigFlutterStoredKey = "cache_path";
