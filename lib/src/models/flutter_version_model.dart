import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import '../utils/compare_semver.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';

part 'flutter_version_model.mapper.dart';

@MappableEnum()
enum VersionType { release, channel, unknownRef, custom }

/// Enum of a channel
@MappableEnum()
enum FlutterChannel {
  stable,
  dev,
  beta,
  master,
  main;

  const FlutterChannel();

  static final fromValue = FlutterChannelMapper.fromValue;
}

/// Provides a structured way to handle Flutter SDK versions.
///
/// This class allows for specific use-cases and categorizations of Flutter SDK
/// versions such as distinguishing if a version is a release, a channel, a git
/// commit or a custom version. Moreover, it allows for fetching a print-friendly
/// name to be used in user interfaces.
@MappableClass(ignoreNull: true)
class FlutterVersion with FlutterVersionMappable {
  /// Represents the underlying string value of the Flutter version.
  final String name;

  /// Has a channel which the version is part of
  final FlutterChannel? releaseChannel;

  final VersionType type;

  final String? fork;

  static final fromMap = FlutterVersionMapper.fromMap;
  static final fromJson = FlutterVersionMapper.fromJson;

  /// Constructs a [FlutterVersion] instance initialized with a given [name].
  @protected
  const FlutterVersion(
    this.name, {
    this.releaseChannel,
    required this.type,
    this.fork,
  });

  FlutterVersion.gitReference(this.name, {this.fork})
      : releaseChannel = null,
        type = VersionType.unknownRef;

  FlutterVersion.channel(this.name, {this.fork})
      : releaseChannel = null,
        type = VersionType.channel;

  const FlutterVersion.release(this.name, {this.releaseChannel, this.fork})
      : type = VersionType.release;

  const FlutterVersion.custom(this.name)
      : releaseChannel = null,
        fork = null,
        type = VersionType.custom;

  factory FlutterVersion.parse(String version) {
    // Match pattern: [fork/]version[@channel]
    final pattern = RegExp(
      r'^(?:(?<fork>[^/]+)/)?(?<version>[^@]+)(?:@(?<channel>\w+))?$',
    );
    final match = pattern.firstMatch(version);

    if (match == null) {
      throw FormatException('Invalid version format: $version');
    }

    // Extract components
    final forkName = match.namedGroup('fork');
    final versionPart = match.namedGroup('version')!;
    final channelPart = match.namedGroup('channel');

    // Handle custom versions
    if (versionPart.startsWith('custom_')) {
      if (forkName != null || channelPart != null) {
        throw FormatException(
          'Custom versions cannot have fork or channel specifications',
        );
      }

      return FlutterVersion.custom(versionPart);
    }

    // Handle channel versions
    if (isFlutterChannel(versionPart)) {
      return FlutterVersion.channel(versionPart, fork: forkName);
    }

    // Handle release versions with channel
    if (channelPart != null) {
      if (!isFlutterChannel(channelPart)) {
        throw FormatException('Invalid channel: $channelPart');
      }

      final nameToUse = '$versionPart@$channelPart';

      return FlutterVersion.release(
        nameToUse,
        releaseChannel: FlutterChannel.fromValue(channelPart),
        fork: forkName,
      );
    }

    // Try to parse as semantic version
    try {
      // Create a version to check for validation only
      String checkVersion = versionPart;
      if (versionPart.startsWith('v')) {
        // Strip 'v' only for validation check
        checkVersion = versionPart.substring(1);
      }

      // Validate format - Version.parse throws FormatException on invalid input
      // ignore: avoid-unused-instances
      Version.parse(checkVersion);

      // Use the original version string (preserving v if present)
      return FlutterVersion.release(versionPart, fork: forkName);
    } catch (e) {
      // Not a valid semver, treat as git reference
      return FlutterVersion.gitReference(versionPart, fork: forkName);
    }
  }

  String get version {
    // If this is a forked version, strip out the fork prefix first
    String versionName = name;
    if (fromFork && name.contains('/')) {
      versionName = name.split('/').last;
    }

    return versionName.split('@').first;
  }

  bool get isMain => name == 'master' || name == 'main';

  bool get isChannel => type == VersionType.channel;

  bool get isRelease => type == VersionType.release;

  bool get isUnknownRef => type == VersionType.unknownRef;

  bool get isCustom => type == VersionType.custom;

  bool get fromFork => fork != null;

  /// Returns the qualified name including fork prefix if present.
  ///
  /// For example: `fork/3.35.4` or `3.35.4` if no fork.
  String get nameWithAlias => fromFork ? '$fork/$name' : name;

  /// Provides a human readable version identifier for UI presentation.
  ///
  /// The return value varies based on the type of version:
  /// * 'Channel: [nameWithAlias]' for channel versions.
  /// * 'Commit: [nameWithAlias]' for commit versions.
  /// * 'SDK Version: [nameWithAlias]' for standard versions.
  String get printFriendlyName {
    // Uppercase

    if (isChannel) return 'Channel: ${nameWithAlias.capitalize}';

    if (isUnknownRef) return 'Commit : $nameWithAlias';

    return 'SDK Version : $nameWithAlias';
  }

  /// Compares CacheVersion with [other]
  int compareTo(FlutterVersion other) {
    final otherVersion = assignVersionWeight(other.version);
    final versionWeight = assignVersionWeight(version);

    return compareSemver(versionWeight, otherVersion);
  }

  @override
  String toString() => nameWithAlias;
}

// A small class for each fork's definition:
@MappableClass(ignoreNull: true)
class FlutterFork with FlutterForkMappable {
  final String name;
  final String url;

  const FlutterFork({required this.name, required this.url});

  // Improved toString for debugging
  @override
  String toString() => 'FlutterFork(name: $name, url: $url)';
}
