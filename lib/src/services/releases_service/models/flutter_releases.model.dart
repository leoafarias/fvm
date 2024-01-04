import 'dart:convert';
import 'dart:io';

import 'release.model.dart';

const _flutterChannels = ['stable', 'beta', 'dev', 'master'];

/// Flutter Releases
class Releases {
  /// Base url for Flutter   /// Channels in Flutter releases
  final String baseUrl;

  /// Channels in Flutter releases
  final Channels channels;

  /// LIst of all releases
  final List<Release> releases;

  /// Version release map
  final Map<String, Release> versionReleaseMap;

  /// Hash release map
  final Map<String, Release> hashReleaseMap;

  const

  /// Constructor
  Releases({
    required this.baseUrl,
    required this.channels,
    required this.releases,
    required this.hashReleaseMap,
    required this.versionReleaseMap,
  });

  /// Creates a FlutterRelease from a [json] string
  factory Releases.fromJson(String json) {
    return Releases.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Create FlutterRelease from a map of values
  factory Releases.fromMap(Map<String, dynamic> json) {
    return _parseCurrentReleases(json);
  }

  /// Returns a [FlutterVersion] release from channel [version]
  Release getLatestChannelRelease(String channelName) {
    if (!_flutterChannels.contains(channelName)) {
      throw Exception('Can only infer release on valid channel');
    }

    final channelRelease = channels[channelName];

    // Returns valid version
    return channelRelease;
  }

  /// Retrieves version information
  Release? getReleaseFromVersion(String version) {
    return versionReleaseMap[version];
  }

  /// Checks if version is a release
  bool containsVersion(String version) {
    return versionReleaseMap.containsKey(version);
  }

  /// Return map of model
  Map<String, dynamic> toMap() => {
        'base_url': baseUrl,
        'channels': channels.toMap(),
        'releases': List<dynamic>.from(releases.map((x) => x.toMap())),
      };
}

/// Goes through the current_release payload.
/// Finds the proper release base on the hash
/// Assings to the current_release
Releases _parseCurrentReleases(Map<String, dynamic> map) {
  final baseUrl = map['base_url'] as String;
  final currentRelease = map['current_release'] as Map<String, dynamic>;
  final releasesJson = map['releases'] as List<dynamic>;

  final systemArch = 'x64';

  final releasesList = <Release>[];
  final versionReleaseMap = <String, Release>{};
  final hashReleaseMap = <String, Release>{};

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

    final releaseItem = Release.fromMap(release as Map<String, dynamic>);

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
    dev: devRelease!,
    beta: betaRelease!,
    stable: stableRelease!,
  );

  return Releases(
    baseUrl: baseUrl,
    channels: channels,
    releases: releasesList,
    versionReleaseMap: versionReleaseMap,
    hashReleaseMap: hashReleaseMap,
  );
}
