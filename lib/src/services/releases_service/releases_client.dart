import 'dart:io';

import 'package:fvm/src/services/releases_service/models/channels.model.dart';
import 'package:fvm/src/services/releases_service/models/release.model.dart';
import 'package:fvm/src/utils/http.dart';

import '../../../exceptions.dart';
import '../../utils/logger.dart';
import 'models/flutter_releases.model.dart';

final _envVars = Platform.environment;
final _storageUrl = 'https://storage.googleapis.com';

/// Returns Google's storage url for releases
String get storageUrl {
  /// Uses environment variable if configured.
  return _envVars['FLUTTER_STORAGE_BASE_URL'] ?? _storageUrl;
}

/// Gets platform specific release URL for a [platform]
String getFlutterReleasesUrl(String platform) =>
    '$storageUrl/flutter_infra_release/releases/releases_$platform.json';

/// Returns a CDN cached version of the releaes per platform
String getReleasesUrl(String platform) {
  return _envVars['FLUTTER_RELEASES_URL'] ??
      'https://raw.githubusercontent.com/fluttertools/fvm/main/releases_$platform.json';
}

class FlutterReleasesClient {
  FlutterReleasesClient._();

  static FlutterReleases? _cacheReleasesRes;

  /// Gets Flutter SDK Releases
  /// Can use memory [cache] if it exists.
  static Future<FlutterReleases> get({
    bool cache = true,
    String? platform,
  }) async {
    platform ??= Platform.operatingSystem;
    final releasesUrl = getReleasesUrl(platform);
    try {
      // If has been cached return
      if (_cacheReleasesRes != null && cache) {
        return Future.value(_cacheReleasesRes);
      }
      final response = await fetch(releasesUrl);

      _cacheReleasesRes = FlutterReleases.fromJson(response);
      return Future.value(_cacheReleasesRes);
    } on Exception catch (err) {
      logger.detail(err.toString());
      return _getFromFlutterUrl(platform);
    }
  }

  static Future<FlutterReleases> _getFromFlutterUrl(
    String platform,
  ) async {
    try {
      final response = await fetch(getFlutterReleasesUrl(platform));
      _cacheReleasesRes = FlutterReleases.fromJson(response);
      return Future.value(_cacheReleasesRes);
    } on Exception {
      throw AppTracedException(
        'Failed to retrieve the Flutter SDK from: ${getFlutterReleasesUrl(platform)}\n'
        'Fvm will use the value set on '
        'env FLUTTER_STORAGE_BASE_URL to check versions\n'
        'if you are located in China, please see this page: https://flutter.dev/community/china',
      );
    }
  }

  /// Returns a [Release]  channel [version]
  static Future<Release> getLatestReleaseOfChannel(
    FlutterChannel channel,
  ) async {
    final releases = await get();
    return releases.getLatestChannelRelease(channel.name);
  }

  /// Returns a [FlutterChannel] from a [version]
  static Future<Release?> getReleaseFromVersion(String version) async {
    final releases = await get();
    return releases.getReleaseFromVersion(version);
  }
}
