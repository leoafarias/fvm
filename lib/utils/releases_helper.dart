import 'dart:convert';
import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:http/http.dart' as http;

/// Gets platform specific release URL
String getReleasesUrl({String platform}) {
  platform ??= Platform.operatingSystem;
  return 'https://storage.googleapis.com/flutter_infra/releases/releases_$platform.json';
}

Releases cacheReleasesRes;

/// Gets Flutter SDK Releases
Future<Releases> getReleases() async {
  try {
    // If has been cached return
    if (cacheReleasesRes != null) return cacheReleasesRes;
    final response = await http.get(getReleasesUrl());
    cacheReleasesRes = releasesFromMap(response.body);
    return cacheReleasesRes;
  } on Exception {
    throw ExceptionCouldNotFetchReleases();
  }
}

// Returns Version based on semver
Future<Release> getVersion(String version) async {
  final releases = await getReleases();
  return releases.getVersion(version);
}

Map<String, dynamic> parseCurrentReleases(Map<String, dynamic> json) {
  final currentRelease = json['current_release'] as Map<String, dynamic>;
  final releases = json['releases'] as List<dynamic>;
  // Hashes of current releases
  final hashMap = currentRelease.map((key, value) => MapEntry(value, key));

  // Filter out channel/currentRelease versions
  releases.forEach((r) {
    // Check if release hash is in hashmap
    final channel = hashMap[r['hash']];
    if (channel != null) currentRelease[channel] = r;
  });

  return currentRelease;
}

Releases releasesFromMap(String str) =>
    Releases.fromMap(jsonDecode(str) as Map<String, dynamic>);

class Releases {
  Releases({
    this.baseUrl,
    this.channels,
    this.versions,
  });

  final String baseUrl;
  final Channels channels;
  final List<Release> versions;

  factory Releases.fromMap(Map<String, dynamic> json) {
    final currentRelease = parseCurrentReleases(json);
    return Releases(
      baseUrl: json['base_url'] as String,
      channels: Channels.fromMap(currentRelease),
      versions: List<Release>.from(json['releases']
              .map((x) => Release.fromMap(x as Map<String, dynamic>))
          as Iterable<dynamic>),
    );
  }

  /// Retrieves version information
  Release getVersion(String version) {
    return versions.firstWhere((v) => v.version == version);
  }

  /// Checks if version is a release
  bool containsVersion(String version) {
    var contains = false;
    versions.forEach((v) {
      // If version is a release return
      if (v.version == version) contains = true;
    });
    return contains;
  }

  Map<String, dynamic> toMap() => {
        'base_url': baseUrl,
        'channels': channels.toMap(),
        'versions': List<dynamic>.from(versions.map((x) => x.toMap())),
      };
}

class Channels {
  Channels({
    this.beta,
    this.dev,
    this.stable,
  });

  final Release beta;
  final Release dev;
  final Release stable;

  factory Channels.fromMap(Map<String, dynamic> json) => Channels(
        beta: Release.fromMap(json['beta'] as Map<String, dynamic>),
        dev: Release.fromMap(json['dev'] as Map<String, dynamic>),
        stable: Release.fromMap(json['stable'] as Map<String, dynamic>),
      );

  Release operator [](String key) {
    if (key == 'beta') return beta;
    if (key == 'dev') return dev;
    if (key == 'stable') return stable;
    return null;
  }

  Map<String, dynamic> toMap() => {
        'beta': beta,
        'dev': dev,
        'stable': stable,
      };

  Map<String, dynamic> toHashMap() => {
        '${beta.hash}': 'beta',
        '${dev.hash}': 'dev',
        '${stable.hash}': 'stable',
      };
}

class Release {
  Release({
    this.hash,
    this.channel,
    this.version,
    this.releaseDate,
    this.archive,
    this.sha256,
  });

  final String hash;
  final Channel channel;
  final String version;
  final DateTime releaseDate;
  final String archive;
  final String sha256;

  factory Release.fromMap(Map<String, dynamic> json) => Release(
        hash: json['hash'] as String,
        channel: channelValues.map[json['channel']],
        version: json['version'] as String,
        releaseDate: DateTime.parse(json['release_date'] as String),
        archive: json['archive'] as String,
        sha256: json['sha256'] as String,
      );

  Map<String, dynamic> toMap() => {
        'hash': hash,
        'channel': channelValues.reverse[channel],
        'version': version,
        'release_date': releaseDate.toIso8601String(),
        'archive': archive,
        'sha256': sha256,
      };
}

enum Channel { STABLE, DEV, BETA }

final channelValues = EnumValues(
    {'beta': Channel.BETA, 'dev': Channel.DEV, 'stable': Channel.STABLE});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap ??= map.map((k, v) => MapEntry(v, k));

    return reverseMap;
  }
}
