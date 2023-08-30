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

    try {
      await ProcessRunner.startOrThrow(
        'git clone --progress $cloneArgs',
        description: 'Cloning Flutter repository',
      );
    } on Exception {
      await _cleanupVersionDir(versionDir);
      rethrow;
    }

    /// If version has a channel reset
    if (version.needReset) {
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
  static Future<void> updateFlutterRepoMirror() async {
    final cacheExists = await ctx.gitCacheDir.exists();

    // If cache file does not exists create it
    if (!cacheExists) {
      await ctx.gitCacheDir.create(recursive: true);
      await ProcessRunner.startOrThrow(
        'git clone --progress --mirror $kFlutterRepo ${ctx.gitCacheDir.path}',
        description: 'Creating local mirror of Flutter repository',
      );
    } else {
      await ProcessRunner.startOrThrow(
        'git remote update',
        description: 'Updating local Flutter repo mirror',
        workingDirectory: ctx.gitCacheDir.path,
      );
    }
  }

  static Future<void> _cleanupVersionDir(Directory versionDir) async {
    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  /// Lists repository tags
  static Future<List<String>> getFlutterTags() async {
    final result = await ProcessRunner.runOrThrow(
      'git ls-remote --tags --refs $kFlutterRepo',
      description: 'Fetching Flutter tags',
    );

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
    final result = await ProcessRunner.runOrThrow(
      'git rev-parse --abbrev-ref HEAD',
      description: 'Fetching Flutter branch',
      workingDirectory: versionDir.path,
    );
    return result.stdout.trim() as String;
  }

  /// Returns the [name] of a tag [version]
  static Future<String?> getTag(String version) async {
    final versionDir = Directory(join(ctx.cacheDir.path, version));
    final result = await ProcessRunner.runOrThrow(
      'git describe --tags --exact-match',
      description: 'Fetching Flutter tag',
      workingDirectory: versionDir.path,
    );
    return result.stdout.trim() as String;
  }

  /// Resets the repository at [directory] to [version] using `git reset`
  ///
  /// Throws [FvmException] if `git`'s exit code is not 0.
  static Future<void> _resetRepository(
    Directory directory, {
    required String version,
  }) async {
    await ProcessRunner.runOrThrow(
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
        await confirm(
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
