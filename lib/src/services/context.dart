import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart';

import '../../constants.dart';
import '../../fvm.dart';
import 'settings_service.dart';

/// The Zone key used to look up the [AppContext].
@visibleForTesting
const Symbol contextKey = #fvmContext;

/// FVM Context
FvmContext get ctx {
  return Zone.current[contextKey] as FvmContext? ?? FvmContext._root;
}

/// Returns current FVM context
class FvmContext {
  /// Bootstrap root context
  static final FvmContext _root = FvmContext._('ROOT');

  /// Constructor
  /// If nothing is provided set default
  FvmContext._(
    this.name, {
    Directory? fvmDir,
    Directory? cacheDir,
  })  : _fvmDir = fvmDir ?? Directory(kFvmHome),
        _cacheDirOverride = cacheDir;

  /// Name of the context
  final String name;
  final Directory _fvmDir;
  final Directory? _cacheDirOverride;

  SettingsDto? _settingsDto;

  /// Returns settings or cached
  SettingsDto get settings {
    return _settingsDto ??= SettingsService.readSync();
  }

  /// FVM Home dir
  Directory get fvmHome {
    return _fvmDir;
  }

  /// Where Flutter SDK Versions are stored
  Directory get cacheDir {
    // Override cacheDir
    if (_cacheDirOverride != null) {
      return _cacheDirOverride!;
    }
    // If there is a cache
    if (settings.cachePath != null) {
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
  FutureOr<V> run<V>({
    required FutureOr<V> Function() body,
    required String name,
    final Directory? fvmDir,
    final Directory? cacheDir,
    ZoneSpecification? zoneSpecification,
  }) async {
    final child = FvmContext._(
      name,
      fvmDir: fvmDir,
      cacheDir: cacheDir,
    );
    return runZoned<FutureOr<V>>(
      () async => await body(),
      zoneValues: <Symbol, FvmContext>{contextKey: child},
      zoneSpecification: zoneSpecification,
    );
  }
}
