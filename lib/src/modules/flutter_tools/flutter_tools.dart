import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'package:fvm/utils/git.dart';

import 'package:fvm/src/modules/flutter_tools/flutter_helpers.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:fvm/utils/pretty_print.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_run.dart';
import 'package:path/path.dart' as path;

/// Runs a process
Future<void> flutterCmd(String exec, List<String> args,
    {String workingDirectory}) async {
  var pr = await run(
    exec,
    args,
    workingDirectory: workingDirectory,
    stdout: stdout,
    stderr: stderr,
    runInShell: Platform.isWindows,
    stdin: stdin,
  );
  exitCode = pr.exitCode;
}

/// Clones Flutter SDK from Version Number or Channel
/// Returns exists:true if comes from cache or false if its new fetch.
Future<void> gitCloneCmd(
  String version,
) async {
  final versionDirectory = Directory(path.join(kVersionsDir.path, version));

  await versionDirectory.create(recursive: true);

  final args = [
    'clone',
    '-c',
    'advice.detachedHead=false',
    '--progress',
    '--depth',
    '1',
    '--single-branch',
    '-b',
    version,
    '--depth',
    '1',
    kFlutterRepo,
    versionDirectory.path
  ];

  final process = await run(
    'git',
    args,
    stdout: stdout,
    stderr: stderr,
    runInShell: Platform.isWindows,
    verbose: logger.isVerbose,
  );

  if (process.exitCode != 0) {
    throw ExceptionCouldNotClone(
        'Could not install Flutter version: $version.');
  }
}

/// Gets SDK Version
Future<String> getFlutterSdkVersion(String version) async {
  final versionDirectory = Directory(path.join(kVersionsDir.path, version));
  if (!await versionDirectory.exists()) {
    throw Exception('Could not get version from SDK that is not installed');
  }
  try {
    final versionFile = File(path.join(versionDirectory.path, 'version'));
    final semver = await versionFile.readAsString();
    return semver;
  } on Exception {
    // If version file does not exist return null for flutter version.
    // Means setup was completed yet
    return null;
  }
}

Future<String> gitGetVersion(String version) async {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  if (!await versionDir.exists()) {
    throw Exception('Could not get version from SDK that is not installed');
  }
  var result = await runGit(['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: versionDir.path);

  if (result.stdout.trim() == 'HEAD') {
    result = await runGit(['tag', '--points-at', 'HEAD'],
        workingDirectory: versionDir.path);
  }

  if (result.exitCode != 0) {
    throw Exception('Could not get version Info.');
  }

  final versionNumber = result.stdout.trim() as String;
  return versionNumber;
}

/// Removes a Version of Flutter SDK
Future<void> removeRelease(String version) async {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  if (await versionDir.exists()) {
    await versionDir.delete(recursive: true);
  }
}

/// Check if version is from git
Future<bool> isInstalledCorrectly(String version) async {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  final gitDir = Directory(path.join(versionDir.path, '.github'));
  final flutterBin = Directory(path.join(versionDir.path, 'bin'));
  // Check if version directory exists
  if (!versionDir.existsSync()) return false;

  // Check if version directory is from git
  if (!gitDir.existsSync() || !flutterBin.existsSync()) {
    print('$version exists but was not setup correctly. Doing cleanup...');
    await removeRelease(version);
    return false;
  }

  return true;
}

Future<void> setupFlutterSdk(String version) async {
  final flutterExec = getFlutterSdkExec(version: version);
  await flutterCmd(flutterExec, ['--version']);
}

void setAsGlobalVersion(String version) {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  createLink(kDefaultFlutterLink, versionDir);

  PrettyPrint.success('The global Flutter version is now $version');
  PrettyPrint.success(
      'Make sure sure to add $kDefaultFlutterPath to your PATH environment variable');
}
