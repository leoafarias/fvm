import 'dart:io';

import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/global_version_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/deprecation_util.dart';
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
  static FVMContext get main => FVMContext.create();
  factory FVMContext.create({
    String? id,
    EnvConfig? configOverrides,
    String? workingDirectory,
    Map<Type, dynamic> overrides = const {},
    bool isTest = false,
  }) {
    workingDirectory ??= Directory.current.path;

    // Check if env defined a config path

    // Load config from file in config path
    final storedConfig = ConfigRepository.load();

    // Merge config from file with env config
    final config = storedConfig.merge(configOverrides);

    final level = isTest ? Level.warning : Level.info;

    final fvmPath = config.fvmPath ?? kAppDirHome;
    final gitCache = config.gitCache ?? true;
    final gitCachePath = config.gitCachePath;
    final flutterRepoUrl = config.flutterRepoUrl ?? kDefaultFlutterRepo;

    deprecationWorkflow(fvmPath);

    return FVMContext._(
      id: id ?? 'MAIN',
      fvmDir: fvmPath,
      workingDirectory: workingDirectory,
      gitCache: gitCache,
      gitCachePath: gitCachePath,
      isTest: isTest,
      flutterRepoUrl: flutterRepoUrl,
      generators: {
        LoggerService: (context) =>
            LoggerService(level: level, context: context),
        ProjectService: (context) => ProjectService(context),
        FlutterService: (context) => FlutterService(context),
        CacheService: (context) => CacheService(context),
        GlobalVersionService: (context) => GlobalVersionService(context),
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
  String get configPath => kAppConfigHome;

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
