import 'dart:io';

import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';
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
    Directory? fvmDir,
    Directory? fvmVersionsDir,
    bool? useGitCache,
    FvmLogger? logger,
    Directory? gitCacheDir,
    String? flutterRepo,
    Map<Type, dynamic> overrides = const {},
    bool isTest = false,
  }) {
    flutterRepo ??=
        kEnvVars['FVM_GIT_CACHE'] ?? 'https://github.com/flutter/flutter.git';

    final fvmDirHomeEnv = kEnvVars['FVM_HOME'];
    if (fvmDirHomeEnv != null) {
      fvmDir ??= Directory(normalize(fvmDirHomeEnv));
    } else {
      fvmDir ??= Directory(kFvmDirDefault);
    }

    fvmVersionsDir ??= Directory(
      join(fvmDir.path, 'versions'),
    );

    gitCacheDir ??= Directory(
      join(fvmDir.path, 'cache.git'),
    );

    final generators = <Type, dynamic>{
      FvmLogger: () => FvmLogger(),
      ProjectService: () => ProjectService(),
      FlutterTools: () => FlutterTools(),
      CacheService: () => CacheService(),
      ...overrides,
    };

    return FVMContext._(
      name,
      fvmDir: fvmDir,
      fvmVersionsDir: fvmVersionsDir,
      useGitCache: useGitCache ?? false,
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
  final Directory fvmDir;

  /// Directory where FVM versions are stored
  final Directory fvmVersionsDir;

  /// Flag to determine if should use git cache
  final bool useGitCache;

  /// Directory for Flutter repo git cache
  final Directory gitCacheDir;

  /// Cached settings
  SettingsDto? settings;

  /// Flag to determine if context is running in a test
  final bool isTest;

  final Map<Type, dynamic>? generators;

  /// File for FVM Settings
  File get settingsFile {
    return File(join(fvmDir.path, '.settings'));
  }

  /// Environment variables
  Map<String, String> get environment => Platform.environment;

  /// Where Default Flutter SDK is stored
  Link get globalCacheLink => Link(join(fvmDir.path, 'default'));

  /// Directory for Global Flutter SDK bin
  String get globalCacheBinPath => join(globalCacheLink.path, 'bin');

  T get<T>() {
    if (generators != null && generators!.containsKey(T)) {
      return generators![T]!() as T;
    }
    throw Exception('Generator for $T not found');
  }

  FVMContext copyWith({
    String? name,
    Directory? fvmDir,
    Directory? fvmVersionsDir,
    bool? useGitCache,
    String? flutterRepo,
    Directory? gitCacheDir,
    bool? isTest,
    Map<Type, dynamic>? generators,
  }) {
    return FVMContext._(
      name ?? this.name,
      fvmDir: fvmDir ?? this.fvmDir,
      fvmVersionsDir: fvmVersionsDir ?? this.fvmVersionsDir,
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
