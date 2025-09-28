// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
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
      case r'release':
        return VersionType.release;
      case r'channel':
        return VersionType.channel;
      case r'unknownRef':
        return VersionType.unknownRef;
      case r'custom':
        return VersionType.custom;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(VersionType self) {
    switch (self) {
      case VersionType.release:
        return r'release';
      case VersionType.channel:
        return r'channel';
      case VersionType.unknownRef:
        return r'unknownRef';
      case VersionType.custom:
        return r'custom';
    }
  }
}

extension VersionTypeMapperExtension on VersionType {
  String toValue() {
    VersionTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<VersionType>(this) as String;
  }
}

class FlutterChannelMapper extends EnumMapper<FlutterChannel> {
  FlutterChannelMapper._();

  static FlutterChannelMapper? _instance;
  static FlutterChannelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterChannelMapper._());
    }
    return _instance!;
  }

  static FlutterChannel fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FlutterChannel decode(dynamic value) {
    switch (value) {
      case r'stable':
        return FlutterChannel.stable;
      case r'dev':
        return FlutterChannel.dev;
      case r'beta':
        return FlutterChannel.beta;
      case r'master':
        return FlutterChannel.master;
      case r'main':
        return FlutterChannel.main;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FlutterChannel self) {
    switch (self) {
      case FlutterChannel.stable:
        return r'stable';
      case FlutterChannel.dev:
        return r'dev';
      case FlutterChannel.beta:
        return r'beta';
      case FlutterChannel.master:
        return r'master';
      case FlutterChannel.main:
        return r'main';
    }
  }
}

extension FlutterChannelMapperExtension on FlutterChannel {
  String toValue() {
    FlutterChannelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FlutterChannel>(this) as String;
  }
}

class FlutterVersionMapper extends ClassMapperBase<FlutterVersion> {
  FlutterVersionMapper._();

  static FlutterVersionMapper? _instance;
  static FlutterVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterVersionMapper._());
      FlutterChannelMapper.ensureInitialized();
      VersionTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterVersion';

  static String _$name(FlutterVersion v) => v.name;
  static const Field<FlutterVersion, String> _f$name = Field('name', _$name);
  static FlutterChannel? _$releaseChannel(FlutterVersion v) => v.releaseChannel;
  static const Field<FlutterVersion, FlutterChannel> _f$releaseChannel =
      Field('releaseChannel', _$releaseChannel, opt: true);
  static VersionType _$type(FlutterVersion v) => v.type;
  static const Field<FlutterVersion, VersionType> _f$type =
      Field('type', _$type);
  static String? _$fork(FlutterVersion v) => v.fork;
  static const Field<FlutterVersion, String> _f$fork =
      Field('fork', _$fork, opt: true);

  @override
  final MappableFields<FlutterVersion> fields = const {
    #name: _f$name,
    #releaseChannel: _f$releaseChannel,
    #type: _f$type,
    #fork: _f$fork,
  };
  @override
  final bool ignoreNull = true;

  static FlutterVersion _instantiate(DecodingData data) {
    return FlutterVersion(data.dec(_f$name),
        releaseChannel: data.dec(_f$releaseChannel),
        type: data.dec(_f$type),
        fork: data.dec(_f$fork));
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
      get copyWith =>
          _FlutterVersionCopyWithImpl<FlutterVersion, FlutterVersion>(
              this as FlutterVersion, $identity, $identity);
  @override
  String toString() {
    return FlutterVersionMapper.ensureInitialized()
        .stringifyValue(this as FlutterVersion);
  }

  @override
  bool operator ==(Object other) {
    return FlutterVersionMapper.ensureInitialized()
        .equalsValue(this as FlutterVersion, other);
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
      $base.as((v, t, t2) => _FlutterVersionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FlutterVersionCopyWith<$R, $In extends FlutterVersion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? name,
      FlutterChannel? releaseChannel,
      VersionType? type,
      String? fork});
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
          Object? releaseChannel = $none,
          VersionType? type,
          Object? fork = $none}) =>
      $apply(FieldCopyWithData({
        if (name != null) #name: name,
        if (releaseChannel != $none) #releaseChannel: releaseChannel,
        if (type != null) #type: type,
        if (fork != $none) #fork: fork
      }));
  @override
  FlutterVersion $make(CopyWithData data) =>
      FlutterVersion(data.get(#name, or: $value.name),
          releaseChannel: data.get(#releaseChannel, or: $value.releaseChannel),
          type: data.get(#type, or: $value.type),
          fork: data.get(#fork, or: $value.fork));

  @override
  FlutterVersionCopyWith<$R2, FlutterVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FlutterVersionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FlutterForkMapper extends ClassMapperBase<FlutterFork> {
  FlutterForkMapper._();

  static FlutterForkMapper? _instance;
  static FlutterForkMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterForkMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterFork';

  static String _$name(FlutterFork v) => v.name;
  static const Field<FlutterFork, String> _f$name = Field('name', _$name);
  static String _$url(FlutterFork v) => v.url;
  static const Field<FlutterFork, String> _f$url = Field('url', _$url);

  @override
  final MappableFields<FlutterFork> fields = const {
    #name: _f$name,
    #url: _f$url,
  };
  @override
  final bool ignoreNull = true;

  static FlutterFork _instantiate(DecodingData data) {
    return FlutterFork(name: data.dec(_f$name), url: data.dec(_f$url));
  }

  @override
  final Function instantiate = _instantiate;

  static FlutterFork fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FlutterFork>(map);
  }

  static FlutterFork fromJson(String json) {
    return ensureInitialized().decodeJson<FlutterFork>(json);
  }
}

mixin FlutterForkMappable {
  String toJson() {
    return FlutterForkMapper.ensureInitialized()
        .encodeJson<FlutterFork>(this as FlutterFork);
  }

  Map<String, dynamic> toMap() {
    return FlutterForkMapper.ensureInitialized()
        .encodeMap<FlutterFork>(this as FlutterFork);
  }

  FlutterForkCopyWith<FlutterFork, FlutterFork, FlutterFork> get copyWith =>
      _FlutterForkCopyWithImpl<FlutterFork, FlutterFork>(
          this as FlutterFork, $identity, $identity);
  @override
  String toString() {
    return FlutterForkMapper.ensureInitialized()
        .stringifyValue(this as FlutterFork);
  }

  @override
  bool operator ==(Object other) {
    return FlutterForkMapper.ensureInitialized()
        .equalsValue(this as FlutterFork, other);
  }

  @override
  int get hashCode {
    return FlutterForkMapper.ensureInitialized().hashValue(this as FlutterFork);
  }
}

extension FlutterForkValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FlutterFork, $Out> {
  FlutterForkCopyWith<$R, FlutterFork, $Out> get $asFlutterFork =>
      $base.as((v, t, t2) => _FlutterForkCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FlutterForkCopyWith<$R, $In extends FlutterFork, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, String? url});
  FlutterForkCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FlutterForkCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FlutterFork, $Out>
    implements FlutterForkCopyWith<$R, FlutterFork, $Out> {
  _FlutterForkCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FlutterFork> $mapper =
      FlutterForkMapper.ensureInitialized();
  @override
  $R call({String? name, String? url}) => $apply(FieldCopyWithData(
      {if (name != null) #name: name, if (url != null) #url: url}));
  @override
  FlutterFork $make(CopyWithData data) => FlutterFork(
      name: data.get(#name, or: $value.name),
      url: data.get(#url, or: $value.url));

  @override
  FlutterForkCopyWith<$R2, FlutterFork, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FlutterForkCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
