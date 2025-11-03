import 'dart:io';

import '../../models/flutter_version_model.dart';
import '../../utils/exceptions.dart';
import '../../utils/http.dart';
import '../base_service.dart';
import 'models/flutter_releases_model.dart';
import 'models/version_model.dart';

class FlutterReleaseClient extends ContextualService {
  // Constants
  static const String _defaultStorageUrl = 'https://storage.googleapis.com';
  static const String _githubRawUrl =
      'https://raw.githubusercontent.com/leoafarias/fvm/main';

  // Instance-level cache instead of static
  FlutterReleasesResponse? _cachedReleases;

  FlutterReleaseClient(super.context);

  /// Gets platform-specific release URL
  String _getFlutterReleasesUrl(String platform) {
    return '$storageUrl/flutter_infra_release/releases/releases_$platform.json';
  }

  /// Returns a CDN cached version of the releases
  String _getGithubCacheUrl(String platform) {
    return Platform.environment['FLUTTER_RELEASES_URL'] ??
        '$_githubRawUrl/releases_$platform.json';
  }

  /// Gets the storage URL from environment variables or default
  static String get storageUrl {
    return Platform.environment['FLUTTER_STORAGE_BASE_URL'] ??
        _defaultStorageUrl;
  }

  /// Fetches Flutter SDK Releases with optional caching
  Future<FlutterReleasesResponse> fetchReleases({
    bool useCache = true,
    String? platform,
  }) async {
    // Return cached data if available and requested
    if (useCache && _cachedReleases != null) {
      return _cachedReleases!;
    }

    final targetPlatform = platform ?? Platform.operatingSystem;
    final githubUrl = _getGithubCacheUrl(targetPlatform);
    final googleUrl = _getFlutterReleasesUrl(targetPlatform);

    try {
      // Try GitHub cache first
      final response = await httpRequest(githubUrl);
      _cachedReleases = FlutterReleasesResponse.fromJson(response);

      return _cachedReleases!;
    } catch (err) {
      logger.debug('GitHub cache request failed: ${err.toString()}');

      try {
        // Fallback to Google storage
        final response = await httpRequest(googleUrl);
        _cachedReleases = FlutterReleasesResponse.fromJson(response);

        return _cachedReleases!;
      } catch (e, stackTrace) {
        Error.throwWithStackTrace(
          AppException(
            'Failed to retrieve Flutter SDK releases. '
            'If you are in China, please see: https://flutter.dev/community/china',
          ),
          stackTrace,
        );
      }
    }
  }

  /// Gets releases filtered by channel name
  Future<List<FlutterSdkRelease>> getChannelReleases(String channelName) async {
    if (!FlutterChannel.values.any((channel) => channel.name == channelName)) {
      throw ArgumentError('Invalid channel name: $channelName');
    }

    final response = await fetchReleases();

    return response.versions
        .where((release) => release.channel.name == channelName)
        .toList();
  }

  /// Checks if a version is valid
  Future<bool> isVersionValid(String version) async {
    final releases = await fetchReleases();

    return releases.containsVersion(version);
  }

  /// Gets the latest release for a specific channel
  Future<FlutterSdkRelease> getLatestChannelRelease(String channel) async {
    final response = await fetchReleases();

    return response.latestChannelRelease(channel);
  }

  /// Gets a specific release by version string
  Future<FlutterSdkRelease?> getReleaseByVersion(String version) async {
    final response = await fetchReleases();

    return response.fromVersion(version);
  }

  /// Clears the internal cache
  void clearCache() {
    _cachedReleases = null;
  }
}
