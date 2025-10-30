import 'package:dart_mappable/dart_mappable.dart';

import '../../../models/flutter_version_model.dart';
import '../releases_client.dart';

part 'version_model.mapper.dart';

/// Release Model
@MappableClass()
class FlutterSdkRelease with FlutterSdkReleaseMappable {
  /// Release hash
  final String hash;

  /// Release channel
  final FlutterChannel channel;

  /// Release version
  final String version;

  /// Release date
  @MappableField(key: 'release_date')
  final DateTime releaseDate;

  /// Release archive name
  final String archive;

  /// Release sha256 hash
  final String sha256;

  /// Is release active in a channel
  @MappableField(key: 'active_channel')
  final bool activeChannel;

  /// Version of the Dart SDK
  @MappableField(key: 'dart_sdk_version')
  final String? dartSdkVersion;

  /// Dart SDK architecture
  @MappableField(key: 'dart_sdk_arch')
  final String? dartSdkArch;

  static final fromMap = FlutterSdkReleaseMapper.fromMap;
  static final fromJson = FlutterSdkReleaseMapper.fromJson;

  const FlutterSdkRelease({
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

  /// Returns channel name of the release
  @MappableField()
  String get channelName => channel.name;

  /// Returns archive url of the release
  @MappableField()
  String get archiveUrl {
    return '${FlutterReleaseClient.storageUrl}/flutter_infra_release/releases/$archive';
  }
}

/// Release channels model
@MappableClass()
class Channels with ChannelsMappable {
  /// Beta channel release
  final FlutterSdkRelease beta;

  /// Dev channel release
  final FlutterSdkRelease dev;

  /// Stable channel release
  final FlutterSdkRelease stable;

  static final fromMap = ChannelsMapper.fromMap;
  static final fromJson = ChannelsMapper.fromJson;

  /// Channel model constructor
  const Channels({required this.beta, required this.dev, required this.stable});

  /// Returns a list of all releases
  List<FlutterSdkRelease> get toList => [dev, beta, stable];

  /// Returns channel by name
  FlutterSdkRelease operator [](String channelName) {
    if (channelName == 'beta') return beta;
    if (channelName == 'dev') return dev;
    if (channelName == 'stable') return stable;
    throw Exception('Not a valid channel $channelName');
  }

  /// Returns a hash map of the channels model
  Map<String, dynamic> toHashMap() => {
        beta.hash: 'beta',
        dev.hash: 'dev',
        stable.hash: 'stable',
      };
}
