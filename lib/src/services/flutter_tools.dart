import 'dart:async';
import 'dart:io';

import '../../constants.dart';
import '../../exceptions.dart';

import '../../fvm.dart';
import '../models/valid_version_model.dart';

import 'releases_service/releases_client.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
import 'package:path/path.dart';

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

  /// Gets Flutter SDK version from CacheVersion
  static Future<String> getSdkVersion(CacheVersion version) async {
    if (!await version.dir.exists()) {
      throw Exception('Could not get version from SDK that is not installed');
    }

    final versionFile = File(join(version.dir.path, 'version'));
    if (await versionFile.exists()) {
      return await versionFile.readAsString();
    } else {
      return null;
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
