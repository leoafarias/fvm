import 'dart:io';

import 'package:path/path.dart';

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
  if (Platform.isWindows) {
    return kEnvVars['UserProfile']!;
  } else {
    return kEnvVars['HOME']!;
  }
}

/// FVM Home directory
String get kFvmHome {
  var home = kEnvVars['FVM_HOME'];
  if (home != null) {
    return normalize(home);
  }

  return join(kUserHome, 'fvm');
}

/// Flutter Channels
const kFlutterChannels = ['master', 'stable', 'dev', 'beta'];
