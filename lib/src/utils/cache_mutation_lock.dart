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
  return withVersionCacheMutationLocks(context, [version], action);
}

/// Runs [action] while holding the shared cache maintenance lock and the
/// exclusive locks for every affected SDK version.
///
/// Version lock paths are validated through [CacheService], deduplicated, and
/// acquired in lexical order so callers that affect more than one cache entry
/// cannot deadlock each other by requesting the versions in different orders.
Future<T> withVersionCacheMutationLocks<T>(
  FvmContext context,
  Iterable<FlutterVersion> versions,
  Future<T> Function() action,
) {
  return withSharedCacheMaintenanceLock(
    context,
    () => withVersionCacheLocksWhileMaintenanceLocked(
      context,
      versions,
      action,
    ),
  );
}

/// Runs [action] while holding the shared cache-wide maintenance lock.
Future<T> withSharedCacheMaintenanceLock<T>(
  FvmContext context,
  Future<T> Function() action,
) {
  return withProcessFileLock(
    lockFile: File(path.join(context.fvmDir, '.locks', 'cache.lock')),
    lockMode: FileLock.shared,
    description: 'SDK cache maintenance',
    logger: context.get(),
    action: action,
  );
}

/// Acquires sorted exclusive version locks while the caller retains the
/// cache-wide maintenance lock.
///
/// This split form allows Git-enabled installation to preserve the required
/// cache-wide → Git → version order without duplicating lock-path logic.
Future<T> withVersionCacheLocksWhileMaintenanceLocked<T>(
  FvmContext context,
  Iterable<FlutterVersion> versions,
  Future<T> Function() action,
) {
  final cacheService = context.get<CacheService>();
  final versionLocks = <String, File>{};
  for (final version in versions) {
    final versionDir = cacheService.getVersionCacheDir(version);
    final relativeVersionPath = path.relative(
      versionDir.path,
      from: context.versionsCachePath,
    );
    versionLocks[relativeVersionPath] = File(
      path.join(
        context.fvmDir,
        '.locks',
        'versions',
        '$relativeVersionPath.lock',
      ),
    );
  }

  final orderedVersionLocks = versionLocks.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final logger = context.get<Logger>();

  Future<T> acquireVersionLock(int index) {
    if (index == orderedVersionLocks.length) return action();

    return withProcessFileLock(
      lockFile: orderedVersionLocks[index].value,
      lockMode: FileLock.exclusive,
      description: 'SDK version cache',
      logger: logger,
      action: () => acquireVersionLock(index + 1),
    );
  }

  return acquireVersionLock(0);
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
