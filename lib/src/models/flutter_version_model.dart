import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import '../utils/compare_semver.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';

part 'flutter_version_model.mapper.dart';

@MappableEnum()
enum VersionType {
  release,
  channel,
  unknownRef,
  custom,
}

/// Enum of a channel
@MappableEnum()
enum FlutterChannel {
  stable,
  dev,
  beta,
  master;

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
    final parts = version.split('@');

    if (parts.length == 2) {
      final channel = parts.last;
      if (isFlutterChannel(channel)) {
        return FlutterVersion.release(
          version,
          releaseChannel: FlutterChannel.fromValue(channel),
        );
      }

      throw FormatException('Invalid version format');
    }

    final forkParts = version.split('/');

    if (forkParts.length == 2) {
      final alias = forkParts.first;
      final version = forkParts.last;

      final forkedVersion = FlutterVersion.parse(version);

      return forkedVersion.copyWith(fork: alias);
    }

    if (version.startsWith('custom_')) {
      return FlutterVersion.custom(version);
    }

    // Check if its commit
    // Check if its channel
    if (isFlutterChannel(version)) {
      return FlutterVersion.channel(version);
    }

    try {
      if (version.startsWith('v')) {
        version = version.replaceFirst('v', '');
      }

      // ignore: avoid-unused-instances
      Version.parse(version);

      return FlutterVersion.release(version);
    } catch (e) {
      return FlutterVersion.gitReference(version);
    }
  }

  String get version => name.split('@').first;

  bool get isMain => name == 'master' || name == 'main';

  bool get isChannel => type == VersionType.channel;

  bool get isRelease => type == VersionType.release;

  bool get isUnknownRef => type == VersionType.unknownRef;

  bool get isCustom => type == VersionType.custom;

  bool get fromFork => fork != null;

  /// Provides a human readable version identifier for UI presentation.
  ///
  /// The return value varies based on the type of version:
  /// * 'Channel: [name]' for channel versions.
  /// * 'Commit: [name]' for commit versions.
  /// * 'SDK Version: [name]' for standard versions.
  String get printFriendlyName {
    // Uppercase

    if (isChannel) return 'Channel: ${name.capitalize}';

    if (isUnknownRef) return 'Commit : $name';

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

// A small class for each fork's definition:
@MappableClass(ignoreNull: true)
class FlutterFork with FlutterForkMappable {
  final String name;
  final String url;

  const FlutterFork({required this.name, required this.url});
}
