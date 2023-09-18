import 'dart:convert';
import 'dart:io';

import 'package:cli_config/cli_config.dart';

import '../../fvm.dart';

/// Service to manage FVM Config
class ConfigRepository {
  ConfigRepository._();

  static EnvConfig loadEnv({
    List<String>? commandLineArgs,
  }) {
    final config = Config.fromConfigFileContents(
      // Empty as not only on the environment
      commandLineDefines: [],
      environment: Platform.environment,
    );

    final fvmPath = config.optionalPath(ConfigVar.fvmPath.configName);
    final gitCachePath = config.optionalPath(ConfigVar.gitCachePath.configName);
    final gitCache = config.optionalBool(ConfigVar.gitCache.configName);
    final fvmConfigPath =
        config.optionalPath(ConfigVar.fvmConfigPath.configName);
    final flutterRepoUrl = config.optionalString(
      ConfigVar.flutterRepo.configName,
    );

    return EnvConfig(
      fvmPath: fvmPath?.path,
      fvmConfigPath: fvmConfigPath?.path,
      gitCache: gitCache,
      gitCachePath: gitCachePath?.path,
      flutterRepoUrl: flutterRepoUrl,
    );
  }

  static EnvConfig? fromFile(String path) {
    final configFile = File(path);
    if (configFile.existsSync()) {
      final map = json.decode(configFile.readAsStringSync());
      return EnvConfig.fromMap(map as Map<String, dynamic>);
    }
    return null;
  }
}
