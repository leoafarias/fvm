import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/config_model.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';
import '../utils/pretty_json.dart';

const String flutterGitUrl = 'FLUTTER_GIT_URL';

/// Service to manage FVM Config
class ConfigRepository {
  const ConfigRepository._();

  static AppConfig load({AppConfig? overrides}) {
    final appConfig = loadAppConfig();
    final envConfig = _loadEnvironment();
    final projectConfig = _loadProjectConfig();

    return appConfig.merge(envConfig).merge(projectConfig).merge(overrides);
  }

  static AppConfig loadAppConfig() {
    final appConfig = AppConfig.loadFromPath(_configPath);
    if (appConfig != null) return appConfig;

    return AppConfig.empty();
  }

  static void save(AppConfig config) {
    final jsonContents = prettyJson(config.toMap());

    _configPath.file.write(jsonContents);
  }

  static ProjectConfig? _loadProjectConfig({Directory? directory}) {
    // Get directory, defined root or current
    directory ??= Directory.current;

    // Checks if the directory is root
    final isRootDir = path.rootPrefix(directory.path) == directory.path;

    // Gets project from directory
    final projectConfig = ProjectConfig.loadFromPath(directory.path);

    // If project has a config return it
    if (projectConfig != null) return projectConfig;

    // Return working directory if has reached root
    if (isRootDir) return null;

    return _loadProjectConfig(directory: directory.parent);
  }

  static void update({
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
    bool? disableUpdateCheck,
    DateTime? lastUpdateCheck,
    bool? priviledgedAccess,
  }) {
    final currentConfig = loadAppConfig();
    final newConfig = currentConfig.copyWith(
      cachePath: cachePath,
      disableUpdateCheck: disableUpdateCheck,
      flutterUrl: flutterUrl,
      gitCachePath: gitCachePath,
      lastUpdateCheck: lastUpdateCheck,
      priviledgedAccess: priviledgedAccess,
      useGitCache: useGitCache,
    );
    save(newConfig);
  }

  static EnvConfig _loadEnvironment() {
    final environments = Platform.environment;

    var config = EnvConfig.empty();

    // Default to Flutter's environment variable if present; can still be overridden
    if (environments.containsKey(flutterGitUrl)) {
      config = config.copyWith(flutterUrl: environments[flutterGitUrl]);
    }

    for (final envVar in ConfigKeys.values) {
      final value = environments[envVar.envKey];
      final legacyFvmHome = environments['FVM_HOME'];

      if (envVar == ConfigKeys.cachePath) {
        config = config.copyWith(cachePath: value ?? legacyFvmHome);
      }

      if (value == null) continue;

      if (envVar == ConfigKeys.useGitCache) {
        config = config.copyWith(useGitCache: stringToBool(value));
      }

      if (envVar == ConfigKeys.gitCachePath) {
        config = config.copyWith(gitCachePath: value);
      }

      if (envVar == ConfigKeys.flutterUrl) {
        config = config.copyWith(flutterUrl: value);
      }
    }

    return config;
  }

  static String get _configPath => kAppConfigFile;
}
