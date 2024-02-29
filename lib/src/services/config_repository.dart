import 'dart:io';

import '../models/config_model.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';
import '../utils/pretty_json.dart';

const String flutterGitUrl = 'FLUTTER_GIT_URL';

/// Service to manage FVM Config
class ConfigRepository {
  const ConfigRepository._();

  static AppConfig loadFile() {
    final appConfig = AppConfig.loadFromPath(_configPath);
    if (appConfig != null) return appConfig;

    return AppConfig.empty();
  }

  static void save(AppConfig config) {
    final jsonContents = prettyJson(config.toMap());

    _configPath.file.write(jsonContents);
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

    final config = Config.empty();

    // Default to Flutter's environment variable if present; can still be overridden
    if (environments.containsKey(flutterGitUrl)) {
      config.flutterUrl = environments[flutterGitUrl];
    }

    for (final variable in ConfigKeys.values) {
      final value = environments[variable.envKey];
      final legacyFvmHome = environments['FVM_HOME'];

      if (variable == ConfigKeys.cachePath) {
        config.cachePath = value ?? legacyFvmHome;
      }

      if (value == null) continue;

      if (variable == ConfigKeys.useGitCache) {
        config.useGitCache = stringToBool(value);
      }

      if (variable == ConfigKeys.gitCachePath) {
        config.gitCachePath = value;
      }

      if (variable == ConfigKeys.flutterUrl) {
        config.flutterUrl = value;
      }

      if (variable == ConfigKeys.priviledgedAccess) {
        config.priviledgedAccess = stringToBool(value);
      }

      if (variable == ConfigKeys.runPubGetOnSdkChanges) {
        config.runPubGetOnSdkChanges = stringToBool(value);
      }
    }

    return config;
  }

  static String get _configPath => kAppConfigFile;
}
