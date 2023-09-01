import 'dart:async';

import 'package:fvm/constants.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/process_manager.dart';

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
  static Future<void> runUpgrade(CacheVersion version) async {
    if (version.isChannel) {
      await runFlutter(version, ['upgrade']);
    } else {
      throw FvmUsageException('Can only upgrade Flutter Channels');
    }
  }

  /// Runs triggers sdk setup/install
  static Future<int> runSetup(CacheVersion version) async {
    logger
      ..info('Setting up Flutter SDK: ${version.name}')
      ..spacer;

    return runFlutter(version, ['doctor', '--version']);
  }

  /// Runs pub get
  static Future<void> runPubGet(CacheVersion version) async {
    await ProcessRunner.run(
      'flutter pub get',
      environment: updateEnvironmentVariables(version, ctx.environment),
      listen: false,
    );
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

  static Future<ValidVersion?> getValidVersion(String version) async {
    if (kFlutterChannels.contains(version)) {
      return ValidVersion(version);
    }

    if (checkIsGitHash(version)) {
      return ValidVersion(version);
    }

    final releases = await fetchFlutterReleases();

    final isVersion = releases.containsVersion(version);

    if (isVersion) {
      return ValidVersion(version);
    }

    return null;
  }
}
