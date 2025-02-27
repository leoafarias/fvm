import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/extensions.dart';
import 'base_service.dart';
import 'cache_service.dart';

class GlobalVersionService extends ContextService {
  final CacheService _cacheService;
  const GlobalVersionService(
    super.context, {
    required CacheService cacheService,
  }) : _cacheService = cacheService;

  Link get _globalCacheLink => Link(context.globalCacheLink);

  /// Sets a [CacheFlutterVersion] as global
  void setGlobal(CacheFlutterVersion version) {
    context.globalCacheLink.link.createLink(version.directory);
  }

  /// Unlinks global version
  void unlinkGlobal() {
    if (_globalCacheLink.existsSync()) {
      _globalCacheLink.deleteSync();
    }
  }

  /// Returns a global [CacheFlutterVersion] if exists
  CacheFlutterVersion? getGlobal() {
    if (!_globalCacheLink.existsSync()) return null;
    // Get directory name
    final version = path.basename(_globalCacheLink.targetSync());
    // Make sure its a valid version
    final validVersion = FlutterVersion.parse(version);

    // Verify version is cached
    return _cacheService.getVersion(validVersion);
  }

  /// Checks if a cached [version] is configured as global
  bool isGlobal(CacheFlutterVersion version) {
    if (!_globalCacheLink.existsSync()) return false;

    return _globalCacheLink.targetSync() == version.directory;
  }

  /// Returns a global version name if exists
  String? getGlobalVersion() {
    if (!_globalCacheLink.existsSync()) return null;

    // Get directory name
    return path.basename(_globalCacheLink.targetSync());
  }
}
