import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/flutter_service.dart';
import '../services/git_service.dart';
import '../services/install_observer.dart';
import '../services/logger_service.dart';
import '../services/process_service.dart';
import '../utils/cache_mutation_lock.dart';
import '../utils/exceptions.dart';
import '../utils/helpers.dart';
import 'workflow.dart';

sealed class _LockedCacheResult {
  const _LockedCacheResult();
}

final class _CacheReady extends _LockedCacheResult {
  final CacheFlutterVersion version;
  final LogProgress? progress;

  const _CacheReady(this.version, {this.progress});
}

final class _NeedsVersionLock extends _LockedCacheResult {
  final FlutterVersion version;

  const _NeedsVersionLock(this.version);
}

class EnsureCacheWorkflow extends Workflow {
  const EnsureCacheWorkflow(super.context);

  Future<_LockedCacheResult> _handleNonExecutable(
    CacheFlutterVersion version, {
    required bool shouldInstall,
    required bool force,
    required bool useGitCacheForInstall,
    required Set<String> lockedVersionPaths,
    required void Function(GitCacheMaintenance maintenance)
    onGitCacheMaintenanceDeferred,
    required InstallObserver? observer,
    required ProcessCancellation? cancellation,
    int retryCount = 0,
  }) async {
    const maxRetries = 2;
    if (retryCount >= maxRetries) {
      throw AppException(
        'Failed to fix corrupted cache after $maxRetries attempts. '
        'Please check disk space and permissions, then try again.',
      );
    }

    logger
      ..notice(
        'Flutter SDK version: ${version.name} isn\'t executable, indicating the cache is corrupted.',
      )
      ..info(
        'Auto-fixing corrupted cache by reinstalling (attempt ${retryCount + 1}/$maxRetries)...',
      );

    await get<CacheService>().remove(version);
    logger.info('Removing corrupted SDK and reinstalling...');

    return _callLocked(
      version,
      shouldInstall: shouldInstall,
      force: force,
      useGitCacheForInstall: useGitCacheForInstall,
      lockedVersionPaths: lockedVersionPaths,
      onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
      observer: observer,
      cancellation: cancellation,
      retryCount: retryCount + 1,
    );
  }

  Future<_LockedCacheResult> _handleVersionMismatch(
    CacheFlutterVersion version, {
    required bool useGitCacheForInstall,
    required Set<String> lockedVersionPaths,
    required void Function(GitCacheMaintenance maintenance)
    onGitCacheMaintenanceDeferred,
    required InstallObserver? observer,
    required ProcessCancellation? cancellation,
  }) async {
    logger
      ..notice(
        'Cached SDK metadata reports ${version.flutterSdkVersion}, but FVM expected ${version.name} for this cache entry.',
      )
      ..info(
        'This can happen when a cached SDK is upgraded or changed outside FVM.',
      )
      ..info();

    final firstOption =
        'Move ${version.flutterSdkVersion} to the correct cache directory and reinstall ${version.name}';

    final secondOption =
        'Remove incorrect version and reinstall ${version.name}';

    String selectedOption;
    if (context.skipInput) {
      logger.warn(
        'CI/non-interactive mode: auto-selecting remove and reinstall',
      );
      selectedOption = secondOption;
    } else {
      selectedOption = logger.select(
        'How would you like to resolve this?',
        options: [firstOption, secondOption],
      );
    }

    if (selectedOption == firstOption) {
      logger.info('Moving SDK to the correct cache directory...');
      get<CacheService>().moveToSdkVersionDirectory(version);
    }

    logger.info('Removing incorrect SDK version...');
    await get<CacheService>().remove(version);

    return _callLocked(
      version,
      shouldInstall: true,
      useGitCacheForInstall: useGitCacheForInstall,
      lockedVersionPaths: lockedVersionPaths,
      onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
      observer: observer,
      cancellation: cancellation,
    );
  }

  FlutterVersion _versionMismatchTarget(CacheFlutterVersion version) {
    final sdkVersion = version.flutterSdkVersion;
    if (sdkVersion == null) {
      throw AppException(
        'Cannot move to SDK version directory without a valid version',
      );
    }

    return FlutterVersion.parse(
      version.fromFork ? '${version.fork}/$sdkVersion' : sdkVersion,
    );
  }

  String _versionLockIdentity(FlutterVersion version) {
    return path.normalize(get<CacheService>().getVersionCacheDir(version).path);
  }

  void _validateContext() {
    if (!isValidGitUrl(context.flutterUrl)) {
      throw AppException(
        'Invalid Flutter URL: "${context.flutterUrl}". '
        'Please change config to a valid git url',
      );
    }
  }

  void _validateGit() {
    try {
      final result = Process.runSync('git', ['--version']);
      if (result.exitCode != 0) {
        throw const AppException('Git is not installed');
      }
    } on ProcessException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const AppException('Git is not installed'),
        stackTrace,
      );
    }
  }

  Future<_LockedCacheResult> _callLocked(
    FlutterVersion version, {
    required bool useGitCacheForInstall,
    required Set<String> lockedVersionPaths,
    required void Function(GitCacheMaintenance maintenance)
    onGitCacheMaintenanceDeferred,
    required InstallObserver? observer,
    required ProcessCancellation? cancellation,
    bool shouldInstall = false,
    bool force = false,
    int retryCount = 0,
  }) async {
    final cacheService = get<CacheService>();
    final flutterService = get<FlutterService>();

    // Another process may have changed this version while this caller waited.
    final cacheVersion = cacheService.getVersion(version);

    if (cacheVersion != null) {
      final integrity = await cacheService.verifyCacheIntegrity(cacheVersion);

      if (integrity == CacheIntegrity.invalid) {
        return await _handleNonExecutable(
          cacheVersion,
          shouldInstall: shouldInstall,
          force: force,
          useGitCacheForInstall: useGitCacheForInstall,
          lockedVersionPaths: lockedVersionPaths,
          onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
          observer: observer,
          cancellation: cancellation,
          retryCount: retryCount,
        );
      }

      if (integrity == CacheIntegrity.versionMismatch &&
          !force &&
          !version.isCustom) {
        final targetVersion = _versionMismatchTarget(cacheVersion);
        if (!lockedVersionPaths.contains(_versionLockIdentity(targetVersion))) {
          return _NeedsVersionLock(targetVersion);
        }

        return _handleVersionMismatch(
          cacheVersion,
          useGitCacheForInstall: useGitCacheForInstall,
          lockedVersionPaths: lockedVersionPaths,
          onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
          observer: observer,
          cancellation: cancellation,
        );
      } else if (force) {
        logger.warn(
          'Not checking for version mismatch as --force flag is set.',
        );
      } else if (version.isCustom) {
        logger.warn(
          'Not checking for version mismatch as local version is being used.',
        );
      }

      // If should install notify the user that is already installed
      if (shouldInstall) {
        logger.success(
          'Flutter SDK: ${cyan.wrap(cacheVersion.printFriendlyName)} is already installed.',
        );
      }

      return _CacheReady(cacheVersion);
    }

    if (version.isCustom) {
      throw AppException('Local Flutter SDKs must be installed manually.');
    }

    if (!shouldInstall) {
      logger.info(
        'Flutter SDK: ${cyan.wrap(version.printFriendlyName)} is not installed.',
      );
      logger.info('Installing Flutter SDK automatically...');
    }

    final progress = logger.progress(
      'Installing Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
    );
    try {
      await flutterService.install(
        version,
        useGitCache: useGitCacheForInstall,
        onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
        observer: observer,
        cancellation: cancellation,
      );
    } on Exception {
      progress.fail('Failed to install ${version.name}');
      rethrow;
    }

    final newCacheVersion = cacheService.getVersion(version);
    if (newCacheVersion == null) {
      throw AppException('Could not verify cache version $version');
    }

    return _CacheReady(newCacheVersion, progress: progress);
  }

  Future<_CacheReady> _callWithVersionLocks(
    FlutterVersion version, {
    required bool shouldInstall,
    required bool force,
    required int retryCount,
    required bool useGitCacheForInstall,
    required bool cacheMaintenanceLockHeld,
    required void Function(GitCacheMaintenance maintenance)
    onGitCacheMaintenanceDeferred,
    required InstallObserver? observer,
    required ProcessCancellation? cancellation,
    required void Function() onLockAcquired,
  }) async {
    var versionsToLock = [version];

    while (true) {
      final lockedVersionPaths = versionsToLock
          .map(_versionLockIdentity)
          .toSet();
      Future<_LockedCacheResult> action() {
        onLockAcquired();

        return _callLocked(
          version,
          shouldInstall: shouldInstall,
          force: force,
          retryCount: retryCount,
          useGitCacheForInstall: useGitCacheForInstall,
          lockedVersionPaths: lockedVersionPaths,
          onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
          observer: observer,
          cancellation: cancellation,
        );
      }

      final result = cacheMaintenanceLockHeld
          ? await withVersionCacheLocksWhileMaintenanceLocked(
              context,
              versionsToLock,
              action,
            )
          : await withVersionCacheMutationLocks(
              context,
              versionsToLock,
              action,
            );

      switch (result) {
        case _CacheReady():
          return result;
        case _NeedsVersionLock(version: final additionalVersion):
          versionsToLock = [version, additionalVersion];
      }
    }
  }

  Future<_CacheReady> _callWithMutationLocks(
    FlutterVersion version, {
    required bool shouldInstall,
    required bool force,
    required int retryCount,
    required bool useGitCacheForInstall,
    required void Function(GitCacheMaintenance maintenance)
    onGitCacheMaintenanceDeferred,
    required InstallObserver? observer,
    required ProcessCancellation? cancellation,
    required void Function() onLockAcquired,
  }) {
    final needsGitCacheLock = useGitCacheForInstall && !version.fromFork;
    if (!needsGitCacheLock) {
      return _callWithVersionLocks(
        version,
        shouldInstall: shouldInstall,
        force: force,
        retryCount: retryCount,
        useGitCacheForInstall: useGitCacheForInstall,
        cacheMaintenanceLockHeld: false,
        onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
        observer: observer,
        cancellation: cancellation,
        onLockAcquired: onLockAcquired,
      );
    }

    return withSharedCacheMaintenanceLock(
      context,
      () => get<GitService>().withGitCacheLock(
        () => _callWithVersionLocks(
          version,
          shouldInstall: shouldInstall,
          force: force,
          retryCount: retryCount,
          useGitCacheForInstall: useGitCacheForInstall,
          cacheMaintenanceLockHeld: true,
          onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
          observer: observer,
          cancellation: cancellation,
          onLockAcquired: onLockAcquired,
        ),
      ),
    );
  }

  Future<CacheFlutterVersion> _completeInstallation(
    FlutterVersion requestedVersion,
    _CacheReady result,
    GitCacheMaintenance? maintenance,
  ) async {
    try {
      if (maintenance != null) {
        await get<FlutterService>().performDeferredGitCacheMaintenance(
          maintenance,
        );
      }

      result.progress?.complete(
        'Flutter SDK: ${cyan.wrap(requestedVersion.printFriendlyName)} installed!',
      );

      return result.version;
    } catch (error, stackTrace) {
      result.progress?.fail('Failed to install ${requestedVersion.name}');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Ensures that the specified Flutter SDK version is cached locally.
  ///
  /// Returns a [CacheFlutterVersion] which represents the locally cached version.
  Future<CacheFlutterVersion> call(
    FlutterVersion version, {
    bool shouldInstall = false,
    bool force = false,
    int retryCount = 0,
    bool? useGitCache,
    InstallObserver? observer,
    ProcessCancellation? cancellation,
  }) async {
    _validateContext();
    _validateGit();
    final cacheService = get<CacheService>();
    final gitService = get<GitService>();

    var cacheVersion = cacheService.getVersion(version);

    // Migrate legacy non-bare caches if present.
    // Refresh the git cache only when we actually need to clone (cache miss).
    final shouldUseGitCache = useGitCache ?? context.gitCache;
    var useGitCacheForInstall = shouldUseGitCache;
    if (shouldUseGitCache && !version.fromFork) {
      try {
        await gitService.ensureBareCacheIfPresent();
        cacheVersion = cacheService.getVersion(version);
        if (cacheVersion == null) {
          await gitService.updateLocalMirror();
        }
      } on GitCacheDependentSdkRemovalException {
        rethrow;
      } on Exception catch (e) {
        useGitCacheForInstall = false;
        logger.debug('Local cache setup exception: $e');
        logger.warn('Failed to setup local cache. Falling back to git clone.');
      }
    }

    GitCacheMaintenance? deferredGitCacheMaintenance;
    final _CacheReady result;
    observer?.onUpdate((
      phase: InstallObservationPhase.acquireLock,
      status: InstallObservationStatus.active,
      detail: 'Waiting for cache mutation lock',
      gitProgress: null,
    ));
    var reportedLockAcquired = false;
    void onLockAcquired() {
      if (reportedLockAcquired) return;
      reportedLockAcquired = true;
      observer?.onUpdate((
        phase: InstallObservationPhase.acquireLock,
        status: InstallObservationStatus.complete,
        detail: 'Cache mutation lock acquired',
        gitProgress: null,
      ));
    }

    try {
      result = await _callWithMutationLocks(
        version,
        shouldInstall: shouldInstall,
        force: force,
        retryCount: retryCount,
        useGitCacheForInstall: useGitCacheForInstall,
        onGitCacheMaintenanceDeferred: (maintenance) {
          deferredGitCacheMaintenance = maintenance;
        },
        observer: observer,
        cancellation: cancellation,
        onLockAcquired: onLockAcquired,
      );
    } catch (error, stackTrace) {
      final maintenance = deferredGitCacheMaintenance;
      if (maintenance != null) {
        await get<FlutterService>().performDeferredGitCacheMaintenance(
          maintenance,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    return _completeInstallation(version, result, deferredGitCacheMaintenance);
  }
}
