import 'dart:io';

import 'package:path/path.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../models/config_model.dart';
import '../utils/helpers.dart';

/// Helpers and tools for the FVM config within a project
class ConfigService {
  ConfigService._();

  /// Returns a [FvmConfig] from within a [directory]
  static Future<FvmConfig> read(Directory directory) async {
    final configDir = Directory(join(directory.path, kFvmDirName));
    final configFile = File(join(configDir.path, kFvmConfigFileName));

    try {
      final jsonString = await configFile.readAsString();
      return FvmConfig.fromJson(configDir, jsonString);
    } on Exception {
      return FvmConfig(
        configDir: configDir,
        flutterSdkVersion: null,
        flavors: {},
      );
    }
  }

  /// Updates link for the project SDK from the [config]
  static Future<void> updateSdkLink(FvmConfig config) async {
    await createLink(config.sdkSymlink, Directory(config.flutterSdkPath));
  }

  /// Saves a fvm [config]
  static Future<void> save(FvmConfig config) async {
    try {
      if (!await config.configFile.exists()) {
        await config.configFile.create(recursive: true);
      }
      await config.configFile.writeAsString(config.toJson());
    } on Exception {
      throw FvmInternalError('Could not save config changes');
    }
    await updateSdkLink(config);
  }
}
