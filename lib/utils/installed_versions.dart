import 'package:fvm/constants.dart';
import 'package:fvm/flutter/flutter_helpers.dart';
import 'package:fvm/flutter/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';

import 'package:path/path.dart' as path;

class InstalledVersion {
  final String name;
  final String sdkVersion;
  final bool isChannel;
  InstalledVersion({
    this.name,
    this.sdkVersion,
    this.isChannel,
  });
}

/// Returns true it's a valid installed version
Future<bool> isInstalledVersion(String version) async {
  final installedVersions = await getInstalledVersions();
  final versionsNames = installedVersions.map((v) => v.name);
  return versionsNames.contains(version);
}

/// Lists Installed Flutter SDK Version
Future<List<InstalledVersion>> getInstalledVersions() async {
  try {
    // Returns empty array if directory does not exist
    if (!kVersionsDir.existsSync()) {
      return [];
    }

    final versions = kVersionsDir.listSync().toList();

    var installedVersions = <InstalledVersion>[];
    for (var version in versions) {
      if (isDirectory(version.path)) {
        final name = path.basename(version.path);
        final sdkVersion = await getFlutterSdkVersion(name);

        installedVersions.add(InstalledVersion(
          name: name,
          sdkVersion: sdkVersion,
          isChannel: isFlutterChannel(name),
        ));
      }
    }

    installedVersions.sort((a, b) => a.name.compareTo(b.name));
    return installedVersions;
  } on Exception {
    throw Exception('Could not list installed versions');
  }
}
