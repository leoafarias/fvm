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
  final FlutterChannel channel;

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
        channel: FlutterChannel.fromName(map['channel'] as String),
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
  String get channelName => channel.name;

  /// Returns archive url of the release
  String get archiveUrl {
    return '$storageUrl/flutter_infra_release/releases/$archive';
  }
}

/// Release channels model
class ReleaseChannels {
  /// Channel model contructor
  ReleaseChannels({
    required this.beta,
    required this.dev,
    required this.stable,
  });

  /// Beta channel release
  final Release beta;

  /// Dev channel release
  final Release dev;

  /// Stable channel release
  final Release stable;

  /// Create a Channels model from a map
  factory ReleaseChannels.fromMap(Map<String, dynamic> map) => ReleaseChannels(
        beta: Release.fromMap(map['beta'] as Map<String, dynamic>),
        dev: Release.fromMap(map['dev'] as Map<String, dynamic>),
        stable: Release.fromMap(
          map['stable'] as Map<String, dynamic>,
        ),
      );

  /// Returns channel by name
  Release operator [](String channelName) {
    if (channelName == 'beta') return beta;
    if (channelName == 'dev') return dev;
    if (channelName == 'stable') return stable;
    throw Exception('Not a valid channle $channelName');
  }

  /// Return a map of values from the Channels model
  Map<String, dynamic> toMap() => {
        'beta': beta,
        'dev': dev,
        'stable': stable,
      };

  /// Returns a hash map of the channels model
  Map<String, dynamic> toHashMap() => {
        beta.hash: 'beta',
        dev.hash: 'dev',
        stable.hash: 'stable',
      };

  /// Returns a list of all releases
  List<Release> get toList => [dev, beta, stable];
}
