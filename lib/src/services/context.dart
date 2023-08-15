import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

import '../../constants.dart';
import '../../fvm.dart';
import 'settings_service.dart';

/// The Zone key used to look up the [FvmContext].
const _contextKey = #fvmContext;

// Used for overriding and forcing zone
FVMContext? _currentContextOverride;

/// FVM Context
FVMContext get ctx {
  return _currentContextOverride ??
      Zone.current[_contextKey] as FVMContext? ??
      FVMContext.root;
}

/// Returns current FVM context
class FVMContext {
  /// Bootstrap root context
  static final FVMContext root = FVMContext._('ROOT');

  factory FVMContext.create(
    String name, {
    Directory? fvmHomeDir,
    Directory? versionCacheDir,
    bool useGitCache = true,
    bool isTest = false,
  }) {
    final context = FVMContext._(
      name,
      fvmHomeDir: fvmHomeDir,
      versionCacheDir: versionCacheDir,
      useGitCache: useGitCache,
      isTest: isTest,
    );

    _currentContextOverride = context;

    return context;
  }

  /// Constructor
  /// If nothing is provided set default
  FVMContext._(
    this.name, {
    Directory? fvmHomeDir,
    Directory? versionCacheDir,
    bool useGitCache = true,
    bool isTest = false,
  })  : _fvmHomeDir = fvmHomeDir ?? Directory(kFvmHome),
        _isTest = isTest,
        _useGitCache = useGitCache,
        _versionCacheDir = versionCacheDir;

  /// Name of the context
  final String name;
  final Directory _fvmHomeDir;
  final Directory? _versionCacheDir;
  final bool _useGitCache;

  SettingsDto? _settingsDto;

  final bool _isTest;

  /// Returns settings or cached
  SettingsDto get settings {
    return _settingsDto ??= SettingsService.readSync();
  }

  /// Flag to determine if context is running in a test
  bool get isTest => _isTest;

  /// Flag to determine if should use git cache
  bool get useGitCache => _useGitCache;

  /// File for FVM Settings
  File get settingsFile {
    return File(join(_fvmHomeDir.path, '.settings'));
  }

  /// FVM Home dir
  Directory get fvmHome {
    return _fvmHomeDir;
  }

  /// Where Flutter SDK Versions are stored
  Directory get cacheDir {
    // Override cacheDir
    if (_versionCacheDir != null) {
      return _versionCacheDir!;
    }
    // If there is a cache
    if (settings.cachePath != null && !isTest) {
      return Directory(normalize(settings.cachePath!));
    }

    /// Default cache directory
    return Directory(join(fvmHome.path, 'versions'));
  }

  /// Directory for Flutter repo git cache
  Directory get gitCacheDir {
    return Directory(
      join(fvmHome.path, 'cache.git'),
    );
  }

  /// Returns the configured Flutter repository
  String get flutterRepo {
    return kFlutterRepo;
  }

  @override
  String toString() {
    return name;
  }

  /// Runs context zoned
  V run<V>({
    required V Function() body,
    required String name,
    final Directory? fvmHomeDir,
    final Directory? cacheDir,
    bool isTest = false,
    ZoneSpecification? zoneSpecification,
  }) {
    final ctx = FVMContext.create(
      name,
      fvmHomeDir: fvmHomeDir,
      versionCacheDir: cacheDir,
      isTest: isTest,
    );
    // Set context key to respect the currentContext

    return runZoned<V>(
      body,
      zoneValues: <Symbol, FVMContext>{_contextKey: ctx},
      zoneSpecification: zoneSpecification,
    );
  }

  static runOnRoot<V>(
    FutureOr<V> Function() body,
  ) async {
    final response = await runZoned<FutureOr<V>>(
      body,
      zoneValues: <Symbol, FVMContext>{_contextKey: root},
    );

    return response;
  }
}
