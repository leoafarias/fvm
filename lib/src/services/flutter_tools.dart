import 'dart:async';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../models/valid_version_model.dart';
import '../utils/commands.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import '../utils/matchers.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterTools {
  FlutterTools._();

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

  /// Sets Flutter config
  // ignore: avoid_positional_boolean_parameters
  static Future<void> setFluterConfig(Map<String, bool> config) async {
    final analytics = config['analytics'] ? '--analytics' : '--no-analytics';
    final web = config['web'] ? '--enable-web' : '--no-enable-web';
    final macos = config['macos']
        ? '--enable-macos-desktop'
        : '--no-enable-macos-desktop';
    final windows = config['windows']
        ? '--enable-windows-desktop'
        : '--no-enable-windows-desktop';
    final linux = config['linux']
        ? '--enable-linux-desktop'
        : '--no-enable-linux-desktop';

    await flutterCmdSimple([
      'config',
      analytics,
      macos,
      windows,
      linux,
      web,
    ]);
  }

  /// Returns configured Flutter settings
  static Future<Map<String, bool>> getFlutterConfig() async {
    try {
      final result = await flutterCmdSimple(['config']);
      final analytics = containsIgnoringWhitespace(
        result,
        'Analytics reporting is currently enabled',
      );
      final macos = containsIgnoringWhitespace(
        result,
        'enable-macos-desktop: true',
      );
      final windows = containsIgnoringWhitespace(
        result,
        'enable-windows-desktop: true',
      );
      final linux = containsIgnoringWhitespace(
        result,
        'enable-linux-desktop: true',
      );
      final web = containsIgnoringWhitespace(
        result,
        'enable-web: true',
      );

      return {
        'analytics': analytics,
        'macos': macos,
        'windows': windows,
        'linux': linux,
        'web': web,
      };
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
