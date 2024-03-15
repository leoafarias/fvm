// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'flutter_version_model.dart';

class VersionTypeMapper extends EnumMapper<VersionType> {
  VersionTypeMapper._();

  static VersionTypeMapper? _instance;
  static VersionTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VersionTypeMapper._());
    }
    return _instance!;
  }

  static VersionType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  VersionType decode(dynamic value) {
    switch (value) {
      case 'release':
        return VersionType.release;
      case 'channel':
        return VersionType.channel;
      case 'commit':
        return VersionType.commit;
      case 'custom':
        return VersionType.custom;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(VersionType self) {
    switch (self) {
      case VersionType.release:
        return 'release';
      case VersionType.channel:
        return 'channel';
      case VersionType.commit:
        return 'commit';
      case VersionType.custom:
        return 'custom';
    }
  }
}

extension VersionTypeMapperExtension on VersionType {
  String toValue() {
    VersionTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<VersionType>(this) as String;
  }
}

class FlutterVersionMapper extends ClassMapperBase<FlutterVersion> {
  FlutterVersionMapper._();

  static FlutterVersionMapper? _instance;
  static FlutterVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterVersionMapper._());
      VersionTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterVersion';

  static String _$name(FlutterVersion v) => v.name;
  static const Field<FlutterVersion, String> _f$name = Field('name', _$name);
  static String? _$releaseFromChannel(FlutterVersion v) => v.releaseFromChannel;
  static const Field<FlutterVersion, String> _f$releaseFromChannel =
      Field('releaseFromChannel', _$releaseFromChannel, opt: true);
  static VersionType _$type(FlutterVersion v) => v.type;
  static const Field<FlutterVersion, VersionType> _f$type =
      Field('type', _$type);

  @override
  final MappableFields<FlutterVersion> fields = const {
    #name: _f$name,
    #releaseFromChannel: _f$releaseFromChannel,
    #type: _f$type,
  };

  static FlutterVersion _instantiate(DecodingData data) {
    return FlutterVersion(data.dec(_f$name),
        releaseFromChannel: data.dec(_f$releaseFromChannel),
        type: data.dec(_f$type));
  }

  @override
  final Function instantiate = _instantiate;

  static FlutterVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FlutterVersion>(map);
  }

  static FlutterVersion fromJson(String json) {
    return ensureInitialized().decodeJson<FlutterVersion>(json);
  }
}

mixin FlutterVersionMappable {
  String toJson() {
    return FlutterVersionMapper.ensureInitialized()
        .encodeJson<FlutterVersion>(this as FlutterVersion);
  }

  Map<String, dynamic> toMap() {
    return FlutterVersionMapper.ensureInitialized()
        .encodeMap<FlutterVersion>(this as FlutterVersion);
  }

  FlutterVersionCopyWith<FlutterVersion, FlutterVersion, FlutterVersion>
      get copyWith => _FlutterVersionCopyWithImpl(
          this as FlutterVersion, $identity, $identity);
  @override
  String toString() {
    return FlutterVersionMapper.ensureInitialized()
        .stringifyValue(this as FlutterVersion);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            FlutterVersionMapper.ensureInitialized()
                .isValueEqual(this as FlutterVersion, other));
  }

  @override
  int get hashCode {
    return FlutterVersionMapper.ensureInitialized()
        .hashValue(this as FlutterVersion);
  }
}

extension FlutterVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FlutterVersion, $Out> {
  FlutterVersionCopyWith<$R, FlutterVersion, $Out> get $asFlutterVersion =>
      $base.as((v, t, t2) => _FlutterVersionCopyWithImpl(v, t, t2));
}

abstract class FlutterVersionCopyWith<$R, $In extends FlutterVersion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, String? releaseFromChannel, VersionType? type});
  FlutterVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _FlutterVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FlutterVersion, $Out>
    implements FlutterVersionCopyWith<$R, FlutterVersion, $Out> {
  _FlutterVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FlutterVersion> $mapper =
      FlutterVersionMapper.ensureInitialized();
  @override
  $R call(
          {String? name,
          Object? releaseFromChannel = $none,
          VersionType? type}) =>
      $apply(FieldCopyWithData({
        if (name != null) #name: name,
        if (releaseFromChannel != $none)
          #releaseFromChannel: releaseFromChannel,
        if (type != null) #type: type
      }));
  @override
  FlutterVersion $make(CopyWithData data) =>
      FlutterVersion(data.get(#name, or: $value.name),
          releaseFromChannel:
              data.get(#releaseFromChannel, or: $value.releaseFromChannel),
          type: data.get(#type, or: $value.type));

  @override
  FlutterVersionCopyWith<$R2, FlutterVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FlutterVersionCopyWithImpl($value, $cast, t);
}
