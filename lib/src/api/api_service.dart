import '../models/project_model.dart';
import '../services/base_service.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/models/flutter_releases.model.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/context.dart';
import 'models/json_response.dart';

class APIService extends ContextService {
  const APIService(super.context);

  static APIService get fromContext => getProvider();

  Future<GetCacheVersionsResponse> getCachedVersions() async {
    final versions = await CacheService.fromContext.getAllVersions();

    return GetCacheVersionsResponse(data: versions);
  }

  Future<APIResponse<FlutterReleasesResponse>> getReleases() async {
    final releases = await FlutterReleases.get();

    return GetReleasesResponse(data: releases);
  }

  APIResponse<Project> getProject() {
    final project = ProjectService.fromContext.findAncestor();

    return GetProjectResponse(data: project);
  }
}
