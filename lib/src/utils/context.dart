import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart';
import 'package:scope/scope.dart';

import '../api/api_service.dart';
import '../models/config_model.dart';
import '../services/base_service.dart';
import '../services/cache_service.dart';
import '../services/config_repository.dart';
import '../services/flutter_service.dart';
import '../services/global_version_service.dart';
import '../services/logger_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../version.dart';
import 'constants.dart';

part 'context.mapper.dart';

final contextKey = ScopeKey<FVMContext>();

/// Generates an [FVMContext] value.
///
/// Generators are allowed to return `null`, in which case the context will
/// store the `null` value as the value for that type.

typedef Generator<T extends Contextual> = T Function(FVMContext context);

// FVMContext get ctx => use(contextKey, withDefault: () => FVMContext.main);

@MappableClass(includeCustomMappers: [GeneratorsMapper()])
class FVMContext with FVMContextMappable {
  static FVMContext main = FVMContext.create();

  /// Name of the context
  final String id;

  /// Working Directory for FVM
  final String workingDirectory;

  /// Flag to determine if context is running in a test
  final bool isTest;

  /// App config
  final AppConfig config;

  /// Environment variables
  final Map<String, String> environment;

  final List<String> args;

  /// Log level
  final Level logLevel;

  /// True if the `--fvm-skip-input` flag was passed to the command
  final bool _skipInput;

  /// Generated values

  /// Constructor
  /// If nothing is provided set default
  @MappableConstructor()
  const FVMContext.raw({
    required this.id,
    required this.workingDirectory,
    required this.config,
    required this.environment,
    required this.args,
    required bool skipInput,
    this.isTest = false,
    this.logLevel = Level.info,
  }) : _skipInput = skipInput;

  static FVMContext create({
    String? id,
    List<String>? args,
    AppConfig? configOverrides,
    String? workingDirectoryOverride,
    Map<String, String>? environmentOverrides,
    bool isTest = false,
  }) {
    // Load all configs
    final config = ConfigRepository.load(overrides: configOverrides);

    // Skips input if running in CI

    final updatedArgs = [...?args];

    final skipInput = updatedArgs.remove('--fvm-skip-input');

    return FVMContext.raw(
      id: id ?? 'MAIN',
      workingDirectory: workingDirectoryOverride ?? Directory.current.path,
      config: config,
      environment: {...Platform.environment, ...?environmentOverrides},
      args: updatedArgs,
      logLevel: isTest ? Level.error : Level.info,
      skipInput: skipInput,
      isTest: isTest,
    );
  }

  /// Directory where FVM is stored
  @MappableField()
  String get fvmDir => config.cachePath ?? kAppDirHome;

  /// Flag to determine if should use git cache
  @MappableField()
  bool get gitCache {
    final useGitCache = config.useGitCache != null ? config.useGitCache! : true;

    return useGitCache && !isCI;
  }

  /// Run pub get on sdk changes
  @MappableField()
  bool get runPubGetOnSdkChanges {
    return config.runPubGetOnSdkChanges != null
        ? config.runPubGetOnSdkChanges!
        : true;
  }

  /// FVM Version
  @MappableField()
  String get fvmVersion => packageVersion;

  @MappableField()
  String get gitCachePath {
    // If git cache is not override use default based on fvmDir
    if (config.gitCachePath != null) return config.gitCachePath!;

    return join(fvmDir, 'cache.git');
  }

  /// Flutter Git Repo
  @MappableField()
  String get flutterUrl => config.flutterUrl ?? kDefaultFlutterUrl;

  /// Last updated check
  @MappableField()
  DateTime? get lastUpdateCheck => config.lastUpdateCheck;

  /// Flutter SDK Path
  @MappableField()
  bool get updateCheckDisabled {
    return config.disableUpdateCheck != null
        ? config.disableUpdateCheck!
        : false;
  }

  /// Privileged access
  @MappableField()
  bool get privilegedAccess {
    return config.privilegedAccess != null ? config.privilegedAccess! : true;
  }

  /// Where Default Flutter SDK is stored
  @MappableField()
  String get globalCacheLink => join(fvmDir, 'default');

  /// Directory for Global Flutter SDK bin
  @MappableField()
  String get globalCacheBinPath => join(globalCacheLink, 'bin');

  /// Directory where FVM versions are stored
  @MappableField()
  String get versionsCachePath => join(fvmDir, 'versions');

  /// Config path
  @MappableField()
  String get configPath => kAppConfigFile;

  /// Checks if the current environment is a Continuous Integration (CI) environment.
  /// This is done by checking for common CI environment variables.
  @MappableField()
  bool get isCI {
    return kCiEnvironmentVariables.any(Platform.environment.containsKey);
  }

  @MappableField()
  bool get skipInput => isCI || _skipInput;

  @override
  String toString() => id;
}

class GeneratorsMapper extends SimpleMapper<Map<Type, Generator>> {
  const GeneratorsMapper();

  @override
  // ignore: avoid-dynamic
  Map<Type, Generator> decode(dynamic value) {
    return {};
  }

  @override
  // ignore: avoid-dynamic
  dynamic encode(Map<Type, Generator> self) => null;
}

class FvmController {
  final FVMContext context;
  late final Logger logger;
  final Map<Type, Generator> _generators;
  final Map<Type, dynamic> _dependencies = {};

  FvmController._(this.context, {required Map<Type, Generator> generators})
      : _generators = generators,
        logger = Logger.fromContext(context);

  FvmController(this.context) : _generators = _defaultGenerators;

  FvmController.overrides(
    this.context, {
    required Map<Type, Generator> generators,
  }) : _generators = {..._defaultGenerators, ...generators};

  ProjectService get projectService => get();

  CacheService get cacheService => get();
  FlutterService get flutterService => get();
  GlobalVersionService get globalVersionService => get();
  APIService get apiService => get();
  FlutterReleasesService get flutterReleasesServices => get();

  T get<T>() {
    if (_dependencies.containsKey(T)) {
      return _dependencies[T] as T;
    }
    if (_generators.containsKey(T)) {
      final generator = _generators[T] as Generator;
      _dependencies[T] = generator(context);

      return _dependencies[T];
    }
    throw Exception('Generator for $T not found');
  }
}

const _defaultGenerators = {
  ProjectService: _buildProjectService,
  CacheService: _buildCacheService,
  FlutterReleasesService: _buildFlutterReleasesService,
  FlutterService: _buildFlutterService,
  GlobalVersionService: _buildGlobalVersionService,
  APIService: _buildAPIService,
};

APIService _buildAPIService(FVMContext context) {
  return APIService(
    context,
    projectService: _buildProjectService(context),
    cacheService: _buildCacheService(context),
    flutterReleasesServices: _buildFlutterReleasesService(context),
  );
}

ProjectService _buildProjectService(FVMContext context) {
  return ProjectService(context);
}

FlutterService _buildFlutterService(FVMContext context) {
  return FlutterService(
    context,
    cacheService: _buildCacheService(context),
    flutterReleasesServices: _buildFlutterReleasesService(context),
    globalVersionService: _buildGlobalVersionService(context),
  );
}

CacheService _buildCacheService(FVMContext context) {
  return CacheService(context);
}

FlutterReleasesService _buildFlutterReleasesService(FVMContext context) {
  return FlutterReleasesService(context);
}

GlobalVersionService _buildGlobalVersionService(FVMContext context) {
  return GlobalVersionService(
    context,
    cacheService: _buildCacheService(context),
  );
}
