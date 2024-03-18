// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'cache_flutter_version_model.dart';

class CacheFlutterVersionMapper extends ClassMapperBase<CacheFlutterVersion> {
  CacheFlutterVersionMapper._();

  static CacheFlutterVersionMapper? _instance;
  static CacheFlutterVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CacheFlutterVersionMapper._());
      FlutterVersionMapper.ensureInitialized();
      VersionTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CacheFlutterVersion';

  static String _$name(CacheFlutterVersion v) => v.name;
  static const Field<CacheFlutterVersion, String> _f$name =
      Field('name', _$name);
  static String _$directory(CacheFlutterVersion v) => v.directory;
  static const Field<CacheFlutterVersion, String> _f$directory =
      Field('directory', _$directory);
  static String? _$releaseFromChannel(CacheFlutterVersion v) =>
      v.releaseFromChannel;
  static const Field<CacheFlutterVersion, String> _f$releaseFromChannel =
      Field('releaseFromChannel', _$releaseFromChannel);
  static VersionType _$type(CacheFlutterVersion v) => v.type;
  static const Field<CacheFlutterVersion, VersionType> _f$type =
      Field('type', _$type);
  static String _$binPath(CacheFlutterVersion v) => v.binPath;
  static const Field<CacheFlutterVersion, String> _f$binPath =
      Field('binPath', _$binPath);
  static bool _$hasOldBinPath(CacheFlutterVersion v) => v.hasOldBinPath;
  static const Field<CacheFlutterVersion, bool> _f$hasOldBinPath =
      Field('hasOldBinPath', _$hasOldBinPath);
  static String _$dartBinPath(CacheFlutterVersion v) => v.dartBinPath;
  static const Field<CacheFlutterVersion, String> _f$dartBinPath =
      Field('dartBinPath', _$dartBinPath);
  static String _$dartExec(CacheFlutterVersion v) => v.dartExec;
  static const Field<CacheFlutterVersion, String> _f$dartExec =
      Field('dartExec', _$dartExec);
  static String _$flutterExec(CacheFlutterVersion v) => v.flutterExec;
  static const Field<CacheFlutterVersion, String> _f$flutterExec =
      Field('flutterExec', _$flutterExec);
  static String? _$flutterSdkVersion(CacheFlutterVersion v) =>
      v.flutterSdkVersion;
  static const Field<CacheFlutterVersion, String> _f$flutterSdkVersion =
      Field('flutterSdkVersion', _$flutterSdkVersion);
  static String? _$dartSdkVersion(CacheFlutterVersion v) => v.dartSdkVersion;
  static const Field<CacheFlutterVersion, String> _f$dartSdkVersion =
      Field('dartSdkVersion', _$dartSdkVersion);
  static bool _$isSetup(CacheFlutterVersion v) => v.isSetup;
  static const Field<CacheFlutterVersion, bool> _f$isSetup =
      Field('isSetup', _$isSetup);

  @override
  final MappableFields<CacheFlutterVersion> fields = const {
    #name: _f$name,
    #directory: _f$directory,
    #releaseFromChannel: _f$releaseFromChannel,
    #type: _f$type,
    #binPath: _f$binPath,
    #hasOldBinPath: _f$hasOldBinPath,
    #dartBinPath: _f$dartBinPath,
    #dartExec: _f$dartExec,
    #flutterExec: _f$flutterExec,
    #flutterSdkVersion: _f$flutterSdkVersion,
    #dartSdkVersion: _f$dartSdkVersion,
    #isSetup: _f$isSetup,
  };

  static CacheFlutterVersion _instantiate(DecodingData data) {
    return CacheFlutterVersion.raw(data.dec(_f$name),
        directory: data.dec(_f$directory),
        releaseFromChannel: data.dec(_f$releaseFromChannel),
        type: data.dec(_f$type));
  }

  @override
  final Function instantiate = _instantiate;

  static CacheFlutterVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CacheFlutterVersion>(map);
  }

  static CacheFlutterVersion fromJson(String json) {
    return ensureInitialized().decodeJson<CacheFlutterVersion>(json);
  }
}

mixin CacheFlutterVersionMappable {
  String toJson() {
    return CacheFlutterVersionMapper.ensureInitialized()
        .encodeJson<CacheFlutterVersion>(this as CacheFlutterVersion);
  }

  Map<String, dynamic> toMap() {
    return CacheFlutterVersionMapper.ensureInitialized()
        .encodeMap<CacheFlutterVersion>(this as CacheFlutterVersion);
  }

  CacheFlutterVersionCopyWith<CacheFlutterVersion, CacheFlutterVersion,
          CacheFlutterVersion>
      get copyWith => _CacheFlutterVersionCopyWithImpl(
          this as CacheFlutterVersion, $identity, $identity);
  @override
  String toString() {
    return CacheFlutterVersionMapper.ensureInitialized()
        .stringifyValue(this as CacheFlutterVersion);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            CacheFlutterVersionMapper.ensureInitialized()
                .isValueEqual(this as CacheFlutterVersion, other));
  }

  @override
  int get hashCode {
    return CacheFlutterVersionMapper.ensureInitialized()
        .hashValue(this as CacheFlutterVersion);
  }
}

extension CacheFlutterVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CacheFlutterVersion, $Out> {
  CacheFlutterVersionCopyWith<$R, CacheFlutterVersion, $Out>
      get $asCacheFlutterVersion =>
          $base.as((v, t, t2) => _CacheFlutterVersionCopyWithImpl(v, t, t2));
}

abstract class CacheFlutterVersionCopyWith<$R, $In extends CacheFlutterVersion,
    $Out> implements FlutterVersionCopyWith<$R, $In, $Out> {
  @override
  $R call(
      {String? name,
      String? directory,
      String? releaseFromChannel,
      VersionType? type});
  CacheFlutterVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _CacheFlutterVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CacheFlutterVersion, $Out>
    implements CacheFlutterVersionCopyWith<$R, CacheFlutterVersion, $Out> {
  _CacheFlutterVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CacheFlutterVersion> $mapper =
      CacheFlutterVersionMapper.ensureInitialized();
  @override
  $R call(
          {String? name,
          String? directory,
          Object? releaseFromChannel = $none,
          VersionType? type}) =>
      $apply(FieldCopyWithData({
        if (name != null) #name: name,
        if (directory != null) #directory: directory,
        if (releaseFromChannel != $none)
          #releaseFromChannel: releaseFromChannel,
        if (type != null) #type: type
      }));
  @override
  CacheFlutterVersion $make(CopyWithData data) =>
      CacheFlutterVersion.raw(data.get(#name, or: $value.name),
          directory: data.get(#directory, or: $value.directory),
          releaseFromChannel:
              data.get(#releaseFromChannel, or: $value.releaseFromChannel),
          type: data.get(#type, or: $value.type));

  @override
  CacheFlutterVersionCopyWith<$R2, CacheFlutterVersion, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _CacheFlutterVersionCopyWithImpl($value, $cast, t);
}
