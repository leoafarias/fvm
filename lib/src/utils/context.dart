import 'dart:convert';
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

class FVMContext {
  static FVMContext get main => FVMContext.create();
  factory FVMContext.create({
    String? id,

    // Will override all configs including command line args
    EnvConfig? configOverride,
    String? workingDirectory,
    Map<Type, dynamic> overrides = const {},
    bool isTest = false,
    List<String>? commandLineArgs,
  }) {
    EnvConfig config = ConfigRepository.loadEnv(
      commandLineArgs: commandLineArgs,
    );

    if (configOverride != null) {
      config = config.merge(configOverride);
    }

    final level = isTest ? Level.warning : Level.info;

    // Migrate old FVM settings
    _warnAboutDeprecatedSettings(
      fvmDir: config.fvmPath!,
      configPath: config.fvmConfigPath!,
    );

    _warnDeprecatedEnvVars();

    return FVMContext._(
      id: id ?? 'MAIN',
      configPath: config.fvmConfigPath!,
      fvmDir: config.fvmPath!,
      workingDirectory: workingDirectory ?? Directory.current.path,
      gitCache: config.gitCache!,
      gitCachePath: config.gitCachePath!,
      isTest: isTest,
      flutterRepoUrl: config.flutterRepoUrl!,
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
    required this.workingDirectory,
    required this.gitCache,
    required this.flutterRepoUrl,
    required this.gitCachePath,
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

  /// Flag to determine if should use git cache
  final bool gitCache;

  /// Directory for Flutter repo git cache
  final String gitCachePath;

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

  /// Directory where FVM versions are stored
  String get versionsCachePath => join(fvmDir, 'versions');

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
    bool? gitCacheEnabled,
    String? flutterRepoUrl,
    String? gitCachePath,
    bool? isTest,
    Map<Type, dynamic>? generators,
  }) {
    return FVMContext._(
      id: id ?? this.id,
      gitCachePath: gitCachePath ?? this.gitCachePath,
      configPath: configPath ?? this.configPath,
      fvmDir: fvmDir ?? this.fvmDir,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      gitCache: gitCacheEnabled ?? gitCache,
      flutterRepoUrl: flutterRepoUrl ?? this.flutterRepoUrl,
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
      gitCachePath: context?.gitCachePath,
      fvmDir: context?.fvmDir,
      workingDirectory: context?.workingDirectory,
      gitCacheEnabled: context?.gitCache,
      flutterRepoUrl: context?.flutterRepoUrl,
      isTest: context?.isTest,
      generators: context?.generators,
    );
  }

  @override
  String toString() => id;
}

void _warnAboutDeprecatedSettings({
  required String fvmDir,
  required String configPath,
}) {
  final settingsFile = File(join(fvmDir, '.settings'));

  if (!settingsFile.existsSync()) {
    return;
  }

  final payload = settingsFile.readAsStringSync();
  try {
    final settings = jsonDecode(payload);

    if (settings['cachePath'] != join(fvmDir, 'versions')) {
      logger.confirm(
        'You have a deprecated setting for cachePath in $settingsFile.'
        'Make sure you update it. $kFvmDocsConfigUrl',
      );
    }
  } catch (_) {
    logger.warn('Could not parse legact settings file');
  }

  settingsFile.deleteSync(recursive: true);
}

// TODO: Removed on future version of the app
// Deprecated on 3.0.0
void _warnDeprecatedEnvVars() {
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
