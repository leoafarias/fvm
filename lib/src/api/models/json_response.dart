import 'package:dart_mappable/dart_mappable.dart';

import '../../models/cache_flutter_version_model.dart';
import '../../models/project_model.dart';
import '../../services/releases_service/models/flutter_releases.model.dart';
import '../../utils/pretty_json.dart';

part 'json_response.mapper.dart';

typedef JSONMap = Map<String, dynamic>;

@MappableClass()
abstract class APIResponse<TPayload> with APIResponseMappable {
  final TPayload data;

  const APIResponse({required this.data});

  String formattedJson() => prettyJson(toMap());
}

@MappableClass()
class GetCacheVersionsResponse extends APIResponse<List<CacheFlutterVersion>>
    with GetCacheVersionsResponseMappable {
  static final fromMap = GetCacheVersionsResponseMapper.fromMap;
  static final fromJson = GetCacheVersionsResponseMapper.fromJson;

  const GetCacheVersionsResponse({required super.data});
}

@MappableClass()
class GetReleasesResponse extends APIResponse<FlutterReleasesResponse>
    with GetReleasesResponseMappable {
  static final fromMap = GetReleasesResponseMapper.fromMap;
  static final fromJson = GetReleasesResponseMapper.fromJson;

  const GetReleasesResponse({required super.data});
}

@MappableClass()
class GetProjectResponse extends APIResponse<Project>
    with GetProjectResponseMappable {
  static final fromMap = GetProjectResponseMapper.fromMap;
  static final fromJson = GetProjectResponseMapper.fromJson;

  const GetProjectResponse({required super.data});
}
