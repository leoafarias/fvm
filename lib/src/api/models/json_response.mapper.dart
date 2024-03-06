// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
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
    }
    return _instance!;
  }

  @override
  final String id = 'APIResponse';
  @override
  Function get typeFactory => <TPayload>(f) => f<APIResponse<TPayload>>();

  static dynamic _$data(APIResponse v) => v.data;
  static dynamic _arg$data<TPayload>(f) => f<TPayload>();
  static const Field<APIResponse, dynamic> _f$data =
      Field('data', _$data, arg: _arg$data);

  @override
  final MappableFields<APIResponse> fields = const {
    #data: _f$data,
  };

  static APIResponse<TPayload> _instantiate<TPayload>(DecodingData data) {
    throw MapperException.missingConstructor('APIResponse');
  }

  @override
  final Function instantiate = _instantiate;

  static APIResponse<TPayload> fromMap<TPayload>(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<APIResponse<TPayload>>(map);
  }

  static APIResponse<TPayload> fromJson<TPayload>(String json) {
    return ensureInitialized().decodeJson<APIResponse<TPayload>>(json);
  }
}

mixin APIResponseMappable<TPayload> {
  String toJson();
  Map<String, dynamic> toMap();
  APIResponseCopyWith<APIResponse<TPayload>, APIResponse<TPayload>,
      APIResponse<TPayload>, TPayload> get copyWith;
}

abstract class APIResponseCopyWith<$R, $In extends APIResponse<TPayload>, $Out,
    TPayload> implements ClassCopyWith<$R, $In, $Out> {
  $R call({TPayload? data});
  APIResponseCopyWith<$R2, $In, $Out2, TPayload> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
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

  static List<CacheFlutterVersion> _$data(GetCacheVersionsResponse v) => v.data;
  static const Field<GetCacheVersionsResponse, List<CacheFlutterVersion>>
      _f$data = Field('data', _$data);

  @override
  final MappableFields<GetCacheVersionsResponse> fields = const {
    #data: _f$data,
  };

  static GetCacheVersionsResponse _instantiate(DecodingData data) {
    return GetCacheVersionsResponse(data: data.dec(_f$data));
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
      get copyWith => _GetCacheVersionsResponseCopyWithImpl(
          this as GetCacheVersionsResponse, $identity, $identity);
  @override
  String toString() {
    return GetCacheVersionsResponseMapper.ensureInitialized()
        .stringifyValue(this as GetCacheVersionsResponse);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            GetCacheVersionsResponseMapper.ensureInitialized()
                .isValueEqual(this as GetCacheVersionsResponse, other));
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
      get $asGetCacheVersionsResponse => $base
          .as((v, t, t2) => _GetCacheVersionsResponseCopyWithImpl(v, t, t2));
}

abstract class GetCacheVersionsResponseCopyWith<$R,
        $In extends GetCacheVersionsResponse, $Out>
    implements APIResponseCopyWith<$R, $In, $Out, List<CacheFlutterVersion>> {
  @override
  ListCopyWith<
      $R,
      CacheFlutterVersion,
      CacheFlutterVersionCopyWith<$R, CacheFlutterVersion,
          CacheFlutterVersion>> get data;
  @override
  $R call({List<CacheFlutterVersion>? data});
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
          CacheFlutterVersion>> get data => ListCopyWith(
      $value.data, (v, t) => v.copyWith.$chain(t), (v) => call(data: v));
  @override
  $R call({List<CacheFlutterVersion>? data}) =>
      $apply(FieldCopyWithData({if (data != null) #data: data}));
  @override
  GetCacheVersionsResponse $make(CopyWithData data) =>
      GetCacheVersionsResponse(data: data.get(#data, or: $value.data));

  @override
  GetCacheVersionsResponseCopyWith<$R2, GetCacheVersionsResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _GetCacheVersionsResponseCopyWithImpl($value, $cast, t);
}

class GetReleasesResponseMapper extends ClassMapperBase<GetReleasesResponse> {
  GetReleasesResponseMapper._();

  static GetReleasesResponseMapper? _instance;
  static GetReleasesResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GetReleasesResponseMapper._());
      APIResponseMapper.ensureInitialized();
      FlutterReleasesResponseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GetReleasesResponse';

  static FlutterReleasesResponse _$data(GetReleasesResponse v) => v.data;
  static const Field<GetReleasesResponse, FlutterReleasesResponse> _f$data =
      Field('data', _$data);

  @override
  final MappableFields<GetReleasesResponse> fields = const {
    #data: _f$data,
  };

  static GetReleasesResponse _instantiate(DecodingData data) {
    return GetReleasesResponse(data: data.dec(_f$data));
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
          GetReleasesResponse>
      get copyWith => _GetReleasesResponseCopyWithImpl(
          this as GetReleasesResponse, $identity, $identity);
  @override
  String toString() {
    return GetReleasesResponseMapper.ensureInitialized()
        .stringifyValue(this as GetReleasesResponse);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            GetReleasesResponseMapper.ensureInitialized()
                .isValueEqual(this as GetReleasesResponse, other));
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
      get $asGetReleasesResponse =>
          $base.as((v, t, t2) => _GetReleasesResponseCopyWithImpl(v, t, t2));
}

abstract class GetReleasesResponseCopyWith<$R, $In extends GetReleasesResponse,
        $Out>
    implements APIResponseCopyWith<$R, $In, $Out, FlutterReleasesResponse> {
  @override
  FlutterReleasesResponseCopyWith<$R, FlutterReleasesResponse,
      FlutterReleasesResponse> get data;
  @override
  $R call({FlutterReleasesResponse? data});
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
  FlutterReleasesResponseCopyWith<$R, FlutterReleasesResponse,
          FlutterReleasesResponse>
      get data => ($value.data as FlutterReleasesResponse)
          .copyWith
          .$chain((v) => call(data: v));
  @override
  $R call({FlutterReleasesResponse? data}) =>
      $apply(FieldCopyWithData({if (data != null) #data: data}));
  @override
  GetReleasesResponse $make(CopyWithData data) =>
      GetReleasesResponse(data: data.get(#data, or: $value.data));

  @override
  GetReleasesResponseCopyWith<$R2, GetReleasesResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _GetReleasesResponseCopyWithImpl($value, $cast, t);
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

  static Project _$data(GetProjectResponse v) => v.data;
  static const Field<GetProjectResponse, Project> _f$data =
      Field('data', _$data);

  @override
  final MappableFields<GetProjectResponse> fields = const {
    #data: _f$data,
  };

  static GetProjectResponse _instantiate(DecodingData data) {
    return GetProjectResponse(data: data.dec(_f$data));
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
      get copyWith => _GetProjectResponseCopyWithImpl(
          this as GetProjectResponse, $identity, $identity);
  @override
  String toString() {
    return GetProjectResponseMapper.ensureInitialized()
        .stringifyValue(this as GetProjectResponse);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            GetProjectResponseMapper.ensureInitialized()
                .isValueEqual(this as GetProjectResponse, other));
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
      get $asGetProjectResponse =>
          $base.as((v, t, t2) => _GetProjectResponseCopyWithImpl(v, t, t2));
}

abstract class GetProjectResponseCopyWith<$R, $In extends GetProjectResponse,
    $Out> implements APIResponseCopyWith<$R, $In, $Out, Project> {
  @override
  ProjectCopyWith<$R, Project, Project> get data;
  @override
  $R call({Project? data});
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
  ProjectCopyWith<$R, Project, Project> get data =>
      ($value.data as Project).copyWith.$chain((v) => call(data: v));
  @override
  $R call({Project? data}) =>
      $apply(FieldCopyWithData({if (data != null) #data: data}));
  @override
  GetProjectResponse $make(CopyWithData data) =>
      GetProjectResponse(data: data.get(#data, or: $value.data));

  @override
  GetProjectResponseCopyWith<$R2, GetProjectResponse, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GetProjectResponseCopyWithImpl($value, $cast, t);
}
