import 'dart:io';

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
  static FVMContext get main => FVMContext.create('MAIN');
  factory FVMContext.create(
    String name, {
    String? fvmDir,
    String? fvmVersionsDir,
    String? workingDirectory,
    bool? useGitCache,
    String? gitCacheDir,
    String? flutterRepo,
    Map<Type, dynamic> overrides = const {},
    bool isTest = false,
  }) {
    flutterRepo ??=
        kEnvVars['FVM_GIT_CACHE'] ?? 'https://github.com/flutter/flutter.git';

    final fvmDirHomeEnv = kEnvVars['FVM_HOME'];
    if (fvmDirHomeEnv != null) {
      fvmDir ??= normalize(fvmDirHomeEnv);
    } else {
      fvmDir ??= kFvmDirDefault;
    }

    fvmVersionsDir ??= join(fvmDir, 'versions');

    gitCacheDir ??= join(fvmDir, 'cache.git');

    final level = isTest ? Level.quiet : Level.info;

    final generators = <Type, dynamic>{
      FvmLogger: () => FvmLogger(level: level),
      ProjectService: () => ProjectService(),
      FlutterTools: () => FlutterTools(),
      CacheService: () => CacheService(),
      ...overrides,
    };

    return FVMContext._(
      name,
      fvmDir: fvmDir,
      fvmVersionsDir: fvmVersionsDir,
      workingDirectory: workingDirectory ?? Directory.current.path,
      useGitCache: useGitCache ?? true,
      isTest: isTest,
      flutterRepo: flutterRepo,
      gitCacheDir: gitCacheDir,
      generators: generators,
    );
  }

  /// Constructor
  /// If nothing is provided set default
  FVMContext._(
    this.name, {
    required this.fvmDir,
    required this.fvmVersionsDir,
    required this.workingDirectory,
    required this.useGitCache,
    required this.flutterRepo,
    required this.gitCacheDir,
    this.generators = const {},
    this.isTest = false,
  });

  /// Name of the context
  final String name;

  /// Flutter Git Repo
  final String flutterRepo;

  /// Directory where FVM is stored
  final String fvmDir;

  /// Directory where FVM versions are stored
  final String fvmVersionsDir;

  /// Flag to determine if should use git cache
  final bool useGitCache;

  /// Directory for Flutter repo git cache
  final String gitCacheDir;

  /// Cached settings
  SettingsDto? settings;

  /// Working Directory for FVM
  final String workingDirectory;

  /// Flag to determine if context is running in a test
  final bool isTest;

  final Map<Type, dynamic>? generators;

  final Map<Type, dynamic> _generated = {};

  /// File for FVM Settings
  File get settingsFile {
    return File(join(fvmDir, '.settings'));
  }

  /// Environment variables
  Map<String, String> get environment => Platform.environment;

  /// Where Default Flutter SDK is stored
  Link get globalCacheLink => Link(join(fvmDir, 'default'));

  /// Directory for Global Flutter SDK bin
  String get globalCacheBinPath => join(globalCacheLink.path, 'bin');

  T get<T>() {
    if (_generated.containsKey(T)) {
      return _generated[T] as T;
    }
    if (generators != null && generators!.containsKey(T)) {
      final generator = generators![T] as Generator;
      _generated[T] = generator();
      return _generated[T];
    }
    throw Exception('Generator for $T not found');
  }

  FVMContext copyWith({
    String? name,
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
      name ?? this.name,
      fvmDir: fvmDir ?? this.fvmDir,
      fvmVersionsDir: fvmVersionsDir ?? this.fvmVersionsDir,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      useGitCache: useGitCache ?? this.useGitCache,
      flutterRepo: flutterRepo ?? this.flutterRepo,
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
      name: context?.name,
      fvmDir: context?.fvmDir,
      fvmVersionsDir: context?.fvmVersionsDir,
      workingDirectory: context?.workingDirectory,
      useGitCache: context?.useGitCache,
      flutterRepo: context?.flutterRepo,
      gitCacheDir: context?.gitCacheDir,
      isTest: context?.isTest,
      generators: context?.generators,
    );
  }

  @override
  String toString() => name;
}
