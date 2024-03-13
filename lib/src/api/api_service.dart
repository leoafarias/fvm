import '../services/base_service.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/context.dart';
import '../utils/extensions.dart';
import '../utils/get_directory_size.dart';
import '../version.dart';
import 'models/json_response.dart';

class APIService extends ContextService {
  const APIService(super.context);

  static APIService get fromContext => getProvider();

  GetInfoResponse getInfo() {
    final project = ProjectService.fromContext.findAncestor();

    return GetInfoResponse(
      context: context,
      fvmVersion: packageVersion,
      project: project,
    );
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

  Future<GetReleasesResponse> getReleases({int limit = 30}) async {
    final payload = await FlutterReleases.get();

    final limitedReleases = payload.versions.take(limit).toList();

    return GetReleasesResponse(
      count: limitedReleases.length,
      versions: limitedReleases,
      channels: payload.channels,
    );
  }
}
