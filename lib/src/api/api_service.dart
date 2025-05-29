import 'dart:io';

import '../services/base_service.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/helpers.dart';
import 'models/json_response.dart';

/// Service providing JSON API access to FVM data for integrations and tooling.
class ApiService extends ContextualService {
  const ApiService(super.context);

  /// Returns the current FVM context and configuration.
  GetContextResponse getContext() => GetContextResponse(context: context);

  /// Returns project information for the specified directory.
  /// If [projectDir] is null, searches from current directory upward.
  GetProjectResponse getProject([Directory? projectDir]) {
    final project = get<ProjectService>().findAncestor(directory: projectDir);

    return GetProjectResponse(project: project);
  }

  /// Returns all cached Flutter SDK versions with optional size calculation.
  /// Set [skipCacheSizeCalculation] to true for faster response on large caches.
  Future<GetCacheVersionsResponse> getCachedVersions({
    bool skipCacheSizeCalculation = false,
  }) async {
    final versions = await get<CacheService>().getAllVersions();

    if (skipCacheSizeCalculation) {
      return GetCacheVersionsResponse(
        size: formatFriendlyBytes(0),
        versions: versions,
      );
    }

    final versionSizes = await Future.wait(versions.map((version) {
      return getDirectorySize(Directory(version.directory));
    }));

    return GetCacheVersionsResponse(
      size: formatFriendlyBytes(versionSizes.fold<int>(0, (a, b) => a + b)),
      versions: versions,
    );
  }

  /// Returns available Flutter SDK releases with optional filtering.
  /// Use [limit] to restrict count and [channelName] to filter by channel.
  Future<GetReleasesResponse> getReleases({
    int? limit,
    String? channelName,
  }) async {
    final payload = await get<FlutterReleaseClient>().fetchReleases();

    var filteredVersions = payload.versions.where((version) {
      if (channelName == null) return true;

      return version.channel.name == channelName;
    });

    if (limit != null) {
      filteredVersions = filteredVersions.take(limit);
    }

    return GetReleasesResponse(
      versions: filteredVersions.toList(),
      channels: payload.channels,
    );
  }
}
