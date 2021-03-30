import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:meta/meta.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

class FlutterApp {
  final String name;
  final Directory projectDir;
  final FvmConfig config;
  final bool isFlutterProject;
  final PubspecYaml pubspec;

  FlutterApp({
    @required this.config,
    this.name,
    this.projectDir,
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
