import 'dart:io';
import 'package:fvm/src/releases_api/models/flutter_releases.model.dart';
import 'package:path/path.dart' as path;

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

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

/// Allows to download a release
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
