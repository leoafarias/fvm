import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/flutter/flutter_helpers.dart';

import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

const STORAGE_BASE_URL = 'https://storage.googleapis.com';

String get storageUrl {
  final envVars = Platform.environment;
  return envVars['FLUTTER_STORAGE_BASE_URL'] ?? STORAGE_BASE_URL;
}

/// Gets platform specific release URL
String getReleasesUrl({String platform}) {
  platform ??= Platform.operatingSystem;
  return '$storageUrl/flutter_infra/releases/releases_$platform.json';
}

FlutterReleases cacheReleasesRes;

/// Gets Flutter SDK Releases

Future<FlutterReleases> fetchFlutterReleases({bool cache = true}) async {
  // TODO: Implement request caching
  try {
    // If has been cached return
    if (cacheReleasesRes != null && cache) return cacheReleasesRes;
    final response = await http.get(getReleasesUrl());
    cacheReleasesRes = releasesFromMap(response.body);
    return cacheReleasesRes;
  } on Exception {
    throw ExceptionCouldNotFetchReleases();
  }
}

Map<String, dynamic> parseCurrentReleases(Map<String, dynamic> json) {
  final currentRelease = json['current_release'] as Map<String, dynamic>;
  final releases = json['releases'] as List<dynamic>;
  // Hashes of current releases
  final hashMap = currentRelease.map((key, value) => MapEntry(value, key));

  // Filter out channel/currentRelease versions
  releases.forEach((r) {
    // Check if release hash is in channel hashmap
    final channel = hashMap[r['hash']];
    // If its not channel return
    if (channel == null) return;
    // Release is active channel
    r['activeChannel'] = true;
    // Assign to current release
    currentRelease[channel] = r;
  });

  return currentRelease;
}

/// ALlows to download a release
Future<void> downloadRelease(String version) async {
  final flutterReleases = await fetchFlutterReleases();
  final release = flutterReleases.getReleaseFromVersion(version);
  final savePath = path.join(kVersionsDir.path, version);
  final url = '$storageUrl/flutter_infra/releases/${release.archive}';

  await Dio().download(
    url,
    savePath,
    onReceiveProgress: (rcv, total) {
      // print(
      //     'received: ${rcv.toStringAsFixed(0)} out of total: ${total.toStringAsFixed(0)}');

      var progress = ((rcv / total) * 100).toStringAsFixed(0);
      print(progress);
      if (progress == '100') {
        print('DONE');
      }
    },
    deleteOnError: true,
  );
}

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
    if (isFlutterChannel(version)) {
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
    this.activeChannel,
  });

  final String hash;
  final Channel channel;
  final String version;
  final DateTime releaseDate;
  final String archive;
  final String sha256;
  final bool activeChannel;

  factory Release.fromMap(Map<String, dynamic> json) => Release(
        hash: json['hash'] as String,
        channel: channelValues.map[json['channel']],
        version: json['version'] as String,
        releaseDate: DateTime.parse(json['release_date'] as String),
        archive: json['archive'] as String,
        sha256: json['sha256'] as String,
        activeChannel: json['activeChannel'] as bool ?? false,
      );

  Map<String, dynamic> toMap() => {
        'hash': hash,
        'channel': channelValues.reverse[channel],
        'version': version,
        'release_date': releaseDate.toIso8601String(),
        'archive': archive,
        'sha256': sha256,
        'activeChannel': activeChannel,
      };
}

enum Channel { stable, dev, beta }

final channelValues = EnumValues(
    {'beta': Channel.beta, 'dev': Channel.dev, 'stable': Channel.stable});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap ??= map.map((k, v) => MapEntry(v, k));

    return reverseMap;
  }
}
