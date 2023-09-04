import 'dart:async';

import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:path/path.dart';
import 'package:process_run/which.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../models/flutter_version_model.dart';
import '../utils/commands.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterTools {
  FlutterTools._();

  /// Upgrades a cached channel
  static Future<void> runUpgrade(CacheFlutterVersion version) async {
    if (version.isChannel) {
      await runFlutter(version, ['upgrade']);
    } else {
      throw FvmUsageException('Can only upgrade Flutter Channels');
    }
  }

  /// Runs triggers sdk setup/install
  static Future<int> runSetup(CacheFlutterVersion version) async {
    return runFlutter(version, ['doctor', '--version']);
  }

  /// Runs pub get
  static Future<void> runPubGet(CacheFlutterVersion version) async {
    await runFlutter(version, ['pub', 'get']);
  }

  static Future<FlutterVersion?> validateFlutterVersion(String version) async {
    final flutterVersion = FlutterVersion(version);
    if (flutterVersion.isChannel || flutterVersion.isCommit) {
      return flutterVersion;
    }

    final releases = await FlutterReleasesClient.get();

    final isVersion = releases.containsVersion(version);

    if (!isVersion) {
      throw FvmUsageException(
        '$version is not a valid Flutter version',
      );
    }

    return flutterVersion;
  }

  /// Gets the global configuration
  static String? whichFlutter() {
    final currentFlutter = whichSync('flutter');
    if (currentFlutter == null) return null;
    return dirname(currentFlutter);
  }
}
