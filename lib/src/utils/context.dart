import 'dart:io';

import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';
import 'package:scope/scope.dart';

import '../../constants.dart';
import '../../fvm.dart';

final contextKey = ScopeKey<FVMContext>();

/// Generates an [FVMContext] value.
///
/// Generators are allowed to return `null`, in which case the context will
/// store the `null` value as the value for that type.
typedef Generator = dynamic Function();

FVMContext get ctx => use(contextKey, withDefault: () => FVMContext.main);

const _defaultFlutterRepoUrl = 'https://github.com/flutter/flutter.git';

class FVMContext {
  static FVMContext get main => FVMContext.create();
  factory FVMContext.create({
    String? id,
    String? configPath,
    // Will override all configs including command line args
    ConfigDto? configOverride,
    String? workingDirectory,
    Map<Type, dynamic> overrides = const {},
    bool isTest = false,
    List<String>? commandLineArgs,
  }) {
    _validateDeprecatedEnvVars();

    configPath ??= applicationConfigHome();

    ConfigDto config = ConfigRepository(configPath).load(
      commandLineArgs: commandLineArgs,
    );

    if (configOverride != null) {
      config = config.merge(configOverride);
      if (commandLineArgs != null) {
        logger.warn(
          'Override: configOverrides will override commandLineArgs',
        );
      }
    }

    final fvmDir = config.fvmDir ?? kFvmDirDefault;
    final fvmVersionsDir = config.fvmVersionsDir ?? join(fvmDir, 'versions');
    // Get config for the FVM Context
    final flutterRepoUrl = config.flutterRepoUrl ?? _defaultFlutterRepoUrl;
    final gitCacheEnabled = config.gitCacheEnabled ?? true;
    final gitCacheDir = config.gitCacheDir ?? join(fvmDir, 'cache.git');

    final level = isTest ? Level.quiet : Level.info;

    // Migrate old FVM settings
    _migrateSettings(
      fvmDir: fvmDir,
      configPath: configPath,
    );

    return FVMContext._(
      id: id ?? 'MAIN',
      configPath: configPath,
      fvmDir: fvmDir,
      fvmVersionsDir: fvmVersionsDir,
      workingDirectory: workingDirectory ?? Directory.current.path,
      gitCacheEnabled: gitCacheEnabled,
      isTest: isTest,
      flutterRepoUrl: flutterRepoUrl,
      gitCacheDir: gitCacheDir,
      generators: {
        FvmLogger: () => FvmLogger(level: level),
        ProjectService: () => ProjectService(),
        FlutterTools: () => FlutterTools(),
        CacheService: () => CacheService(),
        ...overrides,
      },
    );
  }

  /// Constructor
  /// If nothing is provided set default
  FVMContext._({
    required this.id,
    required this.configPath,
    required this.fvmDir,
    required this.fvmVersionsDir,
    required this.workingDirectory,
    required this.gitCacheEnabled,
    required this.flutterRepoUrl,
    required this.gitCacheDir,
    this.generators = const {},
    this.isTest = false,
  });

  /// Name of the context
  final String id;

  final String configPath;

  /// Flutter Git Repo
  final String flutterRepoUrl;

  /// Directory where FVM is stored
  final String fvmDir;

  /// Directory where FVM versions are stored
  final String fvmVersionsDir;

  /// Flag to determine if should use git cache
  final bool gitCacheEnabled;

  /// Directory for Flutter repo git cache
  final String gitCacheDir;

  /// Working Directory for FVM
  final String workingDirectory;

  /// Flag to determine if context is running in a test
  final bool isTest;

  final Map<Type, dynamic>? generators;

  /// Generated values
  final Map<Type, dynamic> _dependencies = {};

  /// Environment variables
  Map<String, String> get environment => Platform.environment;

  /// Where Default Flutter SDK is stored
  Link get globalCacheLink => Link(join(fvmDir, 'default'));

  /// Directory for Global Flutter SDK bin
  String get globalCacheBinPath => join(globalCacheLink.path, 'bin');

  T get<T>() {
    if (_dependencies.containsKey(T)) {
      return _dependencies[T] as T;
    }
    if (generators != null && generators!.containsKey(T)) {
      final generator = generators![T] as Generator;
      _dependencies[T] = generator();
      return _dependencies[T];
    }
    throw Exception('Generator for $T not found');
  }

  FVMContext copyWith({
    String? id,
    String? configPath,
    String? workingDirectory,
    String? fvmDir,
    String? fvmVersionsDir,
    bool? useGitCache,
    String? flutterRepo,
    String? gitCacheDir,
    bool? isTest,
    Map<Type, dynamic>? generators,
  }) {
    return FVMContext._(
      id: id ?? this.id,
      configPath: configPath ?? this.configPath,
      fvmDir: fvmDir ?? this.fvmDir,
      fvmVersionsDir: fvmVersionsDir ?? this.fvmVersionsDir,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      gitCacheEnabled: useGitCache ?? gitCacheEnabled,
      flutterRepoUrl: flutterRepo ?? flutterRepoUrl,
      gitCacheDir: gitCacheDir ?? this.gitCacheDir,
      isTest: isTest ?? this.isTest,
      generators: {
        ...this.generators!,
        if (generators != null) ...generators,
      },
    );
  }

  FVMContext merge([FVMContext? context]) {
    return copyWith(
      id: context?.id,
      configPath: context?.configPath,
      fvmDir: context?.fvmDir,
      fvmVersionsDir: context?.fvmVersionsDir,
      workingDirectory: context?.workingDirectory,
      useGitCache: context?.gitCacheEnabled,
      flutterRepo: context?.flutterRepoUrl,
      gitCacheDir: context?.gitCacheDir,
      isTest: context?.isTest,
      generators: context?.generators,
    );
  }

  @override
  String toString() => id;
}

void _migrateSettings({
  required String fvmDir,
  required String configPath,
}) {
  final settingsFile = File(join(fvmDir, '.settings'));

  if (!settingsFile.existsSync()) {
    return;
  }

  final payload = settingsFile.readAsStringSync();
  final settings = SettingsDto.fromJson(payload);

  logger.confirm('You have settings located at ${settingsFile.path}');

  final configRepo = ConfigRepository(configPath);

  final settingsConfig = ConfigDto(
    fvmVersionsDir: settings.cachePath,
  );

  final currentConfig = configRepo.load();

  configRepo.save(settingsConfig.merge(currentConfig));
}

// TODO: REmoved on future version of the app
// Deprecated on 3.0.0
void _validateDeprecatedEnvVars() {
  final flutterRoot = kEnvVars['FVM_GIT_CACHE'];
  final fvmHome = kEnvVars['FVM_HOME'];
  if (flutterRoot != null) {
    logger.warn('FVM_GIT_CACHE environment variable is deprecated. ');
  }

  if (fvmHome != null) {
    logger.warn('FVM_HOME environment variable is deprecated. ');
  }

  if (flutterRoot == null || fvmHome == null) {
    return;
  }

//TODO: Check that this is correct

  logger
    ..spacer
    ..info(
      'Review the config page for updated information: $kFvmDocsConfigUrl',
    );
}
