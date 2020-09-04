import 'dart:io';

import 'package:fvm/src/flutter_project/fvm_config.model.dart';

class FlutterProject {
  final String name;
  final Directory projectDir;
  final String gitBranch;
  final FvmConfig config;

  FlutterProject({
    this.name,
    this.projectDir,
    this.config,
    this.gitBranch,
  });

  String get pinnedVersion {
    if (config != null) {
      return config.flutterSdkVersion;
    } else {
      return null;
    }
  }
}
