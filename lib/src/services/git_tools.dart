import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import 'context.dart';
import 'releases_service/releases_client.dart';

/// Tools  and helpers used for interacting with git
class GitTools {
  GitTools._();

  /// Clones Flutter SDK from Version Number or Channel

  static Future<void> cloneVersion(String version) async {
    final versionDir = versionCacheDir(version);
    await versionDir.create(recursive: true);

    // Check if its git commit
    final isCommit = checkIsGitHash(version);

    String? channel;

    if (checkIsChannel(version)) {
      channel = version;
    } else if (!isCommit) {
      final flutterReleases = await fetchFlutterReleases();
      channel = flutterReleases.getChannelFromVersion(version);
    }

    final args = [
      'clone',
      '--progress',
      if (!isCommit) ...[
        '-c',
        'advice.detachedHead=false',
        '-b',
        channel ?? version,
      ],
      kFlutterRepo,
      versionDir.path
    ];

    var process = await runExecutableArguments(
      'git',
      args,
      stdout: consoleController.stdoutSink,
      stderr: consoleController.stderrSink,
    );

    if (process.exitCode != 0) {
      // Did not cleanly exit clean up directory
      await _cleanupVersionDir(versionDir);
      logger.trace(process.stderr.toString());
      throw FvmInternalError('Could not git clone $version');
    }

    /// If version has a channel reset
    if (channel != version) {
      try {
        await _resetRepository(versionDir, version: version);
      } on FvmInternalError {
        await _cleanupVersionDir(versionDir);
        rethrow;
      }
    }

    return;
  }

  static Future<void> _cleanupVersionDir(Directory versionDir) async {
    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  /// Lists repository tags
  static Future<List<String>> getFlutterTags() async {
    final result = await runExecutableArguments(
      'git',
      ['ls-remote', '--tags', '$kFlutterRepo'],
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
    final result = await runExecutableArguments(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: versionDir.path,
    );
    return result.stdout.trim() as String;
  }

  /// Returns the [name] of a tag [version]
  static Future<String?> getTag(String version) async {
    final versionDir = Directory(join(ctx.cacheDir.path, version));
    final result = await runExecutableArguments(
      'git',
      ['describe', '--tags', '--exact-match'],
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
    final reset = await runExecutableArguments(
      'git',
      [
        'reset',
        '--hard',
        version,
      ],
      workingDirectory: directory.path,
      stdout: consoleController.stdoutSink,
      stderr: consoleController.stderrSink,
    );

    if (reset.exitCode != 0) {
      logger.trace(reset.stderr.toString());

      throw FvmInternalError(
        'Could not git reset $version: ${reset.exitCode}',
      );
    }
  }
}
