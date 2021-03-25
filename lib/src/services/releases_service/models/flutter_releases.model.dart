import 'dart:convert';

import 'package:fvm/src/flutter_tools/flutter_tools.dart';
import 'package:fvm/src/services/releases_service/current_release_parser.dart';
import 'package:fvm/src/services/releases_service/models/channels.model.dart';
import 'package:fvm/src/services/releases_service/models/release.model.dart';

FlutterReleases releasesFromMap(String str) =>
    FlutterReleases.fromMap(jsonDecode(str) as Map<String, dynamic>);

class FlutterReleases {
  FlutterReleases({
    this.baseUrl,
    this.channels,
    this.releases,
  });

  final String baseUrl;
  final Channels channels;
  final List<Release> releases;

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
    releases.forEach((v) {
      // If version is a release return
      if (v.version == version) contains = true;
    });
    return contains;
  }

  Map<String, dynamic> toMap() => {
        'base_url': baseUrl,
        'channels': channels.toMap(),
        'releases': List<dynamic>.from(releases.map((x) => x.toMap())),
      };
}
