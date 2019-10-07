import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';

/// Returns true if it's a valid Flutter version number
Future<bool> isValidFlutterVersion(String version) async {
  return (await flutterListAllSdks()).contains('v$version');
}

/// Returns true if it's a valid Flutter channel
bool isValidFlutterChannel(String channel) {
  return kFlutterChannels.contains(channel);
}

/// Returns true it's a valid installed version
Future<bool> isValidFlutterInstall(String version) async {
  return (await flutterListInstalledSdks()).contains(version);
}

/// Moves assets from theme directory into brand-app
Future<void> linkDir(FileSystemEntity target, FileSystemEntity source,
    {bool copy = false}) async {
  await _unlinkDir(target);
  try {
    await Link(target.path).create(source.path);
  } on Exception catch (err) {
    throw Exception(['Could not create symlink: ', err]);
  }
}

void _unlinkDir(FileSystemEntity fsEntity) {
  if (fsEntity.existsSync()) {
    fsEntity.deleteSync(recursive: true);
  }
}
