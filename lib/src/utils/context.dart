import 'dart:io';

import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/global_version_service.dart';
import 'package:fvm/src/services/logger_service.dart';
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
typedef Generator = dynamic Function(FVMContext context);

FVMContext get ctx => use(contextKey, withDefault: () => FVMContext.main);

T getProvider<T>() => ctx.get<T>();

class FVMContext {
  static FVMContext main = FVMContext.create();
  factory FVMContext.create({
    String? id,
    AppConfig? configOverrides,
    String? workingDirectory,
    Map<Type, dynamic> overrides = const {},
    bool isTest = false,
  }) {
    workingDirectory ??= Directory.current.path;

    // Load config from file in config path
    final projectConfig = ProjectConfig.loadFromPath(workingDirectory);
    final envConfig = ConfigRepository.loadEnv();
    var appConfig = ConfigRepository.loadFile();

    appConfig = appConfig.copyWith(
      cachePath: envConfig.cachePath ?? projectConfig?.cachePath,
      useGitCache: envConfig.useGitCache ?? projectConfig?.useGitCache,
      gitCachePath: envConfig.gitCachePath ?? projectConfig?.gitCachePath,
      flutterUrl: envConfig.flutterUrl ?? projectConfig?.flutterUrl,
    );

    // Merge config from file with env config
    final config = appConfig.merge(configOverrides);

    final level = isTest ? Level.warning : Level.info;

    final fvmPath = config.cachePath ?? kAppDirHome;
    final gitCache = config.useGitCache ?? true;
    final gitCachePath = config.gitCachePath;
    final flutterRepoUrl = config.flutterUrl ?? kDefaultFlutterUrl;

    return FVMContext._(
      id: id ?? 'MAIN',
      fvmDir: fvmPath,
      workingDirectory: workingDirectory,
      gitCache: gitCache,
      gitCachePath: gitCachePath,
      isTest: isTest,
      flutterRepoUrl: flutterRepoUrl,
      generators: {
        LoggerService: (context) => LoggerService(
              level: level,
              context: context,
            ),
        ProjectService: ProjectService.new,
        FlutterService: FlutterService.new,
        CacheService: CacheService.new,
        GlobalVersionService: GlobalVersionService.new,
        ...overrides,
      },
    );
  }

  /// Constructor
  /// If nothing is provided set default
  FVMContext._({
    required this.id,
    required this.fvmDir,
    required this.workingDirectory,
    required this.gitCache,
    required this.flutterRepoUrl,
    required String? gitCachePath,
    this.generators = const {},
    this.isTest = false,
  }) : _gitCachePath = gitCachePath;

  /// Name of the context
  final String id;

  /// Flutter Git Repo
  final String flutterRepoUrl;

  /// Directory where FVM is stored
  final String fvmDir;

  /// Flag to determine if should use git cache
  final bool gitCache;

  /// Directory for Flutter repo git cache
  final String? _gitCachePath;

  /// Working Directory for FVM
  final String workingDirectory;

  /// Flag to determine if context is running in a test
  final bool isTest;

  /// Generators for dependencies
  final Map<Type, dynamic>? generators;

  /// Generated values
  final Map<Type, dynamic> _dependencies = {};

  /// Environment variables
  Map<String, String> get environment => Platform.environment;

  /// Where Default Flutter SDK is stored
  String get globalCacheLink => join(fvmDir, 'default');

  /// Directory for Global Flutter SDK bin
  String get globalCacheBinPath => join(globalCacheLink, 'bin');

  /// Directory where FVM versions are stored
  String get versionsCachePath => join(fvmDir, 'versions');

  String get gitCachePath {
    // If git cache is not overriden use default based on fvmDir
    if (_gitCachePath != null) return _gitCachePath!;
    return join(fvmDir, 'cache.git');
  }

  /// Config path
  String get configPath => kAppConfigFile;

  T get<T>() {
    if (_dependencies.containsKey(T)) {
      return _dependencies[T] as T;
    }
    if (generators != null && generators!.containsKey(T)) {
      final generator = generators![T] as Generator;
      _dependencies[T] = generator(this);
      return _dependencies[T];
    }
    throw Exception('Generator for $T not found');
  }

  FVMContext copyWith({
    String? id,
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
      gitCachePath: gitCachePath ?? _gitCachePath,
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
      gitCachePath: context?._gitCachePath,
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
