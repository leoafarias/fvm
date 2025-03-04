import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;

import '../utils/file_lock.dart';
import '../utils/git_clone_update_printer.dart';
import 'base_service.dart';

/// Service for Git operations
class GitService extends ContextualService {
  late final FileLocker _updatingCacheLock;

  GitService(super.context) {
    _updatingCacheLock = context.createLock(
      'updating-cache',
      expiresIn: const Duration(minutes: 10),
    );
  }

  /// Helper method to get a GitDir instance, handling common setup
  Future<GitDir> _getGitMirror() async {
    await updateLocalMirror();

    final isGitDir = await GitDir.isGitDir(context.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    return GitDir.fromExisting(context.gitCachePath);
  }

  // Create a custom Process.start, that prints using the progress bar
  Future<void> _createLocalMirror() async {
    final gitCacheDir = Directory(context.gitCachePath);
    logger.info('Creating local mirror...');
    final process = await Process.start(
      'git',
      ['clone', '--progress', context.flutterUrl, gitCacheDir.path],
      runInShell: true,
    );

    final processLogs = <String>[];

    try {
      // ignore: avoid-unassigned-stream-subscriptions
      process.stderr.transform(utf8.decoder).listen((line) {
        printProgressBar(line, logger);
        processLogs.add(line);
      });

      // ignore: avoid-unassigned-stream-subscriptions
      process.stdout.transform(utf8.decoder).listen((line) {
        logger.info(line);
      });
    } catch (e) {
      logger.detail('Formatting error due to invalid return $e');
      // Ignore as its just a printer error
      logger.info('Updating....');
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      logger.err(processLogs.join('\n'));
      gitCacheDir.deleteSync(recursive: true);
      throw Exception('Git clone failed');
    }
    logger.info('Local mirror created successfully!');
  }

  /// Resets to specific reference
  Future<void> resetToReference(String path, String reference) async {
    final gitDir = await GitDir.fromExisting(path);
    await gitDir.runCommand(['reset', '--hard', reference]);
  }

  Future<void> updateLocalMirror() async {
    while (_updatingCacheLock.isLocked) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final gitCacheDir = Directory(context.gitCachePath);
    final isGitDir = await GitDir.isGitDir(gitCacheDir.path);

    try {
      if (isGitDir) {
        try {
          logger.detail('Updating local mirror...');
          final gitDir = await GitDir.fromExisting(gitCacheDir.path);

          // First, prune any stale references
          logger.detail('Pruning stale references...');
          await gitDir.runCommand(['remote', 'prune', 'origin']);

          // Then fetch all refs including tags
          logger.detail('Fetching all refs...');
          await gitDir.runCommand(['fetch', '--all', '--tags', '--prune']);

          // Check if there are any uncommitted changes
          logger.detail('Checking for uncommitted changes...');
          final statusResult =
              await gitDir.runCommand(['status', '--porcelain']);

          final output = (statusResult.stdout as String).trim();
          if (output.isEmpty) {
            logger
                .detail('No uncommitted changes. Working directory is clean.');
          } else {
            await _createLocalMirror();
          }

          logger.detail('Local mirror updated successfully');
        } catch (e) {
          logger.err('Error updating local mirror: $e');

          // Only recreate the mirror if it's a critical git error
          if (e is ProcessException &&
              (e.message.contains('not a git repository') ||
                  e.message.contains('corrupt') ||
                  e.message.contains('damaged'))) {
            logger.warn('Local mirror appears to be corrupted, recreating...');
            await _createLocalMirror();
          } else {
            rethrow;
          }
        }
      } else {
        await _createLocalMirror();
      }
    } catch (e) {
      rethrow;
    } finally {
      _updatingCacheLock.unlock();
    }
  }

  /// Gets a list of all tags in the repository
  Future<List<String>> getTags() async {
    try {
      final gitDir = await _getGitMirror();
      final tags = await gitDir.tags().toList();

      return tags.map((tag) => tag.tag).toList();
    } on Exception {
      return [];
    }
  }

  /// Returns the [name] of a branch or tag for a [version]
  Future<String?> getBranch(String version) async {
    final versionDir = Directory(p.join(context.versionsCachePath, version));

    final isGitDir = await GitDir.isGitDir(versionDir.path);

    if (!isGitDir) throw Exception('Not a git directory');

    final gitDir = await GitDir.fromExisting(versionDir.path);

    final result = await gitDir.currentBranch();

    return result.branchName;
  }

  /// Returns the [name] of a tag [version]
  Future<String?> getTag(String version) async {
    final versionDir = Directory(p.join(context.versionsCachePath, version));

    final isGitDir = await GitDir.isGitDir(versionDir.path);

    if (!isGitDir) throw Exception('Not a git directory');

    final gitDir = await GitDir.fromExisting(versionDir.path);

    try {
      final pr =
          await gitDir.runCommand(['describe', '--tags', '--exact-match']);

      return (pr.stdout as String).trim();
    } catch (e) {
      return null;
    }
  }

  /// Resolves any git reference (branch, tag, commit) to its SHA
  /// Returns null if reference doesn't exist
  Future<String?> getReference(String ref) async {
    try {
      final gitDir = await _getGitMirror();
      final result = await gitDir.runCommand(
        ['rev-parse', '--short', '--verify', ref],
        throwOnError: false,
      );

      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }

      return null;
    } on Exception {
      return null;
    }
  }

  /// Checks if a string is a valid commit
  Future<bool> isCommit(String commit) async {
    try {
      final gitDir = await _getGitMirror();

      // Try to get the commit object
      await gitDir.commitFromRevision(commit);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if a string is a valid tag
  Future<bool> isTag(String tag) async {
    try {
      final tags = await getTags();

      return tags.contains(tag);
    } catch (e) {
      return false;
    }
  }
}
