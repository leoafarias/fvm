import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:fvm/src/services/releases_service/models/flutter_releases.model.dart';
import 'package:fvm/exceptions.dart';

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
    throw InternalError(
        '''Failed to retrieve the Flutter SDK from: ${getReleasesUrl()}\n Fvm will use the value set on env FLUTTER_STORAGE_BASE_URL to check versions.\nif you're located in China, please see this page:
  https://flutter.dev/community/china''');
  }
}
