import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/helpers.dart';

import '../../fvm.dart';

/// Service to manage FVM Config
class ConfigRepository {
  const ConfigRepository._();

  static AppConfig loadFile() {
    final appConfig = AppConfig.loadFromPath(_configPath);
    if (appConfig != null) return appConfig;
    return AppConfig.empty();
  }

  static void save(AppConfig config) {
    config.save(_configPath);
  }

  static void update({
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
    bool? disableUpdateCheck,
    DateTime? lastUpdateCheck,
  }) {
    final currentConfig = loadFile();
    final newConfig = currentConfig.copyWith(
      cachePath: cachePath,
      useGitCache: useGitCache,
      gitCachePath: gitCachePath,
      flutterUrl: flutterUrl,
      disableUpdateCheck: disableUpdateCheck,
      lastUpdateCheck: lastUpdateCheck,
    );
    save(newConfig);
  }

  static Config loadEnv() {
    final environments = Platform.environment;

    bool? gitCache;
    String? gitCachePath;
    String? flutterUrl;
    String? cachePath;
    bool? priviledgedAccess;

    for (final variable in ConfigKeys.values) {
      final value = environments[variable.envKey];
      final legacyFvmHome = environments['FVM_HOME'];

      if (variable == ConfigKeys.cachePath) {
        cachePath = value ?? legacyFvmHome;
        break;
      }

      if (value == null) continue;

      if (variable == ConfigKeys.useGitCache) {
        gitCache = stringToBool(value);
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

      if (variable == ConfigKeys.priviledgedAccess) {
        priviledgedAccess = stringToBool(value);
        break;
      }
    }

    return Config(
      cachePath: cachePath,
      useGitCache: gitCache,
      gitCachePath: gitCachePath,
      flutterUrl: flutterUrl,
      priviledgedAccess: priviledgedAccess,
    );
  }

  static String get _configPath => kAppConfigFile;
}
