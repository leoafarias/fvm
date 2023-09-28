// Use just for reference, should not change

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/change_case.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:fvm/src/utils/pretty_json.dart';

class ConfigKeys {
  final String key;

  const ConfigKeys(this.key);

  @override
  operator ==(other) => other is ConfigKeys && other.key == key;

  @override
  int get hashCode => key.hashCode;

  ChangeCase get _recase => ChangeCase(key);

  static const ConfigKeys cachePath = ConfigKeys('cache_path');
  static const ConfigKeys useGitCache = ConfigKeys('git_cache');
  static const ConfigKeys gitCachePath = ConfigKeys('git_cache_path');
  static const ConfigKeys flutterUrl = ConfigKeys('flutter_url');

  String get envKey => 'FVM_${_recase.constantCase}';
  String get paramKey => _recase.paramCase;
  String get propKey => _recase.camelCase;

  static const values = <ConfigKeys>[
    cachePath,
    useGitCache,
    gitCachePath,
    flutterUrl
  ];

  static ConfigKeys fromName(String name) {
    return values.firstWhere((e) => e.key == name);
  }

  static argResultsToMap(ArgResults argResults) {
    final configMap = <String, dynamic>{};

    for (final key in values) {
      final value = argResults[key.paramKey];
      if (value != null) {
        configMap[key.propKey] = value;
      }
    }

    return configMap;
  }

  static injectArgParser(ArgParser argParser) {
    final configKeysFuncs = {
      ConfigKeys.cachePath.key: () {
        argParser.addOption(
          ConfigKeys.cachePath.paramKey,
          help: 'Path where $kPackageName will cache versions',
        );
      },
      ConfigKeys.useGitCache.key: () {
        argParser.addFlag(
          ConfigKeys.useGitCache.paramKey,
          help:
              'Enable/Disable git cache globally, which is used for faster version installs.',
          negatable: true,
        );
      },
      ConfigKeys.gitCachePath.key: () {
        argParser.addOption(
          ConfigKeys.gitCachePath.paramKey,
          help: 'Path where local Git reference cache is stored',
        );
      },
      ConfigKeys.flutterUrl.key: () {
        argParser.addOption(
          ConfigKeys.flutterUrl.paramKey,
          help: 'Flutter repository Git URL to clone from',
        );
      },
    };

    for (final key in values) {
      configKeysFuncs[key.key]?.call();
    }
  }
}

class Config {
  // If should use gitCache
  final bool? useGitCache;

  final String? gitCachePath;

  /// Flutter repo url
  final String? flutterUrl;

  /// Directory where FVM is stored
  final String? cachePath;

  /// Constructor
  const Config({
    required this.cachePath,
    required this.useGitCache,
    required this.gitCachePath,
    required this.flutterUrl,
  });

  factory Config.empty() {
    return Config(
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
    );
  }

  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      cachePath: map[ConfigKeys.cachePath.propKey] as String?,
      useGitCache: map[ConfigKeys.useGitCache.propKey] as bool?,
      gitCachePath: map[ConfigKeys.gitCachePath.propKey] as String?,
      flutterUrl: map[ConfigKeys.flutterUrl.propKey] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (cachePath != null) ConfigKeys.cachePath.propKey: cachePath,
      if (useGitCache != null) ConfigKeys.useGitCache.propKey: useGitCache,
      if (gitCachePath != null) ConfigKeys.gitCachePath.propKey: gitCachePath,
      if (flutterUrl != null) ConfigKeys.flutterUrl.propKey: flutterUrl,
    };
  }
}

/// App config
class AppConfig extends Config {
  /// Disables update notification
  final bool? disableUpdate;
  final DateTime? lastUpdateCheck;

  /// Constructor
  const AppConfig({
    required this.disableUpdate,
    required this.lastUpdateCheck,
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
  });

  factory AppConfig.empty() {
    return AppConfig(
      disableUpdate: null,
      lastUpdateCheck: null,
      cachePath: null,
      useGitCache: null,
      gitCachePath: null,
      flutterUrl: null,
    );
  }

  static AppConfig? loadFromPath(String path) {
    final configFile = File(path);

    return configFile.existsSync()
        ? AppConfig.fromJson(configFile.readAsStringSync())
        : null;
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    final envConfig = Config.fromMap(map);
    return AppConfig(
      cachePath: envConfig.cachePath,
      gitCachePath: envConfig.gitCachePath,
      flutterUrl: envConfig.flutterUrl,
      useGitCache: envConfig.useGitCache,
      disableUpdate: map['disableUpdate'] as bool?,
      lastUpdateCheck: map['lastUpdateCheck'] != null
          ? DateTime.parse(map['lastUpdateCheck'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      if (disableUpdate != null) 'disableUpdate': disableUpdate,
      if (lastUpdateCheck != null)
        'lastUpdateCheck': lastUpdateCheck?.toIso8601String(),
    };
  }

  factory AppConfig.fromJson(String source) {
    return AppConfig.fromMap(json.decode(source) as Map<String, dynamic>);
  }

  AppConfig copyWith({
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
    bool? disableUpdate,
    DateTime? lastUpdateCheck,
  }) {
    return AppConfig(
      cachePath: cachePath ?? this.cachePath,
      useGitCache: useGitCache ?? this.useGitCache,
      gitCachePath: gitCachePath ?? this.gitCachePath,
      flutterUrl: flutterUrl ?? this.flutterUrl,
      disableUpdate: disableUpdate ?? this.disableUpdate,
      lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
    );
  }

  AppConfig merge(AppConfig? config) {
    return copyWith(
      cachePath: config?.cachePath,
      useGitCache: config?.useGitCache,
      gitCachePath: config?.gitCachePath,
      flutterUrl: config?.flutterUrl,
      disableUpdate: config?.disableUpdate,
      lastUpdateCheck: config?.lastUpdateCheck,
    );
  }

  void save(String path) {
    final jsonContents = prettyJson(toMap());

    path.write(jsonContents);
  }
}

/// Project config
class ProjectConfig extends Config {
  /// Flutter SDK version configured
  String? flutterSdkVersion;

  /// Flavors configured
  Map<String, String>? flavors;

  /// Returns true if has flavors
  bool? unmanagedVscode;

  /// Constructor
  ProjectConfig({
    super.cachePath,
    super.useGitCache,
    super.gitCachePath,
    super.flutterUrl,
    this.flutterSdkVersion,
    this.flavors,
    this.unmanagedVscode,
  });

  /// Returns ConfigDto from a map
  factory ProjectConfig.fromMap(Map<String, dynamic> map) {
    final envConfig = Config.fromMap(map);
    return ProjectConfig(
      cachePath: envConfig.cachePath,
      gitCachePath: envConfig.gitCachePath,
      flutterUrl: envConfig.flutterUrl,
      useGitCache: envConfig.useGitCache,
      flutterSdkVersion: map['flutterSdkVersion'] ?? map['flutter'] as String?,
      unmanagedVscode: map['unmanagedVscode'] as bool?,
      flavors: map['flavors'] != null
          ? Map<String, String>.from(map['flavors'] as Map)
          : null,
    );
  }

  /// Returns ConfigDto from a json string
  factory ProjectConfig.fromJson(String source) =>
      ProjectConfig.fromMap(json.decode(source) as Map<String, dynamic>);

  static ProjectConfig? loadFromPath(String path) {
    final configFile = File(path);

    return configFile.existsSync()
        ? ProjectConfig.fromJson(configFile.readAsStringSync())
        : null;
  }

  /// It checks each property for null prior to adding it to the map.
  /// This is to ensure the returned map doesn't contain any null values.
  /// Also, if [flavors] is not empty it adds it to the map.

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ...super.toMap(),
      if (flutterSdkVersion != null) 'flutter': flutterSdkVersion,
      if (unmanagedVscode != null) 'unmanagedVscode': unmanagedVscode,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }

  ProjectConfig merge(ProjectConfig config) {
    return copyWith(
      cachePath: config.cachePath,
      useGitCache: config.useGitCache,
      gitCachePath: config.gitCachePath,
      flutterUrl: config.flutterUrl,
      flutterSdkVersion: config.flutterSdkVersion,
      flavors: config.flavors,
      unmanagedVscode: config.unmanagedVscode,
    );
  }

  /// returns just the Config
  Config get config => Config(
        cachePath: cachePath,
        useGitCache: useGitCache,
        gitCachePath: gitCachePath,
        flutterUrl: flutterUrl,
      );

  /// Copies current config and overrides with new values
  /// Returns a new ConfigDto

  ProjectConfig copyWith({
    String? cachePath,
    String? fvmVersionsDir,
    String? flutterSdkVersion,
    bool? useGitCache,
    bool? unmanagedVscode,
    String? gitCachePath,
    String? flutterUrl,
    Map<String, String>? flavors,
    bool? disableUpdate,
  }) {
    // merge map and override the keys
    final mergedFlavors = <String, String>{
      if (this.flavors != null) ...this.flavors!,
      if (flavors != null) ...flavors,
    };

    return ProjectConfig(
      cachePath: cachePath ?? cachePath,
      flutterSdkVersion: flutterSdkVersion ?? this.flutterSdkVersion,
      flavors: mergedFlavors,
      unmanagedVscode: unmanagedVscode ?? this.unmanagedVscode,
      useGitCache: useGitCache ?? this.useGitCache,
      gitCachePath: gitCachePath ?? this.gitCachePath,
      flutterUrl: flutterUrl ?? this.flutterUrl,
    );
  }

  void save(String path) {
    final jsonContents = prettyJson(toMap());

    path.write(jsonContents);
  }
}
