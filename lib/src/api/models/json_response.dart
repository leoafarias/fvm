import '../../models/cache_flutter_version_model.dart';
import '../../services/releases_service/models/flutter_releases.model.dart';

typedef JSONMap = Map<String, dynamic>;

abstract class ApiResponse {
  const ApiResponse();

  Map<String, dynamic> toMap();

  @override
  String toString();
}

class ListCommandResponse extends ApiResponse {
  final List<CacheFlutterVersion> versions;
  const ListCommandResponse(this.versions);

  @override
  Map<String, dynamic> toMap() {
    return {'data': versions.map((version) => version.toMap()).toList()};
  }

  @override
  String toString() {
    return versions.map((version) => version.toString()).join('\n');
  }
}

class ReleasesCommandResponse extends ApiResponse {
  final Releases releases;
  const ReleasesCommandResponse(this.releases);

  @override
  Map<String, dynamic> toMap() => {'data': releases.toMap()};

  @override
  String toString() => releases.toString();
}

@
class InstallCommandResponse extends ApiResponse {
  final bool success;
  final CacheFlutterVersion? version;
  const InstallCommandResponse({required this.success, this.version});

  @override
  Map<String, dynamic> toMap() => version.toMap();

  @override
  String toString() => version.toString();
}
