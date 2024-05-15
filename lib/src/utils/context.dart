import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:mason_logger/mason_logger.dart';
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
import '../version.dart';
import 'constants.dart';

part 'context.mapper.dart';

final contextKey = ScopeKey<FVMContext>();

/// Generates an [FVMContext] value.
///
/// Generators are allowed to return `null`, in which case the context will
/// store the `null` value as the value for that type.

typedef Generator<T extends ContextService> = T Function(FVMContext context);

FVMContext get ctx => use(contextKey, withDefault: () => FVMContext.main);

T getProvider<T>() => ctx.get();

@MappableClass(includeCustomMappers: [GeneratorsMapper()])
class FVMContext with FVMContextMappable {
  static FVMContext main = FVMContext.create();

  /// Name of the context
  final String id;

  /// Working Directory for FVM
  final String workingDirectory;

  /// Flag to determine if context is running in a test
  final bool isTest;

  /// Generators for dependencies
  final Map<Type, Generator> generators;

  /// App config
  final AppConfig config;

  /// Environment variables
  final Map<String, String> environment;

  final List<String> args;

  /// True if the `--fvm-skip-input` flag was passed to the command
  final bool _skipInput;

  /// Generated values
  final Map<Type, dynamic> _dependencies = {};

  /// Constructor
  /// If nothing is provided set default
  @MappableConstructor()
  FVMContext.base({
    required this.id,
    required this.workingDirectory,
    required this.config,
    required this.environment,
    required this.args,
    required bool skipInput,
    required this.generators,
    this.isTest = false,
  }) : _skipInput = skipInput;

  static FVMContext create({
    String? id,
    List<String>? args,
    bool? skipInput,
    AppConfig? configOverrides,
    String? workingDirectory,
    Map<Type, dynamic>? generatorOverrides,
    Map<String, String>? environmentOverrides,
    bool isTest = false,
  }) {
    workingDirectory ??= Directory.current.path;

    // Load all configs
    final config = ConfigRepository.load(overrides: configOverrides);

    final level = isTest ? Level.error : Level.info;

    final environment = {...Platform.environment, ...?environmentOverrides};

    return FVMContext.base(
      id: id ?? 'MAIN',
      workingDirectory: workingDirectory,
      config: config,
      environment: environment,
      args: args ?? [],
      skipInput: skipInput ?? false,
      generators: {
        LoggerService: (context) => LoggerService(
              level: level,
              context: context,
            ),
        ProjectService: ProjectService.new,
        FlutterService: FlutterService.new,
        CacheService: CacheService.new,
        GlobalVersionService: GlobalVersionService.new,
        APIService: APIService.new,
        ...?generatorOverrides,
      },
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
    // If git cache is not overriden use default based on fvmDir
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

  /// Priviledged access
  @MappableField()
  bool get priviledgedAccess {
    return config.priviledgedAccess != null ? config.priviledgedAccess! : true;
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

  T get<T>() {
    if (_dependencies.containsKey(T)) {
      return _dependencies[T] as T;
    }
    if (generators.containsKey(T)) {
      final generator = generators[T] as Generator;
      _dependencies[T] = generator(this);

      return _dependencies[T];
    }
    throw Exception('Generator for $T not found');
  }

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
