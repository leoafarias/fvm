import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';

import '../../constants.dart';
import '../utils/extensions.dart';
import 'config_model.dart';
import 'flutter_version_model.dart';

/// Represents a Flutter project.
///
/// This class provides methods and properties related to a Flutter project,
/// such as retrieving the project name, the active flavor, caching paths,
/// and pubspec-related operations.
class Project {
  /// The directory path of the project.
  final String path;

  /// The configuration of the project, if available.
  final ProjectConfig? config;

  final PubSpec? pubspec;

  const

  /// Creates a new instance of [Project].
  ///
  /// The [config] parameter represents the configuration of the project.
  /// The [path] parameter is the directory path of the project.
  /// The [pubspec] parameter represents the pubspec.yaml file of the project.
  Project({required this.config, required this.path, required this.pubspec});

  /// Loads the Flutter project from the given [path].
  ///
  /// The project is loaded by locating the FVM config file and the pubspec.yaml file.
  static Project loadFromPath(String path) {
    final configFile = _fvmConfigPath(path);
    final legacyConfigFile = _legacyFvmConfigPath(path);

    // Used for migration of config files
    final legacyConfig = ProjectConfig.loadFromPath(legacyConfigFile);

    if (legacyConfig != null) {
      legacyConfig.save(configFile);
      legacyConfigFile.file.deleteSync();
    }

    final config = ProjectConfig.loadFromPath(configFile);

    final pubspecFile = File(join(path, 'pubspec.yaml'));
    final pubspec = pubspecFile.existsSync()
        ? PubSpec.fromYamlString(pubspecFile.readAsStringSync())
        : null;

    return Project(path: path, pubspec: pubspec, config: config);
  }

  /// Retrieves the name of the project.
  String get name => basename(path);

  /// Retrieves the pinned Flutter SDK version within the project.
  ///
  /// Returns `null` if no version is pinned.
  FlutterVersion? get pinnedVersion {
    final sdkVersion = config?.flutterSdkVersion;
    if (sdkVersion != null) {
      return FlutterVersion.parse(sdkVersion);
    }
    return null;
  }

  /// Retrieves the active configured flavor of the project.
  String? get activeFlavor {
    return flavors.keys.firstWhereOrNull(
      (key) => flavors[key] == pinnedVersion?.name,
    );
  }

  /// Retrieves the flavors defined in the project's `fvm.yaml` file.
  Map<String, String> get flavors => config?.flavors ?? {};

  /// Retrieves the dart tool package config.
  ///
  /// Returns `null` if the file doesn't exist.
  String? get dartToolGeneratorVersion => _dartToolGeneratorVersion(path);

  /// Retrieves the dart tool version from file.
  ///
  /// Returns `null` if the file doesn't exist.
  String? get dartToolVersion => _dartToolVersion(path);

  /// Indicates whether the project is a Flutter project.
  bool get isFlutter => pubspec?.dependencies.containsKey('flutter') ?? false;

  /// Retrieves the local FVM path of the project.
  ///
  /// This is the directory where FVM stores its configuration files.
  String get localFvmPath => _fvmPath(path);

  /// Retrieves the local FVM cache path of the project.
  ///
  /// This is the directory where Flutter SDK versions are cached.
  String get localVersionsCachePath {
    return join(_fvmPath(path), 'versions');
  }

  /// Returns the path of the Flutter SDK symlink within the project.
  String get localVersionSymlinkPath {
    return join(localVersionsCachePath, pinnedVersion?.name);
  }

  /// Indicates whether the project has `.gitignore` file.
  File get gitignoreFile => File(join(path, '.gitignore'));

  /// Returns the path of the pubspec.yaml file.
  String get pubspecPath => join(path, 'pubspec.yaml');

  /// Returns the path of the FVM config file.
  String get configPath => _fvmConfigPath(path);

  /// Indicates whether the project has an FVM config file.
  bool get hasConfig => config != null;

  /// Indicates whether the project has a pubspec.yaml file.
  bool get hasPubspec => pubspec != null;

  /// Retrieves the Flutter SDK constraint from the pubspec.yaml file.
  ///
  /// Returns `null` if the constraint is not defined.
  VersionConstraint? get sdkConstraint => pubspec?.environment?.sdkConstraint;
}

String _fvmPath(String path) {
  return join(path, kFvmDirName);
}

String _legacyFvmConfigPath(String path) {
  return join(_fvmPath(path), kFvmLegacyConfigFileName);
}

String _fvmConfigPath(String path) {
  return join(path, kFvmConfigFileName);
}

String _dartToolPath(String projectPath) {
  return join(projectPath, '.dart_tool');
}

String? _dartToolGeneratorVersion(String projectPath) {
  final file = File(join(_dartToolPath(projectPath), 'package_config.json'));

  return file.existsSync()
      ? (jsonDecode(file.readAsStringSync())
          as Map<String, dynamic>)['generatorVersion']
      : null;
}

String? _dartToolVersion(String projectPath) {
  final file = File(join(_dartToolPath(projectPath), 'version'));

  return file.existsSync() ? file.readAsStringSync() : null;
}
