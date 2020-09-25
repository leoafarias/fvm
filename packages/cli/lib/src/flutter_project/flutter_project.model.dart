import 'dart:io';

import 'package:fvm/src/flutter_project/fvm_config.model.dart';
import 'package:meta/meta.dart';

class FlutterProject {
  final String name;
  final Directory projectDir;
  final String gitBranch;
  final FvmConfig config;

  FlutterProject({
    @required this.config,
    this.name,
    this.projectDir,
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
