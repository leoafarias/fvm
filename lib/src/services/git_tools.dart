import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import 'context.dart';
import 'settings_service.dart';

/// Tools  and helpers used for interacting with git
class GitTools {
  GitTools._();

  /// Check if Git is installed
  static Future<void> canRun() async {
    try {
      await run('git', ['--version'], workingDirectory: kWorkingDirectory.path);
    } on ProcessException {
      throw Exception(
        'You need Git Installed to run fvm. Go to https://git-scm.com/downloads',
      );
    }
  }

  /// Creates local git cache of Flutter repo.
  static Future<void> createCache() async {
    try {
      if (await ctx.gitCacheDir.exists()) {
        await ctx.gitCacheDir.delete();
      }

      final args = [
        'clone',
        '--mirror',
        kFlutterRepo,
        _cacheRepo,
      ];

      await run(
        'git',
        args,
        workingDirectory: kWorkingDirectory.path,
        stdout: consoleController.stdoutSink,
        stderr: consoleController.stderrSink,
      );
    } on ProcessException {
      throw Exception(
        'You need Git Installed to run fvm. Go to https://git-scm.com/downloads',
      );
    }
  }

  /// Updates local Flutter cache with 'remote update'.
  static Future<void> updateCache() async {
    try {
      final args = ['remote', 'update'];
      await run(
        'git',
        args,
        workingDirectory: _cacheRepo,
        stdout: consoleController.stdoutSink,
        stderr: consoleController.stderrSink,
      );
    } on ProcessException {
      throw Exception(
        'You need Git Installed to run fvm. Go to https://git-scm.com/downloads',
      );
    }
  }

  /// Gets the Flutter repo if configured on FVM settings
  static String get _cacheRepo {
    /// Loads settings file
    final settings = SettingsService.readSync();
    if (settings.gitCache) {
      return ctx.gitCacheDir.path;
    }
    return kFlutterRepo;
  }

  /// Clones Flutter SDK from Version Number or Channel
  /// Returns exists:true if comes from cache or false if its new fetch.
  static Future<void> cloneVersion(String version) async {
    await canRun();
    final versionDirectory = versionCacheDir(version);
    await versionDirectory.create(recursive: true);

    final isCommit = checkIsGitHash(version);

    final args = [
      'clone',
      '--progress',
      if (!isCommit) ...[
        '-c',
        'advice.detachedHead=false',
        '--single-branch',
        '-b',
        version,
      ],
      kFlutterRepo,
      versionDirectory.path
    ];

    final process = await run(
      'git',
      args,
      stdout: consoleController.stdoutSink,
      stderr: consoleController.stderrSink,
    );

    if (process.exitCode != 0) {
      // Did not cleanly exit clean up directory
      if (process.exitCode == 128) {
        if (await versionDirectory.exists()) {
          await versionDirectory.delete();
        }
      }

      logger.trace(process.stderr.toString());
      throw FvmInternalError('Could not git clone $version');
    }

    if (isCommit) {
      try {
        await _resetRepository(versionDirectory, commitHash: version);
      } on FvmInternalError catch (_) {
        if (await versionDirectory.exists()) {
          await versionDirectory.delete(recursive: true);
        }

        rethrow;
      }
    }

    return;
  }

  /// Lists repository tags
  static Future<List<String>> getFlutterTags() async {
    final result = await run('git', ['ls-remote', '--tags', '$kFlutterRepo']);

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
  static Future<String> getBranchOrTag(String version) async {
    final versionDir = Directory(join(ctx.cacheDir.path, version));
    return _getCurrentGitBranch(versionDir);
  }

  static Future<String> _getCurrentGitBranch(Directory dir) async {
    try {
      if (!await dir.exists()) {
        throw Exception(
            'Could not get GIT version from ${dir.path} that does not exist');
      }
      var result = await run('git', ['rev-parse', '--abbrev-ref', 'HEAD'],
          workingDirectory: dir.path);

      if (result.stdout.trim() == 'HEAD') {
        result = await run('git', ['tag', '--points-at', 'HEAD'],
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
  static void _resetRepository(Directory directory, {String commitHash}) async {
    final reset = await run(
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
