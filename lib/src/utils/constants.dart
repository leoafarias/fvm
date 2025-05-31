import 'dart:io';

import 'package:path/path.dart';

/// The package name for Flutter Version Management (FVM).
/// This value is used to construct directory paths and identifiers for FVM.
const kPackageName = 'fvm';

/// A brief description of FVM.
/// This description is used in help messages and documentation.
const kDescription =
    'Flutter Version Management: A cli to manage Flutter SDK versions.';

/// The directory name used within projects to store FVM-related files.
/// This directory is created in the root of a Flutter project.
const kFvmDirName = '.fvm';

/// The URL to the FVM documentation website.
const kFvmDocsUrl = 'https://fvm.app';

/// The URL to the configuration documentation for FVM.
/// This helps users understand how to set up FVM in their projects.
const kFvmDocsConfigUrl = '$kFvmDocsUrl/docs/config';

/// The default Git URL for cloning the Flutter SDK.
/// This URL is used when no alternative source is specified.
const kDefaultFlutterUrl = 'https://github.com/flutter/flutter.git';

/// The name of the FVM configuration file within a project.
/// This file contains the configuration settings for FVM.
const kFvmConfigFileName = '.fvmrc';

/// The legacy FVM configuration file name, used for backward compatibility.
const kFvmLegacyConfigFileName = 'fvm_config.json';

/// Constant for the Visual Studio Code editor name.
/// This is used when selecting an IDE in FVM configurations.
const kVsCode = 'VSCode';

/// Constant for the IntelliJ (or Android Studio) editor name.
/// This helps in identifying the IDE when configuring FVM.
const kIntelliJ = 'IntelliJ (Android Studio, ...)';

/// A shortcut to the environment variables available on the current platform.
/// This is used to retrieve paths and configuration settings from the system.
final _env = Platform.environment;

/// Determines the executable file extension based on the operating system.
/// On Windows, command-line executables often have a '.bat' extension;
/// on other platforms, no extension is used.
final _execExtension = Platform.isWindows ? '.bat' : '';

/// The file name of the Flutter executable, including the platform-specific extension.
/// This is used to locate and invoke the Flutter command-line interface.
final flutterExecFileName = 'flutter$_execExtension';

/// The file name of the Dart executable, including the platform-specific extension.
/// This is used to locate and invoke the Dart VM.
String dartExecFileName = 'dart$_execExtension';

/// The current user's home directory.
/// On Windows, it is taken from the 'USERPROFILE' environment variable,
/// while on other platforms it is taken from the 'HOME' environment variable.
final kUserHome = Platform.isWindows ? _env['USERPROFILE']! : _env['HOME']!;

/// The FVM home directory, constructed by joining the user's home directory with the package name.
/// This directory stores global FVM configuration and state files.
final kAppDirHome = join(kUserHome, kPackageName);

/// The list of supported Flutter release channels.
/// These channels (e.g. 'stable', 'dev', etc.) are used when selecting the version of Flutter to install.
const kFlutterChannels = ['main', 'master', 'stable', 'dev', 'beta'];

/// The full path to the global FVM configuration file.
/// It is located in the user's configuration home directory.
final kAppConfigFile = join(_configHome, kPackageName, kFvmConfigFileName);

/// Retrieves the configuration home directory based on the current operating system.
///
/// On Windows, it uses the APPDATA environment variable.
/// On macOS, it returns the 'Library/Application Support' directory.
/// On Linux, it returns the XDG_CONFIG_HOME value if set; otherwise, it falls back to '$HOME/.config'.
///
/// If none of these conditions apply, it falls back to using '$HOME/.config'.
String get _configHome {
  // This is used just for testing.
  // Should not be used for anything else
  final fvmGlobalConfigPath = _env['TEST_FVM_GLOBAL_CONFIG_PATH'];
  if (fvmGlobalConfigPath != null) {
    return fvmGlobalConfigPath;
  }

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

/// A list of common environment variable names used by Continuous Integration (CI) systems.
/// These variables can be checked to determine if FVM is running in a CI environment,
/// which might affect interactive prompts or logging.
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
