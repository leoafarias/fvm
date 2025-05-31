import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';

import '../models/flutter_version_model.dart';
import '../models/git_reference_model.dart';
import '../utils/file_lock.dart';
import '../utils/git_clone_update_printer.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'process_service.dart';

/// Service for Git operations
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
      logger.debug('Formatting error due to invalid return $e');
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

  /// Helper method to run git ls-remote commands against the remote repository
  Future<List<GitReference>> _fetchGitReferences() async {
    if (_referencesCache != null) return _referencesCache!;

    final List<String> command = ['ls-remote', '--tags', '--branches'];

    command.add(context.flutterUrl);

    final result = await get<ProcessService>().run('git', args: command);

    if (result.exitCode != 0) {
      logger.warn('Fetching git references failed');
      logger.debug(result.stderr);

      return [];
    }

    return _referencesCache =
        GitReference.parseGitReferences(result.stdout as String);
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
    while (_updatingCacheLock.isLocked) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final gitCacheDir = Directory(context.gitCachePath);
    final isGitDir = await GitDir.isGitDir(gitCacheDir.path);

    try {
      if (isGitDir) {
        try {
          logger.debug('Updating local mirror...');
          final gitDir = await GitDir.fromExisting(gitCacheDir.path);

          // First, prune any stale references
          logger.debug('Pruning stale references...');
          await gitDir.runCommand(['remote', 'prune', 'origin']);

          // Then fetch all refs including tags
          logger.debug('Fetching all refs...');
          await gitDir.runCommand(['fetch', '--all', '--tags', '--prune']);

          // Check if there are any uncommitted changes
          logger.debug('Checking for uncommitted changes...');
          final statusResult =
              await gitDir.runCommand(['status', '--porcelain']);

          final output = (statusResult.stdout as String).trim();
          if (output.isEmpty) {
            logger.debug('No uncommitted changes. Working directory is clean.');
          } else {
            await _createLocalMirror();
          }

          logger.debug('Local mirror updated successfully');
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
      final pr =
          await gitDir.runCommand(['describe', '--tags', '--exact-match']);

      return (pr.stdout as String).trim();
    } catch (e) {
      return null;
    }
  }
}
