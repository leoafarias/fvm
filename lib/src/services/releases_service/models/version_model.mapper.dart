// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'version_model.dart';

class FlutterSdkVersionMapper extends ClassMapperBase<FlutterSdkVersion> {
  FlutterSdkVersionMapper._();

  static FlutterSdkVersionMapper? _instance;
  static FlutterSdkVersionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterSdkVersionMapper._());
      FlutterChannelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterSdkVersion';

  static String _$hash(FlutterSdkVersion v) => v.hash;
  static const Field<FlutterSdkVersion, String> _f$hash = Field('hash', _$hash);
  static FlutterChannel _$channel(FlutterSdkVersion v) => v.channel;
  static const Field<FlutterSdkVersion, FlutterChannel> _f$channel =
      Field('channel', _$channel);
  static String _$version(FlutterSdkVersion v) => v.version;
  static const Field<FlutterSdkVersion, String> _f$version =
      Field('version', _$version);
  static DateTime _$releaseDate(FlutterSdkVersion v) => v.releaseDate;
  static const Field<FlutterSdkVersion, DateTime> _f$releaseDate =
      Field('releaseDate', _$releaseDate, key: 'release_date');
  static String _$archive(FlutterSdkVersion v) => v.archive;
  static const Field<FlutterSdkVersion, String> _f$archive =
      Field('archive', _$archive);
  static String _$sha256(FlutterSdkVersion v) => v.sha256;
  static const Field<FlutterSdkVersion, String> _f$sha256 =
      Field('sha256', _$sha256);
  static String? _$dartSdkArch(FlutterSdkVersion v) => v.dartSdkArch;
  static const Field<FlutterSdkVersion, String> _f$dartSdkArch =
      Field('dartSdkArch', _$dartSdkArch, key: 'dart_sdk_arch');
  static String? _$dartSdkVersion(FlutterSdkVersion v) => v.dartSdkVersion;
  static const Field<FlutterSdkVersion, String> _f$dartSdkVersion =
      Field('dartSdkVersion', _$dartSdkVersion, key: 'dart_sdk_version');
  static bool _$activeChannel(FlutterSdkVersion v) => v.activeChannel;
  static const Field<FlutterSdkVersion, bool> _f$activeChannel = Field(
      'activeChannel', _$activeChannel,
      key: 'active_channel', opt: true, def: false);
  static String _$channelName(FlutterSdkVersion v) => v.channelName;
  static const Field<FlutterSdkVersion, String> _f$channelName =
      Field('channelName', _$channelName);
  static String _$archiveUrl(FlutterSdkVersion v) => v.archiveUrl;
  static const Field<FlutterSdkVersion, String> _f$archiveUrl =
      Field('archiveUrl', _$archiveUrl);

  @override
  final MappableFields<FlutterSdkVersion> fields = const {
    #hash: _f$hash,
    #channel: _f$channel,
    #version: _f$version,
    #releaseDate: _f$releaseDate,
    #archive: _f$archive,
    #sha256: _f$sha256,
    #dartSdkArch: _f$dartSdkArch,
    #dartSdkVersion: _f$dartSdkVersion,
    #activeChannel: _f$activeChannel,
    #channelName: _f$channelName,
    #archiveUrl: _f$archiveUrl,
  };

  static FlutterSdkVersion _instantiate(DecodingData data) {
    return FlutterSdkVersion(
        hash: data.dec(_f$hash),
        channel: data.dec(_f$channel),
        version: data.dec(_f$version),
        releaseDate: data.dec(_f$releaseDate),
        archive: data.dec(_f$archive),
        sha256: data.dec(_f$sha256),
        dartSdkArch: data.dec(_f$dartSdkArch),
        dartSdkVersion: data.dec(_f$dartSdkVersion),
        activeChannel: data.dec(_f$activeChannel));
  }

  @override
  final Function instantiate = _instantiate;

  static FlutterSdkVersion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FlutterSdkVersion>(map);
  }

  static FlutterSdkVersion fromJson(String json) {
    return ensureInitialized().decodeJson<FlutterSdkVersion>(json);
  }
}

mixin FlutterSdkVersionMappable {
  String toJson() {
    return FlutterSdkVersionMapper.ensureInitialized()
        .encodeJson<FlutterSdkVersion>(this as FlutterSdkVersion);
  }

  Map<String, dynamic> toMap() {
    return FlutterSdkVersionMapper.ensureInitialized()
        .encodeMap<FlutterSdkVersion>(this as FlutterSdkVersion);
  }

  FlutterSdkVersionCopyWith<FlutterSdkVersion, FlutterSdkVersion,
          FlutterSdkVersion>
      get copyWith => _FlutterSdkVersionCopyWithImpl(
          this as FlutterSdkVersion, $identity, $identity);
  @override
  String toString() {
    return FlutterSdkVersionMapper.ensureInitialized()
        .stringifyValue(this as FlutterSdkVersion);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            FlutterSdkVersionMapper.ensureInitialized()
                .isValueEqual(this as FlutterSdkVersion, other));
  }

  @override
  int get hashCode {
    return FlutterSdkVersionMapper.ensureInitialized()
        .hashValue(this as FlutterSdkVersion);
  }
}

extension FlutterSdkVersionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FlutterSdkVersion, $Out> {
  FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, $Out>
      get $asFlutterSdkVersion =>
          $base.as((v, t, t2) => _FlutterSdkVersionCopyWithImpl(v, t, t2));
}

abstract class FlutterSdkVersionCopyWith<$R, $In extends FlutterSdkVersion,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? hash,
      FlutterChannel? channel,
      String? version,
      DateTime? releaseDate,
      String? archive,
      String? sha256,
      String? dartSdkArch,
      String? dartSdkVersion,
      bool? activeChannel});
  FlutterSdkVersionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _FlutterSdkVersionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FlutterSdkVersion, $Out>
    implements FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, $Out> {
  _FlutterSdkVersionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FlutterSdkVersion> $mapper =
      FlutterSdkVersionMapper.ensureInitialized();
  @override
  $R call(
          {String? hash,
          FlutterChannel? channel,
          String? version,
          DateTime? releaseDate,
          String? archive,
          String? sha256,
          Object? dartSdkArch = $none,
          Object? dartSdkVersion = $none,
          bool? activeChannel}) =>
      $apply(FieldCopyWithData({
        if (hash != null) #hash: hash,
        if (channel != null) #channel: channel,
        if (version != null) #version: version,
        if (releaseDate != null) #releaseDate: releaseDate,
        if (archive != null) #archive: archive,
        if (sha256 != null) #sha256: sha256,
        if (dartSdkArch != $none) #dartSdkArch: dartSdkArch,
        if (dartSdkVersion != $none) #dartSdkVersion: dartSdkVersion,
        if (activeChannel != null) #activeChannel: activeChannel
      }));
  @override
  FlutterSdkVersion $make(CopyWithData data) => FlutterSdkVersion(
      hash: data.get(#hash, or: $value.hash),
      channel: data.get(#channel, or: $value.channel),
      version: data.get(#version, or: $value.version),
      releaseDate: data.get(#releaseDate, or: $value.releaseDate),
      archive: data.get(#archive, or: $value.archive),
      sha256: data.get(#sha256, or: $value.sha256),
      dartSdkArch: data.get(#dartSdkArch, or: $value.dartSdkArch),
      dartSdkVersion: data.get(#dartSdkVersion, or: $value.dartSdkVersion),
      activeChannel: data.get(#activeChannel, or: $value.activeChannel));

  @override
  FlutterSdkVersionCopyWith<$R2, FlutterSdkVersion, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FlutterSdkVersionCopyWithImpl($value, $cast, t);
}

class ChannelsMapper extends ClassMapperBase<Channels> {
  ChannelsMapper._();

  static ChannelsMapper? _instance;
  static ChannelsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelsMapper._());
      FlutterSdkVersionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Channels';

  static FlutterSdkVersion _$beta(Channels v) => v.beta;
  static const Field<Channels, FlutterSdkVersion> _f$beta =
      Field('beta', _$beta);
  static FlutterSdkVersion _$dev(Channels v) => v.dev;
  static const Field<Channels, FlutterSdkVersion> _f$dev = Field('dev', _$dev);
  static FlutterSdkVersion _$stable(Channels v) => v.stable;
  static const Field<Channels, FlutterSdkVersion> _f$stable =
      Field('stable', _$stable);

  @override
  final MappableFields<Channels> fields = const {
    #beta: _f$beta,
    #dev: _f$dev,
    #stable: _f$stable,
  };

  static Channels _instantiate(DecodingData data) {
    return Channels(
        beta: data.dec(_f$beta),
        dev: data.dec(_f$dev),
        stable: data.dec(_f$stable));
  }

  @override
  final Function instantiate = _instantiate;

  static Channels fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Channels>(map);
  }

  static Channels fromJson(String json) {
    return ensureInitialized().decodeJson<Channels>(json);
  }
}

mixin ChannelsMappable {
  String toJson() {
    return ChannelsMapper.ensureInitialized()
        .encodeJson<Channels>(this as Channels);
  }

  Map<String, dynamic> toMap() {
    return ChannelsMapper.ensureInitialized()
        .encodeMap<Channels>(this as Channels);
  }

  ChannelsCopyWith<Channels, Channels, Channels> get copyWith =>
      _ChannelsCopyWithImpl(this as Channels, $identity, $identity);
  @override
  String toString() {
    return ChannelsMapper.ensureInitialized().stringifyValue(this as Channels);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            ChannelsMapper.ensureInitialized()
                .isValueEqual(this as Channels, other));
  }

  @override
  int get hashCode {
    return ChannelsMapper.ensureInitialized().hashValue(this as Channels);
  }
}

extension ChannelsValueCopy<$R, $Out> on ObjectCopyWith<$R, Channels, $Out> {
  ChannelsCopyWith<$R, Channels, $Out> get $asChannels =>
      $base.as((v, t, t2) => _ChannelsCopyWithImpl(v, t, t2));
}

abstract class ChannelsCopyWith<$R, $In extends Channels, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion> get beta;
  FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion> get dev;
  FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion>
      get stable;
  $R call(
      {FlutterSdkVersion? beta,
      FlutterSdkVersion? dev,
      FlutterSdkVersion? stable});
  ChannelsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChannelsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Channels, $Out>
    implements ChannelsCopyWith<$R, Channels, $Out> {
  _ChannelsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Channels> $mapper =
      ChannelsMapper.ensureInitialized();
  @override
  FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion>
      get beta => $value.beta.copyWith.$chain((v) => call(beta: v));
  @override
  FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion> get dev =>
      $value.dev.copyWith.$chain((v) => call(dev: v));
  @override
  FlutterSdkVersionCopyWith<$R, FlutterSdkVersion, FlutterSdkVersion>
      get stable => $value.stable.copyWith.$chain((v) => call(stable: v));
  @override
  $R call(
          {FlutterSdkVersion? beta,
          FlutterSdkVersion? dev,
          FlutterSdkVersion? stable}) =>
      $apply(FieldCopyWithData({
        if (beta != null) #beta: beta,
        if (dev != null) #dev: dev,
        if (stable != null) #stable: stable
      }));
  @override
  Channels $make(CopyWithData data) => Channels(
      beta: data.get(#beta, or: $value.beta),
      dev: data.get(#dev, or: $value.dev),
      stable: data.get(#stable, or: $value.stable));

  @override
  ChannelsCopyWith<$R2, Channels, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ChannelsCopyWithImpl($value, $cast, t);
}
