import '../releases_client.dart';
import 'channels.model.dart';

/// Release Model
class Release {
  /// Constructor
  Release({
    this.hash,
    this.channel,
    this.version,
    this.releaseDate,
    this.archive,
    this.sha256,
    this.activeChannel,
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

  /// Creates a release from a map of values
  factory Release.fromMap(Map<String, dynamic> map) => Release(
        hash: map['hash'] as String,
        channel: channelFromName(map['channel'] as String),
        version: map['version'] as String,
        releaseDate: DateTime.parse(map['release_date'] as String),
        archive: map['archive'] as String,
        sha256: map['sha256'] as String,
        activeChannel: map['activeChannel'] as bool ?? false,
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
      };

  /// Returns channel name of the release
  String get channelName {
    return channel.toString().split('.').last;
  }

  /// Returns archive url of the release
  String get archiveUrl {
    return '$storageUrl/flutter_infra/releases/$archive';
  }
}
