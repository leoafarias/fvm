import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart';

import '../api/api_service.dart';
import '../models/config_model.dart';
import '../models/log_level_model.dart';
import '../services/app_config_service.dart';
import '../services/base_service.dart';
import '../services/cache_service.dart';
import '../services/flutter_service.dart';
import '../services/git_service.dart';
import '../services/logger_service.dart';
import '../services/process_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../version.dart';
import '../workflows/check_project_constraints.workflow.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/resolve_project_deps.workflow.dart';
import '../workflows/setup_flutter.workflow.dart';
import '../workflows/setup_gitignore.workflow.dart';
import '../workflows/update_melos_settings.workflow.dart';
import '../workflows/update_project_references.workflow.dart';
import '../workflows/update_vscode_settings.workflow.dart';
import '../workflows/use_version.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';
import '../workflows/verify_project.workflow.dart';
import 'constants.dart';
import 'extensions.dart';
import 'file_lock.dart';

part 'context.mapper.dart';

/// Generates an [FvmContext] value.
///
/// Generators are allowed to return `null`, in which case the context will
/// store the `null` value as the value for that type.

typedef Generator<T extends Contextual> = T Function(FvmContext context);

// FVMContext get ctx => use(contextKey, withDefault: () => FVMContext.main);

@MappableClass(includeCustomMappers: [GeneratorsMapper()])
class FvmContext with FvmContextMappable {
  /// Name of the context
  final String? debugLabel;

  /// Working Directory for FVM
  final String workingDirectory;

  /// Flag to determine if context is running in a test
  final bool isTest;

  /// App config
  final AppConfig config;

  /// Environment variables
  final Map<String, String> environment;

  /// Log level
  final Level logLevel;

  /// True if the `--fvm-skip-input` flag was passed to the command
  final bool _skipInput;

  final Map<Type, Generator> _generators;
  final Map<Type, dynamic> _dependencies = {};

  /// Constructor
  /// If nothing is provided set default
  @MappableConstructor()
  FvmContext.raw({
    required this.debugLabel,
    required this.workingDirectory,
    required this.config,
    required Map<Type, Generator> generators,
    required this.environment,
    required bool skipInput,
    this.isTest = false,
    this.logLevel = Level.info,
  })  : _skipInput = skipInput,
        _generators = generators;

  static FvmContext create({
    String? debugLabel,
    AppConfig? configOverrides,
    String? workingDirectoryOverride,
    Map<Type, Generator>? generatorsOverride,
    Map<String, String>? environmentOverrides,
    bool skipInput = false,
    Level? logLevel,
    bool isTest = false,
  }) {
    // Load all configs
    final builtConfig = AppConfigService.buildConfig(
      overrides: configOverrides,
    );

    return FvmContext.raw(
      debugLabel: debugLabel,
      workingDirectory: workingDirectoryOverride ?? Directory.current.path,
      config: builtConfig,
      environment: {...Platform.environment, ...?environmentOverrides},
      logLevel: logLevel ?? (isTest ? Level.error : Level.info),
      skipInput: skipInput,
      isTest: isTest,
      generators: {..._defaultGenerators, ...?generatorsOverride},
    );
  }

  Directory get _lockDir => Directory(join(fvmDir, 'locks'));

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

  /// Checks if the current environment is a Continuous Integration (CI) environment.
  /// This is done by checking for common CI environment variables.
  @MappableField()
  bool get isCI {
    return kCiEnvironmentVariables.any(environment.containsKey);
  }

  @MappableField()
  bool get skipInput => isCI || _skipInput;

  /// Creates a file-based lock for cross-process synchronization.
  ///
  /// Uses timestamp-based expiration to prevent deadlocks from crashed processes.
  /// Locks are stored in `~/.fvm/locks/{name}.lock`.
  ///
  /// Usage:
  /// ```dart
  /// final lock = context.createLock('my-operation', expiresIn: Duration(minutes: 5));
  /// final unlock = await lock.getLock();
  /// try {
  ///   // Critical section
  /// } finally {
  ///   unlock();
  /// }
  /// ```
  ///
  /// Defaults to 10 second expiry. Override [expiresIn] for long operations.
  FileLocker createLock(String name, {Duration? expiresIn}) {
    if (!_lockDir.existsSync()) {
      _lockDir.createSync(recursive: true);
    }

    return FileLocker(
      join(_lockDir.path, '$name.lock'),
      lockExpiration: expiresIn ?? const Duration(seconds: 10),
    );
  }

  T get<T>() {
    if (_dependencies.containsKey(T)) {
      return _dependencies[T] as T;
    }
    if (_generators.containsKey(T)) {
      final generator = _generators[T] as Generator;
      _dependencies[T] = generator(this);

      return _dependencies[T];
    }
    throw Exception('Generator for $T not found');
  }

  /// Gets the Flutter URL to use for a specific fork
  String getForkUrl(String forkName) {
    final fork = config.forks.firstWhereOrNull((f) => f.name == forkName);
    if (fork == null) {
      throw Exception('Fork "$forkName" not found in configuration');
    }

    return fork.url;
  }
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
  dynamic encode(Map<Type, Generator> self) {
    return null;
  }
}

const _defaultGenerators = <Type, Generator>{
  ProjectService: ProjectService.new,
  CacheService: CacheService.new,
  FlutterReleaseClient: FlutterReleaseClient.new,
  FlutterService: FlutterService.new,
  ApiService: ApiService.new,
  GitService: GitService.new,
  ProcessService: ProcessService.new,
  Logger: Logger.new,
  UseVersionWorkflow: UseVersionWorkflow.new,
  CheckProjectConstraintsWorkflow: CheckProjectConstraintsWorkflow.new,
  ResolveProjectDependenciesWorkflow: ResolveProjectDependenciesWorkflow.new,
  SetupFlutterWorkflow: SetupFlutterWorkflow.new,
  SetupGitIgnoreWorkflow: SetupGitIgnoreWorkflow.new,
  UpdateProjectReferencesWorkflow: UpdateProjectReferencesWorkflow.new,
  UpdateMelosSettingsWorkflow: UpdateMelosSettingsWorkflow.new,
  UpdateVsCodeSettingsWorkflow: UpdateVsCodeSettingsWorkflow.new,
  ValidateFlutterVersionWorkflow: ValidateFlutterVersionWorkflow.new,
  VerifyProjectWorkflow: VerifyProjectWorkflow.new,
  EnsureCacheWorkflow: EnsureCacheWorkflow.new,
};
