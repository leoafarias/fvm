import 'dart:io';

import '../services/base_service.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/helpers.dart';
import 'models/json_response.dart';

class APIService extends ContextualService {
  final ProjectService _projectService;
  final CacheService _cacheService;
  final FlutterReleasesService _flutterReleasesServices;

  APIService(
    super.context, {
    required ProjectService projectService,
    required CacheService cacheService,
    required FlutterReleasesService flutterReleasesServices,
  })  : _projectService = projectService,
        _cacheService = cacheService,
        _flutterReleasesServices = flutterReleasesServices;

  GetContextResponse getContext() => GetContextResponse(context: context);

  GetProjectResponse getProject([Directory? projectDir]) {
    final project = _projectService.findAncestor(directory: projectDir);

    return GetProjectResponse(project: project);
  }

  Future<GetCacheVersionsResponse> getCachedVersions({
    bool skipCacheSizeCalculation = false,
  }) async {
    final versions = await _cacheService.getAllVersions();

    if (skipCacheSizeCalculation) {
      return GetCacheVersionsResponse(
        size: formatFriendlyBytes(0),
        versions: versions,
      );
    }

    final versionSizes = await Future.wait(versions.map((version) async {
      return getDirectorySize(Directory(version.directory));
    }));

    return GetCacheVersionsResponse(
      size: formatFriendlyBytes(versionSizes.fold<int>(0, (a, b) => a + b)),
      versions: versions,
    );
  }

  Future<GetReleasesResponse> getReleases({
    int? limit,
    String? channelName,
  }) async {
    final payload = await _flutterReleasesServices.getReleases();

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
