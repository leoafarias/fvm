// Use just for reference, should not change

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_mappable/dart_mappable.dart';

import '../utils/change_case.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/pretty_json.dart';

part 'config_model.mapper.dart';

@MappableEnum()
enum ConfigKeys {
  cachePath(description: 'Path where $kPackageName will cache versions'),
  useGitCache(
    description:
        'Enable/Disable git cache globally, which is used for faster version installs.',
  ),
  gitCachePath(description: 'Path where local Git reference cache is stored'),
  flutterUrl(description: 'Flutter repository Git URL to clone from'),

  privilegedAccess(description: 'Enable/Disable privileged access for FVM');

  const ConfigKeys({required this.description});

  final String description;

  ChangeCase get _recase => ChangeCase(name);

  String get envKey => 'FVM_${_recase.constantCase}';

  String get paramKey => _recase.paramCase;

  String get propKey => _recase.camelCase;

  static injectArgParser(ArgParser argParser) {
    final configKeysFunctions = {
      ConfigKeys.cachePath: () {
        argParser.addOption(
          ConfigKeys.cachePath.paramKey,
          help: ConfigKeys.cachePath.description,
        );
      },
      ConfigKeys.useGitCache: () {
        argParser.addFlag(
          ConfigKeys.useGitCache.paramKey,
          help: ConfigKeys.useGitCache.description,
          defaultsTo: true,
          negatable: true,
        );
      },
      ConfigKeys.gitCachePath: () {
        argParser.addOption(
          ConfigKeys.gitCachePath.paramKey,
          help: ConfigKeys.gitCachePath.description,
        );
      },
      ConfigKeys.flutterUrl: () {
        argParser.addOption(
          ConfigKeys.flutterUrl.paramKey,
          help: ConfigKeys.flutterUrl.description,
        );
      },
      ConfigKeys.privilegedAccess: () {
        argParser.addFlag(
          ConfigKeys.privilegedAccess.paramKey,
          help: ConfigKeys.privilegedAccess.description,
          defaultsTo: true,
          negatable: true,
        );
      },
    };

    for (final key in ConfigKeys.values) {
      configKeysFunctions[key]?.call();
    }
  }
}

@MappableClass(ignoreNull: true)
abstract class BaseConfig with BaseConfigMappable {
  // If should use gitCache
  final bool? useGitCache;

  final String? gitCachePath;

  /// Flutter repo url
  final String? flutterUrl;

  /// Directory where FVM is stored
  final String? cachePath;

  /// Constructor
  const BaseConfig({
    required this.cachePath,
    required this.useGitCache,
    required this.gitCachePath,
    required this.flutterUrl,
  });
}

@MappableClass(ignoreNull: true)
class EnvConfig extends BaseConfig with EnvConfigMappable {
  static final fromMap = EnvConfigMapper.fromMap;
  static final fromJson = EnvConfigMapper.fromJson;

  const EnvConfig({
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
  });

  static EnvConfig empty() {
    return EnvConfig(
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
    );
  }
}

@MappableClass(ignoreNull: true)
class FileConfig extends BaseConfig with FileConfigMappable {
  /// If Vscode settings is not managed by FVM
  final bool? updateVscodeSettings;

  /// If FVM should update .gitignore
  final bool? updateGitIgnore;

  final bool? runPubGetOnSdkChanges;

  /// If FVM should run with privileged access
  final bool? privilegedAccess;

  static final fromMap = FileConfigMapper.fromMap;
  static final fromJson = FileConfigMapper.fromJson;

  /// Constructor
  const FileConfig({
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
    required this.privilegedAccess,
    required this.runPubGetOnSdkChanges,
    required this.updateVscodeSettings,
    required this.updateGitIgnore,
  });

  void save(String path) {
    final jsonContents = prettyJson(toMap());

    path.file.write(jsonContents);
  }
}

@MappableClass(ignoreNull: true)
class AppConfig extends FileConfig with AppConfigMappable {
  /// Disables update notification

  final bool? disableUpdateCheck;
  final DateTime? lastUpdateCheck;

  static final fromMap = AppConfigMapper.fromMap;
  static final fromJson = AppConfigMapper.fromJson;

  /// Constructor
  const AppConfig({
    this.disableUpdateCheck,
    this.lastUpdateCheck,
    super.cachePath,
    super.useGitCache,
    super.gitCachePath,
    super.flutterUrl,
    super.privilegedAccess,
    super.runPubGetOnSdkChanges,
    super.updateVscodeSettings,
    super.updateGitIgnore,
  });

  static AppConfig empty() {
    return AppConfig(
      disableUpdateCheck: null,
      lastUpdateCheck: null,
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
      privilegedAccess: null,
      runPubGetOnSdkChanges: null,
      updateVscodeSettings: null,
      updateGitIgnore: null,
    );
  }

  static AppConfig? loadFromPath(String path) {
    final configFile = File(path);

    return configFile.existsSync()
        ? AppConfig.fromJson(configFile.readAsStringSync())
        : null;
  }

  AppConfig merge(BaseConfig? config) {
    if (config == null) return this;
    AppConfig newConfig;
    if (config is EnvConfig) {
      newConfig = AppConfig(
        disableUpdateCheck: disableUpdateCheck,
        cachePath: config.cachePath,
        useGitCache: config.useGitCache,
        gitCachePath: config.gitCachePath,
        flutterUrl: config.flutterUrl,
      );
    }

    if (config is ProjectConfig) {
      newConfig = AppConfig(
        cachePath: config.cachePath,
        useGitCache: config.useGitCache,
        gitCachePath: config.gitCachePath,
        flutterUrl: config.flutterUrl,
        privilegedAccess: config.privilegedAccess,
        runPubGetOnSdkChanges: config.runPubGetOnSdkChanges,
        updateVscodeSettings: config.updateVscodeSettings,
        updateGitIgnore: config.updateGitIgnore,
      );
    }

    if (config is AppConfig) {
      return copyWith.$merge(config);
    }

    newConfig = AppConfig(
      cachePath: config.cachePath,
      useGitCache: config.useGitCache,
      gitCachePath: config.gitCachePath,
      flutterUrl: config.flutterUrl,
    );

    return copyWith.$merge(newConfig);
  }
}

/// Project config
@MappableClass(ignoreNull: true)
class ProjectConfig extends FileConfig with ProjectConfigMappable {
  final String? flutter;
  final Map<String, String>? flavors;

  /// Constructor
  const ProjectConfig({
    this.flutter,
    this.flavors,
    super.cachePath,
    super.useGitCache,
    super.gitCachePath,
    super.flutterUrl,
    super.privilegedAccess,
    super.runPubGetOnSdkChanges,
    super.updateVscodeSettings,
    super.updateGitIgnore,
  });

  static ProjectConfig empty() {
    return ProjectConfig(
      flutter: null,
      flavors: null,
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
      privilegedAccess: null,
      runPubGetOnSdkChanges: null,
      updateVscodeSettings: null,
      updateGitIgnore: null,
    );
  }

  static ProjectConfig? loadFromPath(String path) {
    final configFile = File(path);

    return configFile.existsSync()
        ? ProjectConfig.fromJson(configFile.readAsStringSync())
        : null;
  }

  static ProjectConfig fromJson(String json) {
    return ProjectConfig.fromMap(jsonDecode(json));
  }

  static ProjectConfig fromMap(Map<String, dynamic> map) {
    return ProjectConfigMapper.fromMap({
      ...map,
      'flutter': map['flutterSdkVersion'] ?? map['flutter'],
    });
  }

  Map<String, dynamic> toLegacyMap() {
    return {
      if (flutter != null) 'flutterSdkVersion': flutter,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }
}
