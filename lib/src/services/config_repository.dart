import 'dart:io';

import 'package:fvm/constants.dart';

import '../../fvm.dart';

/// Service to manage FVM Config
class ConfigRepository {
  ConfigRepository._();

  static String get _configPath => kAppConfigFile;

  static AppConfig loadFile() {
    final appConfig = AppConfig.loadFromPath(_configPath);
    if (appConfig != null) return appConfig;
    return AppConfig.empty();
  }

  static void save(AppConfig config) {
    config.save(_configPath);
  }

  static Config loadEnv() {
    final environments = Platform.environment;

    bool? gitCache;
    String? gitCachePath;
    String? flutterUrl;
    String? cachePath;

    for (final variable in ConfigKeys.values) {
      final value = environments[variable.envKey];
      if (value == null) continue;

      if (variable == ConfigKeys.cachePath) {
        cachePath = value;
        break;
      }

      if (variable == ConfigKeys.useGitCache) {
        gitCache = value == 'true';
        break;
      }

      if (variable == ConfigKeys.gitCachePath) {
        gitCachePath = value;
        break;
      }

      if (variable == ConfigKeys.flutterUrl) {
        flutterUrl = value;
        break;
      }
    }

    return Config(
      cachePath: cachePath,
      useGitCache: gitCache,
      gitCachePath: gitCachePath,
      flutterUrl: flutterUrl,
    );
  }
}
