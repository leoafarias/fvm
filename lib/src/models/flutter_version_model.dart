import 'package:fvm/src/utils/compare_semver.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:fvm/src/utils/git_utils.dart';

import '../../constants.dart';
import '../utils/helpers.dart';

/// Provides a structured way to handle Flutter SDK versions.
///
/// This class allows for specific use-cases and categorizations of Flutter SDK
/// versions such as distinguishing if a version is a release, a channel, a git
/// commit or a custom version. Moreover, it allows for fetching a print-friendly
/// name to be used in user interfaces.
class FlutterVersion {
  /// Represents the underlying string value of the Flutter version.
  final String name;

  /// Has a cannel which the version is part of
  final String? releaseFromChannel;

  /// Identifies if the version is an official Flutter SDK release.
  final bool isRelease;

  /// Identifies if the version represents a specific git commit.
  final bool isCommit;

  /// Identifies if the version belongs to a Flutter channel.
  final bool isChannel;

  /// Identifies if the version represents a custom Flutter SDK version.
  final bool isCustom;

  /// Constructs a [FlutterVersion] instance initialized with a given [name].
  const FlutterVersion(
    this.name, {
    this.releaseFromChannel,
    required this.isRelease,
    required this.isCommit,
    required this.isChannel,
    required this.isCustom,
  });

  const FlutterVersion.commit(this.name)
      : isRelease = false,
        releaseFromChannel = null,
        isCommit = true,
        isChannel = false,
        isCustom = false;

  const FlutterVersion.channel(this.name)
      : isRelease = false,
        releaseFromChannel = null,
        isCommit = false,
        isChannel = true,
        isCustom = false;

  const FlutterVersion.custom(this.name)
      : isRelease = false,
        releaseFromChannel = null,
        isCommit = false,
        isChannel = false,
        isCustom = true;

  const FlutterVersion.release(this.name, {this.releaseFromChannel})
      : isRelease = true,
        isCommit = false,
        isChannel = false,
        isCustom = false;

  factory FlutterVersion.parse(String version) {
    final parts = version.split('@');

    if (parts.length == 2) {
      final channel = parts.last;
      if (kFlutterChannels.contains(channel)) {
        return FlutterVersion.release(version, releaseFromChannel: channel);
      }

      throw FormatException('Invalid version format');
    }
    // Check if its custom.
    if (version.startsWith('custom_')) {
      return FlutterVersion.custom(version);
    }

    // Check if its commit
    if (isGitCommit(version)) {
      return FlutterVersion.commit(version);
    }

    // Check if its channel
    if (kFlutterChannels.contains(version)) {
      return FlutterVersion.channel(version);
    }

    // The it must be a release
    return FlutterVersion.release(version);
  }

  String get version => name.split('@').first;

  bool get isMaster => name == 'master';

  /// Provides a human readable version identifier for UI presentation.
  ///
  /// The return value varies based on the type of version:
  /// * 'Channel: [name]' for channel versions.
  /// * 'Commit: [name]' for commit versions.
  /// * 'SDK Version: [name]' for standard versions.
  String get printFriendlyName {
    // Uppercase

    if (isChannel) return 'Channel: ${name.capitalize}';

    if (isCommit) return 'Commit : $name';

    return 'SDK Version : $name';
  }

  /// Compares CacheVersion with [other]
  int compareTo(FlutterVersion other) {
    final otherVersion = assignVersionWeight(other.version);
    final versionWeight = assignVersionWeight(version);
    return compareSemver(versionWeight, otherVersion);
  }

  /// Overrides toString method for better debugging and logging.
  ///
  /// Instead of the instance identifier, the version [name] is returned.
  @override
  String toString() => name;
}
