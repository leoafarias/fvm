import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:git/git.dart';
import 'package:path/path.dart' as path;

import '../models/flutter_version_model.dart';
import '../models/git_reference_model.dart';
import '../utils/exceptions.dart';
import '../utils/file_utils.dart';
import '../utils/file_lock.dart';
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

/// Service for Git operations
/// Handles git cache management and repository operations
class GitService extends ContextualService {
  static const _gitCacheLockTtl = Duration(minutes: 10);

  late final FileLocker _updatingCacheLock;
  List<GitReference>? _referencesCache;

  GitService(super.context) {
    // Create lock based on gitCachePath so all processes using the same
    // git cache share the same lock, even if they have different cachePath.
    // This prevents race conditions when tests share a git cache but have
    // isolated FVM cache directories.
    _updatingCacheLock = createGitCacheLock();
  }

  Future<void> _createLocalMirror() async {
    final gitCacheDir = Directory(context.gitCachePath);
    // Use timestamp + random to avoid conflicts from concurrent operations
    // and when previous temp dirs can't be deleted (Windows file locking)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    final tempDir = Directory(
      path.join(
        gitCacheDir.parent.path,
        '${path.basename(gitCacheDir.path)}.tmp.${timestamp}_$random',
      ),
    );

    // Ensure the parent exists
    if (!gitCacheDir.parent.existsSync()) {
      gitCacheDir.parent.createSync(recursive: true);
    }

    // Clean any previous temp clone
    if (tempDir.existsSync()) {
      await _deleteDirectoryWithRetry(tempDir, requireSuccess: false);
    }

    try {
      await _cloneMirrorInto(tempDir);
    } catch (error) {
      // Ensure we don't leave a partial temp clone behind on failure
      if (tempDir.existsSync()) {
        await _deleteDirectoryWithRetry(tempDir, requireSuccess: false);
      }
      rethrow;
    }

    // Swap directories safely by using a backup in the same parent directory.
    final cachePathType = FileSystemEntity.typeSync(
      gitCacheDir.path,
      followLinks: false,
    );
    final backupSuffix = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    final backupPath = path.join(
      gitCacheDir.parent.path,
      '${path.basename(gitCacheDir.path)}.backup.$backupSuffix',
    );

    FileSystemEntity? backupEntity;
    if (cachePathType == FileSystemEntityType.file ||
        cachePathType == FileSystemEntityType.link) {
      backupEntity = cachePathType == FileSystemEntityType.file
          ? File(gitCacheDir.path)
          : Link(gitCacheDir.path);
    } else if (cachePathType == FileSystemEntityType.directory) {
      backupEntity = gitCacheDir;
    }

    try {
      if (backupEntity != null) {
        final existingBackupType = FileSystemEntity.typeSync(
          backupPath,
          followLinks: false,
        );
        if (existingBackupType == FileSystemEntityType.directory) {
          await _deleteDirectoryWithRetry(
            Directory(backupPath),
            requireSuccess: false,
          );
        } else if (existingBackupType == FileSystemEntityType.file) {
          File(backupPath).deleteSync();
        } else if (existingBackupType == FileSystemEntityType.link) {
          Link(backupPath).deleteSync();
        }
        backupEntity.renameSync(backupPath);
      }

      tempDir.renameSync(gitCacheDir.path);
    } catch (error) {
      if (!gitCacheDir.existsSync() && backupEntity != null) {
        try {
          if (backupEntity is Directory) {
            Directory(backupPath).renameSync(gitCacheDir.path);
          } else if (backupEntity is File) {
            File(backupPath).renameSync(gitCacheDir.path);
          } else if (backupEntity is Link) {
            Link(backupPath).renameSync(gitCacheDir.path);
          }
        } on FileSystemException catch (restoreError) {
          logger.warn('Failed to restore previous cache: ${restoreError.message}');
        }
      }
      rethrow;
    }

    if (backupEntity != null) {
      final backupType = FileSystemEntity.typeSync(
        backupPath,
        followLinks: false,
      );
      if (backupType == FileSystemEntityType.directory) {
        await _deleteDirectoryWithRetry(
          Directory(backupPath),
          requireSuccess: false,
        );
      } else if (backupType == FileSystemEntityType.file) {
        File(backupPath).deleteSync();
      } else if (backupType == FileSystemEntityType.link) {
        Link(backupPath).deleteSync();
      }
    }

    // Clean up orphaned temp directories from previous runs (after rename completes)
    await _cleanupOrphanedTempDirs(gitCacheDir.parent);

    logger.info('Local mirror created successfully!');

    // After rebuilding the mirror, ensure all installed SDKs point their
    // alternates to the new bare path (cache.git/objects).
    try {
      await _rewriteAlternatesToBarePath();
    } catch (e) {
      logger.warn('Failed to update SDK alternates: $e. Installed SDKs may need reinstall.');
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
      // Ensure the mirror is actually bare; a non-bare clone here would
      // break later operations and should be treated as invalid.
      if (!await _isBareRepository(gitCacheDir.path)) {
        throw const ProcessException(
          'git',
          ['config', '--bool', 'core.bare'],
          'Mirror is not bare after clone',
          1,
        );
      }
    } on ProcessException {
      // Only ProcessException expected from ProcessService.run()
      // Cleanup corrupted mirror before rethrowing
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

  /// Returns true if the repository at [path] is a bare repository.
  Future<bool> _isBareRepository(String path) async {
    final result = await get<ProcessService>().run(
      'git',
      args: ['config', '--bool', 'core.bare'],
      workingDirectory: path,
    );

    return (result.stdout as String?)?.trim().toLowerCase() == 'true';
  }

  /// Helper method to run git ls-remote commands against the remote repository
  Future<List<GitReference>> _fetchGitReferences() async {
    if (_referencesCache != null) return _referencesCache!;

    final List<String> command = ['ls-remote', '--tags', '--branches'];

    command.add(context.flutterUrl);

    try {
      final result = await get<ProcessService>().run('git', args: command);

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

  /// Cleans up orphaned temp directories from previous failed operations.
  /// These can accumulate when Windows file locking prevents deletion.
  Future<void> _cleanupOrphanedTempDirs(Directory parentDir) async {
    if (!parentDir.existsSync()) return;

    final baseName = path.basename(context.gitCachePath);
    for (final entity in parentDir.listSync()) {
      if (entity is! Directory) continue;
      final name = path.basename(entity.path);
      // Match temp dir patterns: {baseName}.tmp.{timestamp}_{random}, {baseName}.bare-tmp.{timestamp}_{random}
      // e.g., cache.git.tmp.1234567890_12345, cache.git.bare-tmp.1234567890_12345
      // Also matches legacy format without random suffix for cleanup compatibility
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
      // Try to repair by fetching from remote - this can fix missing objects
      try {
        await _syncMirrorWithRemote(gitCacheDir);
        await _validateMirror(gitCacheDir);
        logger.info('Mirror repaired successfully via fetch');

        return;
      } on ProcessException {
        // Repair failed, need full recreate
        logger.warn('Repair failed, recreating mirror from scratch...');
        await _createLocalMirror();

        return;
      }
    }

    await _syncMirrorWithRemote(gitCacheDir);
    logger.debug('Local mirror updated successfully');
  }

  /// Rewrites alternates files from legacy non-bare path to the bare mirror.
  /// Safe to run multiple times; it only updates entries that point at the
  /// current cache path but still include the legacy `/.git/objects` suffix or
  /// any other mismatched subpath.
  Future<void> _rewriteAlternatesToBarePath() async {
    final cacheService = get<CacheService>();
    final versions = await cacheService.getAllVersions();
    if (versions.isEmpty) return;

    final desiredPath = path.normalize(
      path.join(context.gitCachePath, 'objects'),
    );
    final desiredParent = path.normalize(path.join(context.gitCachePath));

    for (final version in versions) {
      final alternatesFile = File(
        path.join(version.directory, '.git', 'objects', 'info', 'alternates'),
      );

      if (!alternatesFile.existsSync()) continue;

      try {
        final current = alternatesFile.readAsStringSync().trim();

        // Resolve relative paths from the alternates file's directory, not cwd
        final currentNorm = path.normalize(
          path.isAbsolute(current)
              ? current
              : path.join(alternatesFile.parent.path, current),
        );

        // Only fix alternates that reference our cache path (not backups, etc.)
        // Use case-insensitive comparison on Windows where paths are case-insensitive
        final matchesParent = Platform.isWindows
            ? currentNorm.toLowerCase().startsWith(desiredParent.toLowerCase())
            : currentNorm.startsWith(desiredParent);
        if (!matchesParent) {
          continue;
        }

        if (currentNorm == desiredPath) {
          continue; // already correct
        }

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

  /// Migrates an existing non-bare cache clone to a bare mirror without
  /// re-downloading. This reuses local objects and only fetches deltas.
  Future<void> _migrateCacheCloneToMirror(
    Directory legacyDir, {
    bool updateRemote = true,
  }) async {
    logger.info('Migrating cache clone to bare mirror...');

    final processService = get<ProcessService>();

    // Step 1: Clean the legacy clone to ensure no file locks or weird state
    logger.debug('Cleaning legacy clone...');
    try {
      await processService.run(
        'git',
        args: ['reset', '--hard', 'HEAD'],
        workingDirectory: legacyDir.path,
      );
    } on ProcessException catch (e) {
      // Continue even if reset fails (e.g., detached HEAD edge cases)
      logger.debug('Reset failed (${e.message}), continuing...');
    }

    try {
      await processService.run(
        'git',
        args: ['clean', '-fdx'],
        workingDirectory: legacyDir.path,
      );
    } on ProcessException catch (e) {
      logger.debug('Clean failed (${e.message}), continuing...');
    }

    // Step 2: Create bare mirror from local clone (fast - no network)
    // Use timestamp + random to avoid conflicts from concurrent operations
    // and when previous temp dirs can't be deleted (Windows file locking)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    final tempBareDir = Directory(
      path.join(
        legacyDir.parent.path,
        '${path.basename(legacyDir.path)}.bare-tmp.${timestamp}_$random',
      ),
    );

    // Clean any previous temp directory
    if (tempBareDir.existsSync()) {
      await _deleteDirectoryWithRetry(tempBareDir, requireSuccess: false);
    }

    logger.info('Creating bare mirror from local clone...');
    try {
      await processService.run(
        'git',
        args: [
          'clone',
          '--mirror',
          if (Platform.isWindows) '-c',
          if (Platform.isWindows) 'core.longpaths=true',
          legacyDir.path,
          tempBareDir.path,
        ],
      );
    } catch (error) {
      // Clean up on failure
      if (tempBareDir.existsSync()) {
        await _deleteDirectoryWithRetry(tempBareDir, requireSuccess: false);
      }
      rethrow;
    }

    // Step 3: Sync remote (set origin + fetch latest delta) if requested
    if (updateRemote) {
      logger.info('Fetching latest from remote...');
      try {
        await _syncMirrorWithRemote(tempBareDir);
      } catch (error) {
        await _deleteDirectoryWithRetry(tempBareDir, requireSuccess: false);
        rethrow;
      }
    } else {
      // Ensure the mirror points at the official remote even if we skip fetch
      await setOriginUrl(
        repositoryPath: tempBareDir.path,
        url: context.flutterUrl,
      );
    }

    // Step 4: Validate the new mirror
    logger.debug('Validating new mirror...');
    try {
      await _validateMirror(tempBareDir);

      // Verify it's actually bare
      if (!await _isBareRepository(tempBareDir.path)) {
        throw AppException('Migration resulted in non-bare repository');
      }
    } catch (error) {
      await _deleteDirectoryWithRetry(tempBareDir, requireSuccess: false);
      rethrow;
    }

    // Step 5: Swap directories - rename legacy to backup, temp to target
    logger.debug('Swapping directories...');
    final backupSuffix = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    final backupDir = Directory(
      path.join(
        legacyDir.parent.path,
        '${path.basename(legacyDir.path)}.backup.$backupSuffix',
      ),
    );

    if (backupDir.existsSync()) {
      await _deleteDirectoryWithRetry(backupDir, requireSuccess: false);
    }

    try {
      legacyDir.renameSync(backupDir.path);
      tempBareDir.renameSync(legacyDir.path);
    } catch (error) {
      if (!legacyDir.existsSync() && backupDir.existsSync()) {
        try {
          backupDir.renameSync(legacyDir.path);
        } on FileSystemException catch (restoreError) {
          logger.warn(
            'Failed to restore legacy cache: ${restoreError.message}',
          );
        }
      }
      rethrow;
    }

    if (backupDir.existsSync()) {
      await _deleteDirectoryWithRetry(backupDir, requireSuccess: false);
    }

    // Clean up orphaned temp directories from previous runs
    await _cleanupOrphanedTempDirs(legacyDir.parent);

    logger.info('Legacy cache migrated to bare mirror successfully!');

    // Step 6: Update alternates in installed SDKs to point to new bare path
    try {
      await _rewriteAlternatesToBarePath();
    } catch (e) {
      logger.warn('Failed to update SDK alternates: $e. Installed SDKs may need reinstall.');
    }

    // Final safeguard: verify resulting cache is bare; otherwise recreate
    // from scratch to avoid leaving legacy worktree layouts behind.
    if (!await _isBareRepository(legacyDir.path)) {
      logger.warn('Migration yielded non-bare cache, recreating mirror...');
      await _deleteDirectoryWithRetry(legacyDir, requireSuccess: false);
      await _createLocalMirror();
    }
  }

  FileLocker createGitCacheLock() {
    return FileLocker(
      '${context.gitCachePath}.lock',
      lockExpiration: _gitCacheLockTtl,
    );
  }

  /// Sets the repository origin URL for the given git directory.
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

  Future<bool> isGitReference(String version) async {
    final references = await _fetchGitReferences();

    return references.any((reference) => reference.name == version);
  }

  /// Resets to specific reference
  Future<void> resetHard(String path, String reference) async {
    final gitDir = await GitDir.fromExisting(path);
    await gitDir.runCommand(['reset', '--hard', reference]);
  }

  Future<void> updateLocalMirror() async {
    final unlock = await _updatingCacheLock.getLock();
    final gitCacheDir = Directory(context.gitCachePath);

    try {
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
              await _deleteDirectoryWithRetry(gitCacheDir, requireSuccess: false);
            }
            await _createLocalMirror();
          }
          break;
        case _GitCacheState.missing:
          logger.debug('Git cache not found. Creating mirror...');
          await _createLocalMirror();
          break;
      }
    } finally {
      unlock();
    }
  }

  /// Ensures a legacy non-bare cache is migrated to a bare mirror if present.
  /// This does not create or refresh the mirror from remote.
  Future<void> ensureBareCacheIfPresent() async {
    final gitCacheDir = Directory(context.gitCachePath);
    if (!gitCacheDir.existsSync()) return;

    final cacheState = await _determineCacheState(gitCacheDir);
    switch (cacheState) {
      case _GitCacheState.ready:
      case _GitCacheState.missing:
        break;
      case _GitCacheState.legacy:
        await _migrateCacheCloneToMirror(gitCacheDir, updateRemote: false);
        break;
      case _GitCacheState.invalid:
        // Defer handling to install/update workflows to avoid heavy work here.
        logger.debug(
          'Git cache is invalid; skipping migration. It will be recreated on next install.',
        );
        break;
    }
  }

  /// Returns the [name] of a branch [version]
  Future<String?> getBranch(String version) async {
    // For backward compatibility, use the FlutterVersion object
    // to ensure proper directory path resolution
    final flutterVersion = FlutterVersion.parse(version);
    final versionDir = get<CacheService>().getVersionCacheDir(flutterVersion);

    final isGitDir = await GitDir.isGitDir(versionDir.path);

    if (!isGitDir) throw Exception('Not a git directory');

    final gitDir = await GitDir.fromExisting(versionDir.path);

    final result = await gitDir.currentBranch();

    return result.branchName;
  }

  /// Returns the [name] of a tag [version]
  Future<String?> getTag(String version) async {
    // For backward compatibility, use the FlutterVersion object
    // to ensure proper directory path resolution
    final flutterVersion = FlutterVersion.parse(version);
    final versionDir = get<CacheService>().getVersionCacheDir(flutterVersion);

    final isGitDir = await GitDir.isGitDir(versionDir.path);

    if (!isGitDir) throw Exception('Not a git directory');

    final gitDir = await GitDir.fromExisting(versionDir.path);

    try {
      final pr = await gitDir.runCommand([
        'describe',
        '--tags',
        '--exact-match',
      ]);

      return (pr.stdout as String).trim();
    } on ProcessException catch (e) {
      final message = e.message.toLowerCase();

      if (message.contains('no tag exactly matches')) {
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
