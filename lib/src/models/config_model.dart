import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart';

import '../../constants.dart';
import '../utils/pretty_json.dart';

/// FVM Config model
class FvmConfig {
  /// Directory of the FVM Config
  Directory configDir;

  /// Flutter SDK version configured
  String flutterSdkVersion;

  /// Environments configured
  Map<String, dynamic> environment;

  /// Constructor
  FvmConfig({
    @required this.configDir,
    @required this.flutterSdkVersion,
    @required this.environment,
  });

  /// Returns FvmConfig in [directory] from [jsonString]
  factory FvmConfig.fromJson(Directory directory, String jsonString) {
    return FvmConfig.fromMap(
      directory,
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Returns FvmConfig in [directory] from [map] of values
  factory FvmConfig.fromMap(Directory directory, Map<String, dynamic> map) {
    return FvmConfig(
      configDir: directory,
      flutterSdkVersion: map['flutterSdkVersion'] as String,
      environment: (map['environment'] as Map<String, dynamic>) ?? {},
    );
  }

  /// Returns the path of the Flutter SDK
  String get flutterSdkPath {
    return join(kFvmCacheDir.path, flutterSdkVersion);
  }

  /// Returns the active configured environment
  String get activeEnv {
    return environment.keys.firstWhere(
      (key) => environment[key] == flutterSdkVersion,
      orElse: () => null,
    );
  }

  /// Check if config file exists
  bool get exists {
    return configFile.existsSync();
  }

  /// Returns config file
  File get configFile {
    return File(join(configDir.path, kFvmConfigFileName));
  }

  /// Returns symlink of the SDK in configured
  Link get sdkSymlink {
    return Link(join(configDir.path, 'flutter_sdk'));
  }

  /// Returns json of FvmConfig
  String toJson() => prettyJson(toMap());

  /// Returns a map of values from FvmConfig
  Map<String, dynamic> toMap() {
    return {
      'flutterSdkVersion': flutterSdkVersion,
      'environment': environment,
    };
  }
}
