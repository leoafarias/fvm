import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';

import '../../fvm.dart';

/// Service to manage FVM Config
class ConfigRepository {
  ConfigRepository._();

  static File get _configFile => File(kAppConfigHome);

  static EnvConfig load() {
    final fileConfig = _fromFile();

    final envConfig = _fromEnv();

    return fileConfig.merge(envConfig);
  }

  static void save(
    EnvConfig config,
  ) {
    final currentConfig = load();
    final mergedConfig = currentConfig.merge(config);

    if (!_configFile.existsSync()) {
      _configFile.createSync(recursive: true);
    }

    final configMap = mergedConfig.toMap();
    _configFile.writeAsStringSync(json.encode(configMap));
  }

  static EnvConfig _fromFile() {
    if (_configFile.existsSync()) {
      final map = json.decode(_configFile.readAsStringSync());
      return EnvConfig.fromMap(map as Map<String, dynamic>);
    }
    return EnvConfig();
  }

  static EnvConfig _fromEnv() {
    final environments = Platform.environment;

    EnvConfig envConfig = EnvConfig();

    for (final variable in ConfigVariable.values) {
      final value = environments[variable.envName];
      if (value == null) continue;

      switch (variable) {
        case ConfigVariable.fvmPath:
          envConfig = envConfig.copyWith(fvmPath: value);
          break;
        case ConfigVariable.gitCache:
          envConfig = envConfig.copyWith(gitCache: value == 'true');
          break;
        case ConfigVariable.gitCachePath:
          envConfig = envConfig.copyWith(gitCachePath: value);
          break;
        case ConfigVariable.flutterRepo:
          envConfig = envConfig.copyWith(flutterRepoUrl: value);
          break;
      }
    }

    return envConfig;
  }
}
