import 'dart:io';

import 'package:fvm/src/models/fvm_config_model.dart';
import 'package:meta/meta.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

class FlutterApp {
  final String name;
  final Directory projectDir;
  final String gitBranch;
  final FvmConfig config;
  final bool isFlutterProject;
  final PubspecYaml pubspec;

  FlutterApp({
    @required this.config,
    this.name,
    this.projectDir,
    this.gitBranch,
    this.isFlutterProject,
    this.pubspec,
  });

  String get pinnedVersion {
    if (config != null) {
      return config.flutterSdkVersion;
    } else {
      return null;
    }
  }
}
