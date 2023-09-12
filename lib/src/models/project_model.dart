import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:path/path.dart';
import 'package:pubspec2/pubspec2.dart';

import 'config_model.dart';

/// Flutter Project model
class Project {
  /// Directory of project
  final Directory projectDir;

  /// Config found within the project
  ProjectConfig? config;

  final PubSpec? pubspec;

  /// Project constructor
  Project({
    required this.config,
    required this.projectDir,
    required this.pubspec,
  });

  /// Returns the project name
  String get name => basename(projectDir.path);

  /// Pinned version within a project
  /// returns null if no version is pinned
  String? get pinnedVersion {
    return config?.flutter;
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

  Directory get fvmDir {
    return Directory(join(projectDir.path, kFvmDirName));
  }

  Directory get fvmCacheDir {
    return Directory(join(fvmDir.path, 'versions'));
  }

  /// Returns the project path to the Flutter SDK symlink
  Link get cacheVersionSymlink {
    return Link(join(
      fvmCacheDir.path,
      pinnedVersion,
    ));
  }

  /// Compatibility version for non-admin permission
  Directory get cacheVersionSymlinkCompat {
    return Directory(join(
      fvmCacheDir.path,
      pinnedVersion,
    ));
  }

  /// .gitignore file
  File get gitignoreFile {
    return File(join(projectDir.path, '.gitignore'));
  }

  /// Old linking path
  Link get legacyCacheVersionSymlink {
    return Link(join(
      projectDir.path,
      kFvmDirName,
      'flutter_sdk',
    ));
  }

  /// Returns dart tool package config
  File get _dartToolPackgeConfig {
    return File(join(projectDir.path, '.dart_tool', 'package_config.json'));
  }

  File get _dartToolVersionFile {
    return File(join(projectDir.path, '.dart_tool', 'version'));
  }

  /// Pubspec file
  File get pubspecFile {
    return File(join(projectDir.path, 'pubspec.yaml'));
  }

  /// Config file
  File get configFile {
    return File(join(fvmDir.path, kFvmConfigFileName));
  }

  /// Checks if project has config
  bool get hasConfig => config != null;
}
