import 'dart:convert';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

import '../../../models/flutter_version_model.dart';
import 'version_model.dart';

part 'flutter_releases_model.mapper.dart';

const _flutterChannels = ['stable', 'beta', 'dev'];

/// Flutter Releases
@MappableClass()
class FlutterReleasesResponse with FlutterReleasesResponseMappable {
  /// Base url for Flutter   /// Channels in Flutter releases
  final String baseUrl;

  /// Channels in Flutter releases
  final Channels channels;

  /// LIst of all releases
  final List<FlutterSdkRelease> versions;

  /// Version release map
  final Map<String, FlutterSdkRelease> _versionReleaseMap;

  const FlutterReleasesResponse({
    required this.baseUrl,
    required this.channels,
    required this.versions,
    required Map<String, FlutterSdkRelease> versionReleaseMap,
  }) : _versionReleaseMap = versionReleaseMap;

  /// Creates a FlutterRelease from a [json] string
  factory FlutterReleasesResponse.fromJson(String json) {
    return FlutterReleasesResponse.fromMap(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// Create FlutterRelease from a map of values
  factory FlutterReleasesResponse.fromMap(Map<String, dynamic> json) {
    return _parseCurrentReleases(json);
  }

  /// Returns a [FlutterVersion] release from channel [version]
  FlutterSdkRelease latestChannelRelease(String channel) {
    if (!_flutterChannels.contains(channel)) {
      throw Exception('Can only infer release on valid channel');
    }

    return channels[channel];
  }

  /// Retrieves version information
  FlutterSdkRelease? fromVersion(String version) {
    return _versionReleaseMap[version];
  }

  /// Checks if version is a release
  bool containsVersion(String version) {
    return _versionReleaseMap.containsKey(version);
  }
}

/// Goes through the current_release payload.
/// Finds the proper release base on the hash
/// Assigns to the current_release
FlutterReleasesResponse _parseCurrentReleases(Map<String, dynamic> map) {
  final baseUrl = map['base_url'] as String;
  final currentRelease = map['current_release'] as Map<String, dynamic>;
  // ignore: avoid-dynamic
  final releasesJson = map['releases'] as List<dynamic>;

  final systemArch = 'x64';

  final releasesList = <FlutterSdkRelease>[];
  final versionReleaseMap = <String, FlutterSdkRelease>{};
  final hashReleaseMap = <String, FlutterSdkRelease>{};

  // Filter out channel/currentRelease versions
  // Could be more efficient
  for (var release in releasesJson) {
    for (var current in currentRelease.entries) {
      final channelName = current.key;
      final releaseHash = current.value;
      if (releaseHash == release['hash'] && channelName == release['channel']) {
        release['active_channel'] = true;
      }
    }

    if (Platform.isMacOS) {
      // Filter out releases based on architecture
      // Remove if architecture is not compatible
      final arch = release['dart_sdk_arch'];

      if (arch != systemArch && arch != null) {
        continue;
      }
    }

    final releaseItem = FlutterSdkRelease.fromMap(
      release as Map<String, dynamic>,
    );

    /// Add to releases
    releasesList.add(releaseItem);
    versionReleaseMap[releaseItem.version] = releaseItem;
    hashReleaseMap[releaseItem.hash] = releaseItem;
  }

  final dev = currentRelease['dev'] as String?;
  final beta = currentRelease['beta'] as String?;
  final stable = currentRelease['stable'] as String?;

  final devRelease = hashReleaseMap[dev];
  final betaRelease = hashReleaseMap[beta];
  final stableRelease = hashReleaseMap[stable];

  final channels = Channels(
    beta: betaRelease!,
    dev: devRelease!,
    stable: stableRelease!,
  );

  return FlutterReleasesResponse(
    baseUrl: baseUrl,
    channels: channels,
    versions: releasesList,
    versionReleaseMap: versionReleaseMap,
  );
}
