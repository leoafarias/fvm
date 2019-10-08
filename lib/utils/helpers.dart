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
Future<void> linkDir(
  Link source,
  FileSystemEntity target,
) async {
  try {
    if (await source.exists()) {
      await source.delete();
    }
    await source.create(target.path);
  } on Exception catch (err) {
    throw Exception(['Could not link ${target.path}:', err]);
  }
}
