import 'dart:io';

/// Flutter Repo Address
const kFlutterRepo = "https://github.com/flutter/flutter.git";

/// Working Directory for FVM
final kWorkingDirectory = Directory.current;

/// Local Project Flutter Link
final kLocalFlutterLink = Link('${kWorkingDirectory.path}/fvm');

/// FVM Home directory
String _fvmHome() {
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

/// Where Flutter SDK Versions are stored
final kVersionsDir = Directory('${_fvmHome()}/versions');

/// Flutter Channels
final kFlutterChannels = ['master', 'stable', 'dev', 'beta'];
