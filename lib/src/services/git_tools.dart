import 'dart:io';

import 'package:fvm/src/utils/process_manager.dart';
import 'package:path/path.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../models/valid_version_model.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import 'context.dart';
import 'releases_service/releases_client.dart';

/// Tools  and helpers used for interacting with git
class GitTools {
  GitTools._();

  /// Clones Flutter SDK from Version Number or Channel
  static Future<void> cloneVersion(ValidVersion version) async {
    final versionDir = versionCacheDir(version.name);
    await versionDir.create(recursive: true);

    // Check if its git commit
    String? channel;

    if (version.isChannel) {
      channel = version.name;
      // If its not a commit hash
    } else if (version.isRelease) {
      if (version.forceChannel != null) {
        // Version name forces channel version
        channel = version.forceChannel;
      } else {
        // Fetches the channel of version by priority
        final flutterReleases = await fetchFlutterReleases();
        channel = flutterReleases.getChannelFromVersion(version.name);
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
      if (!version.isGitHash) ...versionCloneParams,
      if (ctx.useGitCache) ...useMirrorParams,
    ].join(' ');

    try {
      await ProcessRunner.run(
        'git clone --progress $cloneArgs ${ctx.flutterRepo} ${versionDir.path}',
      );
    } on Exception {
      await _cleanupVersionDir(versionDir);
      rethrow;
    }

    /// If version is not a channel reset to version
    if (!version.isChannel) {
      try {
        await _resetRepository(versionDir, version: version.version);
      } on FvmException {
        await _cleanupVersionDir(versionDir);
        rethrow;
      }
    }

    return;
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  static Future<void> _updateFlutterRepoCache() async {
    // If cache file does not exists create it
    if (!ctx.gitCacheDir.existsSync()) {
      await ctx.gitCacheDir.create(recursive: true);
      await ProcessRunner.runWithProgress(
        'git clone --progress $kFlutterRepo ${ctx.gitCacheDir.path}',
        description: 'Creating local mirror of Flutter repository',
      );
    } else {
      final dotGitDir = Directory(join(ctx.gitCacheDir.path, '.git'));

      if (!dotGitDir.existsSync()) {
        ctx.gitCacheDir.deleteSync(recursive: true);
        logger.info('Recreating mirror');
        return _updateFlutterRepoCache();
      }

      await ProcessRunner.runWithProgress(
        'git remote update',
        description: 'Updating local Flutter repo cache',
        workingDirectory: ctx.gitCacheDir.path,
      );
    }
  }

  static Future<void> _cleanupVersionDir(Directory versionDir) async {
    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  /// Resets the repository at [directory] to [version] using `git reset`
  ///
  /// Throws [FvmException] if `git`'s exit code is not 0.
  static Future<void> _resetRepository(
    Directory directory, {
    required String version,
  }) async {
    await ProcessRunner.runWithProgress(
      'git reset --hard $version',
      description: 'Resetting cached Flutter repository',
      workingDirectory: directory.path,
    );
  }

  /// Add `` to `.gitignore` file
  static Future<void> writeGitIgnore() async {
    const ignoreStr = '\n.fvm/flutter_sdk';
    final gitIgnoreFile = File('.gitignore');
    if (!await gitIgnoreFile.exists()) {
      // If no gitIgnore file exists skip
      return;
    }

    // If in test mode skip
    if (ctx.isTest) return;

    final content = await gitIgnoreFile.readAsString();

    if (!content.contains(ignoreStr) &&
        logger.confirm(
          'You should have .fvm/flutter_sdk in your .gitignore. Would you like to do this now?',
        )) {
      final writeContent =
          '${content.endsWith('\n') ? "" : "\n"}\n# FVM \n.fvm/flutter_sdk';

      await gitIgnoreFile.writeAsString(
        writeContent,
        mode: FileMode.append,
      );
      logger.success('Added ".fvm/flutter_sdk" to .gitignore.');
    }
  }
}
