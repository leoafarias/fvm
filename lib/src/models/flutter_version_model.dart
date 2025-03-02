import 'package:dart_mappable/dart_mappable.dart';
import 'package:pub_semver/pub_semver.dart';

import '../utils/compare_semver.dart';
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

@MappableClass()
abstract class FlutterVersion with FlutterVersionMappable {
  final String name;
  final VersionType type;
  FlutterVersion(this.name, {required this.type});

  static parse(String version) {
    final parts = version.split('@');

    if (parts.length == 2) {
      final channel = parts.last;
      if (isFlutterChannel(channel)) {
        return ReleaseVersion(version, fromChannel: channel);
      }

      throw FormatException('Invalid version format');
    }
    // Check if its custom.
    if (version.startsWith('custom_')) {
      return CustomVersion(version);
    }

    // Check if its commit
    if (isGitCommit(version)) {
      return CommitVersion(version);
    }

    // Check if its channel
    if (isFlutterChannel(version)) {
      return ChannelVersion(version);
    }

    // The it must be a release
    return ReleaseVersion(version);
  }

  bool get isMaster => name == 'master';
  bool get isChannel => type == VersionType.channel;
  bool get isRelease => type == VersionType.release;
  bool get isCommit => type == VersionType.commit;
  bool get isCustom => type == VersionType.custom;

  /// Provides a human readable version identifier.
  String get friendlyName;

  String get versionWeight;

  String get branch;

  /// Compares this version with [other] using semantic version weights.
  int compareTo(FlutterVersion other) {
    return compareSemver(versionWeight, other.versionWeight);
  }
}

@MappableClass()
class ReleaseVersion extends FlutterVersion with ReleaseVersionMappable {
  final String? fromChannel;
  ReleaseVersion(super.name, {this.fromChannel})
      : super(type: VersionType.release);

  bool get hasChannel => fromChannel != null;

  String get release => name.split('@').first;

  /// Returns the git reference for the release
  ///
  /// For release this is the tag
  @override
  String get branch => fromChannel ?? release;

  @override
  String get friendlyName =>
      'SDK Version: $release${fromChannel != null ? ' (from channel: $fromChannel)' : ''}';

  @override
  String get versionWeight {
    try {
      // Checking to throw an issue if it cannot parse
      // ignore: avoid-unused-instances
      Version.parse(release);
    } on Exception {
      return '0.0.0';
    }

    return name;
  }
}

@MappableClass()
class ChannelVersion extends FlutterVersion with ChannelVersionMappable {
  ChannelVersion(String name) : super(name, type: VersionType.channel);

  @override
  String get friendlyName => 'Channel: ${name.capitalize}';

  @override
  String get branch => name;
  @override
  String get versionWeight {
    switch (name) {
      case 'master':
        return '400.0.0';
      case 'stable':
        return '300.0.0';
      case 'beta':
        return '200.0.0';
      case 'dev':
        return '100.0.0';
      default:
        return '0.0.0';
    }
  }
}

@MappableClass()
class CommitVersion extends FlutterVersion with CommitVersionMappable {
  CommitVersion(String name) : super(name, type: VersionType.commit);

  /// Returns the git reference for the release
  ///
  /// For commit this is the commit hash
  @override
  String get branch => name;

  @override
  String get friendlyName => 'Commit: $name';

  @override
  String get versionWeight => '500.0';
}

@MappableClass()
class CustomVersion extends FlutterVersion with CustomVersionMappable {
  CustomVersion(String name) : super(name, type: VersionType.custom);

  @override
  String get branch => throw UnimplementedError();

  @override
  String get friendlyName => 'Custom Version: $name';

  @override
  String get versionWeight {
    final versionName = name.replaceFirst('custom_', '');

    try {
      // Ignore
      // ignore: avoid-unused-instances
      Version.parse(versionName);
    } on Exception {
      return '500.0';
    }

    return versionName;
  }
}
