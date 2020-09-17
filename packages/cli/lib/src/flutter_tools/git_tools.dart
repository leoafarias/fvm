import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'package:fvm/src/utils/logger.dart';

import 'package:path/path.dart' as path;
import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_run.dart';

/// Check if Git is installed
Future<void> _checkIfGitInstalled() async {
  try {
    await run(
      'git',
      ['--version'],
      workingDirectory: kWorkingDirectory.path,
      runInShell: Platform.isWindows,
    );
  } on ProcessException {
    throw Exception(
        'You need Git Installed to run fvm. Go to https://git-scm.com/downloads');
  }
}

/// Clones Flutter SDK from Version Number or Channel
/// Returns exists:true if comes from cache or false if its new fetch.
Future<void> runGitClone(String version) async {
  await _checkIfGitInstalled();
  final versionDirectory = Directory(path.join(kVersionsDir.path, version));

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
    runInShell: Platform.isWindows,
    verbose: logger.isVerbose,
  );

  if (process.exitCode != 0) {
    // If clone to directory fails. Remove directory
    if (await versionDirectory.exists()) {
      await versionDirectory.delete();
    }
    throw InternalError('Could not install Flutter version: $version.');
  }
}

Future<String> getCurrentGitBranch(Directory dir) async {
  try {
    if (!await dir.exists()) {
      throw Exception('Could not get version from SDK that is not installed');
    }
    var result = await run('git', ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: dir.path, runInShell: true);

    if (result.stdout.trim() == 'HEAD') {
      result = await run('git', ['tag', '--points-at', 'HEAD'],
          workingDirectory: dir.path, runInShell: true);
    }

    if (result.exitCode != 0) {
      return null;
    }

    return result.stdout.trim() as String;
  } on Exception catch (err) {
    //TODO: better error logging
    FvmLogger.error(err.toString());
    return null;
  }
}

Future<String> gitGetVersion(String version) async {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  return getCurrentGitBranch(versionDir);
}
