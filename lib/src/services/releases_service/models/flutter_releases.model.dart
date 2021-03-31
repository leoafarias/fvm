import 'dart:convert';

import '../../flutter_tools.dart';
import '../current_release_parser.dart';
import 'channels.model.dart';
import 'release.model.dart';

FlutterReleases releasesFromMap(String str) =>
    FlutterReleases.fromMap(jsonDecode(str) as Map<String, dynamic>);

/// Flutter Releases
class FlutterReleases {
  /// Constructor
  FlutterReleases({
    this.baseUrl,
    this.channels,
    this.releases,
  });

  /// Base url for Flutter   /// Channels in Flutter releases

  final String baseUrl;

  /// Channels in Flutter releases
  final Channels channels;

  /// LIst of all releases
  final List<Release> releases;

  /// Create FlutterReleaes from a map of values
  factory FlutterReleases.fromMap(Map<String, dynamic> json) {
    final currentRelease = parseCurrentReleases(json);
    return FlutterReleases(
      baseUrl: json['base_url'] as String,
      channels: Channels.fromMap(currentRelease),
      releases: List<Release>.from(json['releases'].map(
        (r) => Release.fromMap(r as Map<String, dynamic>),
      ) as Iterable<dynamic>),
    );
  }

  /// Retrieves version information
  Release getReleaseFromVersion(String version) {
    if (FlutterTools.isChannel(version)) {
      return channels[version];
    }

    return releases.firstWhere((v) => v.version == version, orElse: () => null);
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
