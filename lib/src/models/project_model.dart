import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/services/pubspec_repository.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:path/path.dart';
import 'package:pubspec2/pubspec2.dart';

import 'config_model.dart';

/// Flutter Project model
class Project {
  /// Directory of project
  final String path;

  /// Config found within the project
  ConfigDto? config;

  final PubSpec? pubspec;

  /// Project constructor
  Project({
    required this.config,
    required this.path,
    required this.pubspec,
  });

  /// Returns the project name
  String get name => basename(path);

  /// Pinned version within a project
  /// returns null if no version is pinned
  String? get pinnedVersion {
    return config?.flutterSdkVersion;
  }

  /// Returns the active configured flavor
  String? get activeFlavor {
    return flavors.keys.firstWhereOrNull(
      (key) => flavors[key] == pinnedVersion,
    );
  }

  Map<String, dynamic> get flavors => config?.flavors ?? {};

  String? get dartToolGeneratorVersion {
    return _dartToolPackgeConfig.existsSync()
        ? (jsonDecode(
            _dartToolPackgeConfig.readAsStringSync(),
          ) as Map<String, dynamic>)['generatorVersion']
        : null;
  }

  String? get dartToolVersion => _dartToolVersionFile.existsSync()
      ? _dartToolVersionFile.readAsStringSync()
      : null;

  bool get isFlutter {
    return pubspec?.dependencies.containsKey('flutter') ?? false;
  }

  Directory get fvmPath => Directory(_getLocalFvmPath(path));

  Directory get fvmCachePath =>
      Directory(join(_getLocalFvmPath(path), 'versions'));

  /// Returns the project path to the Flutter SDK symlink
  Link get cacheVersionSymlink {
    return Link(join(
      fvmCachePath.path,
      pinnedVersion,
    ));
  }

  /// Compatibility version for non-admin permission
  Directory get cacheVersionSymlinkCompat {
    return Directory(join(
      fvmCachePath.path,
      pinnedVersion,
    ));
  }

  /// .gitignore file
  File get gitignoreFile => File(join(path, '.gitignore'));

  /// Old linking path
  Link get legacyCacheVersionSymlink {
    return Link(join(
      path,
      kFvmDirName,
      'flutter_sdk',
    ));
  }

  /// Returns dart tool package config
  File get _dartToolPackgeConfig {
    return File(join(path, '.dart_tool', 'package_config.json'));
  }

  File get _dartToolVersionFile {
    return File(join(path, '.dart_tool', 'version'));
  }

  /// Pubspec file
  String get pubspecPath => join(path, 'pubspec.yaml');

  /// Config file
  String get configPath => _getLocalFvmConfigPath(path);

  /// Checks if project has config
  bool get hasConfig => config != null;

  static Project loadFromPath(String path) {
    final configPath = _getLocalFvmConfigPath(path);

    final config = ConfigRepository(configPath).load();

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
