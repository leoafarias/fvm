import 'dart:io';

import '../services/base_service.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/context.dart';
import '../utils/extensions.dart';
import '../utils/get_directory_size.dart';
import 'models/json_response.dart';

class APIService extends ContextService {
  const APIService(super.context);

  static APIService get fromContext => getProvider();

  GetContextResponse getContext() => GetContextResponse(context: context);

  GetProjectResponse getProject([Directory? projectDir]) {
    final project =
        ProjectService.fromContext.findAncestor(directory: projectDir);

    return GetProjectResponse(project: project);
  }

  Future<GetCacheVersionsResponse> getCachedVersions({
    bool skipCacheSizeCalculation = false,
  }) async {
    final versions = await CacheService.fromContext.getAllVersions();

    var versionSizes = List.filled(versions.length, 0);

    if (!skipCacheSizeCalculation) {
      versionSizes = await Future.wait(versions.map((version) async {
        return await getDirectorySize(version.directory.dir);
      }));
    }

    return GetCacheVersionsResponse(
      size: formatBytes(versionSizes.fold<int>(0, (a, b) => a + b)),
      versions: versions,
    );
  }

  Future<GetReleasesResponse> getReleases({
    int? limit,
    String? channelName,
  }) async {
    final payload = await FlutterReleasesClient.getReleases();

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
