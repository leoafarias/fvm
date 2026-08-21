// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'json_response.dart';

class APIResponseMapper extends ClassMapperBase<APIResponse> {
  APIResponseMapper._();

  static APIResponseMapper? _instance;
  static APIResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = APIResponseMapper._());
      GetCacheVersionsResponseMapper.ensureInitialized();
      GetReleasesResponseMapper.ensureInitialized();
      GetProjectResponseMapper.ensureInitialized();
      GetContextResponseMapper.ensureInitialized();
      GetProjectsResponseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'APIResponse';

  @override
  final MappableFields<APIResponse> fields = const {};

  static APIResponse _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('APIResponse');
  }

  @override
  final Function instantiate = _instantiate;

  static APIResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<APIResponse>(map);
  }

  static APIResponse fromJson(String json) {
    return ensureInitialized().decodeJson<APIResponse>(json);
  }
}

mixin APIResponseMappable {
  String toJson();
  Map<String, dynamic> toMap();
}

class GetCacheVersionsResponseMapper
    extends ClassMapperBase<GetCacheVersionsResponse> {
  GetCacheVersionsResponseMapper._();

  static GetCacheVersionsResponseMapper? _instance;
  static GetCacheVersionsResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals
          .use(_instance = GetCacheVersionsResponseMapper._());
      APIResponseMapper.ensureInitialized();
      CacheFlutterVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GetCacheVersionsResponse';

  static String _$size(GetCacheVersionsResponse v) => v.size;
  static const Field<GetCacheVersionsResponse, String> _f$size =
      Field('size', _$size);
  static List<CacheFlutterVersion> _$versions(GetCacheVersionsResponse v) =>
      v.versions;
  static const Field<GetCacheVersionsResponse, List<CacheFlutterVersion>>
      _f$versions = Field('versions', _$versions);

  @override
  final MappableFields<GetCacheVersionsResponse> fields = const {
    #size: _f$size,
    #versions: _f$versions,
  };

  static GetCacheVersionsResponse _instantiate(DecodingData data) {
    return GetCacheVersionsResponse(
        size: data.dec(_f$size), versions: data.dec(_f$versions));
  }

  @override
  final Function instantiate = _instantiate;

  static GetCacheVersionsResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GetCacheVersionsResponse>(map);
  }

  static GetCacheVersionsResponse fromJson(String json) {
    return ensureInitialized().decodeJson<GetCacheVersionsResponse>(json);
  }
}

mixin GetCacheVersionsResponseMappable {
  String toJson() {
    return GetCacheVersionsResponseMapper.ensureInitialized()
        .encodeJson<GetCacheVersionsResponse>(this as GetCacheVersionsResponse);
  }

  Map<String, dynamic> toMap() {
    return GetCacheVersionsResponseMapper.ensureInitialized()
        .encodeMap<GetCacheVersionsResponse>(this as GetCacheVersionsResponse);
  }

  GetCacheVersionsResponseCopyWith<GetCacheVersionsResponse,
          GetCacheVersionsResponse, GetCacheVersionsResponse>
      get copyWith => _GetCacheVersionsResponseCopyWithImpl<
              GetCacheVersionsResponse, GetCacheVersionsResponse>(
          this as GetCacheVersionsResponse, $identity, $identity);
  @override
  String toString() {
    return GetCacheVersionsResponseMapper.ensureInitialized()
        .stringifyValue(this as GetCacheVersionsResponse);
  }

  @override
  bool operator ==(Object other) {
    return GetCacheVersionsResponseMapper.ensureInitialized()
        .equalsValue(this as GetCacheVersionsResponse, other);
  }

  @override
  int get hashCode {
    return GetCacheVersionsResponseMapper.ensureInitialized()
        .hashValue(this as GetCacheVersionsResponse);
  }
}

extension GetCacheVersionsResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GetCacheVersionsResponse, $Out> {
  GetCacheVersionsResponseCopyWith<$R, GetCacheVersionsResponse, $Out>
      get $asGetCacheVersionsResponse => $base.as((v, t, t2) =>
          _GetCacheVersionsResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GetCacheVersionsResponseCopyWith<
    $R,
    $In extends GetCacheVersionsResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
      $R,
      CacheFlutterVersion,
      CacheFlutterVersionCopyWith<$R, CacheFlutterVersion,
          CacheFlutterVersion>> get versions;
  $R call({String? size, List<CacheFlutterVersion>? versions});
  GetCacheVersionsResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GetCacheVersionsResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GetCacheVersionsResponse, $Out>
    implements
        GetCacheVersionsResponseCopyWith<$R, GetCacheVersionsResponse, $Out> {
  _GetCacheVersionsResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GetCacheVersionsResponse> $mapper =
      GetCacheVersionsResponseMapper.ensureInitialized();
  @override
  ListCopyWith<
      $R,
      CacheFlutterVersion,
      CacheFlutterVersionCopyWith<$R, CacheFlutterVersion,
          CacheFlutterVersion>> get versions => ListCopyWith($value.versions,
      (v, t) => v.copyWith.$chain(t), (v) => call(versions: v));
  @override
  $R call({String? size, List<CacheFlutterVersion>? versions}) =>
      $apply(FieldCopyWithData({
        if (size != null) #size: size,
        if (versions != null) #versions: versions
      }));
  @override
  GetCacheVersionsResponse $make(CopyWithData data) => GetCacheVersionsResponse(
      size: data.get(#size, or: $value.size),
      versions: data.get(#versions, or: $value.versions));

  @override
  GetCacheVersionsResponseCopyWith<$R2, GetCacheVersionsResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _GetCacheVersionsResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GetReleasesResponseMapper extends ClassMapperBase<GetReleasesResponse> {
  GetReleasesResponseMapper._();

  static GetReleasesResponseMapper? _instance;
  static GetReleasesResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GetReleasesResponseMapper._());
      APIResponseMapper.ensureInitialized();
      FlutterSdkReleaseMapper.ensureInitialized();
      ChannelsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GetReleasesResponse';

  static List<FlutterSdkRelease> _$versions(GetReleasesResponse v) =>
      v.versions;
  static const Field<GetReleasesResponse, List<FlutterSdkRelease>> _f$versions =
      Field('versions', _$versions);
  static Channels _$channels(GetReleasesResponse v) => v.channels;
  static const Field<GetReleasesResponse, Channels> _f$channels =
      Field('channels', _$channels);

  @override
  final MappableFields<GetReleasesResponse> fields = const {
    #versions: _f$versions,
    #channels: _f$channels,
  };

  static GetReleasesResponse _instantiate(DecodingData data) {
    return GetReleasesResponse(
        versions: data.dec(_f$versions), channels: data.dec(_f$channels));
  }

  @override
  final Function instantiate = _instantiate;

  static GetReleasesResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GetReleasesResponse>(map);
  }

  static GetReleasesResponse fromJson(String json) {
    return ensureInitialized().decodeJson<GetReleasesResponse>(json);
  }
}

mixin GetReleasesResponseMappable {
  String toJson() {
    return GetReleasesResponseMapper.ensureInitialized()
        .encodeJson<GetReleasesResponse>(this as GetReleasesResponse);
  }

  Map<String, dynamic> toMap() {
    return GetReleasesResponseMapper.ensureInitialized()
        .encodeMap<GetReleasesResponse>(this as GetReleasesResponse);
  }

  GetReleasesResponseCopyWith<GetReleasesResponse, GetReleasesResponse,
      GetReleasesResponse> get copyWith => _GetReleasesResponseCopyWithImpl<
          GetReleasesResponse, GetReleasesResponse>(
      this as GetReleasesResponse, $identity, $identity);
  @override
  String toString() {
    return GetReleasesResponseMapper.ensureInitialized()
        .stringifyValue(this as GetReleasesResponse);
  }

  @override
  bool operator ==(Object other) {
    return GetReleasesResponseMapper.ensureInitialized()
        .equalsValue(this as GetReleasesResponse, other);
  }

  @override
  int get hashCode {
    return GetReleasesResponseMapper.ensureInitialized()
        .hashValue(this as GetReleasesResponse);
  }
}

extension GetReleasesResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GetReleasesResponse, $Out> {
  GetReleasesResponseCopyWith<$R, GetReleasesResponse, $Out>
      get $asGetReleasesResponse => $base.as(
          (v, t, t2) => _GetReleasesResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GetReleasesResponseCopyWith<$R, $In extends GetReleasesResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, FlutterSdkRelease,
          FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease>>
      get versions;
  ChannelsCopyWith<$R, Channels, Channels> get channels;
  $R call({List<FlutterSdkRelease>? versions, Channels? channels});
  GetReleasesResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GetReleasesResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GetReleasesResponse, $Out>
    implements GetReleasesResponseCopyWith<$R, GetReleasesResponse, $Out> {
  _GetReleasesResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GetReleasesResponse> $mapper =
      GetReleasesResponseMapper.ensureInitialized();
  @override
  ListCopyWith<$R, FlutterSdkRelease,
          FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease>>
      get versions => ListCopyWith($value.versions,
          (v, t) => v.copyWith.$chain(t), (v) => call(versions: v));
  @override
  ChannelsCopyWith<$R, Channels, Channels> get channels =>
      $value.channels.copyWith.$chain((v) => call(channels: v));
  @override
  $R call({List<FlutterSdkRelease>? versions, Channels? channels}) =>
      $apply(FieldCopyWithData({
        if (versions != null) #versions: versions,
        if (channels != null) #channels: channels
      }));
  @override
  GetReleasesResponse $make(CopyWithData data) => GetReleasesResponse(
      versions: data.get(#versions, or: $value.versions),
      channels: data.get(#channels, or: $value.channels));

  @override
  GetReleasesResponseCopyWith<$R2, GetReleasesResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _GetReleasesResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GetProjectResponseMapper extends ClassMapperBase<GetProjectResponse> {
  GetProjectResponseMapper._();

  static GetProjectResponseMapper? _instance;
  static GetProjectResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GetProjectResponseMapper._());
      APIResponseMapper.ensureInitialized();
      ProjectMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GetProjectResponse';

  static Project _$project(GetProjectResponse v) => v.project;
  static const Field<GetProjectResponse, Project> _f$project =
      Field('project', _$project);

  @override
  final MappableFields<GetProjectResponse> fields = const {
    #project: _f$project,
  };

  static GetProjectResponse _instantiate(DecodingData data) {
    return GetProjectResponse(project: data.dec(_f$project));
  }

  @override
  final Function instantiate = _instantiate;

  static GetProjectResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GetProjectResponse>(map);
  }

  static GetProjectResponse fromJson(String json) {
    return ensureInitialized().decodeJson<GetProjectResponse>(json);
  }
}

mixin GetProjectResponseMappable {
  String toJson() {
    return GetProjectResponseMapper.ensureInitialized()
        .encodeJson<GetProjectResponse>(this as GetProjectResponse);
  }

  Map<String, dynamic> toMap() {
    return GetProjectResponseMapper.ensureInitialized()
        .encodeMap<GetProjectResponse>(this as GetProjectResponse);
  }

  GetProjectResponseCopyWith<GetProjectResponse, GetProjectResponse,
          GetProjectResponse>
      get copyWith => _GetProjectResponseCopyWithImpl<GetProjectResponse,
          GetProjectResponse>(this as GetProjectResponse, $identity, $identity);
  @override
  String toString() {
    return GetProjectResponseMapper.ensureInitialized()
        .stringifyValue(this as GetProjectResponse);
  }

  @override
  bool operator ==(Object other) {
    return GetProjectResponseMapper.ensureInitialized()
        .equalsValue(this as GetProjectResponse, other);
  }

  @override
  int get hashCode {
    return GetProjectResponseMapper.ensureInitialized()
        .hashValue(this as GetProjectResponse);
  }
}

extension GetProjectResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GetProjectResponse, $Out> {
  GetProjectResponseCopyWith<$R, GetProjectResponse, $Out>
      get $asGetProjectResponse => $base.as(
          (v, t, t2) => _GetProjectResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GetProjectResponseCopyWith<$R, $In extends GetProjectResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ProjectCopyWith<$R, Project, Project> get project;
  $R call({Project? project});
  GetProjectResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GetProjectResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GetProjectResponse, $Out>
    implements GetProjectResponseCopyWith<$R, GetProjectResponse, $Out> {
  _GetProjectResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GetProjectResponse> $mapper =
      GetProjectResponseMapper.ensureInitialized();
  @override
  ProjectCopyWith<$R, Project, Project> get project =>
      $value.project.copyWith.$chain((v) => call(project: v));
  @override
  $R call({Project? project}) =>
      $apply(FieldCopyWithData({if (project != null) #project: project}));
  @override
  GetProjectResponse $make(CopyWithData data) =>
      GetProjectResponse(project: data.get(#project, or: $value.project));

  @override
  GetProjectResponseCopyWith<$R2, GetProjectResponse, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GetProjectResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GetContextResponseMapper extends ClassMapperBase<GetContextResponse> {
  GetContextResponseMapper._();

  static GetContextResponseMapper? _instance;
  static GetContextResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GetContextResponseMapper._());
      APIResponseMapper.ensureInitialized();
      FvmContextMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GetContextResponse';

  static FvmContext _$context(GetContextResponse v) => v.context;
  static const Field<GetContextResponse, FvmContext> _f$context =
      Field('context', _$context);

  @override
  final MappableFields<GetContextResponse> fields = const {
    #context: _f$context,
  };

  static GetContextResponse _instantiate(DecodingData data) {
    return GetContextResponse(context: data.dec(_f$context));
  }

  @override
  final Function instantiate = _instantiate;

  static GetContextResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GetContextResponse>(map);
  }

  static GetContextResponse fromJson(String json) {
    return ensureInitialized().decodeJson<GetContextResponse>(json);
  }
}

mixin GetContextResponseMappable {
  String toJson() {
    return GetContextResponseMapper.ensureInitialized()
        .encodeJson<GetContextResponse>(this as GetContextResponse);
  }

  Map<String, dynamic> toMap() {
    return GetContextResponseMapper.ensureInitialized()
        .encodeMap<GetContextResponse>(this as GetContextResponse);
  }

  GetContextResponseCopyWith<GetContextResponse, GetContextResponse,
          GetContextResponse>
      get copyWith => _GetContextResponseCopyWithImpl<GetContextResponse,
          GetContextResponse>(this as GetContextResponse, $identity, $identity);
  @override
  String toString() {
    return GetContextResponseMapper.ensureInitialized()
        .stringifyValue(this as GetContextResponse);
  }

  @override
  bool operator ==(Object other) {
    return GetContextResponseMapper.ensureInitialized()
        .equalsValue(this as GetContextResponse, other);
  }

  @override
  int get hashCode {
    return GetContextResponseMapper.ensureInitialized()
        .hashValue(this as GetContextResponse);
  }
}

extension GetContextResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GetContextResponse, $Out> {
  GetContextResponseCopyWith<$R, GetContextResponse, $Out>
      get $asGetContextResponse => $base.as(
          (v, t, t2) => _GetContextResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GetContextResponseCopyWith<$R, $In extends GetContextResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  FvmContextCopyWith<$R, FvmContext, FvmContext> get context;
  $R call({FvmContext? context});
  GetContextResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GetContextResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GetContextResponse, $Out>
    implements GetContextResponseCopyWith<$R, GetContextResponse, $Out> {
  _GetContextResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GetContextResponse> $mapper =
      GetContextResponseMapper.ensureInitialized();
  @override
  FvmContextCopyWith<$R, FvmContext, FvmContext> get context =>
      $value.context.copyWith.$chain((v) => call(context: v));
  @override
  $R call({FvmContext? context}) =>
      $apply(FieldCopyWithData({if (context != null) #context: context}));
  @override
  GetContextResponse $make(CopyWithData data) =>
      GetContextResponse(context: data.get(#context, or: $value.context));

  @override
  GetContextResponseCopyWith<$R2, GetContextResponse, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GetContextResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ProjectUsageResponseMapper extends ClassMapperBase<ProjectUsageResponse> {
  ProjectUsageResponseMapper._();

  static ProjectUsageResponseMapper? _instance;
  static ProjectUsageResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ProjectUsageResponseMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ProjectUsageResponse';

  static String _$name(ProjectUsageResponse v) => v.name;
  static const Field<ProjectUsageResponse, String> _f$name =
      Field('name', _$name);
  static String _$path(ProjectUsageResponse v) => v.path;
  static const Field<ProjectUsageResponse, String> _f$path =
      Field('path', _$path);
  static String _$status(ProjectUsageResponse v) => v.status;
  static const Field<ProjectUsageResponse, String> _f$status =
      Field('status', _$status);
  static String? _$flutter(ProjectUsageResponse v) => v.flutter;
  static const Field<ProjectUsageResponse, String> _f$flutter =
      Field('flutter', _$flutter);
  static Map<String, String> _$flavors(ProjectUsageResponse v) => v.flavors;
  static const Field<ProjectUsageResponse, Map<String, String>> _f$flavors =
      Field('flavors', _$flavors);
  static List<String> _$referencedVersions(ProjectUsageResponse v) =>
      v.referencedVersions;
  static const Field<ProjectUsageResponse, List<String>> _f$referencedVersions =
      Field('referencedVersions', _$referencedVersions);
  static DateTime _$firstSeenAt(ProjectUsageResponse v) => v.firstSeenAt;
  static const Field<ProjectUsageResponse, DateTime> _f$firstSeenAt =
      Field('firstSeenAt', _$firstSeenAt);
  static DateTime _$lastSeenAt(ProjectUsageResponse v) => v.lastSeenAt;
  static const Field<ProjectUsageResponse, DateTime> _f$lastSeenAt =
      Field('lastSeenAt', _$lastSeenAt);

  @override
  final MappableFields<ProjectUsageResponse> fields = const {
    #name: _f$name,
    #path: _f$path,
    #status: _f$status,
    #flutter: _f$flutter,
    #flavors: _f$flavors,
    #referencedVersions: _f$referencedVersions,
    #firstSeenAt: _f$firstSeenAt,
    #lastSeenAt: _f$lastSeenAt,
  };

  static ProjectUsageResponse _instantiate(DecodingData data) {
    return ProjectUsageResponse(
        name: data.dec(_f$name),
        path: data.dec(_f$path),
        status: data.dec(_f$status),
        flutter: data.dec(_f$flutter),
        flavors: data.dec(_f$flavors),
        referencedVersions: data.dec(_f$referencedVersions),
        firstSeenAt: data.dec(_f$firstSeenAt),
        lastSeenAt: data.dec(_f$lastSeenAt));
  }

  @override
  final Function instantiate = _instantiate;

  static ProjectUsageResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ProjectUsageResponse>(map);
  }

  static ProjectUsageResponse fromJson(String json) {
    return ensureInitialized().decodeJson<ProjectUsageResponse>(json);
  }
}

mixin ProjectUsageResponseMappable {
  String toJson() {
    return ProjectUsageResponseMapper.ensureInitialized()
        .encodeJson<ProjectUsageResponse>(this as ProjectUsageResponse);
  }

  Map<String, dynamic> toMap() {
    return ProjectUsageResponseMapper.ensureInitialized()
        .encodeMap<ProjectUsageResponse>(this as ProjectUsageResponse);
  }

  ProjectUsageResponseCopyWith<ProjectUsageResponse, ProjectUsageResponse,
      ProjectUsageResponse> get copyWith => _ProjectUsageResponseCopyWithImpl<
          ProjectUsageResponse, ProjectUsageResponse>(
      this as ProjectUsageResponse, $identity, $identity);
  @override
  String toString() {
    return ProjectUsageResponseMapper.ensureInitialized()
        .stringifyValue(this as ProjectUsageResponse);
  }

  @override
  bool operator ==(Object other) {
    return ProjectUsageResponseMapper.ensureInitialized()
        .equalsValue(this as ProjectUsageResponse, other);
  }

  @override
  int get hashCode {
    return ProjectUsageResponseMapper.ensureInitialized()
        .hashValue(this as ProjectUsageResponse);
  }
}

extension ProjectUsageResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ProjectUsageResponse, $Out> {
  ProjectUsageResponseCopyWith<$R, ProjectUsageResponse, $Out>
      get $asProjectUsageResponse => $base.as(
          (v, t, t2) => _ProjectUsageResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ProjectUsageResponseCopyWith<
    $R,
    $In extends ProjectUsageResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get flavors;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get referencedVersions;
  $R call(
      {String? name,
      String? path,
      String? status,
      String? flutter,
      Map<String, String>? flavors,
      List<String>? referencedVersions,
      DateTime? firstSeenAt,
      DateTime? lastSeenAt});
  ProjectUsageResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ProjectUsageResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ProjectUsageResponse, $Out>
    implements ProjectUsageResponseCopyWith<$R, ProjectUsageResponse, $Out> {
  _ProjectUsageResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ProjectUsageResponse> $mapper =
      ProjectUsageResponseMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get flavors => MapCopyWith($value.flavors,
          (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(flavors: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get referencedVersions => ListCopyWith(
          $value.referencedVersions,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(referencedVersions: v));
  @override
  $R call(
          {String? name,
          String? path,
          String? status,
          Object? flutter = $none,
          Map<String, String>? flavors,
          List<String>? referencedVersions,
          DateTime? firstSeenAt,
          DateTime? lastSeenAt}) =>
      $apply(FieldCopyWithData({
        if (name != null) #name: name,
        if (path != null) #path: path,
        if (status != null) #status: status,
        if (flutter != $none) #flutter: flutter,
        if (flavors != null) #flavors: flavors,
        if (referencedVersions != null) #referencedVersions: referencedVersions,
        if (firstSeenAt != null) #firstSeenAt: firstSeenAt,
        if (lastSeenAt != null) #lastSeenAt: lastSeenAt
      }));
  @override
  ProjectUsageResponse $make(CopyWithData data) => ProjectUsageResponse(
      name: data.get(#name, or: $value.name),
      path: data.get(#path, or: $value.path),
      status: data.get(#status, or: $value.status),
      flutter: data.get(#flutter, or: $value.flutter),
      flavors: data.get(#flavors, or: $value.flavors),
      referencedVersions:
          data.get(#referencedVersions, or: $value.referencedVersions),
      firstSeenAt: data.get(#firstSeenAt, or: $value.firstSeenAt),
      lastSeenAt: data.get(#lastSeenAt, or: $value.lastSeenAt));

  @override
  ProjectUsageResponseCopyWith<$R2, ProjectUsageResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ProjectUsageResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class VersionUsageResponseMapper extends ClassMapperBase<VersionUsageResponse> {
  VersionUsageResponseMapper._();

  static VersionUsageResponseMapper? _instance;
  static VersionUsageResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VersionUsageResponseMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'VersionUsageResponse';

  static String _$version(VersionUsageResponse v) => v.version;
  static const Field<VersionUsageResponse, String> _f$version =
      Field('version', _$version);
  static int _$projectCount(VersionUsageResponse v) => v.projectCount;
  static const Field<VersionUsageResponse, int> _f$projectCount =
      Field('projectCount', _$projectCount);
  static List<String> _$projectPaths(VersionUsageResponse v) => v.projectPaths;
  static const Field<VersionUsageResponse, List<String>> _f$projectPaths =
      Field('projectPaths', _$projectPaths);
  static bool _$global(VersionUsageResponse v) => v.global;
  static const Field<VersionUsageResponse, bool> _f$global =
      Field('global', _$global);
  static bool _$unreferenced(VersionUsageResponse v) => v.unreferenced;
  static const Field<VersionUsageResponse, bool> _f$unreferenced =
      Field('unreferenced', _$unreferenced);

  @override
  final MappableFields<VersionUsageResponse> fields = const {
    #version: _f$version,
    #projectCount: _f$projectCount,
    #projectPaths: _f$projectPaths,
    #global: _f$global,
    #unreferenced: _f$unreferenced,
  };

  static VersionUsageResponse _instantiate(DecodingData data) {
    return VersionUsageResponse(
        version: data.dec(_f$version),
        projectCount: data.dec(_f$projectCount),
        projectPaths: data.dec(_f$projectPaths),
        global: data.dec(_f$global),
        unreferenced: data.dec(_f$unreferenced));
  }

  @override
  final Function instantiate = _instantiate;

  static VersionUsageResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VersionUsageResponse>(map);
  }

  static VersionUsageResponse fromJson(String json) {
    return ensureInitialized().decodeJson<VersionUsageResponse>(json);
  }
}

mixin VersionUsageResponseMappable {
  String toJson() {
    return VersionUsageResponseMapper.ensureInitialized()
        .encodeJson<VersionUsageResponse>(this as VersionUsageResponse);
  }

  Map<String, dynamic> toMap() {
    return VersionUsageResponseMapper.ensureInitialized()
        .encodeMap<VersionUsageResponse>(this as VersionUsageResponse);
  }

  VersionUsageResponseCopyWith<VersionUsageResponse, VersionUsageResponse,
      VersionUsageResponse> get copyWith => _VersionUsageResponseCopyWithImpl<
          VersionUsageResponse, VersionUsageResponse>(
      this as VersionUsageResponse, $identity, $identity);
  @override
  String toString() {
    return VersionUsageResponseMapper.ensureInitialized()
        .stringifyValue(this as VersionUsageResponse);
  }

  @override
  bool operator ==(Object other) {
    return VersionUsageResponseMapper.ensureInitialized()
        .equalsValue(this as VersionUsageResponse, other);
  }

  @override
  int get hashCode {
    return VersionUsageResponseMapper.ensureInitialized()
        .hashValue(this as VersionUsageResponse);
  }
}

extension VersionUsageResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VersionUsageResponse, $Out> {
  VersionUsageResponseCopyWith<$R, VersionUsageResponse, $Out>
      get $asVersionUsageResponse => $base.as(
          (v, t, t2) => _VersionUsageResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VersionUsageResponseCopyWith<
    $R,
    $In extends VersionUsageResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get projectPaths;
  $R call(
      {String? version,
      int? projectCount,
      List<String>? projectPaths,
      bool? global,
      bool? unreferenced});
  VersionUsageResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _VersionUsageResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VersionUsageResponse, $Out>
    implements VersionUsageResponseCopyWith<$R, VersionUsageResponse, $Out> {
  _VersionUsageResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VersionUsageResponse> $mapper =
      VersionUsageResponseMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get projectPaths => ListCopyWith(
          $value.projectPaths,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(projectPaths: v));
  @override
  $R call(
          {String? version,
          int? projectCount,
          List<String>? projectPaths,
          bool? global,
          bool? unreferenced}) =>
      $apply(FieldCopyWithData({
        if (version != null) #version: version,
        if (projectCount != null) #projectCount: projectCount,
        if (projectPaths != null) #projectPaths: projectPaths,
        if (global != null) #global: global,
        if (unreferenced != null) #unreferenced: unreferenced
      }));
  @override
  VersionUsageResponse $make(CopyWithData data) => VersionUsageResponse(
      version: data.get(#version, or: $value.version),
      projectCount: data.get(#projectCount, or: $value.projectCount),
      projectPaths: data.get(#projectPaths, or: $value.projectPaths),
      global: data.get(#global, or: $value.global),
      unreferenced: data.get(#unreferenced, or: $value.unreferenced));

  @override
  VersionUsageResponseCopyWith<$R2, VersionUsageResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _VersionUsageResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GetProjectsResponseMapper extends ClassMapperBase<GetProjectsResponse> {
  GetProjectsResponseMapper._();

  static GetProjectsResponseMapper? _instance;
  static GetProjectsResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GetProjectsResponseMapper._());
      APIResponseMapper.ensureInitialized();
      ProjectUsageResponseMapper.ensureInitialized();
      VersionUsageResponseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GetProjectsResponse';

  static List<ProjectUsageResponse> _$projects(GetProjectsResponse v) =>
      v.projects;
  static const Field<GetProjectsResponse, List<ProjectUsageResponse>>
      _f$projects = Field('projects', _$projects);
  static List<VersionUsageResponse> _$versionUsage(GetProjectsResponse v) =>
      v.versionUsage;
  static const Field<GetProjectsResponse, List<VersionUsageResponse>>
      _f$versionUsage = Field('versionUsage', _$versionUsage);
  static List<String> _$unreferencedVersions(GetProjectsResponse v) =>
      v.unreferencedVersions;
  static const Field<GetProjectsResponse, List<String>>
      _f$unreferencedVersions =
      Field('unreferencedVersions', _$unreferencedVersions);
  static List<String> _$missingVersions(GetProjectsResponse v) =>
      v.missingVersions;
  static const Field<GetProjectsResponse, List<String>> _f$missingVersions =
      Field('missingVersions', _$missingVersions);

  @override
  final MappableFields<GetProjectsResponse> fields = const {
    #projects: _f$projects,
    #versionUsage: _f$versionUsage,
    #unreferencedVersions: _f$unreferencedVersions,
    #missingVersions: _f$missingVersions,
  };

  static GetProjectsResponse _instantiate(DecodingData data) {
    return GetProjectsResponse(
        projects: data.dec(_f$projects),
        versionUsage: data.dec(_f$versionUsage),
        unreferencedVersions: data.dec(_f$unreferencedVersions),
        missingVersions: data.dec(_f$missingVersions));
  }

  @override
  final Function instantiate = _instantiate;

  static GetProjectsResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GetProjectsResponse>(map);
  }

  static GetProjectsResponse fromJson(String json) {
    return ensureInitialized().decodeJson<GetProjectsResponse>(json);
  }
}

mixin GetProjectsResponseMappable {
  String toJson() {
    return GetProjectsResponseMapper.ensureInitialized()
        .encodeJson<GetProjectsResponse>(this as GetProjectsResponse);
  }

  Map<String, dynamic> toMap() {
    return GetProjectsResponseMapper.ensureInitialized()
        .encodeMap<GetProjectsResponse>(this as GetProjectsResponse);
  }

  GetProjectsResponseCopyWith<GetProjectsResponse, GetProjectsResponse,
      GetProjectsResponse> get copyWith => _GetProjectsResponseCopyWithImpl<
          GetProjectsResponse, GetProjectsResponse>(
      this as GetProjectsResponse, $identity, $identity);
  @override
  String toString() {
    return GetProjectsResponseMapper.ensureInitialized()
        .stringifyValue(this as GetProjectsResponse);
  }

  @override
  bool operator ==(Object other) {
    return GetProjectsResponseMapper.ensureInitialized()
        .equalsValue(this as GetProjectsResponse, other);
  }

  @override
  int get hashCode {
    return GetProjectsResponseMapper.ensureInitialized()
        .hashValue(this as GetProjectsResponse);
  }
}

extension GetProjectsResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GetProjectsResponse, $Out> {
  GetProjectsResponseCopyWith<$R, GetProjectsResponse, $Out>
      get $asGetProjectsResponse => $base.as(
          (v, t, t2) => _GetProjectsResponseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GetProjectsResponseCopyWith<$R, $In extends GetProjectsResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
      $R,
      ProjectUsageResponse,
      ProjectUsageResponseCopyWith<$R, ProjectUsageResponse,
          ProjectUsageResponse>> get projects;
  ListCopyWith<
      $R,
      VersionUsageResponse,
      VersionUsageResponseCopyWith<$R, VersionUsageResponse,
          VersionUsageResponse>> get versionUsage;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get unreferencedVersions;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get missingVersions;
  $R call(
      {List<ProjectUsageResponse>? projects,
      List<VersionUsageResponse>? versionUsage,
      List<String>? unreferencedVersions,
      List<String>? missingVersions});
  GetProjectsResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GetProjectsResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GetProjectsResponse, $Out>
    implements GetProjectsResponseCopyWith<$R, GetProjectsResponse, $Out> {
  _GetProjectsResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GetProjectsResponse> $mapper =
      GetProjectsResponseMapper.ensureInitialized();
  @override
  ListCopyWith<
      $R,
      ProjectUsageResponse,
      ProjectUsageResponseCopyWith<$R, ProjectUsageResponse,
          ProjectUsageResponse>> get projects => ListCopyWith($value.projects,
      (v, t) => v.copyWith.$chain(t), (v) => call(projects: v));
  @override
  ListCopyWith<
      $R,
      VersionUsageResponse,
      VersionUsageResponseCopyWith<$R, VersionUsageResponse,
          VersionUsageResponse>> get versionUsage => ListCopyWith(
      $value.versionUsage,
      (v, t) => v.copyWith.$chain(t),
      (v) => call(versionUsage: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get unreferencedVersions => ListCopyWith(
          $value.unreferencedVersions,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(unreferencedVersions: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get missingVersions => ListCopyWith(
          $value.missingVersions,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(missingVersions: v));
  @override
  $R call(
          {List<ProjectUsageResponse>? projects,
          List<VersionUsageResponse>? versionUsage,
          List<String>? unreferencedVersions,
          List<String>? missingVersions}) =>
      $apply(FieldCopyWithData({
        if (projects != null) #projects: projects,
        if (versionUsage != null) #versionUsage: versionUsage,
        if (unreferencedVersions != null)
          #unreferencedVersions: unreferencedVersions,
        if (missingVersions != null) #missingVersions: missingVersions
      }));
  @override
  GetProjectsResponse $make(CopyWithData data) => GetProjectsResponse(
      projects: data.get(#projects, or: $value.projects),
      versionUsage: data.get(#versionUsage, or: $value.versionUsage),
      unreferencedVersions:
          data.get(#unreferencedVersions, or: $value.unreferencedVersions),
      missingVersions: data.get(#missingVersions, or: $value.missingVersions));

  @override
  GetProjectsResponseCopyWith<$R2, GetProjectsResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _GetProjectsResponseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
