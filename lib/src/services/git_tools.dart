import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/utils/helpers.dart';

import 'package:fvm/src/utils/logger.dart';

import 'package:path/path.dart' as path;
import 'package:process_run/cmd_run.dart';

/// Tools used for interacting with git

class GitTools {
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

  /// Clones Flutter SDK from Version Number or Channel
  /// Returns exists:true if comes from cache or false if its new fetch.
  static Future<void> cloneVersion(String version) async {
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

  static Future<bool> checkBranchUpToDate(String branch) async {
    final result =
        await run('git', ['rev-list', 'HEAD...origin/$branch', '--count']);
    // If 0 then it's up to date
    return result.stdout == 0;
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

  static Future<String> getBranchOrTag(String version) async {
    final versionDir = Directory(path.join(kFvmCacheDir.path, version));
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
}
