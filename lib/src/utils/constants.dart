import 'dart:io';

import 'package:path/path.dart';

/// The package name for FVM.
const kPackageName = 'fvm';

/// CLI description shown in help messages.
const kDescription =
    'Flutter Version Management: A cli to manage Flutter SDK versions.';

/// Directory name for FVM files within projects.
const kFvmDirName = '.fvm';

/// FVM documentation URL.
const kFvmDocsUrl = 'https://fvm.app';

/// FVM configuration documentation URL.
const kFvmDocsConfigUrl = '$kFvmDocsUrl/docs/config';

/// Default Flutter SDK Git URL.
const kDefaultFlutterUrl = 'https://github.com/flutter/flutter.git';

/// FVM configuration file name.
const kFvmConfigFileName = '.fvmrc';

/// Legacy config file name for backward compatibility.
const kFvmLegacyConfigFileName = 'fvm_config.json';

/// Visual Studio Code editor constant.
const kVsCode = 'VSCode';

/// IntelliJ/Android Studio editor constant.
const kIntelliJ = 'IntelliJ (Android Studio, ...)';

final _env = Platform.environment;

/// Platform-specific executable extension (.bat on Windows, empty otherwise).
final _execExtension = Platform.isWindows ? '.bat' : '';

/// Flutter executable file name with platform extension.
final flutterExecFileName = 'flutter$_execExtension';

/// Dart executable file name with platform extension.
String dartExecFileName = 'dart$_execExtension';

/// User's home directory (USERPROFILE on Windows, HOME otherwise).
final kUserHome = Platform.isWindows ? _env['USERPROFILE']! : _env['HOME']!;

/// FVM home directory (~/.fvm or equivalent).
final kAppDirHome = join(kUserHome, kPackageName);

/// Supported Flutter release channels.
const kFlutterChannels = ['main', 'master', 'stable', 'dev', 'beta'];

/// Path to the global FVM configuration file.
final kAppConfigFile = join(_configHome, kPackageName, kFvmConfigFileName);

/// Platform-specific configuration home directory.
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

    // As per the XDG Base Directory Specification, default to $HOME/.config.
    return join(kUserHome, '.config');
  }

  // Fallback for any other platform: use $HOME/.config.
  return join(kUserHome, '.config');
}

/// Environment variables indicating CI environment (disables interactive prompts).
const kCiEnvironmentVariables = [
  // General indicator used by many CI providers.
  'CI',
  // Travis CI specific.
  'TRAVIS',
  // CircleCI specific.
  'CIRCLECI',
  // GitHub Actions specific.
  'GITHUB_ACTIONS',
  // GitLab CI specific.
  'GITLAB_CI',
  // Jenkins specific.
  'JENKINS_URL',
  // Bamboo specific.
  'BAMBOO_BUILD_NUMBER',
  // TeamCity specific.
  'TEAMCITY_VERSION',
  // Azure Pipelines specific.
  'TF_BUILD',
];
