import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as path;

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../models/git_reference_model.dart';
import '../utils/exceptions.dart';
import '../utils/git_clone_progress_tracker.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'process_service.dart';

enum _GitCacheState { missing, invalid, legacy, ready }

typedef _VersionWithAlternates = ({
  CacheFlutterVersion version,
  File alternatesFile,
});

/// Service for Git operations
/// Handles git cache management and repository operations
class GitService extends ContextualService {
  List<GitReference>? _referencesCache;

  GitService(super.context);

  Future<void> _createLocalMirror() async {
    final gitCacheDir = Directory(context.gitCachePath);

    // Ensure the parent exists
    if (!gitCacheDir.parent.existsSync()) {
      gitCacheDir.parent.createSync(recursive: true);
    }

    // Remove any existing cache (dir/file/symlink) before cloning
    final cachePathType = FileSystemEntity.typeSync(
      gitCacheDir.path,
      followLinks: false,
    );
    if (cachePathType == FileSystemEntityType.file ||
        cachePathType == FileSystemEntityType.link) {
      File(gitCacheDir.path).deleteSync();
    } else if (cachePathType == FileSystemEntityType.directory) {
      await _deleteDirectoryWithRetry(
        gitCacheDir,
        requireSuccess: false,
      );
    }

    await _cloneMirrorInto(gitCacheDir);

    logger.info('Local mirror created successfully!');
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

    // ignore: avoid-unassigned-stream-subscriptions
    process.stderr.transform(utf8.decoder).listen((line) {
      progressTracker.processLine(line);
      processLogs.add(line);
    });

    // ignore: avoid-unassigned-stream-subscriptions
    process.stdout.transform(utf8.decoder).listen(logger.info);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      progressTracker.complete();
      logger.err(processLogs.join('\n'));
      if (gitCacheDir.existsSync()) {
        await _deleteDirectoryWithRetry(gitCacheDir, requireSuccess: false);
      }
      throw Exception('Git clone failed');
    }

    progressTracker.complete();
    try {
      await _validateMirror(gitCacheDir, strict: true);
    } catch (error) {
      await _deleteDirectoryWithRetry(gitCacheDir, requireSuccess: false);
      rethrow;
    }

    return gitCacheDir;
  }

  Future<void> _validateMirror(Directory directory, {bool strict = true}) {
    final args = strict
        ? ['fsck', '--strict', '--no-dangling']
        : ['fsck', '--connectivity-only'];

    return get<ProcessService>().run(
      'git',
      args: args,
      workingDirectory: directory.path,
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

  Future<bool> isGitReference(String version) async {
    final references = await _fetchGitReferences();

    return references.any((reference) => reference.name == version);
  }

  /// Resets to specific reference
  Future<void> resetHard(String path, String reference) async {
    final gitDir = await GitDir.fromExisting(path);
    await gitDir.runCommand(['reset', '--hard', reference]);
  }

  Future<void> _deleteDirectoryWithRetry(
    Directory directory, {
    bool requireSuccess = true,
  }) async {
    if (!directory.existsSync()) return;

    final attempts = Platform.isWindows ? 5 : 1;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        directory.deleteSync(recursive: true);
        return;
      } on FileSystemException catch (error) {
        if (!Platform.isWindows || attempt == attempts) {
          if (requireSuccess) {
            rethrow;
          }
          logger.warn(
            'Unable to delete ${directory.path}: ${error.message}',
          );
          return;
        }
        await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
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
        case _GitCacheState.invalid:
          await _migrateLegacyCache(gitCacheDir);
          break;
        case _GitCacheState.missing:
          logger.debug('Git cache not found. Creating mirror...');
          await _createLocalMirror();
          break;
      }
    } else {
      await _createLocalMirror();
    }
  }

  Future<_GitCacheState> _determineCacheState(Directory gitCacheDir) async {
    if (!gitCacheDir.existsSync()) {
      return _GitCacheState.missing;
    }

    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['rev-parse', '--is-bare-repository'],
        workingDirectory: gitCacheDir.path,
      );

      final output = (result.stdout ?? '').toString().trim().toLowerCase();
      if (output == 'true') {
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
      // Use the faster connectivity check during routine refresh; strict fsck is
      // still run when creating/recreating the mirror.
      await _validateMirror(gitCacheDir, strict: false);
    } on ProcessException catch (error) {
      logger.warn(
        'Local mirror validation failed (${error.message}). Recreating...',
      );
      await _createLocalMirror();
      return;
    }

    await _syncMirrorWithRemote(gitCacheDir);
    logger.debug('Local mirror updated successfully');
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

  Future<void> _migrateLegacyCache(Directory gitCacheDir) async {
    logger.warn(
      'Detected legacy git cache at ${gitCacheDir.path}. Starting migration...',
    );

    final versionsNeedingDetach = await _versionsWithAlternates();
    if (versionsNeedingDetach.isNotEmpty) {
      logger.info(
        'Detaching git cache alternates for '
        '${versionsNeedingDetach.length} installed SDK(s)...',
      );
      await _detachAlternates(versionsNeedingDetach);

      final remaining = await _versionsWithAlternates();
      if (remaining.isNotEmpty) {
        final stuckVersions =
            remaining.map((entry) => entry.version.name).join(', ');
        throw AppException(
          'Unable to detach git cache from: $stuckVersions. '
          'Resolve the errors above and rerun the command.',
        );
      }
    } else {
      logger.debug('No SDK alternates referencing the git cache were found.');
    }

    await _createLocalMirror();
    logger.info('Git cache migration complete.');
  }

  Future<List<_VersionWithAlternates>> _versionsWithAlternates() async {
    final cacheVersions = await get<CacheService>().getAllVersions();
    final versionsWithAlternates = <_VersionWithAlternates>[];

    for (final version in cacheVersions) {
      final alternatesFile = _alternatesFileFor(version);
      if (alternatesFile.existsSync()) {
        versionsWithAlternates.add((
          version: version,
          alternatesFile: alternatesFile,
        ));
      }
    }

    return versionsWithAlternates;
  }

  File _alternatesFileFor(CacheFlutterVersion version) {
    return File(
      path.join(version.directory, '.git', 'objects', 'info', 'alternates'),
    );
  }

  Future<void> _detachAlternates(
    List<_VersionWithAlternates> versions,
  ) async {
    for (final entry in versions) {
      final version = entry.version;
      final alternatesFile = entry.alternatesFile;

      if (!alternatesFile.existsSync()) {
        continue;
      }

      final backupFile = File('${alternatesFile.path}.backup');
      final progress =
          logger.progress('Detaching cache for ${version.printFriendlyName}');

      try {
        backupFile.writeAsStringSync(alternatesFile.readAsStringSync());

        final gitDir = await GitDir.fromExisting(version.directory);
        await gitDir.runCommand(['repack', '-ad', '--quiet']);
        await gitDir.runCommand(['fsck', '--connectivity-only']);

        alternatesFile.deleteSync();
        if (backupFile.existsSync()) {
          backupFile.deleteSync();
        }

        progress.complete(
          'Detached cache for ${version.printFriendlyName}',
        );
      } catch (error, stackTrace) {
        progress.fail('Failed to detach ${version.printFriendlyName}');
        if (backupFile.existsSync()) {
          backupFile.copySync(alternatesFile.path);
          backupFile.deleteSync();
        }

        Error.throwWithStackTrace(
          AppException(
            'Failed to detach git cache for ${version.printFriendlyName}: '
            '$error',
          ),
          stackTrace,
        );
      }
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
