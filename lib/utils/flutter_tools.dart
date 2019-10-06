import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:path/path.dart';
import 'package:io/io.dart';

/// Runs a process
Future<void> processRunner(String cmd, List<String> args,
    {String workingDirectory}) async {
  final manager = ProcessManager();
  var spawn =
      await manager.spawn(cmd, args, workingDirectory: workingDirectory);
  await spawn.exitCode;
  await sharedStdIn.terminate();
}

/// Clones Flutter SDK from Channel
Future<void> flutterChannelClone(String branch) async {
  final branchDirectory = Directory('${kVersionsDir.path}/$branch');
  await flutterSdkRemove(branch);
  await branchDirectory.create(recursive: true);

  await Process.run('git', ['clone', '-b', branch, kFlutterRepo, '.'],
      workingDirectory: branchDirectory.path);
}

/// Clones Flutter SDK from Version Number
Future<void> flutterVersionClone(String version) async {
  final versionDirectory = Directory('${kVersionsDir.path}/$version');
  await flutterSdkRemove(version);
  await versionDirectory.create(recursive: true);

  await Process.run('git', ['clone', '-b', 'v$version', kFlutterRepo, '.'],
      workingDirectory: versionDirectory.path);
}

/// Clones Flutter SDK
Future<void> flutterSdkInfo(String branch) async {
  final branchDirectory = Directory('${kVersionsDir.path}/$branch');

  var result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: branchDirectory.path);

  if (result.stdout.trim() == 'HEAD') {
    result = await Process.run('git', ['tag', '--points-at', 'HEAD'],
        workingDirectory: branchDirectory.path);
  }

  final versionNumber = result.stdout.trim();
  return versionNumber;
}

/// Lists all Flutter SDK Versions
Future<List<String>> listSdkVersions() async {
  final result =
      await Process.run('git', ['ls-remote', '--tags', '$kFlutterRepo']);
// refs/tags/
  List<String> tags = result.stdout.split('\n');

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
Future<void> flutterSdkRemove(String branch) async {
  final branchDirectory = Directory('${kVersionsDir.path}/$branch');
  if (await branchDirectory.exists()) {
    await branchDirectory.delete(recursive: true);
  }
}

/// Lists Installed Flutter SDK Version
Future<List<String>> flutterListInstalledSdks() async {
  final versions = kVersionsDir.listSync();
  final installedVersions = versions.map((version) async {
    return basename(version.path);
  });

  final results = await Future.wait(installedVersions);

  return results;
}
