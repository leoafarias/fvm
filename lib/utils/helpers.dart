import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:path/path.dart';

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

/// Check if it is the current version.
bool isCurrentVersion(String version) {
  final link = projectFlutterLink();
  if (link != null) {
    return Uri.parse(File(link.targetSync()).parent.parent.path)
            .pathSegments
            .last ==
        version;
  }
  return false;
}

/// The fvm link of the current working directory.
Link projectFlutterLink() {
  Link link;
  var dir = kWorkingDirectory;
  while (true) {
    link = Link('${dir.path}/fvm');
    // print("finding: ${link.path}");
    // print("${link.path} exists:  ${link.existsSync()}");
    if (link.existsSync()) {
      return link;
    }
    dir = dir.parent;
    if (rootPrefix == dir.path) {
      return null;
    }
  }
}
