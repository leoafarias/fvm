import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/base_service.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/io_utils.dart';
import 'package:path/path.dart' as path;

class GlobalVersionService extends ContextService {
  const GlobalVersionService(super.context);

  static GlobalVersionService get fromContext =>
      getProvider<GlobalVersionService>();

  /// Sets a [CacheFlutterVersion] as global
  void setGlobal(CacheFlutterVersion version) {
    createLink(context.globalCacheLink, version.directory);
  }

  Link get _globalCacheLink => Link(context.globalCacheLink);

  /// Returns a global [CacheFlutterVersion] if exists
  CacheFlutterVersion? getGlobal() {
    if (!_globalCacheLink.existsSync()) return null;
    // Get directory name
    final version = path.basename(_globalCacheLink.targetSync());
    // Make sure its a valid version
    final validVersion = FlutterVersion.parse(version);
    // Verify version is cached
    return CacheService(context).getVersion(validVersion);
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
