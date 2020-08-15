import 'package:fvm/constants.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/local_versions/local_version.model.dart';
import 'package:fvm/src/local_versions/local_versions_tools.dart';

import 'package:fvm/src/utils/helpers.dart';

import 'package:path/path.dart' as path;

class LocalVersionRepo {
  /// Returns true it's a valid installed version
  static Future<bool> isInstalled(String version) async {
    final installedVersions = await getAll();
    final versionsNames = installedVersions.map((v) => v.name);
    return versionsNames.contains(version);
  }

  /// Lists Installed Flutter SDK Version
  static Future<List<LocalFlutterVersion>> getAll() async {
    try {
      // Returns empty array if directory does not exist
      if (!kVersionsDir.existsSync()) {
        return [];
      }

      final versions = kVersionsDir.listSync().toList();

      var installedVersions = <LocalFlutterVersion>[];
      for (var version in versions) {
        if (isDirectory(version.path)) {
          final name = path.basename(version.path);
          final sdkVersion = await getFlutterSdkVersion(name);

          installedVersions.add(LocalFlutterVersion(
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
}
