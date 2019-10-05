import 'dart:io';
import 'package:fvm/constants.dart';

/// Clones Flutter SDK
Future<void> flutterSdkClone(String branch) async {
  final branchDirectory = Directory('${kVersionsDir.path}/$branch');
  if (await branchDirectory.exists()) {
    await branchDirectory.delete(recursive: true);
  }
  await branchDirectory.create(recursive: true);

  final result = await Process.run(
      'git', ['clone', '-b', branch, kFlutterRepo, '.'],
      workingDirectory: branchDirectory.path);
  return result;
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
