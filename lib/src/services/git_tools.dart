import 'dart:io';

import 'package:fvm/src/utils/run_command.dart';
import 'package:path/path.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../models/valid_version_model.dart';
import '../utils/console_utils.dart';
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
      await updateFlutterRepoMirror();
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
      '--dissociate',
    ];

    final cloneArgs = [
      //if its a git hash
      if (!version.isGitHash) ...versionCloneParams,
      if (ctx.useGitCache) ...useMirrorParams,
      kFlutterRepo,
      versionDir.path,
    ].join(' ');

    final process = await runProcess(
      'git clone --progress $cloneArgs',
    );

    if (process.exitCode != 0) {
      // Did not cleanly exit clean up directory
      await _cleanupVersionDir(versionDir);
      logger.trace(process.stderr.toString());
      throw FvmInternalError('Could not git clone $version');
    }

    /// If version has a channel reset
    if (version.needReset) {
      try {
        await _resetRepository(versionDir, version: version.version);
      } on FvmInternalError {
        await _cleanupVersionDir(versionDir);
        rethrow;
      }
    }

    return;
  }

  /// Creates a local git mirror of the Flutter repository
  static Future<void> _createFlutterRepoMirror() async {
    // Delete if already exists
    if (await ctx.gitCacheDir.exists()) {
      await ctx.gitCacheDir.delete(recursive: true);
    }

    await ctx.gitCacheDir.create(recursive: true);

    final process = await runProcess(
      'git clone --progress --mirror $kFlutterRepo ${ctx.gitCacheDir.path}',
    );

    if (process.exitCode != 0) {
      throw FvmInternalError(
        'Could not create local mirror of Flutter repo: ${process.stderr}}',
      );
    }
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  static Future<void> updateFlutterRepoMirror() async {
    final cacheExists = await ctx.gitCacheDir.exists();

    // If cache file does not exists create it
    if (!cacheExists) {
      Logger.info('Creating local mirror of Flutter repo...');
      await _createFlutterRepoMirror();
      Logger.fine('Creation complete.');
    } else {
      Logger.info('Updating local mirror of Flutter repo...');
      await runProcess(
        'git remote update',
        workingDirectory: ctx.gitCacheDir.path,
      );
      Logger.fine('Update complete.');
    }
  }

  static Future<void> _cleanupVersionDir(Directory versionDir) async {
    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  /// Lists repository tags
  static Future<List<String>> getFlutterTags() async {
    final result = await runGit(
      'ls-remote --tags --refs $kFlutterRepo',
    );

    if (result.exitCode != 0) {
      throw Exception('Could not fetch list of available Flutter SDKs');
    }

    var tags = result.stdout.split('\n') as List<String>;

    var versionsList = <String>[];
    for (var tag in tags) {
      final version = tag.split('refs/tags/');

      if (version.length > 1) {
        versionsList.add(version[1]);
      }
    }

    return versionsList;
  }

  /// Returns the [name] of a branch or tag for a [version]
  static Future<String?> getBranch(String version) async {
    final versionDir = Directory(join(ctx.cacheDir.path, version));
    final result = await runGit(
      'rev-parse --abbrev-ref HEAD',
      workingDirectory: versionDir.path,
    );
    return result.stdout.trim() as String;
  }

  /// Returns the [name] of a tag [version]
  static Future<String?> getTag(String version) async {
    final versionDir = Directory(join(ctx.cacheDir.path, version));
    final result = await runGit(
      'describe --tags --exact-match',
      workingDirectory: versionDir.path,
    );
    return result.stdout.trim() as String;
  }

  /// Resets the repository at [directory] to [version] using `git reset`
  ///
  /// Throws [FvmInternalError] if `git`'s exit code is not 0.
  static Future<void> _resetRepository(
    Directory directory, {
    required String version,
  }) async {
    final reset = await runGit(
      'reset --hard $version',
      workingDirectory: directory.path,
    );

    if (reset.exitCode != 0) {
      logger.trace(reset.stderr.toString());

      throw FvmInternalError(
        'Could not git reset $version: ${reset.exitCode}',
      );
    }
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
        await confirm(
          'You should have .fvm/flutter_sdk in your .gitignore. Would you like to do this now?',
        )) {
      final writeContent =
          '${content.endsWith('\n') ? "" : "\n"}\n# FVM \n.fvm/flutter_sdk';

      await gitIgnoreFile.writeAsString(
        writeContent,
        mode: FileMode.append,
      );
      Logger.fine('Added ".fvm/flutter_sdk" to .gitignore.');
    }
    Logger.spacer();
  }
}
