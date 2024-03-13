import 'package:dart_mappable/dart_mappable.dart';

import '../../models/cache_flutter_version_model.dart';
import '../../models/project_model.dart';
import '../../services/releases_service/models/version_model.dart';
import '../../utils/context.dart';
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
  final int count;

  /// Channels in Flutter releases
  final Channels channels;

  /// LIst of all releases
  final List<FlutterSdkVersion> versions;

  static final fromMap = GetReleasesResponseMapper.fromMap;
  static final fromJson = GetReleasesResponseMapper.fromJson;

  const GetReleasesResponse({
    required this.count,
    required this.versions,
    required this.channels,
  });
}

@MappableClass()
class GetProjectResponse extends APIResponse with GetProjectResponseMappable {
  final Project project;

  static final fromMap = GetProjectResponseMapper.fromMap;
  static final fromJson = GetProjectResponseMapper.fromJson;

  const GetProjectResponse({required this.project});
}

@MappableClass()
class GetInfoResponse extends APIResponse with GetInfoResponseMappable {
  final FVMContext context;
  final String fvmVersion;
  final Project project;

  static final fromMap = GetInfoResponseMapper.fromMap;
  static final fromJson = GetInfoResponseMapper.fromJson;

  const GetInfoResponse({
    required this.context,
    required this.fvmVersion,
    required this.project,
  });
}
