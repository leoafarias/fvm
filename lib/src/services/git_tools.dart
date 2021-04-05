import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import 'context.dart';
import 'settings_service.dart';

// ignore: avoid_classes_with_only_static_members
/// Tools  and helpers used for interacting with git

// ignore: non_constant_identifier_names
final GitTools = GitToolsWithContext();

/// Tools  and helpers used for interacting with git
class GitToolsWithContext {
  FvmContext get _context {
    return ctx;
  }

  /// Check if Git is installed
  Future<void> canRun() async {
    try {
      await run('git', ['--version'], workingDirectory: kWorkingDirectory.path);
    } on ProcessException {
      throw Exception(
        'You need Git Installed to run fvm. Go to https://git-scm.com/downloads',
      );
    }
  }

  /// Creates local git cache of Flutter repo.
  Future<void> createCache() async {
    try {
      if (await _context.gitCacheDir.exists()) {
        await _context.gitCacheDir.delete();
      }

      final args = [
        'clone',
        '--mirror',
        kFlutterRepo,
        flutterRepo,
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
  Future<void> updateCache() async {
    try {
      final args = ['remote', 'update'];
      await run(
        'git',
        args,
        workingDirectory: flutterRepo,
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
  String get flutterRepo {
    /// Loads settings file
    final settings = SettingsService.readSync();
    if (settings.gitCache) {
      return _context.gitCacheDir.path;
    }
    return kFlutterRepo;
  }

  /// Clones Flutter SDK from Version Number or Channel
  /// Returns exists:true if comes from cache or false if its new fetch.
  Future<void> cloneVersion(String version) async {
    await canRun();
    final versionDirectory = versionCacheDir(version);
    await versionDirectory.create(recursive: true);

    final args = [
      'clone',
      '-c',
      'advice.detachedHead=false',
      '--progress',
      '--single-branch',
      '-b',
      version,
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

    return;
  }

  /// Checks if [branch] is up to date. Returns [true] if it is.
  Future<bool> checkBranchUpToDate(String branch) async {
    final result =
        await run('git', ['rev-list', 'HEAD...origin/$branch', '--count']);
    // If 0 then it's up to date
    return result.stdout == 0;
  }

  /// Lists repository tags
  Future<List<String>> getFlutterTags() async {
    print(_context.cacheDir.path);
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
  Future<String> getBranchOrTag(String version) async {
    final versionDir = Directory(join(_context.cacheDir.path, version));
    return _getCurrentGitBranch(versionDir);
  }

  Future<String> _getCurrentGitBranch(Directory dir) async {
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
}
