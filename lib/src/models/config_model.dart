// Use just for reference, should not change

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

  priviledgedAccess(description: 'Enable/Disable priviledged access for FVM');

  const ConfigKeys({required this.description});

  final String description;

  ChangeCase get _recase => ChangeCase(toString());

  String get envKey => 'FVM_${_recase.constantCase}';

  String get paramKey => _recase.paramCase;

  String get propKey => _recase.camelCase;

  static injectArgParser(ArgParser argParser) {
    final configKeysFuncs = {
      ConfigKeys.cachePath: () {
        argParser.addOption(
          ConfigKeys.cachePath.paramKey,
          help: 'Path where $kPackageName will cache versions',
        );
      },
      ConfigKeys.useGitCache: () {
        argParser.addFlag(
          ConfigKeys.useGitCache.paramKey,
          help:
              'Enable/Disable git cache globally, which is used for faster version installs.',
          defaultsTo: true,
          negatable: true,
        );
      },
      ConfigKeys.gitCachePath: () {
        argParser.addOption(
          ConfigKeys.gitCachePath.paramKey,
          help: 'Path where local Git reference cache is stored',
        );
      },
      ConfigKeys.flutterUrl: () {
        argParser.addOption(
          ConfigKeys.flutterUrl.paramKey,
          help: 'Flutter repository Git URL to clone from',
        );
      },
      ConfigKeys.priviledgedAccess: () {
        argParser.addFlag(
          ConfigKeys.priviledgedAccess.paramKey,
          help: 'Enable/Disable priviledged access for FVM',
          defaultsTo: true,
          negatable: true,
        );
      },
    };

    for (final key in ConfigKeys.values) {
      configKeysFuncs[key]?.call();
    }
  }
}

@MappableClass()
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

@MappableClass()
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

@MappableClass()
class FileConfig extends BaseConfig with FileConfigMappable {
  /// If Vscode settings is not managed by FVM
  final bool? updateVscodeSettings;

  /// If FVM should update .gitignore
  final bool? updateGitIgnore;

  final bool? runPubGetOnSdkChanges;

  /// If FVM should run with priviledged access
  final bool? priviledgedAccess;

  static final fromMap = FileConfigMapper.fromMap;
  static final fromJson = FileConfigMapper.fromJson;

  /// Constructor
  const FileConfig({
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
    required this.priviledgedAccess,
    required this.runPubGetOnSdkChanges,
    required this.updateVscodeSettings,
    required this.updateGitIgnore,
  });

  void save(String path) {
    final jsonContents = prettyJson(toMap());

    path.file.write(jsonContents);
  }
}

@MappableClass()
class AppConfig extends FileConfig with AppConfigMappable {
  /// Disables update notification

  final bool? disableUpdateCheck;
  final DateTime? lastUpdateCheck;

  static final fromMap = AppConfigMapper.fromMap;
  static final fromJson = AppConfigMapper.fromJson;

  /// Constructor
  const AppConfig({
    required this.disableUpdateCheck,
    required this.lastUpdateCheck,
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
    required super.priviledgedAccess,
    required super.runPubGetOnSdkChanges,
    required super.updateVscodeSettings,
    required super.updateGitIgnore,
  });

  static AppConfig empty() {
    return AppConfig(
      disableUpdateCheck: null,
      lastUpdateCheck: null,
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
      priviledgedAccess: null,
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
    if (config is EnvConfig) {
      return copyWith(
        cachePath: config.cachePath,
        disableUpdateCheck: disableUpdateCheck,
        flutterUrl: config.flutterUrl,
        gitCachePath: config.gitCachePath,
        useGitCache: config.useGitCache,
      );
    }

    if (config is ProjectConfig) {
      return copyWith(
        cachePath: config.cachePath,
        flutterUrl: config.flutterUrl,
        gitCachePath: config.gitCachePath,
        priviledgedAccess: config.priviledgedAccess,
        runPubGetOnSdkChanges: config.runPubGetOnSdkChanges,
        updateGitIgnore: config.updateGitIgnore,
        updateVscodeSettings: config.updateVscodeSettings,
        useGitCache: config.useGitCache,
      );
    }

    if (config is AppConfig) {
      return copyWith(
        cachePath: config.cachePath,
        disableUpdateCheck: config.disableUpdateCheck,
        flutterUrl: config.flutterUrl,
        gitCachePath: config.gitCachePath,
        lastUpdateCheck: config.lastUpdateCheck,
        priviledgedAccess: config.priviledgedAccess,
        runPubGetOnSdkChanges: config.runPubGetOnSdkChanges,
        updateGitIgnore: config.updateGitIgnore,
        updateVscodeSettings: config.updateVscodeSettings,
        useGitCache: config.useGitCache,
      );
    }

    return copyWith(
      cachePath: config.cachePath,
      flutterUrl: config.flutterUrl,
      gitCachePath: config.gitCachePath,
      useGitCache: config.useGitCache,
    );
  }
}

/// Project config
@MappableClass()
class ProjectConfig extends FileConfig with ProjectConfigMappable {
  final String? flutterSdkVersion;
  final Map<String, String>? flavors;

  static final fromJson = ProjectConfigMapper.fromJson;

  /// Constructor
  const ProjectConfig({
    required this.flutterSdkVersion,
    required this.flavors,
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
    required super.priviledgedAccess,
    required super.runPubGetOnSdkChanges,
    required super.updateVscodeSettings,
    required super.updateGitIgnore,
  });

  static ProjectConfig empty() {
    return ProjectConfig(
      flutterSdkVersion: null,
      flavors: null,
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
      priviledgedAccess: null,
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

  ProjectConfig fromMap(Map<String, dynamic> map) {
    return ProjectConfigMapper.fromMap({
      ...map,
      'flutterSdkVersion': map['flutterSdkVersion'] ?? map['flutter'],
    });
  }

  Map<String, dynamic> toLegacyMap() {
    return {
      if (flutterSdkVersion != null) 'flutterSdkVersion': flutterSdkVersion,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }
}
