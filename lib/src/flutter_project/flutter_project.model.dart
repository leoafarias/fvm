import 'dart:io';

import 'package:fvm/src/flutter_project/fvm_config.model.dart';
import 'package:meta/meta.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

class FlutterProject {
  final String name;
  final Directory projectDir;
  final String gitBranch;
  final FvmConfig config;
  final bool isFlutterProject;
  final PubspecYaml pubspec;

  FlutterProject({
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
