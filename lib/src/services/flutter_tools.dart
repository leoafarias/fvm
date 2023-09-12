import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:git/git.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../models/flutter_version_model.dart';
import '../utils/commands.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterTools {
  FlutterTools();

  static FlutterTools get instance => ctx.get<FlutterTools>();

  /// Upgrades a cached channel
  Future<void> runUpgrade(CacheFlutterVersion version) async {
    if (version.isChannel) {
      await runFlutter(version, ['upgrade']);
    } else {
      throw AppException('Can only upgrade Flutter Channels');
    }
  }

  /// Runs triggers sdk setup/install
  Future<int> runSetup(CacheFlutterVersion version) async {
    return runFlutter(version, ['doctor', '--version']);
  }

  /// Runs pub get
  Future<void> runPubGet(CacheFlutterVersion version) async {
    await runFlutter(
      version,
      ['pub', 'get'],
      showOutput: false,
    );
  }

  /// Clones Flutter SDK from Version Number or Channel
  Future<void> install(FlutterVersion version) async {
    final versionDir = CacheService.instance.getVersionCacheDir(version.name);

    // Check if its git commit
    String? channel;

    if (version.isChannel) {
      channel = version.name;
      // If its not a commit hash
    } else if (version.isRelease) {
      if (version.releaseChannel != null) {
        // Version name forces channel version
        channel = version.releaseChannel;
      } else {
        final release =
            await FlutterReleasesClient.getReleaseFromVersion(version.name);
        channel = release?.channel.name;
      }
    }

    if (ctx.useGitCache) {
      await _updateFlutterRepoCache();
    }

    final versionCloneParams = [
      '-c',
      'advice.detachedHead=false',
      '-b',
      channel ?? version.name,
    ];

    final useMirrorParams = [
      '--reference',
      ctx.gitCacheDir,
    ];

    final cloneArgs = [
      //if its a git hash
      if (!version.isCommit) ...versionCloneParams,
      if (ctx.useGitCache) ...useMirrorParams,
    ];

    try {
      final result = await runGit(
        [
          'clone',
          '--progress',
          ...cloneArgs,
          ctx.flutterRepo,
          versionDir.path,
        ],
        echoOutput: ctx.isTest ? false : true,
      );

      final gitVersionDir =
          CacheService.instance.getVersionCacheDir(version.name);
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
      CacheService.instance.remove(version);
      rethrow;
    }

    return;
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  Future<void> _updateFlutterRepoCache() async {
    final isGitDir = await GitDir.isGitDir(ctx.gitCacheDir);

    // If cache file does not exists create it
    if (isGitDir) {
      final gitDir = await GitDir.fromExisting(ctx.gitCacheDir);
      await gitDir.runCommand(['remote', 'update'], echoOutput: true);
    } else {
      final gitCacheDir = Directory(ctx.gitCacheDir);
      // Ensure brand new directory
      if (gitCacheDir.existsSync()) {
        gitCacheDir.deleteSync(recursive: true);
      }
      gitCacheDir.createSync(recursive: true);

      await runGit(
        ['clone', '--progress', ctx.flutterRepo, gitCacheDir.path],
        echoOutput: true,
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
    final isGitDir = await GitDir.isGitDir(ctx.gitCacheDir);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    final gitDir = await GitDir.fromExisting(ctx.gitCacheDir);
    final result = await gitDir.runCommand(['tag']);
    if (result.exitCode != 0) {
      return [];
    }

    return LineSplitter.split(result.stdout as String)
        .map((line) => line.trim())
        .toList();
  }

  Future<String?> getReference(String ref) async {
    final isGitDir = await GitDir.isGitDir(ctx.gitCacheDir);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    final gitDir = await GitDir.fromExisting(ctx.gitCacheDir);
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
