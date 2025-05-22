import 'package:dart_mappable/dart_mappable.dart';

import '../utils/compare_semver.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/git_utils.dart';
import '../utils/helpers.dart';

part 'flutter_version_model.mapper.dart';

@MappableEnum()
enum VersionType {
  release,
  channel,
  commit,
  custom,
}

/// Provides a structured way to handle Flutter SDK versions.
///
/// This class allows for specific use-cases and categorizations of Flutter SDK
/// versions such as distinguishing if a version is a release, a channel, a git
/// commit or a custom version. Moreover, it allows for fetching a print-friendly
/// name to be used in user interfaces.
@MappableClass()
class FlutterVersion with FlutterVersionMappable {
  /// Represents the underlying string value of the Flutter version.
  final String name;

  /// Has a channel which the version is part of
  final String? releaseFromChannel;

  final VersionType type;

  static final fromMap = FlutterVersionMapper.fromMap;
  static final fromJson = FlutterVersionMapper.fromJson;

  /// Constructs a [FlutterVersion] instance initialized with a given [name].
  const FlutterVersion(
    this.name, {
    this.releaseFromChannel,
    required this.type,
  });

  const FlutterVersion.commit(this.name)
      : releaseFromChannel = null,
        type = VersionType.commit;

  const FlutterVersion.channel(this.name)
      : releaseFromChannel = null,
        type = VersionType.channel;

  const FlutterVersion.custom(this.name)
      : type = VersionType.custom,
        releaseFromChannel = null;

  const FlutterVersion.release(this.name, {this.releaseFromChannel})
      : type = VersionType.release;

  factory FlutterVersion.parse(String version) {
    // Check if its custom.
    if (version.startsWith('custom_')) {
      return FlutterVersion.custom(version);
    }

    final parts = version.split('@');
    if (parts.length == 2) {
      final channel = parts.last;
      if (kFlutterChannels.contains(channel)) {
        return FlutterVersion.release(version, releaseFromChannel: channel);
      }

      throw FormatException('Invalid version format');
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

  bool get isChannel => type == VersionType.channel;

  bool get isRelease => type == VersionType.release;

  bool get isCommit => type == VersionType.commit;

  bool get isCustom => type == VersionType.custom;

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

  @override
  String toString() => name;
}
