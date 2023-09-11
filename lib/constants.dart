import 'dart:io';

import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart';

const kPackageName = 'fvm';
const kDescription =
    'Flutter Version Management: A cli to manage Flutter SDK versions.';

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

/// User Home Path
String get kUserHome {
  if (Platform.isWindows) {
    return kEnvVars['USERPROFILE']!;
  } else {
    return kEnvVars['HOME']!;
  }
}

/// FVM Home directory
String get kFvmDirDefault => join(kUserHome, 'fvm');

/// Flutter Channels
const kFlutterChannels = ['master', 'stable', 'dev', 'beta'];

String applicationConfigHome() => join(_configHome, kPackageName);

String get _configHome {
  if (Platform.isWindows) {
    final appdata = ctx.environment['APPDATA'];
    if (appdata == null) {
      throw Exception('Environment variable %APPDATA% is not defined!');
    }
    return appdata;
  }

  if (Platform.isMacOS) {
    return join(kUserHome, 'Library', 'Application Support');
  }

  if (Platform.isLinux) {
    final xdgConfigHome = ctx.environment['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null) {
      return xdgConfigHome;
    }
    // XDG Base Directory Specification says to use $HOME/.config/ when
    // $XDG_CONFIG_HOME isn't defined.
    return join(kUserHome, '.config');
  }

  // We have no guidelines, perhaps we should just do: $HOME/.config/
  // same as XDG specification would specify as fallback.
  return join(kUserHome, '.config');
}
