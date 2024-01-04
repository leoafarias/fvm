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

T getProvider<T>() => ctx.get();

class FVMContext {
  static FVMContext main = FVMContext.create();

  /// Name of the context
  final String id;

  /// Working Directory for FVM
  final String workingDirectory;

  /// Flag to determine if context is running in a test
  final bool isTest;

  /// App config
  final AppConfig config;

  /// Generators for dependencies
  final Map<Type, dynamic>? generators;

  /// Generated values
  final Map<Type, dynamic> _dependencies = {};

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

    appConfig = appConfig.mergeConfig(envConfig).mergeConfig(projectConfig);

    // Merge config from file with env config
    final config = appConfig.merge(configOverrides);

    final level = isTest ? Level.warning : Level.info;

    return FVMContext._(
      id: id ?? 'MAIN',
      workingDirectory: workingDirectory,
      config: config,
      isTest: isTest,
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
    required this.workingDirectory,
    required this.config,
    this.generators = const {},
    this.isTest = false,
  });

  /// Environment variables
  Map<String, String> get environment => Platform.environment;

  /// Directory where FVM is stored
  String get fvmDir => config.cachePath ?? kAppDirHome;

  /// Flag to determine if should use git cache
  bool get gitCache => config.useGitCache ?? true;

  String get gitCachePath {
    // If git cache is not overriden use default based on fvmDir
    if (config.gitCachePath != null) return config.gitCachePath!;
    return join(fvmDir, 'cache.git');
  }

  /// Flutter Git Repo
  String get flutterUrl => config.flutterUrl ?? kDefaultFlutterUrl;

  /// Last updated check
  DateTime? get lastUpdateCheck => config.lastUpdateCheck;

  /// Flutter SDK Path
  bool get updateCheckDisabled => config.disableUpdateCheck ?? false;

  /// Priviledged access
  bool get priviledgedAccess => config.priviledgedAccess ?? true;

  /// Where Default Flutter SDK is stored
  String get globalCacheLink => join(fvmDir, 'default');

  /// Directory for Global Flutter SDK bin
  String get globalCacheBinPath => join(globalCacheLink, 'bin');

  /// Directory where FVM versions are stored
  String get versionsCachePath => join(fvmDir, 'versions');

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

  @override
  String toString() => id;
}
