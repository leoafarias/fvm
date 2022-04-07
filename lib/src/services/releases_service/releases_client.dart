import 'dart:io';

import '../../../exceptions.dart';
import '../../utils/http.dart';
import '../../utils/logger.dart';
import 'models/flutter_releases.model.dart';

final _envVars = Platform.environment;
const _storageDefaultBase = 'https://storage.googleapis.com';

/// Returns Google's storage url for releases
String get storageUrl {
  /// Uses environment variable if configured.
  return _envVars['FLUTTER_STORAGE_BASE_URL'] ?? _storageDefaultBase;
}

/// Gets platform specific release URL for a [platform]
/// Defaults to the platform's OS.
/// returns [url] for the list of the platform releases.
String getGoogleReleaseUrl({String? platform}) {
  platform ??= Platform.operatingSystem;
  return '$storageUrl/flutter_infra_release/releases/releases_$platform.json';
}

/// Returns a CDN cached version of the releaes per platform
String getReleasesUrl({String? platform}) {
  platform ??= Platform.operatingSystem;
  return _envVars['FLUTTER_RELEASES_URL'] ??
      'https://raw.githubusercontent.com/fluttertools/fvm/main/releases_$platform.json';
}

FlutterReleases? _cacheReleasesRes;

/// Gets Flutter SDK Releases
/// Can use memory [cache] if it exists.

Future<FlutterReleases> fetchFlutterReleases({bool cache = true}) async {
  try {
    // If has been cached return
    if (_cacheReleasesRes != null && cache) {
      return Future.value(_cacheReleasesRes);
    }
    final response = await fetch(getReleasesUrl());
    _cacheReleasesRes = FlutterReleases.fromJson(response);
    return Future.value(_cacheReleasesRes);
  } on Exception catch (err) {
    logger.trace(err.toString());

    try {
      final response = await fetch(getGoogleReleaseUrl());
      _cacheReleasesRes = FlutterReleases.fromJson(response);
      return Future.value(_cacheReleasesRes);
    } on Exception {
      throw FvmInternalError(
        'Failed to retrieve the Flutter SDK from: ${getGoogleReleaseUrl()}\n'
        'Fvm will use the value set on '
        'env FLUTTER_STORAGE_BASE_URL to check versions\n'
        'if you are located in China, please see this page: https://flutter.dev/community/china',
      );
    }
  }
}
