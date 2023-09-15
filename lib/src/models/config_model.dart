import 'dart:convert';
import 'dart:io';

import 'package:cli_config/cli_config.dart';

// Use just for reference, should not change
const legacyVersionKey = 'flutterSdkVersion';

enum ConfigVar {
  fvmPath('fvmPath', 'fvm_path'),
  fvmConfigPath('fvmConfigPath', 'fvm_config_path'),
  flutterVersion('flutterSdkVersion', 'flutter_sdk_version'),
  gitCache('gitCache', 'git_cache'),
  flavors('flavors', 'flavors'),
  flutterRepo('flutterRepo', 'flutter_repo');

  const ConfigVar(
    this.name,
    this.configName,
  );

  final String name;
  final String configName;

  String get envName {
    final prefix = 'FVM_';
    String uppercaseEnv = name.toUpperCase();
    if (!configName.startsWith(prefix)) {
      uppercaseEnv = '$prefix$uppercaseEnv)';
    }

    return uppercaseEnv;
  }

  String get argName => configName.replaceAll('_', '-');

  factory ConfigVar.fromName(String name) {
    return ConfigVar.values.firstWhere((element) => element.name == name);
  }
}

/// FVM config dto
class ConfigDto {
  /// Flutter SDK version configured
  final String? flutterSdkVersion;

  // If should use gitCache
  final bool? gitCache;

  /// Flutter repo url
  final String? flutterRepoUrl;

  /// Directory where FVM is stored
  final String? fvmPath;

  /// Flavors configured
  Map<String, dynamic>? flavors;

  /// Constructor
  ConfigDto({
    this.fvmPath,
    this.flutterSdkVersion,
    this.flavors,
    this.gitCache,
    this.flutterRepoUrl,
  });

  /// Returns empty ConfigDto
  factory ConfigDto.empty() {
    return ConfigDto();
  }

  /// Returns ConfigDto  from [jsonString]
  factory ConfigDto.fromJson(String jsonString) {
    return ConfigDto.fromMap(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  factory ConfigDto.fromFile(String file) {
    return ConfigDto.fromJson(File(file).readAsStringSync());
  }

  factory ConfigDto.fromEnv({
    List<String>? args,
  }) {
    final envArgsConfig = Config.fromConfigFileContents(
      // Empty as not only on the environment
      fileContents: '{}',
      commandLineDefines: args ?? [],
      environment: Platform.environment,
    );

    return ConfigDto(
      fvmPath: envArgsConfig.optionalPath(ConfigVar.fvmPath.configName)?.path,
      gitCache: envArgsConfig.optionalBool(ConfigVar.gitCache.configName),
      flutterRepoUrl:
          envArgsConfig.optionalString(ConfigVar.flutterRepo.configName),
    );
  }

  /// Returns ConfigDto from a map
  factory ConfigDto.fromMap(Map<String, dynamic> map) {
    return ConfigDto(
      flutterSdkVersion: map[ConfigVar.flutterVersion.name] as String?,
      fvmPath: map[ConfigVar.fvmPath.name] as String?,
      gitCache: map[ConfigVar.gitCache.name] as bool?,
      flutterRepoUrl: map[ConfigVar.flutterRepo.name] as String?,
      flavors: map[ConfigVar.flavors.name] as Map<String, dynamic>?,
    );
  }

  /// It checks each property for null prior to adding it to the map.
  /// This is to ensure the returned map doesn't contain any null values.
  /// Also, if [flavors] is not empty it adds it to the map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ConfigVar.flutterVersion.name: flutterSdkVersion,
      if (fvmPath != null) ConfigVar.fvmPath.name: fvmPath,
      if (gitCache != null) ConfigVar.gitCache.name: gitCache,
      if (flutterRepoUrl != null) ConfigVar.flutterRepo.name: flutterRepoUrl,
      if (flavors != null && flavors!.isNotEmpty)
        ConfigVar.flavors.name: flavors,
    };
  }

  ConfigDto merge(ConfigDto config) {
    return copyWith(
      fvmPath: config.fvmPath,
      flutterSdkVersion: config.flutterSdkVersion,
      flavors: config.flavors,
      gitCache: config.gitCache,
      flutterRepoUrl: config.flutterRepoUrl,
    );
  }

  /// Copies current config and overrides with new values
  /// Returns a new ConfigDto
  ConfigDto copyWith({
    String? fvmPath,
    String? fvmVersionsDir,
    String? flutterSdkVersion,
    Map<String, dynamic>? flavors,
    bool? gitCache,
    String? flutterRepoUrl,
  }) {
    return ConfigDto(
      fvmPath: fvmPath ?? this.fvmPath,
      flutterSdkVersion: flutterSdkVersion ?? this.flutterSdkVersion,
      flavors: flavors ?? this.flavors,
      gitCache: gitCache ?? this.gitCache,
      flutterRepoUrl: flutterRepoUrl ?? flutterRepoUrl,
    );
  }
}
