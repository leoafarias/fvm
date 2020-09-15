import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/flutter_project/fvm_config.model.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:path/path.dart';

class FvmConfigRepo {
  static Future<FvmConfig> read(Directory directory) async {
    final configDir = Directory(join(directory.path, kFvmDirName));
    final configFile = File(join(configDir.path, kFvmConfigFileName));

    try {
      final jsonString = await configFile.readAsString();
      final json = await jsonDecode(jsonString) as Map<String, dynamic>;
      return FvmConfig(
        configDir: configDir,
        flutterSdkVersion: json['flutterSdkVersion'] as String,
      );
    } on Exception {
      return FvmConfig(
        configDir: configDir,
        flutterSdkVersion: null,
      );
    }
  }

  static Future<void> _createSdkLink(FvmConfig config) async {
    await createLink(config.sdkSymlink, File(config.flutterSdkPath));
  }

  static Future<void> save(FvmConfig config) async {
    try {
      if (!await config.configFile.exists()) {
        await config.configFile.create(recursive: true);
      }
      await config.configFile.writeAsString(config.toJson());

      await _createSdkLink(config);
    } on Exception {
      throw Exception('Could not save config changes');
    }
  }
}
