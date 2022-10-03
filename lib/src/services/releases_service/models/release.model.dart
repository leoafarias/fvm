import '../releases_client.dart';
import 'channels.model.dart';

/// Release Model
class Release {
  /// Constructor
  Release({
    required this.hash,
    required this.channel,
    required this.version,
    required this.releaseDate,
    required this.archive,
    required this.sha256,
    required this.dartSdkArch,
    required this.dartSdkVersion,
    this.activeChannel = false,
  });

  /// Release hash
  final String hash;

  /// Release channel
  final Channel channel;

  /// Release version
  final String version;

  /// Release date
  final DateTime releaseDate;

  /// Release archive name
  final String archive;

  /// Release sha256 hash
  final String sha256;

  /// Is release active in a channel
  final bool activeChannel;

  /// Version of the Dart SDK
  final String? dartSdkVersion;

  /// Dart SDK architecture
  final String? dartSdkArch;

  /// Creates a release from a map of values
  factory Release.fromMap(Map<String, dynamic> map) => Release(
        hash: map['hash'] as String,
        channel: channelFromName(map['channel'] as String),
        version: map['version'] as String,
        releaseDate: DateTime.parse(map['release_date'] as String),
        dartSdkArch: map['dart_sdk_arch'] as String?,
        dartSdkVersion: map['dart_sdk_version'] as String?,
        archive: map['archive'] as String,
        sha256: map['sha256'] as String,
        activeChannel: map['activeChannel'] as bool? ?? false,
      );

  /// Turns Release model into a map of values
  Map<String, dynamic> toMap() => {
        'hash': hash,
        'channel': channel.name,
        'version': version,
        'release_date': releaseDate.toIso8601String(),
        'archive': archive,
        'sha256': sha256,
        'activeChannel': activeChannel,
        'dart_sdk_arch': dartSdkArch,
        'dart_sdk_version': dartSdkVersion,
      };

  /// Returns channel name of the release
  String get channelName {
    return channel.name;
  }

  /// Returns archive url of the release
  String get archiveUrl {
    return '$storageUrl/flutter_infra_release/releases/$archive';
  }
}
