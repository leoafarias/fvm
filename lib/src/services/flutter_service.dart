import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/io.dart' as io;
import 'package:mason_logger/mason_logger.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/commands.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import '../utils/parsers/git_clone_update_printer.dart';
import 'base_service.dart';
import 'cache_service.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends ContextService {
  const FlutterService(super.context);

  // Ensures cache.dir exists and its up to date
  Future<void> _ensureCacheDir() async {
    final isGitDir = await GitDir.isGitDir(ctx.gitCachePath);

    // If cache file does not exists create it
    if (!isGitDir) {
      await updateLocalMirror();
    }
  }

  /// Upgrades a cached channel
  Future<void> runUpgrade(CacheFlutterVersion version) async {
    if (version.isChannel) {
      await runFlutter(['upgrade'], version: version);
    } else {
      throw AppException('Can only upgrade Flutter Channels');
    }
  }

  /// Clones Flutter SDK from Version Number or Channel
  Future<void> install(
    FlutterVersion version, {
    required bool useGitCache,
  }) async {
    final versionDir = CacheService(ctx).getVersionCacheDir(version.name);

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
        final release = await ctx.flutterReleasesServices
            .getReleaseFromVersion(version.name);
        channel = release?.channel.name;
      }
    }

    final versionCloneParams = [
      '-c',
      'advice.detachedHead=false',
      '-b',
      channel ?? version.name,
    ];

    final useMirrorParams = ['--reference', ctx.gitCachePath];

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
          ctx.flutterUrl,
          versionDir.path,
        ],
        echoOutput: !(ctx.isTest || !logger.isVerbose),
      );

      final gitVersionDir = CacheService(ctx).getVersionCacheDir(version.name);
      final isGit = await GitDir.isGitDir(gitVersionDir.path);

      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      /// If version is not a channel reset to version
      if (!version.isChannel) {
        final gitDir = await GitDir.fromExisting(gitVersionDir.path);
        // reset --hard $version
        await gitDir.runCommand(['reset', '--hard', version.version]);
      }

      if (result.exitCode != ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
        );
      }
    } on Exception {
      CacheService(ctx).remove(version);
      rethrow;
    }
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  Future<void> updateLocalMirror() async {
    final isGitDir = await GitDir.isGitDir(ctx.gitCachePath);

    // If cache file does not exists create it
    if (isGitDir) {
      final gitDir = await GitDir.fromExisting(ctx.gitCachePath);
      logger.detail('Syncing local mirror...');

      try {
        await gitDir.runCommand(['pull', 'origin']);
      } on ProcessException catch (e) {
        logger.err(e.message);
      }
    } else {
      final gitCacheDir = Directory(ctx.gitCachePath);
      // Ensure brand new directory
      if (gitCacheDir.existsSync()) {
        gitCacheDir.deleteSync(recursive: true);
      }
      gitCacheDir.createSync(recursive: true);

      logger.info('Creating local mirror...');

      await runGitCloneUpdate(
        ['clone', '--progress', ctx.flutterUrl, gitCacheDir.path],
      );
    }
  }

  /// Gets a commit for the Flutter repo
  /// If commit does not exist returns null
  Future<bool> isCommit(String commit) async {
    final commitSha = await getReference(commit);
    if (commitSha == null) {
      return false;
    }

    return commit.contains(commitSha);
  }

  /// Gets a tag for the Flutter repository
  /// If tag does not exist returns null
  Future<bool> isTag(String tag) async {
    final commitSha = await getReference(tag);
    if (commitSha == null) {
      return false;
    }

    final tags = await getTags();

    return tags.any((t) => t == tag);
  }

  Future<List<String>> getTags() async {
    await _ensureCacheDir();
    final isGitDir = await GitDir.isGitDir(ctx.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    final gitDir = await GitDir.fromExisting(ctx.gitCachePath);
    final result = await gitDir.runCommand(['tag']);
    if (result.exitCode != 0) {
      return [];
    }

    return LineSplitter.split(result.stdout as String)
        .map((line) => line.trim())
        .toList();
  }

  Future<String?> getReference(String ref) async {
    await _ensureCacheDir();
    final isGitDir = await GitDir.isGitDir(ctx.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    try {
      final gitDir = await GitDir.fromExisting(ctx.gitCachePath);
      final result = await gitDir.runCommand(
        ['rev-parse', '--short', '--verify', ref],
      );

      return result.stdout.trim();
    } on Exception {
      return null;
    }
  }
}

class FlutterServiceMock extends FlutterService {
  const FlutterServiceMock(super.context);

  @override
  Future<void> install(
    FlutterVersion version, {
    required bool useGitCache,
  }) async {
    /// Moves directory from main context HOME/fvm/versions to test context

    final mainContext = FVMContext.main;
    var cachedVersion = CacheService(mainContext).getVersion(version);
    if (cachedVersion == null) {
      await FlutterService(mainContext)
          .install(version, useGitCache: useGitCache);
      cachedVersion = CacheService(mainContext).getVersion(version);
    }
    final versionDir = CacheService(mainContext).getVersionCacheDir(
      version.name,
    );
    final testVersionDir = CacheService(ctx).getVersionCacheDir(
      version.name,
    );

    await io.copyPath(versionDir.path, testVersionDir.path);
  }
}
