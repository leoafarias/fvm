import 'dart:async';

import 'package:fvm/src/utils/helpers.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../models/valid_version_model.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterTools {
  /// Disables tracking for Flutter SDK
  static Future<void> disableTracking(CacheVersion version) async {
    await flutterCmd(version, ['config', '--no-analytics']);
  }

  /// Upgrades a cached channel
  static Future<void> upgradeChannel(CacheVersion version) async {
    if (version.isChannel) {
      await flutterCmd(version, ['upgrade']);
    } else {
      throw Exception('Can only upgrade Flutter Channels');
    }
  }

  /// Runs triggers sdk setup/install
  static Future<void> setupSdk(CacheVersion version) async {
    try {
      await flutterCmd(version, ['--version']);
    } on Exception catch (err) {
      logger.trace(err.toString());
      throw const FvmInternalError('Could not finish setting up Flutter sdk');
    }
  }

  /// Returns a [ValidVersion] from [name]
  /// Returns the latest release version
  /// for a channel if [forceRelease] is true
  static Future<ValidVersion> inferValidVersion(
    String name, {
    bool forceRelease = false,
  }) async {
    assert(name != null);
    final releases = await fetchFlutterReleases();
    // Not case sensitve
    name = name.toLowerCase();
    final prefixedVersion = 'v$name';

    // Check if its master or a valid release version
    if (name == 'master' || releases.containsVersion(name)) {
      // Return if its flutter channel
      return ValidVersion(name);
    }

    // Is a valid prefixed release
    if (releases.containsVersion(prefixedVersion)) {
      return ValidVersion(prefixedVersion);
    }

    /// Check that is a channel with a release
    if (checkIsReleaseChannel(name)) {
      final channel = releases.channels[name];

      /// Return channel version instead of channel if flag is there
      final version = forceRelease ? channel.version : name;
      // Returns valid version
      return ValidVersion(version);
    }

    // Throws exception if is not in any above condition
    throw FvmUsageException(
      '$name is not a valid Flutter channel or release',
    );
  }
}
