import 'dart:io';
import 'dart:math';

import 'package:git/git.dart';
import 'package:path/path.dart' as path;

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../models/git_reference_model.dart';
import '../utils/exceptions.dart';
import '../utils/file_utils.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'process_service.dart';

/// Cache state for migration decisions.
/// - missing: no cache directory
/// - invalid: exists but not a git repo
/// - legacy: non-bare clone (needs migration)
/// - overbroad: valid bare repo but not a heads/tags-only cache
/// - ready: bare heads/tags-only cache, ready for use
enum _GitCacheState { missing, invalid, legacy, overbroad, ready }

/// Manages git cache, cloning, migration, and reference lookups.
class GitService extends ContextualService {
  static const _headsRefspec = '+refs/heads/*:refs/heads/*';
  static const _tagsRefspec = '+refs/tags/*:refs/tags/*';
  static const _allowedRefPrefixes = ['refs/heads/', 'refs/tags/'];

  static final RegExp _gitCacheTempPackPattern = RegExp(
    r'^(tmp_pack_|tmp_idx_|tmp_rev_)',
  );
  static const Duration _staleGitCacheTempAge = Duration(hours: 24);

  /// OS-generated metadata files that tools like macOS Finder and Windows
  /// Explorer drop into directories. They are never valid git refs.
  static const _osMetadataFileNames = {'.DS_Store', 'Thumbs.db', 'desktop.ini'};

  List<GitReference>? _referencesCache;

  GitService(super.context);

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

  bool _isLockContentionError(FileSystemException error) {
    final message = error.message.toLowerCase();

    return message.contains('lock failed') ||
        message.contains('resource temporarily unavailable') ||
        message.contains('operation would block') ||
        message.contains('already locked') ||
        message.contains('being used by another process');
  }

  /// Serializes git cache reads and writes through a single file lock.
  Future<T> _withGitCacheLock<T>(Future<T> Function() action) async {
    final lockFile = File('${context.gitCachePath}.lock');
    if (!lockFile.parent.existsSync()) {
      lockFile.parent.createSync(recursive: true);
    }

    RandomAccessFile? lockHandle;
    var lockAcquired = false;
    const retryDelay = Duration(milliseconds: 150);
    const waitLogThreshold = Duration(seconds: 2);
    const maxWait = Duration(minutes: 5);

    try {
      try {
        lockHandle = await lockFile.open(mode: FileMode.write);

        final lockWaitStart = DateTime.now();
        var waitingLogged = false;

        while (!lockAcquired) {
          try {
            await lockHandle.lock(FileLock.exclusive);
            lockAcquired = true;
          } on FileSystemException catch (error, stackTrace) {
            if (!_isLockContentionError(error)) {
              Error.throwWithStackTrace(
                AppException(
                  'Failed to acquire git cache lock at ${lockFile.path}: ${error.message}',
                ),
                stackTrace,
              );
            }

            final elapsed = DateTime.now().difference(lockWaitStart);
            if (elapsed > maxWait) {
              Error.throwWithStackTrace(
                AppException(
                  'Timed out waiting for git cache lock at ${lockFile.path} after ${elapsed.inSeconds}s.',
                ),
                stackTrace,
              );
            }

            if (!waitingLogged && elapsed >= waitLogThreshold) {
              waitingLogged = true;
              logger.debug(
                'Waiting for git cache lock at ${lockFile.path}...',
              );
            }

            await Future<void>.delayed(retryDelay);
          }
        }
      } on FileSystemException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          AppException(
            'Failed to acquire git cache lock at ${lockFile.path}: ${error.message}',
          ),
          stackTrace,
        );
      }

      return await action();
    } finally {
      if (lockHandle != null) {
        if (lockAcquired) {
          try {
            await lockHandle.unlock();
          } on FileSystemException catch (error) {
            logger.warn(
              'Failed to unlock git cache lock at ${lockFile.path}: ${error.message}',
            );
          }
        }
        try {
          await lockHandle.close();
        } on FileSystemException catch (error) {
          logger.warn(
            'Failed to close git cache lock at ${lockFile.path}: ${error.message}',
          );
        }
      }
    }
  }

  void _cleanupStaleGitCachePackTemps() {
    final packDir = Directory(
      path.join(context.gitCachePath, 'objects', 'pack'),
    );
    if (!packDir.existsSync()) return;

    final List<FileSystemEntity> entities;
    try {
      entities = packDir.listSync(followLinks: false);
    } on FileSystemException catch (error) {
      logger.warn(
        'Unable to scan git cache temp files in ${packDir.path}: '
        '${error.message}',
      );

      return;
    }

    final cutoff = DateTime.now().subtract(_staleGitCacheTempAge);
    for (final entity in entities) {
      if (entity is! File) continue;

      final name = path.basename(entity.path);
      if (!_gitCacheTempPackPattern.hasMatch(name)) continue;

      final DateTime modified;
      try {
        modified = entity.statSync().modified;
      } on FileSystemException catch (error) {
        logger.warn(
          'Unable to stat git cache temp file ${entity.path}: '
          '${error.message}',
        );
        continue;
      }

      if (!modified.isBefore(cutoff)) continue;

      try {
        entity.deleteSync();
        logger.debug('Removed stale git cache temp file ${entity.path}');
      } on FileSystemException catch (error) {
        logger.warn(
          'Unable to delete stale git cache temp file ${entity.path}: '
          '${error.message}',
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
        baseDir.parent.path,
        '${path.basename(baseDir.path)}.$suffix.$stamp',
      ),
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

  Future<void> _createLocalGitCache() async {
    final gitCacheDir = Directory(context.gitCachePath);

    final tempDir = await _withTempDir(gitCacheDir, 'tmp', (dir) async {
      await _createHeadsTagsCacheInto(dir, sourceUrl: context.flutterUrl);
    });

    await _replaceGitCacheWith(
      targetPath: gitCacheDir.path,
      replacementDir: tempDir,
      restoreFailureLabel: 'previous cache',
    );

    logger.info('Local git cache created successfully!');
  }

  Future<Directory> _createHeadsTagsCacheInto(
    Directory gitCacheDir, {
    required String sourceUrl,
  }) async {
    logger.info('Creating local git cache...');
    gitCacheDir.createSync(recursive: true);

    final processService = get<ProcessService>();
    await processService.run(
      'git',
      args: ['init', '--bare', gitCacheDir.path],
    );

    await _configureHeadsTagsRemote(gitCacheDir, sourceUrl);
    await _fetchHeadsTags(gitCacheDir);
    await _setBareHeadFromRemote(gitCacheDir, sourceUrl);
    await _validateGitCache(gitCacheDir);

    if (!await _isBareRepository(gitCacheDir.path)) {
      throw const ProcessException(
        'git',
        ['config', '--bool', 'core.bare'],
        'Git cache is not bare after creation',
        1,
      );
    }

    return gitCacheDir;
  }

  /// Removes OS-generated metadata files from the repository's refs tree so
  /// that `git fsck` does not treat them as invalid ref names. macOS Finder
  /// creates `.DS_Store` in any directory it visits; Windows Explorer writes
  /// `Thumbs.db` and `desktop.ini`. These names are never valid Flutter refs,
  /// so removing them cannot delete a real branch or tag.
  ///
  /// Handles both repository layouts: a bare cache keeps refs at `<repo>/refs`,
  /// while a non-bare SDK clone keeps them at `<repo>/.git/refs`.
  Future<void> _purgeOsMetadataFromRefs(Directory repository) async {
    final refsDirs = [
      Directory(path.join(repository.path, 'refs')),
      Directory(path.join(repository.path, '.git', 'refs')),
    ];

    for (final refsDir in refsDirs) {
      if (!refsDir.existsSync()) continue;

      await for (final entity
          in refsDir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!_osMetadataFileNames.contains(path.basename(entity.path))) {
          continue;
        }
        try {
          entity.deleteSync();
          logger.debug('Removed OS metadata file: ${entity.path}');
        } on FileSystemException catch (error) {
          logger.debug(
            'Could not remove OS metadata file ${entity.path}: '
            '${error.message}',
          );
        }
      }
    }
  }

  /// Purges OS metadata from the refs tree, then verifies object connectivity
  /// with `git fsck`. Throws a [ProcessException] if the repository is corrupt.
  Future<void> _validateGitCache(Directory directory) async {
    await _purgeOsMetadataFromRefs(directory);
    await get<ProcessService>().run(
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

  Future<void> _runGitIgnoringFailure(
    Directory repository,
    List<String> args,
  ) async {
    try {
      await get<ProcessService>().run(
        'git',
        args: args,
        workingDirectory: repository.path,
      );
    } on ProcessException catch (error) {
      logger.debug(
        'Ignoring git ${args.join(' ')} failure in ${repository.path}: '
        '${error.message}',
      );
    }
  }

  Future<void> _ensureOriginRemote(Directory repository, String url) async {
    try {
      await setOriginUrl(repositoryPath: repository.path, url: url);
    } on ProcessException {
      await get<ProcessService>().run(
        'git',
        args: ['remote', 'add', 'origin', url],
        workingDirectory: repository.path,
      );
    }
  }

  Future<void> _configureHeadsTagsRemote(
    Directory repository,
    String url,
  ) async {
    final processService = get<ProcessService>();

    await _ensureOriginRemote(repository, url);
    await _runGitIgnoringFailure(
      repository,
      ['config', '--unset-all', 'remote.origin.mirror'],
    );
    await _runGitIgnoringFailure(
      repository,
      ['config', '--unset-all', 'remote.origin.fetch'],
    );

    await processService.run(
      'git',
      args: ['config', '--add', 'remote.origin.fetch', _headsRefspec],
      workingDirectory: repository.path,
    );
    await processService.run(
      'git',
      args: ['config', '--add', 'remote.origin.fetch', _tagsRefspec],
      workingDirectory: repository.path,
    );
    await processService.run(
      'git',
      args: ['config', 'remote.origin.tagOpt', '--no-tags'],
      workingDirectory: repository.path,
    );
  }

  Future<void> _fetchHeadsTags(Directory repository) async {
    await get<ProcessService>().run(
      'git',
      args: ['fetch', '--prune', '--no-tags', 'origin'],
      workingDirectory: repository.path,
    );
  }

  Future<void> _fetchLegacyRemoteTrackingHeads(
    Directory targetRepository,
    Directory legacyRepository,
  ) async {
    const originPrefix = 'refs/remotes/origin/';
    final legacyRefs = await _listRefs(legacyRepository);
    final originBranchRefs = legacyRefs.where(
      (ref) => ref.startsWith(originPrefix) && ref != '${originPrefix}HEAD',
    );

    for (final ref in originBranchRefs) {
      final branchName = ref.substring(originPrefix.length);
      if (branchName.isEmpty) continue;

      await get<ProcessService>().run(
        'git',
        args: [
          'fetch',
          '--no-tags',
          legacyRepository.path,
          '+$ref:refs/heads/$branchName',
        ],
        workingDirectory: targetRepository.path,
      );
    }
  }

  Future<List<String>> _configValues(Directory repository, String key) async {
    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['config', '--get-all', key],
        workingDirectory: repository.path,
      );

      return (result.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } on ProcessException catch (error) {
      if (error.errorCode == 1) return [];
      rethrow;
    }
  }

  Future<bool> _hasExactCacheRefspecs(Directory repository) async {
    final refspecs = await _configValues(repository, 'remote.origin.fetch');

    return refspecs.length == 2 &&
        refspecs.contains(_headsRefspec) &&
        refspecs.contains(_tagsRefspec);
  }

  Future<bool> _hasNoTagsTagOpt(Directory repository) async {
    final values = await _configValues(repository, 'remote.origin.tagOpt');

    return values.length == 1 && values.single == '--no-tags';
  }

  Future<bool> _hasNoMirrorConfig(Directory repository) async {
    final values = await _configValues(repository, 'remote.origin.mirror');

    return values.isEmpty;
  }

  Future<List<String>> _listRefs(Directory repository) async {
    final result = await get<ProcessService>().run(
      'git',
      args: ['for-each-ref', '--format=%(refname)'],
      workingDirectory: repository.path,
    );

    return (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  bool _isAllowedCacheRef(String ref) {
    return _allowedRefPrefixes.any(ref.startsWith);
  }

  bool _isAllowedCacheHeadRef(String ref) {
    return ref.startsWith('refs/heads/');
  }

  Future<List<String>> _disallowedRefs(Directory repository) async {
    final refs = await _listRefs(repository);

    return refs.where((ref) => !_isAllowedCacheRef(ref)).toList();
  }

  Future<bool> _refExists(Directory repository, String ref) async {
    try {
      await get<ProcessService>().run(
        'git',
        args: ['show-ref', '--verify', '--quiet', ref],
        workingDirectory: repository.path,
      );

      return true;
    } on ProcessException {
      return false;
    }
  }

  Future<String?> _remoteHeadRef(String url) async {
    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['ls-remote', '--symref', url, 'HEAD'],
      );

      final lines = (result.stdout as String).split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('ref:')) continue;

        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 2 && _isAllowedCacheHeadRef(parts[1])) {
          return parts[1];
        }
      }
    } on ProcessException catch (error) {
      logger.debug(
        'Unable to resolve remote HEAD for $url: ${error.message}',
      );
    }

    return null;
  }

  Future<void> _setBareHeadFromRemote(
    Directory repository,
    String sourceUrl,
  ) async {
    final remoteHead = await _remoteHeadRef(sourceUrl);
    final candidates = [
      if (remoteHead != null) remoteHead,
      'refs/heads/master',
      'refs/heads/main',
    ];

    for (final candidate in candidates) {
      if (await _refExists(repository, candidate)) {
        await get<ProcessService>().run(
          'git',
          args: ['symbolic-ref', 'HEAD', candidate],
          workingDirectory: repository.path,
        );

        return;
      }
    }

    throw AppException(
      'Git cache has no valid HEAD. Expected remote HEAD, master, or main.',
    );
  }

  Future<bool> _hasValidBareHead(Directory repository) async {
    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['symbolic-ref', '--quiet', 'HEAD'],
        workingDirectory: repository.path,
      );
      final headRef = (result.stdout as String).trim();

      return _isAllowedCacheHeadRef(headRef) &&
          await _refExists(repository, headRef);
    } on ProcessException {
      return false;
    }
  }

  Future<bool> _hasHeadsTagsCacheShape(Directory repository) async {
    if (!await _isBareRepository(repository.path)) return false;
    if (!await _hasExactCacheRefspecs(repository)) return false;
    if (!await _hasNoTagsTagOpt(repository)) return false;
    if (!await _hasNoMirrorConfig(repository)) return false;
    if (!await _hasValidBareHead(repository)) return false;
    if ((await _disallowedRefs(repository)).isNotEmpty) return false;

    return true;
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
      // Match patterns for cache temp directories from failed operations.
      if ((name.startsWith('$baseName.tmp.') ||
              name.startsWith('$baseName.bare-tmp.') ||
              name.startsWith('$baseName.heads-tags-tmp.')) &&
          RegExp(r'\.\d+(_\d+)?$').hasMatch(name)) {
        await _deleteDirectoryWithRetry(entity, requireSuccess: false);
      }
    }
  }

  Future<_GitCacheState> _determineCacheShapeState(
    Directory gitCacheDir,
  ) async {
    if (!gitCacheDir.existsSync()) {
      return _GitCacheState.missing;
    }

    try {
      if (!await _isBareRepository(gitCacheDir.path)) {
        return _GitCacheState.legacy;
      }

      return await _hasHeadsTagsCacheShape(gitCacheDir)
          ? _GitCacheState.ready
          : _GitCacheState.overbroad;
    } on ProcessException catch (error) {
      logger.debug(
        'Git cache at ${gitCacheDir.path} is invalid (${error.message}).',
      );

      return _GitCacheState.invalid;
    }
  }

  Future<_GitCacheState> _determineCacheState(Directory gitCacheDir) async {
    final cacheState = await _determineCacheShapeState(gitCacheDir);

    return _withConnectivityCheckedState(gitCacheDir, cacheState);
  }

  Future<_GitCacheState> _withConnectivityCheckedState(
    Directory gitCacheDir,
    _GitCacheState cacheState,
  ) async {
    switch (cacheState) {
      case _GitCacheState.ready:
      case _GitCacheState.overbroad:
        try {
          await _validateGitCache(gitCacheDir);
        } on ProcessException catch (error) {
          logger.debug(
            'Git cache at ${gitCacheDir.path} failed fsck '
            '(${error.message}).',
          );

          return _GitCacheState.invalid;
        }

        return cacheState;
      case _GitCacheState.missing:
      case _GitCacheState.legacy:
      case _GitCacheState.invalid:
        return cacheState;
    }
  }

  Future<void> _refreshExistingGitCache(Directory gitCacheDir) async {
    try {
      await _syncGitCacheWithRemote(gitCacheDir);
      logger.debug('Local git cache updated successfully');
    } on ProcessException catch (error) {
      logger.warn(
        'Local git cache update failed (${error.message}). Attempting repair...',
      );
      try {
        await _validateGitCache(gitCacheDir);
        await _syncGitCacheWithRemote(gitCacheDir);
        logger.info('Git cache repaired successfully');
      } on ProcessException {
        logger.warn('Repair failed, recreating git cache from scratch...');
        await _createLocalGitCache();
      }
    }
  }

  String _normalizeComparablePath(String value) {
    final normalized = path.normalize(value);

    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  String _resolveExistingPathOrNormalize(String value) {
    final normalized = path.normalize(value);
    final type = FileSystemEntity.typeSync(normalized, followLinks: true);
    if (type == FileSystemEntityType.notFound) return normalized;

    return switch (type) {
      FileSystemEntityType.directory =>
        Directory(normalized).resolveSymbolicLinksSync(),
      FileSystemEntityType.file => File(normalized).resolveSymbolicLinksSync(),
      FileSystemEntityType.link => Link(normalized).resolveSymbolicLinksSync(),
      _ => normalized,
    };
  }

  String _resolvedCachePath() {
    return _resolveExistingPathOrNormalize(context.gitCachePath);
  }

  bool _isWithinResolvedCachePath(String candidate, String cachePath) {
    final comparableCandidate = _normalizeComparablePath(candidate);
    final comparableCachePath = _normalizeComparablePath(cachePath);

    return comparableCandidate == comparableCachePath ||
        path.isWithin(comparableCachePath, comparableCandidate);
  }

  String _resolveAlternatePath(File alternatesFile, String line) {
    final trimmed = line.trim();
    final objectDatabasePath = alternatesFile.parent.parent.path;
    final alternatePath = path.isAbsolute(trimmed)
        ? trimmed
        : path.join(objectDatabasePath, trimmed);

    return _resolveExistingPathOrNormalize(alternatePath);
  }

  void _writeAlternateLines(File alternatesFile, List<String> lines) {
    if (lines.isEmpty) {
      if (alternatesFile.existsSync()) {
        alternatesFile.deleteSync();
      }

      return;
    }

    alternatesFile.writeAsStringSync('${lines.join('\n')}\n');
  }

  Future<bool> _dissociateVersionFromGitCache(
    CacheFlutterVersion version,
    String cachePath,
  ) async {
    final alternatesFile = File(
      path.join(version.directory, '.git', 'objects', 'info', 'alternates'),
    );
    if (!alternatesFile.existsSync()) return true;

    var originalLines = <String>[];
    try {
      originalLines = alternatesFile.readAsLinesSync();
      final retainedLines = <String>[];
      var hasFvmOwnedAlternate = false;

      for (final line in originalLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final resolvedAlternate =
            _resolveAlternatePath(alternatesFile, trimmed);
        if (_isWithinResolvedCachePath(resolvedAlternate, cachePath)) {
          hasFvmOwnedAlternate = true;
        } else {
          retainedLines.add(trimmed);
        }
      }

      if (!hasFvmOwnedAlternate) return true;

      await get<ProcessService>().run(
        'git',
        args: ['repack', '-a'],
        workingDirectory: version.directory,
      );

      _writeAlternateLines(alternatesFile, retainedLines);

      await _validateGitCache(Directory(version.directory));

      logger.info('Dissociated ${version.name} from local git cache.');

      return true;
    } catch (error) {
      if (originalLines.isNotEmpty) {
        try {
          alternatesFile.parent.createSync(recursive: true);
          alternatesFile.writeAsStringSync('${originalLines.join('\n')}\n');
        } catch (restoreError) {
          logger.warn(
            'Unable to restore alternates for ${version.name}: $restoreError',
          );
        }
      }
      logger.warn(
        'Unable to dissociate ${version.name} from local git cache: $error',
      );

      return false;
    }
  }

  Future<void> _removeGitCacheDependentSdks(
    List<CacheFlutterVersion> versions,
  ) async {
    if (versions.isEmpty) return;

    final names = versions.map((version) => version.nameWithAlias).join(', ');
    logger.warn(
      'Removing cached Flutter SDKs that could not be dissociated from '
      'the local git cache: $names',
    );

    final cacheService = get<CacheService>();
    for (final version in versions) {
      try {
        await cacheService.remove(version);
        logger.warn(
          'Removed cached Flutter SDK ${version.nameWithAlias} because it '
          'still depended on the local git cache.',
        );
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          GitCacheDependentSdkRemovalException(
            'Unable to remove cached Flutter SDK ${version.nameWithAlias} '
            'after git cache dissociation failed. The local git cache was not '
            'replaced. Error: $error',
          ),
          stackTrace,
        );
      }
    }
  }

  Future<void> _dissociateInstalledSdksFromGitCache() async {
    final versions = await get<CacheService>().getAllVersions();
    if (versions.isEmpty) return;

    final cachePath = _resolvedCachePath();
    final dependentVersions = <CacheFlutterVersion>[];
    for (final version in versions) {
      final dissociated = await _dissociateVersionFromGitCache(
        version,
        cachePath,
      );
      if (!dissociated) {
        dependentVersions.add(version);
      }
    }

    await _removeGitCacheDependentSdks(dependentVersions);
  }

  Future<void> _syncGitCacheWithRemote(Directory gitCacheDir) async {
    logger.debug('Updating local git cache from ${context.flutterUrl}');
    await _configureHeadsTagsRemote(gitCacheDir, context.flutterUrl);
    await _fetchHeadsTags(gitCacheDir);
    await _setBareHeadFromRemote(gitCacheDir, context.flutterUrl);
    await _validateGitCache(gitCacheDir);

    final extraRefs = await _disallowedRefs(gitCacheDir);
    if (extraRefs.isNotEmpty) {
      throw AppException(
        'Git cache contains unsupported refs: ${extraRefs.join(', ')}',
      );
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

  Future<void> _replaceGitCacheWith({
    required String targetPath,
    required Directory replacementDir,
    String restoreFailureLabel = 'previous cache',
  }) async {
    try {
      final existingEntity = _entityAt(targetPath);
      if (existingEntity != null) {
        await _dissociateInstalledSdksFromGitCache();
      }

      await _atomicDirectorySwap(
        targetPath: targetPath,
        replacementDir: replacementDir,
        restoreFailureLabel: restoreFailureLabel,
      );
    } catch (_) {
      if (replacementDir.existsSync()) {
        await _deleteDirectoryWithRetry(replacementDir, requireSuccess: false);
      }
      rethrow;
    }
  }

  /// Rebuilds a clean heads/tags-only cache, optionally using the current
  /// cache as the source to avoid a remote fetch during lightweight migration.
  Future<void> _rebuildHeadsTagsGitCache(
    Directory currentDir, {
    bool updateRemote = true,
  }) async {
    logger.info('Rebuilding local git cache as heads/tags-only...');

    final sourceUrl = updateRemote ? context.flutterUrl : currentDir.path;
    final preserveLegacyRemoteTrackingRefs =
        !updateRemote && !await _isBareRepository(currentDir.path);
    final tempBareDir = await _withTempDir(
      currentDir,
      'heads-tags-tmp',
      (dir) async {
        await _createHeadsTagsCacheInto(dir, sourceUrl: sourceUrl);

        if (preserveLegacyRemoteTrackingRefs) {
          await _fetchLegacyRemoteTrackingHeads(dir, currentDir);
          await _validateGitCache(dir);
        }

        if (!updateRemote) {
          await setOriginUrl(repositoryPath: dir.path, url: context.flutterUrl);
        }

        if (!await _hasHeadsTagsCacheShape(dir)) {
          throw AppException('Rebuilt git cache is not ready for use.');
        }
      },
    );

    await _replaceGitCacheWith(
      targetPath: currentDir.path,
      replacementDir: tempBareDir,
      restoreFailureLabel: 'previous cache',
    );

    logger.info('Local git cache rebuilt successfully!');
  }

  /// Migrates an existing non-bare cache clone to a heads/tags-only bare cache.
  Future<void> _migrateCacheCloneToGitCache(
    Directory legacyDir, {
    bool updateRemote = true,
  }) async {
    logger.info('Migrating cache clone to heads/tags-only git cache...');

    final processService = get<ProcessService>();

    // Clean the legacy clone to release file locks and normalize state.
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

    await _rebuildHeadsTagsGitCache(legacyDir, updateRemote: updateRemote);
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

  /// Acquires the git cache lock, cleans stale pack temp files, then runs
  /// [cloneAction] before releasing the lock.
  Future<T> withPreparedGitCacheForClone<T>(
    Future<T> Function() cloneAction,
  ) {
    return _withGitCacheLock(() async {
      _cleanupStaleGitCachePackTemps();

      return cloneAction();
    });
  }

  Future<bool> removeLocalMirror({
    bool requireSuccess = false,
    void Function(FileSystemException error)? onFinalError,
  }) {
    return _withGitCacheLock(() async {
      final cacheDir = Directory(context.gitCachePath);
      if (cacheDir.existsSync()) {
        await _dissociateInstalledSdksFromGitCache();
      }

      return deleteDirectoryWithRetry(
        cacheDir,
        requireSuccess: requireSuccess,
        onFinalError: onFinalError ??
            (error) {
              logger.warn(
                'Unable to delete local git cache at ${cacheDir.path}: ${error.message}',
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
    return _withGitCacheLock(() async {
      final gitCacheDir = Directory(context.gitCachePath);

      var cacheState = await _determineCacheShapeState(gitCacheDir);
      if (cacheState != _GitCacheState.ready) {
        cacheState = await _withConnectivityCheckedState(
          gitCacheDir,
          cacheState,
        );
      }

      switch (cacheState) {
        case _GitCacheState.ready:
          await _refreshExistingGitCache(gitCacheDir);
          break;
        case _GitCacheState.overbroad:
          await _rebuildHeadsTagsGitCache(gitCacheDir);
          break;
        case _GitCacheState.legacy:
          await _migrateCacheCloneToGitCache(gitCacheDir);
          break;
        case _GitCacheState.invalid:
          logger.warn('Git cache is invalid; recreating from scratch...');
          await _createLocalGitCache();
          break;
        case _GitCacheState.missing:
          logger.debug('Git cache not found. Creating heads/tags cache...');
          await _createLocalGitCache();
          break;
      }
    });
  }

  /// Migrates a legacy or overbroad cache to a heads/tags-only bare cache if
  /// present. Does not create or refresh the cache from remote.
  Future<void> ensureBareCacheIfPresent() {
    return _withGitCacheLock(() async {
      final gitCacheDir = Directory(context.gitCachePath);
      if (!gitCacheDir.existsSync()) return;

      final cacheState = await _determineCacheState(gitCacheDir);
      switch (cacheState) {
        case _GitCacheState.ready:
        case _GitCacheState.missing:
          break;
        case _GitCacheState.overbroad:
          await _rebuildHeadsTagsGitCache(gitCacheDir, updateRemote: false);
          break;
        case _GitCacheState.legacy:
          await _migrateCacheCloneToGitCache(gitCacheDir, updateRemote: false);
          break;
        case _GitCacheState.invalid:
          // Defer handling to install/update workflows to avoid heavy work here.
          logger.debug(
            'Git cache is invalid; skipping migration. It will be recreated on next install.',
          );
          break;
      }
    });
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
