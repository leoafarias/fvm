import 'dart:io';

import 'package:cli_config/cli_config.dart';
import 'package:fvm/constants.dart';
import 'package:path/path.dart';

import '../../fvm.dart';

const _defaultFlutterRepoUrl = 'https://github.com/flutter/flutter.git';

/// Service to manage FVM Config
class ConfigRepository {
  ConfigRepository();

  static EnvConfig loadEnv({
    List<String>? commandLineArgs,
  }) {
    final argsConfig = Config.fromConfigFileContents(
      // Empty as not only on the environment
      fileContents: '{}',
      commandLineDefines: commandLineArgs ?? [],
      environment: Platform.environment,
    );

    // Empty as the default
    final envConfig = EnvConfig.fromConfig(argsConfig);

    final configPath = envConfig.fvmPath ?? applicationConfigHome();

    final storedConfig = EnvConfig.fromFile(configPath) ?? EnvConfig.empty();

    final fvmConfig = storedConfig.merge(envConfig);

    // Set defaults
    final fvmPath = fvmConfig.fvmPath ?? kFvmDirDefault;
    final flutterRepoUrl = fvmConfig.flutterRepoUrl ?? _defaultFlutterRepoUrl;
    final gitCache = fvmConfig.gitCache ?? true;
    final gitCachePath = fvmConfig.gitCachePath ?? join(fvmPath, 'cache.git');

    return EnvConfig(
      fvmPath: fvmPath,
      fvmConfigPath: configPath,
      gitCache: gitCache,
      gitCachePath: gitCachePath,
      flutterRepoUrl: flutterRepoUrl,
    );
  }
}
