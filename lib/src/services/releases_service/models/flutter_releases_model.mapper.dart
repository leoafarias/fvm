// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'flutter_releases_model.dart';

class FlutterReleasesResponseMapper
    extends ClassMapperBase<FlutterReleasesResponse> {
  FlutterReleasesResponseMapper._();

  static FlutterReleasesResponseMapper? _instance;
  static FlutterReleasesResponseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals
          .use(_instance = FlutterReleasesResponseMapper._());
      ChannelsMapper.ensureInitialized();
      FlutterSdkVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterReleasesResponse';

  static String _$baseUrl(FlutterReleasesResponse v) => v.baseUrl;
  static const Field<FlutterReleasesResponse, String> _f$baseUrl =
      Field('baseUrl', _$baseUrl);
  static Channels _$channels(FlutterReleasesResponse v) => v.channels;
  static const Field<FlutterReleasesResponse, Channels> _f$channels =
      Field('channels', _$channels);
  static List<FlutterSdkVersion> _$versions(FlutterReleasesResponse v) =>
      v.versions;
  static const Field<FlutterReleasesResponse, List<FlutterSdkVersion>>
      _f$versions = Field('versions', _$versions);
  static Map<String, FlutterSdkVersion> _$_versionReleaseMap(
          FlutterReleasesResponse v) =>
      v._versionReleaseMap;
  static const Field<FlutterReleasesResponse, Map<String, FlutterSdkVersion>>
      _f$_versionReleaseMap = Field('_versionReleaseMap', _$_versionReleaseMap,
          key: 'versionReleaseMap');

  @override
  final MappableFields<FlutterReleasesResponse> fields = const {
    #baseUrl: _f$baseUrl,
    #channels: _f$channels,
    #versions: _f$versions,
    #_versionReleaseMap: _f$_versionReleaseMap,
  };

  static FlutterReleasesResponse _instantiate(DecodingData data) {
    return FlutterReleasesResponse(
        baseUrl: data.dec(_f$baseUrl),
        channels: data.dec(_f$channels),
        versions: data.dec(_f$versions),
        versionReleaseMap: data.dec(_f$_versionReleaseMap));
  }

  @override
  final Function instantiate = _instantiate;

  static FlutterReleasesResponse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FlutterReleasesResponse>(map);
  }

  static FlutterReleasesResponse fromJson(String json) {
    return ensureInitialized().decodeJson<FlutterReleasesResponse>(json);
  }
}

mixin FlutterReleasesResponseMappable {
  String toJson() {
    return FlutterReleasesResponseMapper.ensureInitialized()
        .encodeJson<FlutterReleasesResponse>(this as FlutterReleasesResponse);
  }

  Map<String, dynamic> toMap() {
    return FlutterReleasesResponseMapper.ensureInitialized()
        .encodeMap<FlutterReleasesResponse>(this as FlutterReleasesResponse);
  }

  FlutterReleasesResponseCopyWith<FlutterReleasesResponse,
          FlutterReleasesResponse, FlutterReleasesResponse>
      get copyWith => _FlutterReleasesResponseCopyWithImpl(
          this as FlutterReleasesResponse, $identity, $identity);
  @override
  String toString() {
    return FlutterReleasesResponseMapper.ensureInitialized()
        .stringifyValue(this as FlutterReleasesResponse);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            FlutterReleasesResponseMapper.ensureInitialized()
                .isValueEqual(this as FlutterReleasesResponse, other));
  }

  @override
  int get hashCode {
    return FlutterReleasesResponseMapper.ensureInitialized()
        .hashValue(this as FlutterReleasesResponse);
  }
}

extension FlutterReleasesResponseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FlutterReleasesResponse, $Out> {
  FlutterReleasesResponseCopyWith<$R, FlutterReleasesResponse, $Out>
      get $asFlutterReleasesResponse => $base
          .as((v, t, t2) => _FlutterReleasesResponseCopyWithImpl(v, t, t2));
}

abstract class FlutterReleasesResponseCopyWith<
    $R,
    $In extends FlutterReleasesResponse,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ChannelsCopyWith<$R, Channels, Channels> get channels;
  ListCopyWith<$R, FlutterSdkVersion,
          FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion>>
      get versions;
  MapCopyWith<$R, String, FlutterSdkVersion,
          FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion>>
      get _versionReleaseMap;
  $R call(
      {String? baseUrl,
      Channels? channels,
      List<FlutterSdkVersion>? versions,
      Map<String, FlutterSdkVersion>? versionReleaseMap});
  FlutterReleasesResponseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _FlutterReleasesResponseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FlutterReleasesResponse, $Out>
    implements
        FlutterReleasesResponseCopyWith<$R, FlutterReleasesResponse, $Out> {
  _FlutterReleasesResponseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FlutterReleasesResponse> $mapper =
      FlutterReleasesResponseMapper.ensureInitialized();
  @override
  ChannelsCopyWith<$R, Channels, Channels> get channels =>
      $value.channels.copyWith.$chain((v) => call(channels: v));
  @override
  ListCopyWith<$R, FlutterSdkVersion,
          FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion>>
      get versions => ListCopyWith($value.versions,
          (v, t) => v.copyWith.$chain(t), (v) => call(versions: v));
  @override
  MapCopyWith<$R, String, FlutterSdkVersion,
          FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion>>
      get _versionReleaseMap => MapCopyWith($value._versionReleaseMap,
          (v, t) => v.copyWith.$chain(t), (v) => call(versionReleaseMap: v));
  @override
  $R call(
          {String? baseUrl,
          Channels? channels,
          List<FlutterSdkVersion>? versions,
          Map<String, FlutterSdkVersion>? versionReleaseMap}) =>
      $apply(FieldCopyWithData({
        if (baseUrl != null) #baseUrl: baseUrl,
        if (channels != null) #channels: channels,
        if (versions != null) #versions: versions,
        if (versionReleaseMap != null) #versionReleaseMap: versionReleaseMap
      }));
  @override
  FlutterReleasesResponse $make(CopyWithData data) => FlutterReleasesResponse(
      baseUrl: data.get(#baseUrl, or: $value.baseUrl),
      channels: data.get(#channels, or: $value.channels),
      versions: data.get(#versions, or: $value.versions),
      versionReleaseMap:
          data.get(#versionReleaseMap, or: $value._versionReleaseMap));

  @override
  FlutterReleasesResponseCopyWith<$R2, FlutterReleasesResponse, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _FlutterReleasesResponseCopyWithImpl($value, $cast, t);
}
