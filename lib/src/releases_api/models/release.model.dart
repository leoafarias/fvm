import 'package:fvm/src/releases_api/models/channels.model.dart';
import 'package:fvm/src/releases_api/releases_client.dart';

class Release {
  Release({
    this.hash,
    this.channel,
    this.version,
    this.releaseDate,
    this.archive,
    this.archiveUrl,
    this.sha256,
    this.activeChannel,
  });

  final String hash;
  final Channel channel;
  final String version;
  final DateTime releaseDate;
  final String archive;
  final String archiveUrl;
  final String sha256;
  final bool activeChannel;

  factory Release.fromMap(Map<String, dynamic> json) => Release(
        hash: json['hash'] as String,
        channel: channelValues.map[json['channel']],
        version: json['version'] as String,
        releaseDate: DateTime.parse(json['release_date'] as String),
        archive: json['archive'] as String,
        archiveUrl: '$storageUrl/flutter_infra/releases/${json['archive']}',
        sha256: json['sha256'] as String,
        activeChannel: json['activeChannel'] as bool ?? false,
      );

  Map<String, dynamic> toMap() => {
        'hash': hash,
        'channel': channelValues.reverse[channel],
        'version': version,
        'release_date': releaseDate.toIso8601String(),
        'archive': archive,
        'archiveUrl': archiveUrl,
        'sha256': sha256,
        'activeChannel': activeChannel,
      };
}
