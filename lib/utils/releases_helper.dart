import 'dart:convert';
import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:http/http.dart' as http;

/// Gets platform specific release URL
String getReleasesUrl({String platform}) {
  platform ??= Platform.operatingSystem;
  return 'https://storage.googleapis.com/flutter_infra/releases/releases_$platform.json';
}

/// Fetches Flutter SDK Releases
Future<FlutterReleases> fetchReleases() async {
  try {
    final response = await http.get(getReleasesUrl());
    return jsonDecode(response.body) as FlutterReleases;
  } on Exception {
    throw ExceptionCouldNotFetchReleases();
  }
}

FlutterReleases flutterReleasesFromMap(String str) =>
    FlutterReleases.fromMap(json.decode(str) as Map<String, dynamic>);

String flutterReleasesToMap(FlutterReleases data) => json.encode(data.toMap());

class FlutterReleases {
  FlutterReleases({
    this.baseUrl,
    this.currentRelease,
    this.releases,
  });

  final String baseUrl;
  final CurrentRelease currentRelease;
  final List<Release> releases;

  factory FlutterReleases.fromMap(Map<String, dynamic> json) => FlutterReleases(
        baseUrl: json['base_url'] as String,
        currentRelease: CurrentRelease.fromMap(json['current_release']),
        releases:
            List<Release>.from(json['releases'].map((x) => Release.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        'base_url': baseUrl,
        'current_release': currentRelease.toMap(),
        'releases': List<dynamic>.from(releases.map((x) => x.toMap())),
      };
}

class CurrentRelease {
  CurrentRelease({
    this.beta,
    this.dev,
    this.stable,
  });

  final String beta;
  final String dev;
  final String stable;

  factory CurrentRelease.fromMap(dynamic json) => CurrentRelease(
        beta: json['beta'] as String,
        dev: json['dev'] as String,
        stable: json['stable'] as String,
      );

  Map<String, dynamic> toMap() => {
        'beta': beta,
        'dev': dev,
        'stable': stable,
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
        hash: json['hash'],
        channel: channelValues.map[json['channel']],
        version: json['version'],
        releaseDate: DateTime.parse(json['release_date']),
        archive: json['archive'],
        sha256: json['sha256'],
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
