import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:path/path.dart' as path;
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
    logVerboseError(err);
    throw Exception('Sorry could not link ${target.path}');
  }
}

/// Check if it is the current version.
Future<bool> isCurrentVersion(String version) async {
  final link = await projectFlutterLink();
  if (link != null) {
    return Uri.file(File(await link.target()).parent.parent.path,
                windows: Platform.isWindows)
            .pathSegments
            .last ==
        version;
  }
  return false;
}

/// The fvm link of the current working directory.
/// [levels] how many levels you would like to go up to search for a version
Future<Link> projectFlutterLink([Directory dir, int levels = 20]) async {
  // If there are no levels exit
  if (levels == 0) {
    return null;
  }
  Link link;

  if (dir == null) {
    dir = kWorkingDirectory;
  }

  link = Link(path.join(dir.path, 'fvm'));

  if (await link.exists()) {
    return link;
  } else if (path.rootPrefix(link.path) == dir.path) {
    return null;
  }
  levels--;
  return await projectFlutterLink(dir, levels);
}
