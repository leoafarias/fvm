import 'dart:convert';
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:meta/meta.dart';

import 'package:path/path.dart';

import 'package:pretty_json/pretty_json.dart';

class FvmConfig {
  Directory configDir;
  String flutterSdkVersion;
  FvmConfig({
    @required this.configDir,
    @required this.flutterSdkVersion,
  });

  factory FvmConfig.fromJson(Directory configDir, String jsonString) {
    return FvmConfig.fromMap(
      configDir,
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  factory FvmConfig.fromMap(Directory configDir, Map<String, dynamic> map) {
    return FvmConfig(
      configDir: configDir,
      flutterSdkVersion: map['flutterSdkVersion'] as String,
    );
  }

  String get flutterSdkPath {
    return join(kVersionsDir.path, flutterSdkVersion);
  }

  File get configFile {
    return File(join(configDir.path, kFvmConfigFileName));
  }

  Link get sdkSymlink {
    return Link(join(configDir.path, 'flutter_sdk'));
  }

  String toJson() => prettyJson(toMap(), indent: 2);

  Map<String, dynamic> toMap() {
    return {
      'flutterSdkVersion': flutterSdkVersion,
    };
  }
}
