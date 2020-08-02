import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/flutter/flutter_releases.dart';
import 'package:path/path.dart' as path;

/// Returns true it's a valid installed version
bool isVersionInstalled(String version) {
  return (getInstalledVersions()).contains(version);
}

/// Lists Installed Flutter SDK Version
//TODO replace this with getInstalledReleases
List<String> getInstalledVersions() {
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
    throw Exception('Could not list installed versions');
  }
}

Future<List<InstalledRelease>> getInstalledReleases() async {
  final flutterReleases = await fetchFlutterReleases();
  final versions = getInstalledVersions();
  final releases = versions.map(flutterReleases.getVersion);
  final filteredReleases = releases.where((release) => release != null);

  return filteredReleases.map((release) => InstalledRelease(release)).toList();
}

// TODO: Refactor versions to use installed releases
class InstalledRelease extends Release {
  // Check if it's a channel release
  // and not pinned version
  final bool isChannel;
  final Directory installedDir;
  InstalledRelease(Release release)
      : installedDir = Directory(path.join(kVersionsDir.path, release.version)),
        isChannel = release.activeChannel,
        super(
          hash: release.hash,
          channel: release.channel,
          version: release.version,
          releaseDate: release.releaseDate,
          archive: release.archive,
          sha256: release.sha256,
          activeChannel: release.activeChannel,
        );
}
