import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';

import '../models/flutter_version_model.dart';
import '../models/git_reference_model.dart';
import '../utils/exceptions.dart';
import '../utils/file_lock.dart';
import '../utils/git_clone_progress_tracker.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'process_service.dart';

/// Service for Git operations
/// Handles git cache management and repository operations
class GitService extends ContextualService {
  late final FileLocker _updatingCacheLock;
  List<GitReference>? _referencesCache;

  GitService(super.context) {
    _updatingCacheLock = context.createLock(
      'updating-cache',
      expiresIn: const Duration(minutes: 10),
    );
  }

  // Create a custom Process.start, that prints using the progress bar
  Future<void> _createLocalMirror() async {
    final gitCacheDir = Directory(context.gitCachePath);
    logger.info('Creating local mirror...');
    final process = await Process.start(
      'git',
      [
        'clone',
        '--progress',
        // Enable long paths on Windows to prevent checkout failures
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
    process.stdout.transform(utf8.decoder).listen((line) {
      logger.info(line);
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      logger.err(processLogs.join('\n'));
      gitCacheDir.deleteSync(recursive: true);
      throw Exception('Git clone failed');
    }

    progressTracker.complete();
    logger.info('Local mirror created successfully!');
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

  Future<void> updateLocalMirror() async {
    final unlock = await _updatingCacheLock.getLock();

    final gitCacheDir = Directory(context.gitCachePath);
    final isGitDir = await GitDir.isGitDir(gitCacheDir.path);

    try {
      if (isGitDir) {
        try {
          logger.debug('Updating local mirror...');
          final gitDir = await GitDir.fromExisting(gitCacheDir.path);

          // Ensure clean working directory before fetch operations
          // This prevents merge conflicts during fetch (fixes #819)
          logger.debug('Ensuring clean working directory...');
          await gitDir.runCommand(['reset', '--hard', 'HEAD']);
          await gitDir.runCommand(['clean', '-fd']);

          // First, prune any stale references
          logger.debug('Pruning stale references...');
          await gitDir.runCommand(['remote', 'prune', 'origin']);

          // Then fetch all refs including tags
          logger.debug('Fetching all refs...');
          await gitDir.runCommand(['fetch', '--all', '--tags', '--prune']);

          // Check if there are any uncommitted changes
          logger.debug('Checking for uncommitted changes...');
          final statusResult = await gitDir.runCommand([
            'status',
            '--porcelain',
          ]);

          final output = (statusResult.stdout as String).trim();
          if (output.isEmpty) {
            logger.debug('No uncommitted changes. Working directory is clean.');
          } else {
            await _createLocalMirror();
          }

          logger.debug('Local mirror updated successfully');
        } catch (e) {
          final message =
              e is ProcessException ? e.message : e.toString();

          // Only recreate the mirror if it's a critical git error that indicates
          // the repository is unrecoverable. Other errors (network, permissions, etc.)
          // are re-thrown so callers can handle them appropriately.
          // Known critical error patterns: "not a git repository", "corrupt", "damaged"
          if (e is ProcessException &&
              (message.contains('not a git repository') ||
                  message.contains('corrupt') ||
                  message.contains('damaged'))) {
            logger.warn(
              'Local mirror appears to be corrupted (${e.message}). '
              'Recreating mirror...',
            );
            await _createLocalMirror();
          } else {
            logger.err(
              'Failed to update local mirror: $e. '
              'Try running "fvm doctor" to diagnose issues.',
            );
            rethrow;
          }
        }
      } else {
        await _createLocalMirror();
      }
    } finally {
      unlock();
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
