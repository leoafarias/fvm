import 'dart:convert';

import '../current_release_parser.dart';
import 'channels.model.dart';
import 'release.model.dart';

const _flutterChannels = [
  'stable',
  'beta',
  'dev',
  'master',
];

/// Flutter Releases
class FlutterReleases {
  /// Constructor
  FlutterReleases({
    required this.baseUrl,
    required this.channels,
    required this.releases,
  });

  /// Base url for Flutter   /// Channels in Flutter releases

  final String baseUrl;

  /// Channels in Flutter releases
  final ReleaseChannels channels;

  /// LIst of all releases
  final List<Release> releases;

  /// Creates a FlutterRelease from a [json] string
  factory FlutterReleases.fromJson(String json) {
    return FlutterReleases.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Create FlutterRelease from a map of values
  factory FlutterReleases.fromMap(Map<String, dynamic> json) {
    final parsedResults = parseCurrentReleases(json);
    return FlutterReleases(
      baseUrl: json['base_url'] as String,
      channels: ReleaseChannels.fromMap(parsedResults.channels),
      releases: List<Release>.from(
        parsedResults.releases.map(
          (release) => Release.fromMap(release as Map<String, dynamic>),
        ),
      ),
    );
  }

  /// Returns a [FlutterVersion] release from channel [version]
  Release getLatestChannelRelease(
    String channelName,
  ) {
    if (!_flutterChannels.contains(channelName)) {
      throw Exception('Can only infer release on valid channel');
    }

    final channelRelease = channels[channelName];

    // Returns valid version
    return channelRelease;
  }

  /// Retrieves version information
  Release? getReleaseFromVersion(String version) {
    if (_flutterChannels.contains(version)) {
      return channels[version];
    }

    int findReleaseIdx(FlutterChannel channel) {
      return releases.indexWhere(
        (v) => v.version == version && v.channel == channel,
      );
    }

    // Versions can be in multiple versions
    // Prioritize by order of maturity
    // TODO: could be optimized and avoid multiple loops
    final stableIndex = findReleaseIdx(FlutterChannel.stable);
    final betaIndex = findReleaseIdx(FlutterChannel.beta);
    final devIndex = findReleaseIdx(FlutterChannel.dev);

    Release? release;
    if (stableIndex >= 0) {
      release = releases[stableIndex];
    } else if (betaIndex >= 0) {
      release = releases[betaIndex];
    } else if (devIndex >= 0) {
      release = releases[devIndex];
    }

    return release;
  }

  /// Checks if version is a release
  bool containsVersion(String version) {
    var contains = false;
    for (var release in releases) {
      if (release.version == version) {
        contains = true;
      }
    }

    return contains;
  }

  /// Return map of model
  Map<String, dynamic> toMap() => {
        'base_url': baseUrl,
        'channels': channels.toMap(),
        'releases': List<dynamic>.from(releases.map((x) => x.toMap())),
      };
}
