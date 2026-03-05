import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:git/git.dart';
import 'package:path/path.dart' as path;

import '../models/flutter_version_model.dart';
import '../models/git_reference_model.dart';
import '../utils/exceptions.dart';
import '../utils/file_utils.dart';
import '../utils/git_clone_progress_tracker.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'process_service.dart';

/// Cache state for migration decisions.
/// - missing: no cache directory
/// - invalid: exists but not a git repo
/// - legacy: non-bare clone (needs migration)
/// - ready: bare mirror, ready for use
enum _GitCacheState { missing, invalid, legacy, ready }

/// Manages git cache (bare mirror), cloning, migration, and reference lookups.
class GitService extends ContextualService {
  List<GitReference>? _referencesCache;

  GitService(super.context);

  bool _isLockContentionError(FileSystemException error) {
    final message = error.message.toLowerCase();

    return message.contains('lock failed') ||
        message.contains('resource temporarily unavailable') ||
        message.contains('operation would block') ||
        message.contains('already locked') ||
        message.contains('being used by another process');
  }

  Never _throwLockAcquisitionError(
    File lockFile,
    FileSystemException error,
    StackTrace stackTrace,
  ) {
    Error.throwWithStackTrace(
      AppException(
        'Failed to acquire git cache lock at ${lockFile.path}: '
        '${error.message}',
      ),
      stackTrace,
    );
  }

  Future<RandomAccessFile> _openCacheMutationLock(File lockFile) async {
    try {
      return await lockFile.open(mode: FileMode.write);
    } on FileSystemException catch (error, stackTrace) {
      _throwLockAcquisitionError(lockFile, error, stackTrace);
    }
  }

  Future<void> _acquireCacheMutationLock(
    RandomAccessFile lockHandle,
    File lockFile,
  ) async {
    const retryDelay = Duration(milliseconds: 150);
    const waitLogThreshold = Duration(seconds: 2);
    const maxWait = Duration(minutes: 5);

    final lockWaitStart = DateTime.now();
    var waitingLogged = false;

    while (true) {
      try {
        await lockHandle.lock(FileLock.exclusive);
        return;
      } on FileSystemException catch (error, stackTrace) {
        if (!_isLockContentionError(error)) {
          _throwLockAcquisitionError(lockFile, error, stackTrace);
        }

        final elapsed = DateTime.now().difference(lockWaitStart);
        if (elapsed > maxWait) {
          Error.throwWithStackTrace(
            AppException(
              'Timed out waiting for git cache lock at ${lockFile.path} '
              'after ${elapsed.inSeconds}s.',
            ),
            stackTrace,
          );
        }

        if (!waitingLogged && elapsed >= waitLogThreshold) {
          waitingLogged = true;
          logger.debug('Waiting for git cache lock at ${lockFile.path}...');
        }

        await Future<void>.delayed(retryDelay);
      }
    }
  }

  Future<void> _releaseCacheMutationLock(
    RandomAccessFile lockHandle,
    File lockFile, {
    required bool unlock,
  }) async {
    if (unlock) {
      try {
        await lockHandle.unlock();
      } on FileSystemException catch (error) {
        logger.warn(
          'Failed to unlock git cache lock at ${lockFile.path}: '
          '${error.message}',
        );
      }
    }

    try {
      await lockHandle.close();
    } on FileSystemException catch (error) {
      logger.warn(
        'Failed to close git cache lock at ${lockFile.path}: '
        '${error.message}',
      );
    }
  }

  Future<T> _withCacheMutationLock<T>(Future<T> Function() action) async {
    final lockFile = File('${context.gitCachePath}.lock');
    if (!lockFile.parent.existsSync()) {
      lockFile.parent.createSync(recursive: true);
    }

    RandomAccessFile? lockHandle;
    var lockAcquired = false;

    try {
      lockHandle = await _openCacheMutationLock(lockFile);
      await _acquireCacheMutationLock(lockHandle, lockFile);
      lockAcquired = true;
      return await action();
    } finally {
      if (lockHandle != null) {
        await _releaseCacheMutationLock(
          lockHandle,
          lockFile,
          unlock: lockAcquired,
        );
      }
    }
  }

  /// Creates a uniquely-named temp directory next to [baseDir] using [suffix]
  /// to distinguish the operation. The parent is created if needed.
  Directory _createTempDir(Directory baseDir, String suffix) {
    if (!baseDir.parent.existsSync()) {
      baseDir.parent.createSync(recursive: true);
    }
    final stamp =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    return Directory(
      path.join(
          baseDir.parent.path, '${path.basename(baseDir.path)}.$suffix.$stamp'),
    );
  }

  /// Runs [action] in a temp directory, cleaning up on failure.
  Future<Directory> _withTempDir(
    Directory baseDir,
    String suffix,
    Future<void> Function(Directory tempDir) action,
  ) async {
    final tempDir = _createTempDir(baseDir, suffix);
    if (tempDir.existsSync()) {
      await _deleteDirectoryWithRetry(tempDir, requireSuccess: false);
    }
    try {
      await action(tempDir);
      return tempDir;
    } catch (_) {
      if (tempDir.existsSync()) {
        await _deleteDirectoryWithRetry(tempDir, requireSuccess: false);
      }
      rethrow;
    }
  }

  Future<void> _createLocalMirror() async {
    final gitCacheDir = Directory(context.gitCachePath);

    final tempDir = await _withTempDir(gitCacheDir, 'tmp', (dir) async {
      await _cloneMirrorInto(dir);
    });

    await _atomicDirectorySwap(
      targetPath: gitCacheDir.path,
      replacementDir: tempDir,
      restoreFailureLabel: 'previous cache',
    );

    logger.info('Local mirror created successfully!');
    await _tryRewriteAlternates();
  }

  /// Best-effort update of SDK alternates after mirror rebuild/migration.
  Future<void> _tryRewriteAlternates() async {
    try {
      await _rewriteAlternatesToBarePath();
    } catch (e) {
      logger.warn(
        'Failed to update SDK alternates: $e. Installed SDKs may need reinstall.',
      );
    }
  }

  Future<Directory> _cloneMirrorInto(Directory gitCacheDir) async {
    logger.info('Creating local mirror...');
    final process = await Process.start(
      'git',
      [
        'clone',
        '--mirror',
        '--progress',
        if (Platform.isWindows) '-c',
        if (Platform.isWindows) 'core.longpaths=true',
        context.flutterUrl,
        gitCacheDir.path,
      ],
      runInShell: true,
    );

    final processLogs = <String>[];
    final progressTracker = GitCloneProgressTracker(logger);

    final stderrDone = process.stderr.transform(utf8.decoder).forEach((line) {
      progressTracker.processLine(line);
      processLogs.add(line);
    });

    final stdoutDone = process.stdout.transform(utf8.decoder).forEach(
          logger.info,
        );

    final exitCode = await process.exitCode;
    await Future.wait([stderrDone, stdoutDone]);
    if (exitCode != 0) {
      progressTracker.complete();
      logger.err(processLogs.join('\n'));
      if (gitCacheDir.existsSync()) {
        await _deleteDirectoryWithRetry(gitCacheDir, requireSuccess: false);
      }
      throw AppException(
        'Unable to create the local Flutter git mirror. '
        'Exit code: $exitCode. '
        'Rerun with --verbose for more details.\n'
        '${processLogs.isNotEmpty ? processLogs.join('\n') : 'No output captured.'}',
      );
    }

    progressTracker.complete();
    try {
      await _validateMirror(gitCacheDir);
      if (!await _isBareRepository(gitCacheDir.path)) {
        throw const ProcessException(
          'git',
          ['config', '--bool', 'core.bare'],
          'Mirror is not bare after clone',
          1,
        );
      }
    } on ProcessException {
      await _deleteDirectoryWithRetry(gitCacheDir, requireSuccess: false);
      rethrow;
    }

    return gitCacheDir;
  }

  Future<void> _validateMirror(Directory directory) {
    return get<ProcessService>().run(
      'git',
      args: ['fsck', '--connectivity-only'],
      workingDirectory: directory.path,
    );
  }

  Future<bool> _isBareRepository(String path) async {
    final result = await get<ProcessService>().run(
      'git',
      args: ['config', '--bool', 'core.bare'],
      workingDirectory: path,
    );

    return (result.stdout as String?)?.trim().toLowerCase() == 'true';
  }

  Future<List<GitReference>> _fetchGitReferences() async {
    if (_referencesCache != null) return _referencesCache!;

    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['ls-remote', '--tags', '--branches', context.flutterUrl],
      );

      return _referencesCache = GitReference.parseGitReferences(
        result.stdout as String,
      );
    } on ProcessException catch (error, stackTrace) {
      logger.debug('ProcessException while fetching git references: $error');
      Error.throwWithStackTrace(
        AppException(
          'Failed to fetch git references from ${context.flutterUrl}. '
          'Ensure git is installed and the URL is accessible.',
        ),
        stackTrace,
      );
    }
  }

  Future<void> _deleteDirectoryWithRetry(
    Directory directory, {
    bool requireSuccess = true,
  }) async {
    await deleteDirectoryWithRetry(
      directory,
      requireSuccess: requireSuccess,
      onFinalError: requireSuccess
          ? null
          : (error) {
              logger.warn(
                'Unable to delete ${directory.path}: ${error.message}',
              );
            },
    );
  }

  /// Cleans up orphaned temp directories from previous failed operations
  /// (can accumulate on Windows when file locking prevents deletion).
  Future<void> _cleanupOrphanedTempDirs(Directory parentDir) async {
    if (!parentDir.existsSync()) return;

    final baseName = path.basename(context.gitCachePath);
    for (final entity in parentDir.listSync()) {
      if (entity is! Directory) continue;
      final name = path.basename(entity.path);
      // Match patterns: {baseName}.tmp.{ts}_{rand} and {baseName}.bare-tmp.{ts}_{rand}
      if ((name.startsWith('$baseName.tmp.') ||
              name.startsWith('$baseName.bare-tmp.')) &&
          RegExp(r'\.\d+(_\d+)?$').hasMatch(name)) {
        await _deleteDirectoryWithRetry(entity, requireSuccess: false);
      }
    }
  }

  Future<_GitCacheState> _determineCacheState(Directory gitCacheDir) async {
    if (!gitCacheDir.existsSync()) {
      return _GitCacheState.missing;
    }

    try {
      if (await _isBareRepository(gitCacheDir.path)) {
        return _GitCacheState.ready;
      }

      return _GitCacheState.legacy;
    } on ProcessException catch (error) {
      logger.debug(
        'Git cache at ${gitCacheDir.path} is invalid (${error.message}).',
      );

      return _GitCacheState.invalid;
    }
  }

  Future<void> _refreshExistingMirror(Directory gitCacheDir) async {
    try {
      await _validateMirror(gitCacheDir);
    } on ProcessException catch (error) {
      logger.warn(
        'Local mirror validation failed (${error.message}). Attempting repair...',
      );
      try {
        await _syncMirrorWithRemote(gitCacheDir);
        await _validateMirror(gitCacheDir);
        logger.info('Mirror repaired successfully via fetch');
        return;
      } on ProcessException {
        logger.warn('Repair failed, recreating mirror from scratch...');
        await _createLocalMirror();
        return;
      }
    }

    await _syncMirrorWithRemote(gitCacheDir);
    logger.debug('Local mirror updated successfully');
  }

  /// Rewrites alternates files from legacy non-bare path to the bare mirror.
  /// Safe to run multiple times; only updates entries that reference our cache
  /// path but don't yet point at the bare `objects` directory.
  Future<void> _rewriteAlternatesToBarePath() async {
    final versions = await get<CacheService>().getAllVersions();
    if (versions.isEmpty) return;

    // Resolve symlinks so macOS /var -> /private/var doesn't break matching
    final cacheDir = Directory(context.gitCachePath);
    final resolvedCachePath = cacheDir.existsSync()
        ? cacheDir.resolveSymbolicLinksSync()
        : context.gitCachePath;
    final desiredPath = path.normalize(
      path.join(resolvedCachePath, 'objects'),
    );
    final desiredParent = path.normalize(resolvedCachePath);

    // Platform-aware path comparison (Windows is case-insensitive)
    String comparable(String p) => Platform.isWindows ? p.toLowerCase() : p;

    bool isWithinCachePath(String target) {
      final targetComparable = comparable(target);
      final cacheComparable = comparable(desiredParent);
      return targetComparable == cacheComparable ||
          path.isWithin(cacheComparable, targetComparable);
    }

    for (final version in versions) {
      final alternatesFile = File(
        path.join(version.directory, '.git', 'objects', 'info', 'alternates'),
      );
      if (!alternatesFile.existsSync()) continue;

      try {
        final current = alternatesFile.readAsStringSync().trim();

        // Resolve relative paths and symlinks for reliable comparison
        final currentRaw = path.isAbsolute(current)
            ? current
            : path.join(alternatesFile.parent.path, current);
        final currentNorm = path.normalize(
          Directory(currentRaw).existsSync()
              ? Directory(currentRaw).resolveSymbolicLinksSync()
              : currentRaw,
        );

        if (!isWithinCachePath(currentNorm)) continue;
        if (comparable(currentNorm) == comparable(desiredPath)) continue;

        alternatesFile.writeAsStringSync('$desiredPath\n');
        logger.info(
          'Updated alternates for ${version.name} -> $desiredPath',
        );
      } on FileSystemException catch (error) {
        logger.warn(
          'Unable to update alternates for ${version.name}: ${error.message}',
        );
      }
    }
  }

  Future<void> _syncMirrorWithRemote(Directory gitCacheDir) async {
    logger.debug('Updating local mirror from ${context.flutterUrl}');
    await setOriginUrl(
      repositoryPath: gitCacheDir.path,
      url: context.flutterUrl,
    );

    await get<ProcessService>().run(
      'git',
      args: ['remote', 'update', '--prune', 'origin'],
      workingDirectory: gitCacheDir.path,
    );
  }

  /// Returns the entity at [entityPath] based on its file system type,
  /// or null if nothing exists there.
  static FileSystemEntity? _entityAt(String entityPath) {
    final type = FileSystemEntity.typeSync(entityPath, followLinks: false);
    switch (type) {
      case FileSystemEntityType.directory:
        return Directory(entityPath);
      case FileSystemEntityType.file:
        return File(entityPath);
      case FileSystemEntityType.link:
        return Link(entityPath);
      default:
        return null;
    }
  }

  /// Deletes whatever exists at [entityPath] (file, link, or directory).
  Future<void> _deleteEntityAt(String entityPath) async {
    final entity = _entityAt(entityPath);
    if (entity == null) return;
    if (entity is Directory) {
      await _deleteDirectoryWithRetry(entity, requireSuccess: false);
    } else {
      entity.deleteSync();
    }
  }

  /// Atomically replaces [targetPath] with [replacementDir] using a backup for
  /// rollback.
  Future<void> _atomicDirectorySwap({
    required String targetPath,
    required Directory replacementDir,
    String restoreFailureLabel = 'previous cache',
  }) async {
    final targetDir = Directory(targetPath);
    final existingEntity = _entityAt(targetPath);
    final backupSuffix =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    final backupPath = path.join(
      targetDir.parent.path,
      '${path.basename(targetPath)}.backup.$backupSuffix',
    );

    try {
      if (existingEntity != null) {
        await _deleteEntityAt(backupPath);
        existingEntity.renameSync(backupPath);
      }

      replacementDir.renameSync(targetPath);
    } catch (_) {
      // Restore from backup if the target was moved but replacement failed
      if (!targetDir.existsSync()) {
        final backup = _entityAt(backupPath);
        if (backup != null) {
          try {
            backup.renameSync(targetPath);
          } on FileSystemException catch (restoreError) {
            logger.warn(
              'Failed to restore $restoreFailureLabel: ${restoreError.message}',
            );
          }
        }
      }
      rethrow;
    }

    await _deleteEntityAt(backupPath);
    await _cleanupOrphanedTempDirs(targetDir.parent);
  }

  /// Migrates an existing non-bare cache clone to a bare mirror without
  /// re-downloading. Reuses local objects and only fetches deltas.
  Future<void> _migrateCacheCloneToMirror(
    Directory legacyDir, {
    bool updateRemote = true,
  }) async {
    logger.info('Migrating cache clone to bare mirror...');

    final processService = get<ProcessService>();

    // Clean the legacy clone to release file locks and normalize state
    for (final args in [
      ['reset', '--hard', 'HEAD'],
      ['clean', '-fdx'],
    ]) {
      try {
        await processService.run(
          'git',
          args: args,
          workingDirectory: legacyDir.path,
        );
      } on ProcessException catch (e) {
        logger.debug('${args.first} failed (${e.message}), continuing...');
      }
    }

    // Create bare mirror from local clone (fast — no network needed)
    logger.info('Creating bare mirror from local clone...');
    final tempBareDir = await _withTempDir(legacyDir, 'bare-tmp', (dir) async {
      await processService.run(
        'git',
        args: [
          'clone',
          '--mirror',
          if (Platform.isWindows) '-c',
          if (Platform.isWindows) 'core.longpaths=true',
          legacyDir.path,
          dir.path,
        ],
      );

      // Point at the official remote
      if (updateRemote) {
        logger.info('Fetching latest from remote...');
        await _syncMirrorWithRemote(dir);
      } else {
        await setOriginUrl(repositoryPath: dir.path, url: context.flutterUrl);
      }

      // Validate the new mirror
      await _validateMirror(dir);
      if (!await _isBareRepository(dir.path)) {
        throw AppException('Migration resulted in non-bare repository');
      }
    });

    await _atomicDirectorySwap(
      targetPath: legacyDir.path,
      replacementDir: tempBareDir,
      restoreFailureLabel: 'legacy cache',
    );

    logger.info('Legacy cache migrated to bare mirror successfully!');
    await _tryRewriteAlternates();

    // Final safeguard: verify resulting cache is bare; otherwise recreate
    // from scratch to avoid leaving legacy worktree layouts behind.
    if (!await _isBareRepository(legacyDir.path)) {
      logger.warn('Migration yielded non-bare cache, recreating mirror...');
      await _deleteDirectoryWithRetry(legacyDir, requireSuccess: false);
      await _createLocalMirror();
    }
  }

  Future<void> setOriginUrl({
    required String repositoryPath,
    required String url,
  }) {
    return get<ProcessService>().run(
      'git',
      args: ['remote', 'set-url', 'origin', url],
      workingDirectory: repositoryPath,
    );
  }

  Future<bool> removeLocalMirror({
    bool requireSuccess = false,
    void Function(FileSystemException error)? onFinalError,
  }) {
    return _withCacheMutationLock(() async {
      final cacheDir = Directory(context.gitCachePath);

      return deleteDirectoryWithRetry(
        cacheDir,
        requireSuccess: requireSuccess,
        onFinalError: onFinalError ??
            (error) {
              logger.warn(
                'Unable to delete local mirror at ${cacheDir.path}: ${error.message}',
              );
            },
      );
    });
  }

  Future<bool> isGitReference(String version) async {
    final references = await _fetchGitReferences();

    return references.any((reference) => reference.name == version);
  }

  /// Resets to specific reference
  Future<void> resetHard(String path, String reference) async {
    final gitDir = await GitDir.fromExisting(path);
    await gitDir.runCommand(['reset', '--hard', reference]);
  }

  Future<void> updateLocalMirror() {
    return _withCacheMutationLock(() async {
      final gitCacheDir = Directory(context.gitCachePath);

      final cacheState = await _determineCacheState(gitCacheDir);

      switch (cacheState) {
        case _GitCacheState.ready:
          await _refreshExistingMirror(gitCacheDir);
          break;
        case _GitCacheState.legacy:
          // Migrate existing clone to bare mirror (fast - uses local objects)
          await _migrateCacheCloneToMirror(gitCacheDir);
          break;
        case _GitCacheState.invalid:
          // Try migration first - may have usable objects even if repo state is bad
          logger.debug('Attempting to salvage invalid cache...');
          try {
            await _migrateCacheCloneToMirror(gitCacheDir);
          } catch (e) {
            logger.warn('Migration failed ($e), recreating from scratch...');
            // Ensure clean slate before full recreation
            if (gitCacheDir.existsSync()) {
              await _deleteDirectoryWithRetry(
                gitCacheDir,
                requireSuccess: false,
              );
            }
            await _createLocalMirror();
          }
          break;
        case _GitCacheState.missing:
          logger.debug('Git cache not found. Creating mirror...');
          await _createLocalMirror();
          break;
      }
    });
  }

  /// Migrates a legacy non-bare cache to a bare mirror if present.
  /// Does not create or refresh the mirror from remote.
  Future<void> ensureBareCacheIfPresent() {
    return _withCacheMutationLock(() async {
      final gitCacheDir = Directory(context.gitCachePath);
      if (!gitCacheDir.existsSync()) return;

      final cacheState = await _determineCacheState(gitCacheDir);
      if (cacheState == _GitCacheState.ready) {
        return;
      }

      if (cacheState == _GitCacheState.legacy) {
        await _migrateCacheCloneToMirror(gitCacheDir, updateRemote: false);
        return;
      }

      // Defer handling to install/update workflows to avoid heavy work here.
      logger.debug(
        'Git cache is invalid; skipping migration. It will be recreated on next install.',
      );
    });
  }

  /// Resolves [version] to a [GitDir] for the cached SDK directory.
  Future<GitDir> _resolveGitDir(String version) async {
    final flutterVersion = FlutterVersion.parse(version);
    final versionDir = get<CacheService>().getVersionCacheDir(flutterVersion);

    if (!await GitDir.isGitDir(versionDir.path)) {
      throw Exception('Not a git directory');
    }

    return GitDir.fromExisting(versionDir.path);
  }

  /// Returns the branch name for a cached [version].
  Future<String?> getBranch(String version) async {
    final gitDir = await _resolveGitDir(version);
    final result = await gitDir.currentBranch();
    return result.branchName;
  }

  /// Returns the exact tag for a cached [version], or null if none matches.
  Future<String?> getTag(String version) async {
    final gitDir = await _resolveGitDir(version);

    try {
      final pr = await gitDir.runCommand([
        'describe',
        '--tags',
        '--exact-match',
      ]);
      return (pr.stdout as String).trim();
    } on ProcessException catch (e) {
      if (e.message.toLowerCase().contains('no tag exactly matches')) {
        logger.debug('No exact tag match for version "$version".');
        return null;
      }
      logger.err('Failed to get tag for version "$version": ${e.message}');
      rethrow;
    } catch (e) {
      logger.err('Unexpected error getting tag for version "$version": $e');
      rethrow;
    }
  }
}
