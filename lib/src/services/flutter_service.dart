import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/services/base_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/parsers/git_clone_update_printer.dart';
import 'package:git/git.dart';
import 'package:io/io.dart' as io;
import 'package:mason_logger/mason_logger.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../models/flutter_version_model.dart';
import '../utils/commands.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends ContextService {
  const FlutterService(super.context);

  // Ensures cache.dir exists and its up to date
  Future<void> _ensureCacheDir() async {
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);

    // If cache file does not exists create it
    if (!isGitDir) {
      await updateLocalMirror();
    }
  }

  static FlutterService get fromContext => getProvider();

  /// Upgrades a cached channel
  Future<void> runUpgrade(CacheFlutterVersion version) async {
    if (version.isChannel) {
      await runFlutter(['upgrade'], version: version);
    } else {
      throw AppException('Can only upgrade Flutter Channels');
    }
  }

  /// Clones Flutter SDK from Version Number or Channel
  Future<void> install(FlutterVersion version) async {
    final versionDir = CacheService(context).getVersionCacheDir(version.name);

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
            await FlutterReleases.getReleaseFromVersion(version.name);
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

    final cloneArgs = [
      //if its a git hash
      if (!version.isCommit) ...versionCloneParams,
      if (context.gitCache) ...useMirrorParams,
    ];

    try {
      final result = await runGit([
        'clone',
        '--progress',
        ...cloneArgs,
        context.flutterUrl,
        versionDir.path,
      ], echoOutput: !(context.isTest || !logger.isVerbose));

      final gitVersionDir =
          CacheService(context).getVersionCacheDir(version.name);
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
      CacheService(context).remove(version);
      rethrow;
    }
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  Future<void> updateLocalMirror() async {
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);

    // If cache file does not exists create it
    if (isGitDir) {
      final gitDir = await GitDir.fromExisting(context.gitCachePath);
      logger.detail('Syncing local mirror...');

      try {
        await gitDir.runCommand(['pull', 'origin']);
      } on ProcessException catch (e) {
        logger.err(e.message);
      }
    } else {
      final gitCacheDir = Directory(context.gitCachePath);
      // Ensure brand new directory
      if (gitCacheDir.existsSync()) {
        gitCacheDir.deleteSync(recursive: true);
      }
      gitCacheDir.createSync(recursive: true);

      logger.info('Creating local mirror...');

      await runGitCloneUpdate(
        ['clone', '--progress', context.flutterUrl, gitCacheDir.path],
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
    return tags.where((t) => t == tag).isNotEmpty;
  }

  Future<List<String>> getTags() async {
    await _ensureCacheDir();
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    final gitDir = await GitDir.fromExisting(context.gitCachePath);
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
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    final gitDir = await GitDir.fromExisting(context.gitCachePath);
    try {
      final result = await gitDir.runCommand(
        ['rev-parse', '--short', '--verify', ref],
      );

      return result.stdout.trim();
    } on Exception {
      return null;
    }
  }
}

class FlutterServiveMock extends FlutterService {
  FlutterServiveMock(FVMContext context) : super(context);

  @override
  Future<void> install(FlutterVersion version) async {
    /// Moves directory from main context HOME/fvm/versions to test context

    final mainContext = FVMContext.main;
    var cachedVersion = CacheService(mainContext).getVersion(version);
    if (cachedVersion == null) {
      await FlutterService(mainContext).install(version);
      cachedVersion = CacheService(mainContext).getVersion(version);
    }
    final versionDir = CacheService(mainContext).getVersionCacheDir(
      version.name,
    );
    final testVersionDir = CacheService(context).getVersionCacheDir(
      version.name,
    );

    await io.copyPath(versionDir.path, testVersionDir.path);
  }
}
