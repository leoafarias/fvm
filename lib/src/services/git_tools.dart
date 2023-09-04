import 'package:fvm/fvm.dart';
import 'package:git/git.dart';

import '../../exceptions.dart';
import '../models/flutter_version_model.dart';
import 'context.dart';
import 'releases_service/releases_client.dart';

/// Tools  and helpers used for interacting with git
class GitTools {
  GitTools({
    FVMContext? context,
  }) : _context = context ?? ctx;

  final FVMContext _context;

  /// Clones Flutter SDK from Version Number or Channel
  static Future<void> cloneVersion(FlutterVersion version) async {
    CacheService.remove(version);

    final versionDir = CacheService.getVersionCacheDir(version.name);

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
      ctx.gitCacheDir.path,
    ];

    final cloneArgs = [
      //if its a git hash
      if (!version.isCommit) ...versionCloneParams,
      if (ctx.useGitCache) ...useMirrorParams,
    ];

    try {
      await runGit(
        [
          'clone',
          '--progress',
          ...cloneArgs,
          ctx.flutterRepo,
          versionDir.path,
        ],
        echoOutput: true,
      );
    } on Exception {
      CacheService.remove(version);
      rethrow;
    }

    final gitVersionDir = CacheService.getVersionCacheDir(version.name);
    final isGit = await GitDir.isGitDir(gitVersionDir.path);

    if (!isGit) {
      throw FvmError('Not a git directory');
    }

    /// If version is not a channel reset to version
    if (!version.isChannel) {
      try {
        final gitDir = await GitDir.fromExisting(gitVersionDir.path);
        // reset --hard $version
        await gitDir.runCommand(['reset', '--hard', version.name]);
      } on FvmException {
        CacheService.remove(version);
        rethrow;
      }
    }

    return;
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  static Future<void> _updateFlutterRepoCache() async {
    final isGitDir = await GitDir.isGitDir(ctx.gitCacheDir.path);

    // If cache file does not exists create it
    if (isGitDir) {
      final gitDir = await GitDir.fromExisting(ctx.gitCacheDir.path);
      await gitDir.runCommand(['remote', 'update']);
    } else {
      // Ensure brand new directory
      ctx.gitCacheDir
        ..deleteSync(recursive: true)
        ..createSync(recursive: true);

      await runGit(
        ['clone', '--progress', ctx.flutterRepo, ctx.gitCacheDir.path],
        echoOutput: true,
      );
    }
  }
}
