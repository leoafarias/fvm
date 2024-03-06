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

  Future<GetCacheVersionsResponse> getCachedVersions() async {
    final versions = await CacheService.fromContext.getAllVersions();

    final versionSizes = await Future.wait(versions.map((version) async {
      final size = await getDirectorySize(version.directory.dir);

      return size;
    }));

    return GetCacheVersionsResponse(
      versions: versions,
      size: formatBytes(versionSizes.fold<int>(0, (a, b) => a + b)),
    );
  }

  Future<GetReleasesResponse> getReleases() async {
    final releases = await FlutterReleases.get();

    return GetReleasesResponse(releases: releases);
  }

  GetProjectResponse getProject() {
    final project = ProjectService.fromContext.findAncestor();

    return GetProjectResponse(project: project);
  }
}
