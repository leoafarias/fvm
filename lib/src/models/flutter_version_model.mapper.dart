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
      ReleaseVersionMapper.ensureInitialized();
      ChannelVersionMapper.ensureInitialized();
      CommitVersionMapper.ensureInitialized();
      CustomVersionMapper.ensureInitialized();
      VersionTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterVersion';

  static String _$name(FlutterVersion v) => v.name;
  static const Field<FlutterVersion, String> _f$name = Field('name', _$name);
  static VersionType _$type(FlutterVersion v) => v.type;
  static const Field<FlutterVersion, VersionType> _f$type =
      Field('type', _$type);

  @override
  final MappableFields<FlutterVersion> fields = const {
    #name: _f$name,
    #type: _f$type,
  };

  static FlutterVersion _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('FlutterVersion');
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
  String toJson();
  Map<String, dynamic> toMap();
  FlutterVersionCopyWith<FlutterVersion, FlutterVersion, FlutterVersion>
      get copyWith;
}

abstract class FlutterVersionCopyWith<$R, $In extends FlutterVersion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name});
  FlutterVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class ReleaseVersionMapper extends ClassMapperBase<ReleaseVersion> {
  ReleaseVersionMapper._();

  static ReleaseVersionMapper? _instance;
  static ReleaseVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ReleaseVersionMapper._());
      FlutterVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ReleaseVersion';

  static String _$name(ReleaseVersion v) => v.name;
  static const Field<ReleaseVersion, String> _f$name = Field('name', _$name);
  static String? _$fromChannel(ReleaseVersion v) => v.fromChannel;
  static const Field<ReleaseVersion, String> _f$fromChannel =
      Field('fromChannel', _$fromChannel, opt: true);
  static VersionType _$type(ReleaseVersion v) => v.type;
  static const Field<ReleaseVersion, VersionType> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<ReleaseVersion> fields = const {
    #name: _f$name,
    #fromChannel: _f$fromChannel,
    #type: _f$type,
  };

  static ReleaseVersion _instantiate(DecodingData data) {
    return ReleaseVersion(data.dec(_f$name),
        fromChannel: data.dec(_f$fromChannel));
  }

  @override
  final Function instantiate = _instantiate;

  static ReleaseVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ReleaseVersion>(map);
  }

  static ReleaseVersion fromJson(String json) {
    return ensureInitialized().decodeJson<ReleaseVersion>(json);
  }
}

mixin ReleaseVersionMappable {
  String toJson() {
    return ReleaseVersionMapper.ensureInitialized()
        .encodeJson<ReleaseVersion>(this as ReleaseVersion);
  }

  Map<String, dynamic> toMap() {
    return ReleaseVersionMapper.ensureInitialized()
        .encodeMap<ReleaseVersion>(this as ReleaseVersion);
  }

  ReleaseVersionCopyWith<ReleaseVersion, ReleaseVersion, ReleaseVersion>
      get copyWith => _ReleaseVersionCopyWithImpl(
          this as ReleaseVersion, $identity, $identity);
  @override
  String toString() {
    return ReleaseVersionMapper.ensureInitialized()
        .stringifyValue(this as ReleaseVersion);
  }

  @override
  bool operator ==(Object other) {
    return ReleaseVersionMapper.ensureInitialized()
        .equalsValue(this as ReleaseVersion, other);
  }

  @override
  int get hashCode {
    return ReleaseVersionMapper.ensureInitialized()
        .hashValue(this as ReleaseVersion);
  }
}

extension ReleaseVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ReleaseVersion, $Out> {
  ReleaseVersionCopyWith<$R, ReleaseVersion, $Out> get $asReleaseVersion =>
      $base.as((v, t, t2) => _ReleaseVersionCopyWithImpl(v, t, t2));
}

abstract class ReleaseVersionCopyWith<$R, $In extends ReleaseVersion, $Out>
    implements FlutterVersionCopyWith<$R, $In, $Out> {
  @override
  $R call({String? name, String? fromChannel});
  ReleaseVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ReleaseVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ReleaseVersion, $Out>
    implements ReleaseVersionCopyWith<$R, ReleaseVersion, $Out> {
  _ReleaseVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ReleaseVersion> $mapper =
      ReleaseVersionMapper.ensureInitialized();
  @override
  $R call({String? name, Object? fromChannel = $none}) =>
      $apply(FieldCopyWithData({
        if (name != null) #name: name,
        if (fromChannel != $none) #fromChannel: fromChannel
      }));
  @override
  ReleaseVersion $make(CopyWithData data) =>
      ReleaseVersion(data.get(#name, or: $value.name),
          fromChannel: data.get(#fromChannel, or: $value.fromChannel));

  @override
  ReleaseVersionCopyWith<$R2, ReleaseVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ReleaseVersionCopyWithImpl($value, $cast, t);
}

class ChannelVersionMapper extends ClassMapperBase<ChannelVersion> {
  ChannelVersionMapper._();

  static ChannelVersionMapper? _instance;
  static ChannelVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelVersionMapper._());
      FlutterVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ChannelVersion';

  static String _$name(ChannelVersion v) => v.name;
  static const Field<ChannelVersion, String> _f$name = Field('name', _$name);
  static VersionType _$type(ChannelVersion v) => v.type;
  static const Field<ChannelVersion, VersionType> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<ChannelVersion> fields = const {
    #name: _f$name,
    #type: _f$type,
  };

  static ChannelVersion _instantiate(DecodingData data) {
    return ChannelVersion(data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static ChannelVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChannelVersion>(map);
  }

  static ChannelVersion fromJson(String json) {
    return ensureInitialized().decodeJson<ChannelVersion>(json);
  }
}

mixin ChannelVersionMappable {
  String toJson() {
    return ChannelVersionMapper.ensureInitialized()
        .encodeJson<ChannelVersion>(this as ChannelVersion);
  }

  Map<String, dynamic> toMap() {
    return ChannelVersionMapper.ensureInitialized()
        .encodeMap<ChannelVersion>(this as ChannelVersion);
  }

  ChannelVersionCopyWith<ChannelVersion, ChannelVersion, ChannelVersion>
      get copyWith => _ChannelVersionCopyWithImpl(
          this as ChannelVersion, $identity, $identity);
  @override
  String toString() {
    return ChannelVersionMapper.ensureInitialized()
        .stringifyValue(this as ChannelVersion);
  }

  @override
  bool operator ==(Object other) {
    return ChannelVersionMapper.ensureInitialized()
        .equalsValue(this as ChannelVersion, other);
  }

  @override
  int get hashCode {
    return ChannelVersionMapper.ensureInitialized()
        .hashValue(this as ChannelVersion);
  }
}

extension ChannelVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChannelVersion, $Out> {
  ChannelVersionCopyWith<$R, ChannelVersion, $Out> get $asChannelVersion =>
      $base.as((v, t, t2) => _ChannelVersionCopyWithImpl(v, t, t2));
}

abstract class ChannelVersionCopyWith<$R, $In extends ChannelVersion, $Out>
    implements FlutterVersionCopyWith<$R, $In, $Out> {
  @override
  $R call({String? name});
  ChannelVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ChannelVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChannelVersion, $Out>
    implements ChannelVersionCopyWith<$R, ChannelVersion, $Out> {
  _ChannelVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChannelVersion> $mapper =
      ChannelVersionMapper.ensureInitialized();
  @override
  $R call({String? name}) =>
      $apply(FieldCopyWithData({if (name != null) #name: name}));
  @override
  ChannelVersion $make(CopyWithData data) =>
      ChannelVersion(data.get(#name, or: $value.name));

  @override
  ChannelVersionCopyWith<$R2, ChannelVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ChannelVersionCopyWithImpl($value, $cast, t);
}

class CommitVersionMapper extends ClassMapperBase<CommitVersion> {
  CommitVersionMapper._();

  static CommitVersionMapper? _instance;
  static CommitVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CommitVersionMapper._());
      FlutterVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CommitVersion';

  static String _$name(CommitVersion v) => v.name;
  static const Field<CommitVersion, String> _f$name = Field('name', _$name);
  static VersionType _$type(CommitVersion v) => v.type;
  static const Field<CommitVersion, VersionType> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<CommitVersion> fields = const {
    #name: _f$name,
    #type: _f$type,
  };

  static CommitVersion _instantiate(DecodingData data) {
    return CommitVersion(data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static CommitVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CommitVersion>(map);
  }

  static CommitVersion fromJson(String json) {
    return ensureInitialized().decodeJson<CommitVersion>(json);
  }
}

mixin CommitVersionMappable {
  String toJson() {
    return CommitVersionMapper.ensureInitialized()
        .encodeJson<CommitVersion>(this as CommitVersion);
  }

  Map<String, dynamic> toMap() {
    return CommitVersionMapper.ensureInitialized()
        .encodeMap<CommitVersion>(this as CommitVersion);
  }

  CommitVersionCopyWith<CommitVersion, CommitVersion, CommitVersion>
      get copyWith => _CommitVersionCopyWithImpl(
          this as CommitVersion, $identity, $identity);
  @override
  String toString() {
    return CommitVersionMapper.ensureInitialized()
        .stringifyValue(this as CommitVersion);
  }

  @override
  bool operator ==(Object other) {
    return CommitVersionMapper.ensureInitialized()
        .equalsValue(this as CommitVersion, other);
  }

  @override
  int get hashCode {
    return CommitVersionMapper.ensureInitialized()
        .hashValue(this as CommitVersion);
  }
}

extension CommitVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CommitVersion, $Out> {
  CommitVersionCopyWith<$R, CommitVersion, $Out> get $asCommitVersion =>
      $base.as((v, t, t2) => _CommitVersionCopyWithImpl(v, t, t2));
}

abstract class CommitVersionCopyWith<$R, $In extends CommitVersion, $Out>
    implements FlutterVersionCopyWith<$R, $In, $Out> {
  @override
  $R call({String? name});
  CommitVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CommitVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CommitVersion, $Out>
    implements CommitVersionCopyWith<$R, CommitVersion, $Out> {
  _CommitVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CommitVersion> $mapper =
      CommitVersionMapper.ensureInitialized();
  @override
  $R call({String? name}) =>
      $apply(FieldCopyWithData({if (name != null) #name: name}));
  @override
  CommitVersion $make(CopyWithData data) =>
      CommitVersion(data.get(#name, or: $value.name));

  @override
  CommitVersionCopyWith<$R2, CommitVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CommitVersionCopyWithImpl($value, $cast, t);
}

class CustomVersionMapper extends ClassMapperBase<CustomVersion> {
  CustomVersionMapper._();

  static CustomVersionMapper? _instance;
  static CustomVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CustomVersionMapper._());
      FlutterVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CustomVersion';

  static String _$name(CustomVersion v) => v.name;
  static const Field<CustomVersion, String> _f$name = Field('name', _$name);
  static VersionType _$type(CustomVersion v) => v.type;
  static const Field<CustomVersion, VersionType> _f$type =
      Field('type', _$type, mode: FieldMode.member);

  @override
  final MappableFields<CustomVersion> fields = const {
    #name: _f$name,
    #type: _f$type,
  };

  static CustomVersion _instantiate(DecodingData data) {
    return CustomVersion(data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static CustomVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CustomVersion>(map);
  }

  static CustomVersion fromJson(String json) {
    return ensureInitialized().decodeJson<CustomVersion>(json);
  }
}

mixin CustomVersionMappable {
  String toJson() {
    return CustomVersionMapper.ensureInitialized()
        .encodeJson<CustomVersion>(this as CustomVersion);
  }

  Map<String, dynamic> toMap() {
    return CustomVersionMapper.ensureInitialized()
        .encodeMap<CustomVersion>(this as CustomVersion);
  }

  CustomVersionCopyWith<CustomVersion, CustomVersion, CustomVersion>
      get copyWith => _CustomVersionCopyWithImpl(
          this as CustomVersion, $identity, $identity);
  @override
  String toString() {
    return CustomVersionMapper.ensureInitialized()
        .stringifyValue(this as CustomVersion);
  }

  @override
  bool operator ==(Object other) {
    return CustomVersionMapper.ensureInitialized()
        .equalsValue(this as CustomVersion, other);
  }

  @override
  int get hashCode {
    return CustomVersionMapper.ensureInitialized()
        .hashValue(this as CustomVersion);
  }
}

extension CustomVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CustomVersion, $Out> {
  CustomVersionCopyWith<$R, CustomVersion, $Out> get $asCustomVersion =>
      $base.as((v, t, t2) => _CustomVersionCopyWithImpl(v, t, t2));
}

abstract class CustomVersionCopyWith<$R, $In extends CustomVersion, $Out>
    implements FlutterVersionCopyWith<$R, $In, $Out> {
  @override
  $R call({String? name});
  CustomVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CustomVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CustomVersion, $Out>
    implements CustomVersionCopyWith<$R, CustomVersion, $Out> {
  _CustomVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CustomVersion> $mapper =
      CustomVersionMapper.ensureInitialized();
  @override
  $R call({String? name}) =>
      $apply(FieldCopyWithData({if (name != null) #name: name}));
  @override
  CustomVersion $make(CopyWithData data) =>
      CustomVersion(data.get(#name, or: $value.name));

  @override
  CustomVersionCopyWith<$R2, CustomVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CustomVersionCopyWithImpl($value, $cast, t);
}
