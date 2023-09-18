// Use just for reference, should not change

enum ConfigVar {
  fvmPath('fvmPath', 'fvm_path'),
  fvmConfigPath('fvmConfigPath', 'fvm_config_path'),
  gitCache('gitCache', 'git_cache'),
  gitCachePath('gitCachePath', 'git_cache_path'),
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

abstract class ConfigDto {
  // If should use gitCache
  final bool? gitCache;

  final String? gitCachePath;

  /// Flutter repo url
  final String? flutterRepoUrl;

  /// Directory where FVM is stored
  final String? fvmPath;

  const ConfigDto({
    required this.fvmPath,
    required this.gitCache,
    required this.gitCachePath,
    required this.flutterRepoUrl,
  });
}

class EnvConfig extends ConfigDto {
  /// Path to the config
  final String? fvmConfigPath;

  const EnvConfig({
    super.fvmPath,
    super.gitCache,
    super.flutterRepoUrl,
    super.gitCachePath,
    this.fvmConfigPath,
  });

  factory EnvConfig.fromMap(Map<String, dynamic> map) {
    return EnvConfig(
      fvmConfigPath: map[ConfigVar.fvmConfigPath.name] as String?,
      fvmPath: map[ConfigVar.fvmPath.name] as String?,
      gitCache: map[ConfigVar.gitCache.name] as bool?,
      gitCachePath: map[ConfigVar.gitCache.name] as String?,
      flutterRepoUrl: map[ConfigVar.flutterRepo.name] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (fvmConfigPath != null) ConfigVar.fvmConfigPath.name: fvmConfigPath,
      if (fvmPath != null) ConfigVar.fvmPath.name: fvmPath,
      if (gitCache != null) ConfigVar.gitCache.name: gitCache,
      if (gitCachePath != null) ConfigVar.gitCachePath.name: gitCachePath,
      if (flutterRepoUrl != null) ConfigVar.flutterRepo.name: flutterRepoUrl,
    };
  }

  EnvConfig merge(EnvConfig? config) {
    return copyWith(
      fvmPath: config?.fvmPath,
      fvmConfigPath: config?.fvmConfigPath,
      gitCache: config?.gitCache,
      gitCachePath: config?.gitCachePath,
      flutterRepoUrl: config?.flutterRepoUrl,
    );
  }

  EnvConfig copyWith({
    String? fvmPath,
    String? fvmConfigPath,
    bool? gitCache,
    String? gitCachePath,
    String? flutterRepoUrl,
  }) {
    return EnvConfig(
      fvmPath: fvmPath ?? this.fvmPath,
      fvmConfigPath: fvmConfigPath ?? this.fvmConfigPath,
      gitCache: gitCache ?? this.gitCache,
      gitCachePath: gitCachePath ?? this.gitCachePath,
      flutterRepoUrl: flutterRepoUrl ?? this.flutterRepoUrl,
    );
  }
}

/// Project config
class ProjectConfig extends ConfigDto {
  /// Flutter SDK version configured
  final String? flutterSdkVersion;

  /// FVM Version
  final String? fvmVersion;

  /// Flavors configured
  final Map<String, String>? flavors;

  /// Returns true if has flavors
  final bool? manageVscode;

  /// Constructor
  const ProjectConfig({
    super.fvmPath,
    super.gitCache,
    super.gitCachePath,
    super.flutterRepoUrl,
    this.fvmVersion,
    this.flutterSdkVersion,
    this.flavors,
    this.manageVscode,
  });

  /// Returns empty ConfigDto
  const ProjectConfig.empty()
      : flutterSdkVersion = null,
        flavors = null,
        manageVscode = null,
        fvmVersion = null,
        super(
          fvmPath: null,
          gitCache: null,
          gitCachePath: null,
          flutterRepoUrl: null,
        );

  /// Returns ConfigDto from a map
  factory ProjectConfig.fromMap(Map<String, dynamic> map) {
    return ProjectConfig(
      flutterSdkVersion: map['flutterSdkVersion'] as String?,
      fvmPath: map[ConfigVar.fvmPath.name] as String?,
      gitCache: map[ConfigVar.gitCache.name] as bool?,
      flutterRepoUrl: map[ConfigVar.flutterRepo.name] as String?,
      fvmVersion: map['fvmVersion'] as String?,
      manageVscode: map['manageVscode'] as bool?,
      gitCachePath: map[ConfigVar.gitCachePath.name] as String?,
      flavors: map['flavors'] != null
          ? Map<String, String>.from(map['flavors'] as Map)
          : null,
    );
  }

  /// It checks each property for null prior to adding it to the map.
  /// This is to ensure the returned map doesn't contain any null values.
  /// Also, if [flavors] is not empty it adds it to the map.

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (flutterSdkVersion != null) 'flutterSdkVersion': flutterSdkVersion,
      if (fvmVersion != null) 'fvmVersion': fvmVersion,
      if (fvmPath != null) ConfigVar.fvmPath.name: fvmPath,
      if (gitCache != null) ConfigVar.gitCache.name: gitCache,
      if (gitCachePath != null) ConfigVar.gitCachePath.name: gitCachePath,
      if (flutterRepoUrl != null) ConfigVar.flutterRepo.name: flutterRepoUrl,
      if (manageVscode != null) 'manageVscode': manageVscode,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }

  ProjectConfig merge(ProjectConfig config) {
    return copyWith(
      fvmVersion: config.fvmVersion,
      fvmPath: config.fvmPath,
      flutterSdkVersion: config.flutterSdkVersion,
      flavors: config.flavors,
      gitCache: config.gitCache,
      gitCachePath: config.gitCachePath,
      manageVscode: config.manageVscode,
      flutterRepoUrl: config.flutterRepoUrl,
    );
  }

  /// Copies current config and overrides with new values
  /// Returns a new ConfigDto
  ProjectConfig copyWith({
    String? fvmVersion,
    String? fvmPath,
    String? fvmVersionsDir,
    String? flutterSdkVersion,
    bool? gitCache,
    bool? manageVscode,
    String? gitCachePath,
    String? flutterRepoUrl,
    Map<String, String>? flavors,
  }) {
    // merge map and override the keys
    final mergedFlavors = <String, String>{
      if (this.flavors != null) ...this.flavors!,
      if (flavors != null) ...flavors,
    };

    return ProjectConfig(
      fvmVersion: fvmVersion ?? this.fvmVersion,
      fvmPath: fvmPath ?? this.fvmPath,
      flutterSdkVersion: flutterSdkVersion ?? this.flutterSdkVersion,
      flavors: mergedFlavors,
      manageVscode: manageVscode ?? this.manageVscode,
      gitCache: gitCache ?? this.gitCache,
      gitCachePath: gitCachePath ?? this.gitCachePath,
      flutterRepoUrl: flutterRepoUrl ?? this.flutterRepoUrl,
    );
  }
}
