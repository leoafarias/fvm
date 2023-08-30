import 'dart:io';

import 'package:fvm/src/utils/process_manager.dart';
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

      throw FvmError(
        'Could not git clone $version',
        errorMessage: process.stderr.toString(),
      );
    }

    /// If version has a channel reset
    if (version.needReset) {
      try {
        await _resetRepository(versionDir, version: version.version);
      } on FvmError {
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

    final process = await startProcess(
      'git clone --progress --mirror $kFlutterRepo ${ctx.gitCacheDir.path}',
    );

    if (process.exitCode != 0) {
      throw FvmError(
        'Could not create local mirror of Flutter repository}',
        errorMessage: process.stderr.toString(),
      );
    }
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  static Future<void> updateFlutterRepoMirror() async {
    final cacheExists = await ctx.gitCacheDir.exists();

    // If cache file does not exists create it
    if (!cacheExists) {
      final progress = logger.progress(
        'Creating local mirror of Flutter repo...',
      );

      await _createFlutterRepoMirror();
      progress.complete('Mirror created.');
    } else {
      final progress =
          logger.progress('Updating local mirror of Flutter repo...');
      await runProcess(
        'git remote update',
        workingDirectory: ctx.gitCacheDir.path,
      );
      logger.success('Update complete.');
    }
  }

  static Future<void> _cleanupVersionDir(Directory versionDir) async {
    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  /// Lists repository tags
  static Future<List<String>> getFlutterTags() async {
    final result = await runProcess(
      'git ls-remote --tags --refs $kFlutterRepo',
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
    final result = await runProcess(
      'git rev-parse --abbrev-ref HEAD',
      workingDirectory: versionDir.path,
    );
    return result.stdout.trim() as String;
  }

  /// Returns the [name] of a tag [version]
  static Future<String?> getTag(String version) async {
    final versionDir = Directory(join(ctx.cacheDir.path, version));
    final result = await runProcess(
      'git describe --tags --exact-match',
      workingDirectory: versionDir.path,
    );
    return result.stdout.trim() as String;
  }

  /// Resets the repository at [directory] to [version] using `git reset`
  ///
  /// Throws [FvmError] if `git`'s exit code is not 0.
  static Future<void> _resetRepository(
    Directory directory, {
    required String version,
  }) async {
    final process = await runProcess(
      'git reset --hard $version',
      workingDirectory: directory.path,
    );

    if (process.exitCode != 0) {
      throw FvmError(
        'Could not reset repository $version: ${process.exitCode}',
        errorMessage: process.stderr.toString(),
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
