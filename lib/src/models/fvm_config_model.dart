import 'dart:convert';
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/pretty_json.dart';
import 'package:meta/meta.dart';

import 'package:path/path.dart';

class FvmConfig {
  Directory configDir;
  String flutterSdkVersion;
  Map<String, dynamic> environment;
  FvmConfig({
    @required this.configDir,
    @required this.flutterSdkVersion,
    this.environment = const {},
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
      environment: map['environment'] as Map<String, dynamic>,
    );
  }

  String get flutterSdkPath {
    return join(kFvmCacheDir.path, flutterSdkVersion);
  }

  String get activeEnv {
    return environment.keys.firstWhere(
      (key) => environment[key] == flutterSdkVersion,
      orElse: () => null,
    );
  }

  bool get exists {
    return configFile.existsSync();
  }

  File get configFile {
    return File(join(configDir.path, kFvmConfigFileName));
  }

  Link get sdkSymlink {
    return Link(join(configDir.path, 'flutter_sdk'));
  }

  String toJson() => prettyJson(toMap());

  Map<String, dynamic> toMap() {
    return {
      'flutterSdkVersion': flutterSdkVersion,
      'environment': environment,
    };
  }
}
