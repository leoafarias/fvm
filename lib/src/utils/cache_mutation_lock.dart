import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/logger_service.dart';
import 'context.dart';
import 'process_lock.dart';

Future<T> withVersionCacheMutationLock<T>(
  FvmContext context,
  FlutterVersion version,
  Future<T> Function() action,
) {
  final cacheService = context.get<CacheService>();
  final versionDir = cacheService.getVersionCacheDir(version);
  final relativeVersionPath = path.relative(
    versionDir.path,
    from: context.versionsCachePath,
  );
  final maintenanceLock = File(
    path.join(context.fvmDir, '.locks', 'cache.lock'),
  );
  final versionLock = File(
    path.join(
      context.fvmDir,
      '.locks',
      'versions',
      '$relativeVersionPath.lock',
    ),
  );
  final logger = context.get<Logger>();

  return withProcessFileLock(
    lockFile: maintenanceLock,
    lockMode: FileLock.shared,
    description: 'SDK cache maintenance',
    logger: logger,
    action: () => withProcessFileLock(
      lockFile: versionLock,
      lockMode: FileLock.exclusive,
      description: 'SDK version cache',
      logger: logger,
      action: action,
    ),
  );
}

Future<T> withAllVersionsCacheMutationLock<T>(
  FvmContext context,
  Future<T> Function() action,
) {
  return withProcessFileLock(
    lockFile: File(path.join(context.fvmDir, '.locks', 'cache.lock')),
    lockMode: FileLock.exclusive,
    description: 'SDK cache maintenance',
    logger: context.get(),
    action: action,
  );
}
