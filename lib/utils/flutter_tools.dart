import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/git.dart';

import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:fvm/utils/print.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_run.dart';
import 'package:path/path.dart' as path;

/// Runs a process
Future<void> flutterCmd(String exec, List<String> args,
    {String workingDirectory}) async {
  var pr = await run(exec, args,
      workingDirectory: workingDirectory, stdout: stdout, stderr: stderr);
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

  final process = await run('git', args,
      stdout: stdout, stderr: stderr, verbose: logger.isVerbose);

  if (process.exitCode != 0) {
    throw ExceptionCouldNotClone(
        'Could not install Flutter version: $version.');
  }
}

/// Gets SDK Version
Future<String> flutterSdkVersion(String branch) async {
  final branchDirectory = Directory(path.join(kVersionsDir.path, branch));

  if (!branchDirectory.existsSync()) {
    throw Exception('Could not get version from SDK that is not installed');
  }
  return await _gitGetVersion(branchDirectory.path);
}

Future<String> _gitGetVersion(String path) async {
  var result = await runGit(['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: path);

  if (result.stdout.trim() == 'HEAD') {
    result =
        await runGit(['tag', '--points-at', 'HEAD'], workingDirectory: path);
  }

  if (result.exitCode != 0) {
    throw Exception('Could not get version Info.');
  }

  final versionNumber = result.stdout.trim() as String;
  return versionNumber;
}

/// Lists all Flutter SDK Versions
Future<List<String>> flutterListAllSdks() async {
  final result = await runGit(['ls-remote', '--tags', '$kFlutterRepo']);

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

/// Removes a Version of Flutter SDK
void flutterSdkRemove(String version) {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  if (versionDir.existsSync()) {
    versionDir.deleteSync(recursive: true);
  }
}

/// Check if version is from git
bool isInstalledCorrectly(String version) {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  final gitDir = Directory(path.join(versionDir.path, '.github'));
  final flutterBin = Directory(path.join(versionDir.path, 'bin'));
  // Check if version directory exists
  if (!versionDir.existsSync()) return false;

  // Check if version directory is from git
  if (!gitDir.existsSync() || !flutterBin.existsSync()) {
    print('$version exists but was not setup correctly. Doing cleanup...');
    flutterSdkRemove(version);
    return false;
  }

  return true;
}

/// Lists Installed Flutter SDK Version
List<String> flutterListInstalledSdks() {
  try {
    // Returns empty array if directory does not exist
    if (!kVersionsDir.existsSync()) {
      return [];
    }

    final versions = kVersionsDir.listSync().toList();

    var installedVersions = <String>[];
    for (var version in versions) {
      if (FileSystemEntity.typeSync(version.path) ==
          FileSystemEntityType.directory) {
        installedVersions.add(path.basename(version.path));
      }
    }

    installedVersions.sort();
    return installedVersions;
  } on Exception {
    throw Exception('Could not list installed sdks');
  }
}

void setAsGlobalVersion(String version) {
  final versionDir = Directory(path.join(kVersionsDir.path, version));
  createLink(kDefaultFlutterLink, versionDir);

  Print.success('The global Flutter version is now $version');
  Print.success(
      'Make sure sure to add $kDefaultFlutterPath to your PATH environment variable');
}
