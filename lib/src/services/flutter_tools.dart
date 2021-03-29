import 'dart:async';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/valid_version_model.dart';

import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/commands.dart';
import 'package:fvm/src/utils/logger.dart';

class FlutterTools {
  /// Disables tracking for Flutter SDK
  static Future<void> disableTracking(CacheVersion version) async {
    await flutterCmd(version, ['config', '--no-analytics']);
  }

  /// Returns true if it's a valid Flutter channel
  static bool isChannel(String channel) {
    return kFlutterChannels.contains(channel);
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

  /// Tries to infer a correct flutter version number
  static Future<ValidVersion> inferVersion(String version) async {
    assert(version != null);
    final releases = await fetchFlutterReleases();
    // Not case sensitve
    version = version.toLowerCase();

    // Return if its flutter channel
    if (isChannel(version) || releases.containsVersion(version)) {
      return ValidVersion(version);
    }
    // Try prefixing the version
    final prefixedVersion = 'v$version';
    if (releases.containsVersion(prefixedVersion)) {
      return ValidVersion(prefixedVersion);
    } else {
      /// Fallback if cannot verify version
      throw FvmUsageException(
        '$version is not a valid Flutter channel or release',
      );
    }
  }
}
