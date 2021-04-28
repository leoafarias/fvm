import 'dart:convert';

import '../../../utils/helpers.dart';
import '../current_release_parser.dart';
import 'channels.model.dart';
import 'release.model.dart';

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
  final Channels channels;

  /// LIst of all releases
  final List<Release> releases;

  /// Creates a FlutterRelease from a [json] string
  factory FlutterReleases.fromJson(String json) {
    return FlutterReleases.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Create FlutterRelease from a map of values
  factory FlutterReleases.fromMap(Map<String, dynamic> json) {
    final currentRelease = parseCurrentReleases(json);
    return FlutterReleases(
      baseUrl: json['base_url'] as String,
      channels: Channels.fromMap(currentRelease),
      releases: List<Release>.from(
        json['releases'].map(
          (release) => Release.fromMap(release as Map<String, dynamic>),
        ) as Iterable<dynamic>,
      ),
    );
  }

  /// Retrieves version information
  Release? getReleaseFromVersion(String version) {
    if (checkIsChannel(version)) {
      return channels[version];
    }

    final foundIdx = releases.indexWhere((v) => v.version == version);
    if (foundIdx < 0) {
      return null;
    } else {
      releases[foundIdx];
    }
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
