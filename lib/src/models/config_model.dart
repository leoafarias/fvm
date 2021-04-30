import 'dart:convert';
import 'dart:io';

// ignore: prefer_relative_imports
import 'package:fvm/src/services/context.dart';
import 'package:path/path.dart';

import '../../constants.dart';
import '../utils/pretty_json.dart';

/// FVM Config model
class FvmConfig {
  /// Directory of the FVM Config
  Directory configDir;

  /// Flutter SDK version configured
  String? flutterSdkVersion;

  /// Flavors configured
  Map<String, dynamic> flavors;

  /// Constructor
  FvmConfig({
    required this.configDir,
    required this.flutterSdkVersion,
    required this.flavors,
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
      flavors: map['flavors'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Returns the path of the Flutter SDK
  String get flutterSdkPath {
    return join(ctx.cacheDir.path, flutterSdkVersion);
  }

  /// Returns the active configured flavor
  String? get activeFlavor {
    final env = flavors.keys.firstWhere(
      (key) => flavors[key] == flutterSdkVersion,
      orElse: () => '',
    );

    if (env.isEmpty) {
      return null;
    }
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
      'flavors': flavors,
    };
  }
}
