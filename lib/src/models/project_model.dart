import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/services/pubspec_repository.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec2/pubspec2.dart';

import 'config_model.dart';

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

  /// Creates a new instance of [Project].
  ///
  /// The [config] parameter represents the configuration of the project.
  /// The [path] parameter is the directory path of the project.
  /// The [pubspec] parameter represents the pubspec.yaml file of the project.
  Project({
    required this.config,
    required this.path,
    required this.pubspec,
  });

  /// Retrieves the name of the project.
  String get name => basename(path);

  /// Retrieves the pinned Flutter SDK version within the project.
  ///
  /// Returns `null` if no version is pinned.
  String? get pinnedVersion {
    return config?.flutterSdkVersion;
  }

  /// Retrieves the active configured flavor of the project.
  String? get activeFlavor {
    return flavors.keys.firstWhereOrNull(
      (key) => flavors[key] == pinnedVersion,
    );
  }

  /// Retrieves the flavors defined in the project's `fvm.yaml` file.
  Map<String, dynamic> get flavors => config?.flavors ?? {};

  /// Retrieves the dart tool package config.
  ///
  /// Returns `null` if the file doesn't exist.
  String? get dartToolGeneratorVersion {
    return _dartToolPackageConfig.existsSync()
        ? (jsonDecode(
            _dartToolPackageConfig.readAsStringSync(),
          ) as Map<String, dynamic>)['generatorVersion']
        : null;
  }

  /// Retrieves the dart tool version from file.
  ///
  /// Returns `null` if the file doesn't exist.
  String? get dartToolVersion => _dartToolVersionFile.existsSync()
      ? _dartToolVersionFile.readAsStringSync()
      : null;

  /// Indicates whether the project is a Flutter project.
  bool get isFlutter {
    return pubspec?.dependencies.containsKey('flutter') ?? false;
  }

  /// Retrieves the local FVM path of the project.
  ///
  /// This path is used for caching Flutter SDK versions.
  Directory get fvmPath => Directory(_getLocalFvmPath(path));

  /// Retrieves the local FVM cache path of the project.
  ///
  /// This is the directory where Flutter SDK versions are cached.
  Directory get fvmCachePath =>
      Directory(join(_getLocalFvmPath(path), 'versions'));

  /// Returns the path of the Flutter SDK symlink within the project.
  Link get cacheVersionSymlink {
    return Link(join(
      fvmCachePath.path,
      pinnedVersion,
    ));
  }

  /// Returns the compatibility path of the Flutter SDK symlink within the project.
  Directory get cacheVersionSymlinkCompat {
    return Directory(join(
      fvmCachePath.path,
      pinnedVersion,
    ));
  }

  /// Indicates whether the project has `.gitignore` file.
  File get gitignoreFile => File(join(path, '.gitignore'));

  /// Returns the legacy path of the Flutter SDK symlink within the project.
  Link get legacyCacheVersionSymlink {
    return Link(join(
      path,
      kFvmDirName,
      'flutter_sdk',
    ));
  }

  /// Returns the dart tool package config.
  ///
  /// This file specifies the version of the Dart tool package.
  File get _dartToolPackageConfig {
    return File(join(path, '.dart_tool', 'package_config.json'));
  }

  /// Returns the dart tool version from file.
  ///
  /// This file stores the version of the Dart tool.
  File get _dartToolVersionFile {
    return File(join(path, '.dart_tool', 'version'));
  }

  /// Returns the path of the pubspec.yaml file.
  String get pubspecPath => join(path, 'pubspec.yaml');

  /// Returns the path of the FVM config file.
  String get configPath => _getLocalFvmConfigPath(path);

  /// Indicates whether the project has an FVM config file.
  bool get hasConfig => config != null;

  /// Retrieves the Flutter SDK constraint from the pubspec.yaml file.
  ///
  /// Returns `null` if the constraint is not defined.
  VersionConstraint? get sdkConstraint {
    return pubspec?.environment?.sdkConstraint;
  }

  /// Loads the Flutter project from the given [path].
  ///
  /// The project is loaded by locating the FVM config file and the pubspec.yaml file.
  static Project loadFromPath(String path) {
    ProjectConfig? config;

    final configPath = _getLocalFvmConfigPath(path);
    final configFile = File(configPath);
    if (configFile.existsSync()) {
      final map = json.decode(configFile.readAsStringSync());
      config = ProjectConfig.fromMap(map as Map<String, dynamic>);
    }

    final pubspecPath = join(path, 'pubspec.yaml');
    final pubspec = PubspecRepository(pubspecPath).load();

    return Project(
      path: path,
      pubspec: pubspec,
      config: config,
    );
  }
}

String _getLocalFvmPath(String path) {
  return join(path, kFvmDirName);
}

String _getLocalFvmConfigPath(String path) {
  return join(_getLocalFvmPath(path), kFvmConfigFileName);
}
