import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' as io;
import 'package:meta/meta.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/exceptions.dart';
import '../utils/file_lock.dart';
import '../utils/git_clone_update_printer.dart';
import '../utils/helpers.dart';
import '../utils/run_command.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends Contextual {
  @protected
  final CacheService cacheService;

  @protected
  final FlutterReleasesService flutterReleasesServices;
  final _dartCmd = 'dart';

  final _flutterCmd = 'flutter';

  late final _isUpdatingCache = FileLocker(
    '${context.fvmDir}/cache.lock',
    lockExpiration: const Duration(seconds: 10),
    pollingInterval: const Duration(milliseconds: 100),
  );

  FlutterService(
    super.context, {
    required this.cacheService,
    required this.flutterReleasesServices,
  });

  /// Runs dart cmd
  Future<ProcessResult> _runVersion(
    String cmd,
    CacheFlutterVersion version,
    List<String> args, {
    bool? echoOutput,
    bool? throwOnError,
  }) async {
    final isFlutter = cmd == _flutterCmd;
    // Get exec path for dart
    final execPath = isFlutter ? version.flutterExec : version.dartExec;

    // Update environment
    final environment = updateEnvironmentVariables(
      [version.binPath, version.dartBinPath],
      context.environment,
      logger,
    );

    // Run command
    return await _runCmd(
      execPath,
      args: args,
      environment: environment,
      echoOutput: echoOutput,
      throwOnError: throwOnError,
    );
  }

  Future<ProcessResult> _runCmd(
    String execPath, {
    List<String> args = const [],
    Map<String, String>? environment,
    bool? echoOutput,
    bool? throwOnError,
  }) async {
    echoOutput ??= true;
    throwOnError ??= false;

    return await runCommand(
      execPath,
      args: args,
      environment: environment,
      throwOnError: throwOnError,
      echoOutput: echoOutput,
      context: context,
      logger: logger,
    );
  }

  /// Helper method to get a GitDir instance, handling common setup
  Future<GitDir> _getGitDir() async {
    await updateLocalMirror();

    final isGitDir = await GitDir.isGitDir(context.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    return GitDir.fromExisting(context.gitCachePath);
  }

  Future<void> _recreateLocalMirror(Directory gitCacheDir) async {
    if (gitCacheDir.existsSync()) {
      gitCacheDir.deleteSync(recursive: true);
    }

    gitCacheDir.createSync(recursive: true);
    logger.info('Creating local mirror...');

    try {
      await runGitCloneUpdate(
        ['clone', '--progress', context.flutterUrl, gitCacheDir.path],
        logger,
      );
      logger.info('Local mirror created successfully');
    } catch (e) {
      logger.err('Failed to create local mirror: $e');
      gitCacheDir.deleteSync(recursive: true);
      rethrow;
    }
  }

  /// Runs Flutter cmd
  Future<ProcessResult> runFlutter(
    List<String> args, {
    CacheFlutterVersion? version,
    bool? echoOutput,
    bool? throwOnError,
  }) {
    version ??= cacheService.getGlobal();

    if (version == null) {
      return _runCmd(_flutterCmd, args: args);
    }

    return _runVersion(
      _flutterCmd,
      version,
      args,
      echoOutput: echoOutput,
      throwOnError: throwOnError,
    );
  }

  /// Runs dart cmd
  Future<ProcessResult> runDart(
    List<String> args, {
    CacheFlutterVersion? version,
    bool? echoOutput,
    bool? throwOnError,
  }) {
    version ??= cacheService.getGlobal();

    if (version == null) {
      return _runCmd(_dartCmd, args: args);
    }

    return _runVersion(
      _dartCmd,
      version,
      args,
      echoOutput: echoOutput,
      throwOnError: throwOnError,
    );
  }

  /// Exec commands with the Flutter env
  Future<ProcessResult> exec(
    String execPath,
    List<String> args,
    CacheFlutterVersion? version,
  ) async {
    // Update environment variables
    // If execPath is not provided will get the path configured version
    var environment = context.environment;
    if (version != null) {
      environment = updateEnvironmentVariables(
        [version.binPath, version.dartBinPath],
        context.environment,
        logger,
      );
    }

    // Run command
    return await _runCmd(execPath, args: args, environment: environment);
  }

  /// Clones Flutter SDK from Version Number or Channel
  Future<void> install(FlutterVersion version) async {
    final versionDir = cacheService.getVersionCacheDir(version.name);

    // Check if its git commit
    String? channel;

    if (version.isChannel) {
      channel = version.name;
      // If its not a commit hash
    } else if (version.isRelease) {
      if (version.releaseFromChannel != null) {
        // Version name forces channel version
        channel = version.releaseFromChannel;
      } else {
        final release =
            await flutterReleasesServices.getReleaseFromVersion(version.name);
        channel = release?.channel.name;
      }
    }

    final versionCloneParams = [
      '-c',
      'advice.detachedHead=false',
      '-b',
      channel ?? version.name,
    ];

    final useMirrorParams = ['--reference', context.gitCachePath];

    final useGitCache = context.gitCache;

    final cloneArgs = [
      //if its a git hash
      if (!version.isCommit) ...versionCloneParams,
      if (useGitCache) ...useMirrorParams,
    ];

    try {
      final result = await runGit(
        [
          'clone',
          '--progress',
          ...cloneArgs,
          context.flutterUrl,
          versionDir.path,
        ],
        echoOutput: !(context.isTest || !logger.isVerbose),
      );

      final isGit = await GitDir.isGitDir(versionDir.path);

      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      /// If version is not a channel reset to version
      if (!version.isChannel) {
        final gitDir = await GitDir.fromExisting(versionDir.path);
        // reset --hard $version
        await gitDir.runCommand(['reset', '--hard', version.version]);
      }

      if (result.exitCode != io.ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
        );
      }
    } on Exception {
      cacheService.remove(version);
      rethrow;
    }
  }

  Future<void> updateLocalMirror() async {
    final unlock = await _isUpdatingCache.getLock();

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
            print('No uncommitted changes. Working directory is clean.');
          } else {
            await _recreateLocalMirror(gitCacheDir);
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
            await _recreateLocalMirror(gitCacheDir);
          } else {
            rethrow;
          }
        }
      } else {
        await _recreateLocalMirror(gitCacheDir);
      }
    } finally {
      unlock();
    }
  }

  /// Gets a list of all tags in the repository
  Future<List<String>> getTags() async {
    try {
      final gitDir = await _getGitDir();
      final tags = await gitDir.tags().toList();

      return tags.map((tag) => tag.tag).toList();
    } on Exception {
      return [];
    }
  }

  /// Resolves any git reference (branch, tag, commit) to its SHA
  /// Returns null if reference doesn't exist
  Future<String?> getReference(String ref) async {
    try {
      final gitDir = await _getGitDir();
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
      final gitDir = await _getGitDir();

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
