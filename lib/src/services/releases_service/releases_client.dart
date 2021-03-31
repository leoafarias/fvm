import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../exceptions.dart';
import 'models/flutter_releases.model.dart';

const _storageDefaultBase = 'https://storage.googleapis.com';

/// Returns Google's storage url for releases
String get storageUrl {
  final envVars = Platform.environment;

  /// Uses environment variable if configured.
  return envVars['FLUTTER_STORAGE_BASE_URL'] ?? _storageDefaultBase;
}

/// Gets platform specific release URL for a [platform]
/// Defaults to the platform's OS.
/// returns [url] for the list of the platform releases.
String getReleasesUrl({String platform}) {
  platform ??= Platform.operatingSystem;
  return '$storageUrl/flutter_infra/releases/releases_$platform.json';
}

FlutterReleases _cacheReleasesRes;

/// Gets Flutter SDK Releases
/// Can use memory [cache] if it exists.
Future<FlutterReleases> fetchFlutterReleases({bool cache = true}) async {
  try {
    // If has been cached return
    if (_cacheReleasesRes != null && cache) return _cacheReleasesRes;
    final response = await http.get(getReleasesUrl());
    _cacheReleasesRes = releasesFromMap(response.body);
    return _cacheReleasesRes;
  } on Exception {
    throw FvmInternalError(
      '''Failed to retrieve the Flutter SDK from: ${getReleasesUrl()}\n Fvm will use the value set on env FLUTTER_STORAGE_BASE_URL to check versions.\nif you're located in China, please see this page:
https://flutter.dev/community/china''',
    );
  }
}
