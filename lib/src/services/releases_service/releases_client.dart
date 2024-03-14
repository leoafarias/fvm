import 'dart:io';

import '../../utils/exceptions.dart';
import '../../utils/http.dart';
import '../logger_service.dart';
import 'models/channels_model.dart';
import 'models/flutter_releases_model.dart';
import 'models/version_model.dart';

final _envVars = Platform.environment;
final _defaultStorageUrl = 'https://storage.googleapis.com';

/// Returns Google's storage url for releases
String get storageUrl {
  /// Uses environment variable if configured.
  return _envVars['FLUTTER_STORAGE_BASE_URL'] ?? _defaultStorageUrl;
}

/// Gets platform specific release URL for a [platform]
String _getFlutterReleasesUrl(String platform) =>
    '$storageUrl/flutter_infra_release/releases/releases_$platform.json';

/// Returns a CDN cached version of the releaes per platform
String _getGithubCacheUrl(String platform) {
  return _envVars['FLUTTER_RELEASES_URL'] ??
      'https://raw.githubusercontent.com/leoafarias/fvm/main/releases_$platform.json';
}

class FlutterReleasesClient {
  static FlutterReleasesResponse? _cacheReleasesRes;
  const FlutterReleasesClient._();

  /// Gets Flutter SDK Releases
  /// Can use memory [cache] if it exists.
  static Future<FlutterReleasesResponse> getReleases({
    bool cache = true,
    String? platform,
  }) async {
    platform ??= Platform.operatingSystem;
    final releasesUrl = _getGithubCacheUrl(platform);
    try {
      // If has been cached return
      if (_cacheReleasesRes != null && cache) {
        return await Future.value(_cacheReleasesRes);
      }

      final response = await fetch(releasesUrl);

      return _cacheReleasesRes = FlutterReleasesResponse.fromJson(response);
    } catch (err) {
      logger.detail(err.toString());
      try {
        return _cacheReleasesRes = await getReleasesFromGoogle(platform);
      } catch (_, stackTrace) {
        Error.throwWithStackTrace(
          AppException(
            'Failed to retrieve the Flutter SDK from: ${_getFlutterReleasesUrl(platform)}\n'
            'Fvm will use the value set on '
            'env FLUTTER_STORAGE_BASE_URL to check versions\n'
            'if you are located in China, please see this page: https://flutter.dev/community/china',
          ),
          stackTrace,
        );
      }
    }
  }

  static Future<FlutterReleasesResponse> getReleasesFromGoogle(
    String platform,
  ) async {
    final response = await fetch(_getFlutterReleasesUrl(platform));

    return FlutterReleasesResponse.fromJson(response);
  }

  // Function to filter releases based on channel
  static Future<List<FlutterSdkRelease>> getReleasesFilteredByChannel(
    String channelName,
  ) async {
    if (!FlutterChannel.values.any((element) => element.name == channelName)) {
      throw Exception('Invalid channel name: $channelName');
    }

    final response = await getReleases();

    return response.versions
        .where((release) => release.channel.name == channelName)
        .toList();
  }

  static Future<bool> isVersionValid(String version) async {
    final releases = await getReleases();

    return releases.containsVersion(version);
  }

  /// Returns a [FlutterSdkRelease]  channel [version]
  static Future<FlutterSdkRelease> getLatestReleaseOfChannel(
    FlutterChannel channel,
  ) async {
    final releases = await getReleases();

    return releases.getLatestChannelRelease(channel.name);
  }

  /// Returns a [FlutterChannel] from a [version]
  static Future<FlutterSdkRelease?> getReleaseFromVersion(
    String version,
  ) async {
    final releases = await getReleases();

    return releases.getReleaseFromVersion(version);
  }
}
