import 'dart:async';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../models/valid_version_model.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterTools {
  FlutterTools._();

  /// Upgrades a cached channel
  static Future<void> upgrade(CacheVersion version) async {
    if (version.isChannel) {
      await runFlutter(version, ['upgrade']);
    } else {
      throw Exception('Can only upgrade Flutter Channels');
    }
  }

  /// Runs triggers sdk setup/install
  static Future<void> setupSdk(CacheVersion version) async {
    Logger.info('Setting up Flutter SDK: ${version.name}');
    Logger.spacer();
    try {
      await runFlutter(version, ['doctor', '--version']);
    } on Exception catch (err) {
      logger.trace(err.toString());
      throw const FvmInternalError(
        'Could not finish setting up Flutter sdk. Use `--verbose` for more details',
      );
    }
  }

  /// Runs pub get
  static Future<void> pubGet(CacheVersion version) async {
    try {
      await runFlutter(version, ['pub', 'get']);
    } on Exception catch (err) {
      logger.trace(err.toString());
      logger.stderr(
        'Could not resolve dependencies. Use `--verbose` for more details',
      );
      return;
    }
  }

  /// Returns a [ValidVersion] release from channel [version]
  static Future<ValidVersion> inferReleaseFromChannel(
    ValidVersion version,
  ) async {
    if (!version.isChannel) {
      throw Exception('Can only infer release on valid channel');
    }

    final releases = await fetchFlutterReleases();

    final channel = releases.channels[version.name];

    // Returns valid version
    return ValidVersion(channel.version);
  }
}
