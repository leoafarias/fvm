import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/helpers.dart';
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

// TODO: force all branch and versions to be lowercase

/// Clones Flutter SDK from Channel
/// Returns true if comes from exists or false if its new fetch.
Future<void> flutterChannelClone(String channel) async {
  final channelDirectory = Directory('${kVersionsDir.path}/$channel');

  if (!isValidFlutterChannel(channel)) {
    throw ExceptionNotValidChannel('"$channel" is not a valid channel');
  }

// TODO: make sure the version is a valid version in the folder before cloning
  if (await channelDirectory.exists()) {
    return;
  }

  await channelDirectory.create(recursive: true);

  var result = await Process.run(
      'git', ['clone', '-b', channel, kFlutterRepo, '.'],
      workingDirectory: channelDirectory.path);

  if (result.exitCode != 0) {
    throw ExceptionCouldNotClone("Could not clone $channel");
  }
}

/// Clones Flutter SDK from Version Number
/// Returns exists:true if comes from cache or false if its new fetch.
Future<void> flutterVersionClone(String version) async {
  final versionDirectory = Directory('${kVersionsDir.path}/$version');

  if (!await isValidFlutterVersion(version)) {
    throw ExceptionNotValidVersion('"$version" is not a valid version');
  }

  if (await versionDirectory.exists()) {
    return;
  }

  await versionDirectory.create(recursive: true);

  var result = await Process.run(
      'git', ['clone', '-b', 'v$version', kFlutterRepo, '.'],
      workingDirectory: versionDirectory.path);

  if (result.exitCode != 0) {
    throw ExceptionCouldNotClone("Could not clone $version");
  }
}

/// Gets Flutter version from project
// Future<String> flutterGetProjectVersion() async {
//   final target = await kLocalFlutterLink.target();
//   print(target);
//   return await _gitGetVersion(target);
// }

/// Gets SDK Version
Future<String> flutterSdkVersion(String branch) async {
  final branchDirectory = Directory('${kVersionsDir.path}/$branch');
  return await _gitGetVersion(branchDirectory.path);
}

Future<String> _gitGetVersion(String path) async {
  var result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: path);

  if (result.stdout.trim() == 'HEAD') {
    result = await Process.run('git', ['tag', '--points-at', 'HEAD'],
        workingDirectory: path);
  }

  if (result.exitCode != 0) {
    throw Exception('Could not get version Info.');
  }

  final versionNumber = result.stdout.trim();
  return versionNumber;
}

/// Lists all Flutter SDK Versions
Future<List<String>> flutterListAllSdks() async {
  final result =
      await Process.run('git', ['ls-remote', '--tags', '$kFlutterRepo']);

  if (result.exitCode != 0) {
    throw Exception('Could not fetch list of available Flutter SDKs');
  }

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
Future<void> flutterSdkRemove(String version) async {
  final versionDir = Directory('${kVersionsDir.path}/$version');
  if (await versionDir.exists()) {
    await versionDir.delete(recursive: true);
  }
}

/// Lists Installed Flutter SDK Version
Future<List<String>> flutterListInstalledSdks() async {
  if (!await kVersionsDir.exists()) {
    return [];
  }
  final versions = kVersionsDir.listSync();

  final installedVersions = versions
      .where((version) =>
          FileSystemEntity.typeSync(version.path) ==
          FileSystemEntityType.directory)
      .map((version) async {
    return basename(version.path);
  });

  final results = await Future.wait(installedVersions);
  results.sort();
  return results;
}

/// Links Flutter Dir to existsd SDK
Future<void> linkProjectFlutterDir(String version) async {
  final versionBin = Directory('${kVersionsDir.path}/$version/bin/flutter');
  await linkDir(kLocalFlutterLink, versionBin);
}
