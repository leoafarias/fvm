import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import 'context.dart';

/// Tools  and helpers used for interacting with git
class GitTools {
  GitTools._();

  /// Clones Flutter SDK from Version Number or Channel
  /// Returns exists:true if comes from cache or false if its new fetch.
  static Future<void> cloneVersion(String version) async {
    final versionDir = versionCacheDir(version);
    await versionDir.create(recursive: true);

    final isCommit = checkIsGitHash(version);

    final args = [
      'clone',
      '--progress',
      if (!isCommit) ...[
        '-c',
        'advice.detachedHead=false',
        '-b',
        version,
      ],
      kFlutterRepo,
      versionDir.path
    ];

    final process = await runExecutableArguments(
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

    if (isCommit) {
      try {
        await _resetRepository(versionDir, commitHash: version);
      } on FvmInternalError catch (_) {
        await _cleanupVersionDir(versionDir);

        rethrow;
      }
    }

    return;
  }

  static Future<void> _cleanupVersionDir(Directory versionDir) async {
    if (await versionDir.exists()) {
      await versionDir.delete();
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
  static Future<String?> getBranchOrTag(String version) async {
    final versionDir = Directory(join(ctx.cacheDir.path, version));
    return _getCurrentGitBranch(versionDir);
  }

  static Future<String?> _getCurrentGitBranch(Directory dir) async {
    try {
      if (!await dir.exists()) {
        throw Exception(
            'Could not get GIT version from ${dir.path} that does not exist');
      }
      var result = await runExecutableArguments(
          'git', ['rev-parse', '--abbrev-ref', 'HEAD'],
          workingDirectory: dir.path);

      if (result.stdout.trim() == 'HEAD') {
        result = await runExecutableArguments(
            'git', ['tag', '--points-at', 'HEAD'],
            workingDirectory: dir.path);
      }

      if (result.exitCode != 0) {
        return null;
      }

      return result.stdout.trim() as String;
    } on Exception catch (err) {
      FvmLogger.error(err.toString());
      return null;
    }
  }

  /// Resets the repository at [directory] to [commitHash] using `git reset`
  ///
  /// Throws [FvmInternalError] if `git`'s exit code is not 0.
  static Future<void> _resetRepository(
    Directory directory, {
    required String commitHash,
  }) async {
    final reset = await runExecutableArguments(
      'git',
      [
        '-C',
        directory.path,
        'reset',
        '--hard',
        commitHash,
      ],
      stdout: consoleController.stdoutSink,
      stderr: consoleController.stderrSink,
    );

    if (reset.exitCode != 0) {
      logger.trace(reset.stderr.toString());

      throw FvmInternalError(
        'Could not git reset $commitHash: ${reset.exitCode}',
      );
    }
  }
}
