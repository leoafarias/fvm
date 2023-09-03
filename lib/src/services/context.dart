import 'dart:io';

import 'package:path/path.dart';
import 'package:scope/scope.dart';

import '../../constants.dart';
import '../../fvm.dart';

final contextKey = ScopeKey<FVMContext>();

FVMContext get ctx => use(contextKey, withDefault: () => FVMContext.main);

class FVMContext {
  static FVMContext main = FVMContext.create('MAIN');
  factory FVMContext.create(
    String name, {
    Directory? fvmDir,
    Directory? fvmVersionsDir,
    bool? useGitCache,
    Directory? gitCacheDir,
    String? flutterRepo,
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

    final gitCacheDir = Directory(
      join(fvmDir.path, 'cache.git'),
    );

    return FVMContext._(
      name,
      fvmDir: fvmDir,
      fvmVersionsDir: fvmVersionsDir,
      useGitCache: useGitCache ?? true,
      isTest: isTest,
      flutterRepo: flutterRepo,
      gitCacheDir: gitCacheDir,
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

  FVMContext copyWith({
    String? name,
    Directory? fvmDir,
    Directory? fvmVersionsDir,
    bool? useGitCache,
    String? flutterRepo,
    Directory? gitCacheDir,
    bool? isTest,
  }) {
    return FVMContext._(
      name ?? this.name,
      fvmDir: fvmDir ?? this.fvmDir,
      fvmVersionsDir: fvmVersionsDir ?? this.fvmVersionsDir,
      useGitCache: useGitCache ?? this.useGitCache,
      flutterRepo: flutterRepo ?? this.flutterRepo,
      gitCacheDir: gitCacheDir ?? this.gitCacheDir,
      isTest: isTest ?? this.isTest,
    );
  }

  FVMContext merge([FVMContext? context]) {
    return copyWith(
      name: context?.name,
      fvmDir: context?.fvmDir,
      fvmVersionsDir: context?.fvmVersionsDir,
      useGitCache: context?.useGitCache,
      flutterRepo: context?.flutterRepo,
      isTest: context?.isTest,
    );
  }

  @override
  String toString() => name;
}
