import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart';

import '../../constants.dart';
import 'settings_service.dart';

/// The Zone key used to look up the [AppContext].
@visibleForTesting
const Symbol contextKey = #fvmContext;

/// FVM Context
FvmContext get ctx {
  return Zone.current[contextKey] as FvmContext ?? FvmContext._root;
}

/// Returns current FVM context
class FvmContext {
  /// Bootstrap root context
  static final FvmContext _root = FvmContext._('ROOT');

  /// Constructor
  /// If nothing is provided set default
  FvmContext._(
    this.name, {
    Directory fvmDir,
    Directory cacheDir,
  })  : _fvmDir = fvmDir ?? Directory(kFvmHome),
        _cacheDir = cacheDir;

  /// Name of the context
  final String name;
  final Directory _fvmDir;
  final Directory _cacheDir;

  /// File for FVM Settings
  File get settingsFile {
    return File(join(_fvmDir.path, '.settings'));
  }

  /// Where Flutter SDK Versions are stored
  Directory get cacheDir {
    final _settings = SettingsService.readSync();
    // If there is a cache
    if (_settings.cachePath != null) {
      return Directory(normalize(_cacheDir.path));
    }

    /// Default cache directory
    return Directory(join(_fvmDir.path, 'versions'));
  }

  /// Directory for Flutter repo git cache
  Directory get gitCacheDir {
    return Directory(join(_fvmDir.path, 'git-cache'));
  }

  /// Returns the configured Flutter repository
  String get flutterRepo {
    return kFlutterRepo;
  }

  /// Where Default Flutter SDK is stored
  Link get globalCacheLink => Link(join(_fvmDir.path, 'default'));

  /// Directory for Global Flutter SDK bin
  String get globalCacheBinPath => join(
        globalCacheLink.path,
        'bin',
      );

  @override
  String toString() {
    return name;
  }

  /// Runs context zoned
  FutureOr<V> run<V>({
    @required FutureOr<V> Function() body,
    String name,
    final Directory fvmDir,
    final Directory cacheDir,
    ZoneSpecification zoneSpecification,
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
