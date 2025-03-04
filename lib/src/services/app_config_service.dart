import 'dart:io';

import '../models/config_model.dart';
import '../utils/helpers.dart';

const String flutterGitUrl = 'FLUTTER_GIT_URL';

/// Service to manage FVM Config
class AppConfigService {
  const AppConfigService._();

  static AppConfig buildConfig({AppConfig? overrides}) {
    return createAppConfig(
      globalConfig: LocalAppConfig.read(),
      envConfig: _loadEnvironment(),
      projectConfig: _loadProjectConfig(),
      overrides: overrides,
    );
  }

  static AppConfig createAppConfig({
    required LocalAppConfig globalConfig,
    required Config? envConfig,
    required ProjectConfig? projectConfig,
    required AppConfig? overrides,
  }) {
    final validConfigs =
        [globalConfig, envConfig, projectConfig, overrides].whereType<Config>();

    var appConfig = AppConfig();

    for (final config in validConfigs) {
      if (config is AppConfig) {
        appConfig = appConfig.copyWith.$merge(config);
      }
      if (config is LocalAppConfig) {
        appConfig = appConfig.copyWith.$merge(
          AppConfig(
            cachePath: config.cachePath,
            useGitCache: config.useGitCache,
            gitCachePath: config.gitCachePath,
            flutterUrl: config.flutterUrl,
            privilegedAccess: config.privilegedAccess,
            runPubGetOnSdkChanges: config.runPubGetOnSdkChanges,
            updateVscodeSettings: config.updateVscodeSettings,
            updateGitIgnore: config.updateGitIgnore,
            disableUpdateCheck: config.disableUpdateCheck,
            lastUpdateCheck: config.lastUpdateCheck,
            forks: config.forks,
          ),
        );
      }

      if (config is FileConfig) {
        appConfig = appConfig.copyWith.$merge(
          AppConfig(
            cachePath: config.cachePath,
            useGitCache: config.useGitCache,
            gitCachePath: config.gitCachePath,
            flutterUrl: config.flutterUrl,
            privilegedAccess: config.privilegedAccess,
            runPubGetOnSdkChanges: config.runPubGetOnSdkChanges,
            updateVscodeSettings: config.updateVscodeSettings,
            updateGitIgnore: config.updateGitIgnore,
          ),
        );
      }

      appConfig = appConfig.copyWith.$merge(
        AppConfig(
          cachePath: config.cachePath,
          useGitCache: config.useGitCache,
          gitCachePath: config.gitCachePath,
          flutterUrl: config.flutterUrl,
        ),
      );
    }

    return appConfig;
  }

  static ProjectConfig? _loadProjectConfig() {
    return lookUpDirectoryAncestor(
      directory: Directory.current,
      validate: ProjectConfig.loadFromDirectory,
    );
  }

  static Config _loadEnvironment() {
    final environments = Platform.environment;

    var config = EnvConfig();
    // Default to Flutter's environment variable if present; can still be overridden
    if (environments.containsKey(flutterGitUrl)) {
      config = config.copyWith(flutterUrl: environments[flutterGitUrl]);
    }

    final configSetters = {
      ConfigOptions.cachePath: (String value) =>
          config = config.copyWith(cachePath: value),
      ConfigOptions.useGitCache: (String value) =>
          config = config.copyWith(useGitCache: stringToBool(value)),
      ConfigOptions.gitCachePath: (String value) =>
          config = config.copyWith(gitCachePath: value),
      ConfigOptions.flutterUrl: (String value) =>
          config = config.copyWith(flutterUrl: value),
    };
    // Apply each environment variable if it exists
    for (final envVar in ConfigOptions.values) {
      final value = environments[envVar.envKey];
      if (value != null) {
        configSetters[envVar]?.call(value);
      }
    }

    return config;
  }
}
