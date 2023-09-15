import 'dart:convert';
import 'dart:io';

import 'package:cli_config/cli_config.dart';

class FvmConfig extends ConfigDto {
  final String configPath;

  FvmConfig({
    required this.configPath,
    required String super.flutterSdkVersion,
    required String super.fvmDir,
    required String super.fvmVersionsDir,
    required String super.gitCacheDir,
    required bool super.gitCacheEnabled,
    required String super.flutterRepoUrl,
    required Map<String, dynamic> super.flavors,
  });
}

/// FVM config dto
class ConfigDto {
  /// Flutter SDK version configured
  final String? flutterSdkVersion;

  // If should use gitCache
  final bool? gitCacheEnabled;

  /// Git cache directory
  final String? gitCacheDir;

  /// Flutter repo url
  final String? flutterRepoUrl;

  /// Directory where FVM is stored
  final String? fvmDir;

  /// Directory where FVM versions are stored
  final String? fvmVersionsDir;

  /// Flavors configured
  Map<String, dynamic>? flavors;

  /// Constructor
  ConfigDto({
    this.fvmDir,
    this.fvmVersionsDir,
    this.flutterSdkVersion,
    this.flavors,
    this.gitCacheEnabled,
    this.gitCacheDir,
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

  factory ConfigDto.fromConfig({
    String? configPath,
    List<String>? args,
  }) {
    String? fileContents;

    if (configPath != null) {
      final file = File(configPath);
      if (file.existsSync()) {
        fileContents = file.readAsStringSync();
      }
    }

    final config = Config.fromConfigFileContents(
      fileContents: fileContents,
      commandLineDefines: args ?? [],
    );
    return ConfigDto._fromConfig(config);
  }

  factory ConfigDto._fromConfig(Config config) {
    final fvmDir = config.optionalPath('fvmDir')?.path;
    final fvmVersionsDir = config.optionalPath('fvmVersionsDir')?.path;
    final flutterSdkVersion = config.optionalString('flutterSdkVersion');
    final gitCacheEnabled = config.optionalBool('gitCacheEnabled');
    final gitCacheDir = config.optionalPath('gitCacheDir')?.path;
    final flutterRepoUrl = config.optionalString('flutterRepoUrl');

    final flavorsMap = <String, dynamic>{};

    return ConfigDto(
      fvmDir: fvmDir,
      fvmVersionsDir: fvmVersionsDir,
      flutterSdkVersion: flutterSdkVersion,
      flavors: flavorsMap,
      gitCacheEnabled: gitCacheEnabled,
      gitCacheDir: gitCacheDir,
      flutterRepoUrl: flutterRepoUrl,
    );
  }

  /// Returns ConfigDto from a map
  factory ConfigDto.fromMap(Map<String, dynamic> map) {
    return ConfigDto(
      flutterSdkVersion: map['flutterSdkVersion'] as String?,
      fvmDir: map['fvmDir'] as String?,
      fvmVersionsDir: map['fvmVersionsDir'] as String?,
      gitCacheDir: map['gitCacheDir'] as String?,
      gitCacheEnabled: map['gitCacheEnabled'] as bool?,
      flutterRepoUrl: map['flutterRepoUrl'] as String?,
      flavors: map['flavors'] as Map<String, dynamic>?,
    );
  }

  /// It checks each property for null prior to adding it to the map.
  /// This is to ensure the returned map doesn't contain any null values.
  /// Also, if [flavors] is not empty it adds it to the map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'flutterSdkVersion': flutterSdkVersion,
      if (fvmDir != null) 'fvmDir': fvmDir,
      if (fvmVersionsDir != null) 'fvmVersionsDir': fvmVersionsDir,
      if (gitCacheDir != null) 'gitCacheDir': gitCacheDir,
      if (gitCacheEnabled != null) 'gitCacheEnabled': gitCacheEnabled,
      if (flutterRepoUrl != null) 'flutterRepoUrl': flutterRepoUrl,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }

  ConfigDto merge(ConfigDto config) {
    return copyWith(
      fvmDir: config.fvmDir,
      fvmVersionsDir: config.fvmVersionsDir,
      flutterSdkVersion: config.flutterSdkVersion,
      flavors: config.flavors,
      gitCacheEnabled: config.gitCacheEnabled,
      gitCacheDir: config.gitCacheDir,
      flutterRepoUrl: config.flutterRepoUrl,
    );
  }

  /// Copies current config and overrides with new values
  /// Returns a new ConfigDto
  ConfigDto copyWith({
    String? fvmDir,
    String? fvmVersionsDir,
    String? flutterSdkVersion,
    Map<String, dynamic>? flavors,
    bool? gitCacheEnabled,
    String? gitCacheDir,
    String? flutterRepoUrl,
  }) {
    return ConfigDto(
      fvmDir: fvmDir ?? this.fvmDir,
      fvmVersionsDir: fvmVersionsDir ?? this.fvmVersionsDir,
      flutterSdkVersion: flutterSdkVersion ?? this.flutterSdkVersion,
      flavors: flavors ?? this.flavors,
      gitCacheEnabled: gitCacheEnabled ?? this.gitCacheEnabled,
      gitCacheDir: gitCacheDir ?? this.gitCacheDir,
      flutterRepoUrl: flutterRepoUrl ?? this.flutterRepoUrl,
    );
  }
}
