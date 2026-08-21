import 'package:dart_mappable/dart_mappable.dart';

import '../../models/cache_flutter_version_model.dart';
import '../../models/project_model.dart';
import '../../services/releases_service/models/version_model.dart';
import '../../utils/context.dart';
import '../../utils/helpers.dart';
import '../../utils/pretty_json.dart';

part 'json_response.mapper.dart';

typedef JSONMap = Map<String, dynamic>;

@MappableClass(generateMethods: skipCopyWith)
abstract class APIResponse with APIResponseMappable {
  const APIResponse();

  String toPrettyJson() => prettyJson(toMap());
}

@MappableClass()
class GetCacheVersionsResponse extends APIResponse
    with GetCacheVersionsResponseMappable {
  final String size;
  final List<CacheFlutterVersion> versions;

  static final fromMap = GetCacheVersionsResponseMapper.fromMap;
  static final fromJson = GetCacheVersionsResponseMapper.fromJson;

  const GetCacheVersionsResponse({required this.size, required this.versions});
}

@MappableClass()
class GetReleasesResponse extends APIResponse with GetReleasesResponseMappable {
  /// Channels in Flutter releases
  final Channels channels;

  /// List of all releases
  final List<FlutterSdkRelease> versions;

  static final fromMap = GetReleasesResponseMapper.fromMap;
  static final fromJson = GetReleasesResponseMapper.fromJson;

  const GetReleasesResponse({required this.versions, required this.channels});
}

@MappableClass()
class GetProjectResponse extends APIResponse with GetProjectResponseMappable {
  final Project project;

  static final fromMap = GetProjectResponseMapper.fromMap;
  static final fromJson = GetProjectResponseMapper.fromJson;

  const GetProjectResponse({required this.project});
}

@MappableClass()
class GetContextResponse extends APIResponse with GetContextResponseMappable {
  final FvmContext context;
  static final fromMap = GetContextResponseMapper.fromMap;
  static final fromJson = GetContextResponseMapper.fromJson;

  const GetContextResponse({required this.context});
}

@MappableClass()
class ProjectUsageResponse with ProjectUsageResponseMappable {
  final String name;
  final String path;
  final String status;
  final String? flutter;
  final Map<String, String> flavors;
  final List<String> referencedVersions;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  static final fromMap = ProjectUsageResponseMapper.fromMap;
  static final fromJson = ProjectUsageResponseMapper.fromJson;

  const ProjectUsageResponse({
    required this.name,
    required this.path,
    required this.status,
    required this.flutter,
    required this.flavors,
    required this.referencedVersions,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });
}

@MappableClass()
class VersionUsageResponse with VersionUsageResponseMappable {
  final String version;
  final int projectCount;
  final List<String> projectPaths;
  final bool global;
  final bool unreferenced;

  static final fromMap = VersionUsageResponseMapper.fromMap;
  static final fromJson = VersionUsageResponseMapper.fromJson;

  const VersionUsageResponse({
    required this.version,
    required this.projectCount,
    required this.projectPaths,
    required this.global,
    required this.unreferenced,
  });
}

@MappableClass()
class GetProjectsResponse extends APIResponse with GetProjectsResponseMappable {
  final List<ProjectUsageResponse> projects;
  final List<VersionUsageResponse> versionUsage;
  final List<String> unreferencedVersions;
  final List<String> missingVersions;

  static final fromMap = GetProjectsResponseMapper.fromMap;
  static final fromJson = GetProjectsResponseMapper.fromJson;

  const GetProjectsResponse({
    required this.projects,
    required this.versionUsage,
    required this.unreferencedVersions,
    required this.missingVersions,
  });
}
