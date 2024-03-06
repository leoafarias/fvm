import 'package:dart_mappable/dart_mappable.dart';

import '../../models/cache_flutter_version_model.dart';
import '../../models/project_model.dart';
import '../../services/releases_service/models/flutter_releases.model.dart';
import '../../utils/pretty_json.dart';

part 'json_response.mapper.dart';

typedef JSONMap = Map<String, dynamic>;

@MappableClass()
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

  const GetCacheVersionsResponse({
    required this.size,
    required this.versions,
  });
}

@MappableClass()
class GetReleasesResponse extends APIResponse with GetReleasesResponseMappable {
  final FlutterReleasesResponse releases;

  static final fromMap = GetReleasesResponseMapper.fromMap;
  static final fromJson = GetReleasesResponseMapper.fromJson;

  const GetReleasesResponse({required this.releases});
}

@MappableClass()
class GetProjectResponse extends APIResponse with GetProjectResponseMappable {
  final Project project;

  static final fromMap = GetProjectResponseMapper.fromMap;
  static final fromJson = GetProjectResponseMapper.fromJson;

  const GetProjectResponse({required this.project});
}
