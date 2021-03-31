import 'dart:io';

import 'package:path/path.dart';

import '../../constants.dart';
import '../models/config_model.dart';
import '../utils/helpers.dart';

class ConfigService {
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
        environment: {},
      );
    }
  }

  static Future<void> updateSdkLink(FvmConfig config) async {
    await createLink(config.sdkSymlink, File(config.flutterSdkPath));
  }

  static Future<void> save(FvmConfig config) async {
    try {
      if (!await config.configFile.exists()) {
        await config.configFile.create(recursive: true);
      }
      await config.configFile.writeAsString(config.toJson());

      await updateSdkLink(config);
    } on Exception catch (err) {
      print(err);
      throw Exception('Could not save config changes');
    }
  }
}
