// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'release.model.dart';

class ReleaseMapper extends ClassMapperBase<Release> {
  ReleaseMapper._();

  static ReleaseMapper? _instance;
  static ReleaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ReleaseMapper._());
      FlutterChannelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Release';

  static String _$hash(Release v) => v.hash;
  static const Field<Release, String> _f$hash = Field('hash', _$hash);
  static FlutterChannel _$channel(Release v) => v.channel;
  static const Field<Release, FlutterChannel> _f$channel =
      Field('channel', _$channel);
  static String _$version(Release v) => v.version;
  static const Field<Release, String> _f$version = Field('version', _$version);
  static DateTime _$releaseDate(Release v) => v.releaseDate;
  static const Field<Release, DateTime> _f$releaseDate =
      Field('releaseDate', _$releaseDate, key: 'release_date');
  static String _$archive(Release v) => v.archive;
  static const Field<Release, String> _f$archive = Field('archive', _$archive);
  static String _$sha256(Release v) => v.sha256;
  static const Field<Release, String> _f$sha256 = Field('sha256', _$sha256);
  static String? _$dartSdkArch(Release v) => v.dartSdkArch;
  static const Field<Release, String> _f$dartSdkArch =
      Field('dartSdkArch', _$dartSdkArch, key: 'dart_sdk_arch');
  static String? _$dartSdkVersion(Release v) => v.dartSdkVersion;
  static const Field<Release, String> _f$dartSdkVersion =
      Field('dartSdkVersion', _$dartSdkVersion, key: 'dart_sdk_version');
  static bool _$activeChannel(Release v) => v.activeChannel;
  static const Field<Release, bool> _f$activeChannel = Field(
      'activeChannel', _$activeChannel,
      key: 'active_channel', opt: true, def: false);
  static String _$channelName(Release v) => v.channelName;
  static const Field<Release, String> _f$channelName =
      Field('channelName', _$channelName);
  static String _$archiveUrl(Release v) => v.archiveUrl;
  static const Field<Release, String> _f$archiveUrl =
      Field('archiveUrl', _$archiveUrl);

  @override
  final MappableFields<Release> fields = const {
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

  static Release _instantiate(DecodingData data) {
    return Release(
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

  static Release fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Release>(map);
  }

  static Release fromJson(String json) {
    return ensureInitialized().decodeJson<Release>(json);
  }
}

mixin ReleaseMappable {
  String toJson() {
    return ReleaseMapper.ensureInitialized()
        .encodeJson<Release>(this as Release);
  }

  Map<String, dynamic> toMap() {
    return ReleaseMapper.ensureInitialized()
        .encodeMap<Release>(this as Release);
  }

  ReleaseCopyWith<Release, Release, Release> get copyWith =>
      _ReleaseCopyWithImpl(this as Release, $identity, $identity);
  @override
  String toString() {
    return ReleaseMapper.ensureInitialized().stringifyValue(this as Release);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            ReleaseMapper.ensureInitialized()
                .isValueEqual(this as Release, other));
  }

  @override
  int get hashCode {
    return ReleaseMapper.ensureInitialized().hashValue(this as Release);
  }
}

extension ReleaseValueCopy<$R, $Out> on ObjectCopyWith<$R, Release, $Out> {
  ReleaseCopyWith<$R, Release, $Out> get $asRelease =>
      $base.as((v, t, t2) => _ReleaseCopyWithImpl(v, t, t2));
}

abstract class ReleaseCopyWith<$R, $In extends Release, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
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
  ReleaseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ReleaseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Release, $Out>
    implements ReleaseCopyWith<$R, Release, $Out> {
  _ReleaseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Release> $mapper =
      ReleaseMapper.ensureInitialized();
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
  Release $make(CopyWithData data) => Release(
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
  ReleaseCopyWith<$R2, Release, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ReleaseCopyWithImpl($value, $cast, t);
}

class ChannelsMapper extends ClassMapperBase<Channels> {
  ChannelsMapper._();

  static ChannelsMapper? _instance;
  static ChannelsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelsMapper._());
      ReleaseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Channels';

  static Release _$beta(Channels v) => v.beta;
  static const Field<Channels, Release> _f$beta = Field('beta', _$beta);
  static Release _$dev(Channels v) => v.dev;
  static const Field<Channels, Release> _f$dev = Field('dev', _$dev);
  static Release _$stable(Channels v) => v.stable;
  static const Field<Channels, Release> _f$stable = Field('stable', _$stable);

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
  ReleaseCopyWith<$R, Release, Release> get beta;
  ReleaseCopyWith<$R, Release, Release> get dev;
  ReleaseCopyWith<$R, Release, Release> get stable;
  $R call({Release? beta, Release? dev, Release? stable});
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
  ReleaseCopyWith<$R, Release, Release> get beta =>
      $value.beta.copyWith.$chain((v) => call(beta: v));
  @override
  ReleaseCopyWith<$R, Release, Release> get dev =>
      $value.dev.copyWith.$chain((v) => call(dev: v));
  @override
  ReleaseCopyWith<$R, Release, Release> get stable =>
      $value.stable.copyWith.$chain((v) => call(stable: v));
  @override
  $R call({Release? beta, Release? dev, Release? stable}) =>
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
