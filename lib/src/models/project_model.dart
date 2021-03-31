import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

import 'config_model.dart';

/// Flutter Project model
class Project {
  /// Name of the flutter project
  final String name;

  /// Directory of project
  final Directory projectDir;

  /// Config found within the project
  final FvmConfig config;

  /// Is Flutter project
  final bool isFlutterProject;

  /// Pubspec of the project
  final PubspecYaml pubspec;

  /// Project constructor
  Project({
    @required this.config,
    this.name,
    this.projectDir,
    this.isFlutterProject,
    this.pubspec,
  });

  /// Pinned version within a project
  /// returns null if no version is pinned
  String get pinnedVersion {
    if (config != null) {
      return config.flutterSdkVersion;
    } else {
      return null;
    }
  }
}
