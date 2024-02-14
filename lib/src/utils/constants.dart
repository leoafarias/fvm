import 'dart:io';

import 'package:path/path.dart';

const kPackageName = 'fvm';
const kDescription =
    'Flutter Version Management: A cli to manage Flutter SDK versions.';

/// Project directory for fvm
const kFvmDirName = '.fvm';

const kFvmDocsUrl = 'https://fvm.app';
const kFvmDocsConfigUrl = '$kFvmDocsUrl/docs/config';

const kDefaultFlutterUrl = 'https://github.com/flutter/flutter.git';

/// Project fvm config file name
const kFvmConfigFileName = '.fvmrc';

/// Project fvm config file name
const kFvmLegacyConfigFileName = 'fvm_config.json';

/// Vscode name
const kVsCode = 'VSCode';

/// IntelliJ name
const kIntelliJ = 'IntelliJ (Android Studio, ...)';

/// Environment variables
final _env = Platform.environment;

// Extension per platform
final _execExtension = Platform.isWindows ? '.bat' : '';

/// Flutter executable file name
final flutterExecFileName = 'flutter$_execExtension';

/// Dart executable file name
String dartExecFileName = 'dart$_execExtension';

/// User Home Path
final kUserHome = Platform.isWindows ? _env['USERPROFILE']! : _env['HOME']!;

/// FVM Home directory
final kAppDirHome = join(kUserHome, kPackageName);

/// Flutter Channels
const kFlutterChannels = ['master', 'stable', 'dev', 'beta'];

final kAppConfigFile = join(_configHome, kPackageName, kFvmConfigFileName);

String get _configHome {
  if (Platform.isWindows) {
    final appdata = _env['APPDATA'];
    if (appdata == null) {
      throw Exception('Environment variable %APPDATA% is not defined!');
    }
    return appdata;
  }

  if (Platform.isMacOS) {
    return join(kUserHome, 'Library', 'Application Support');
  }

  if (Platform.isLinux) {
    final xdgConfigHome = _env['XDG_CONFIG_HOME'];
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
