// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'version_model.dart';

class FlutterSdkReleaseMapper extends ClassMapperBase<FlutterSdkRelease> {
  FlutterSdkReleaseMapper._();

  static FlutterSdkReleaseMapper? _instance;
  static FlutterSdkReleaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterSdkReleaseMapper._());
      FlutterChannelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterSdkRelease';

  static String _$hash(FlutterSdkRelease v) => v.hash;
  static const Field<FlutterSdkRelease, String> _f$hash = Field('hash', _$hash);
  static FlutterChannel _$channel(FlutterSdkRelease v) => v.channel;
  static const Field<FlutterSdkRelease, FlutterChannel> _f$channel = Field(
    'channel',
    _$channel,
  );
  static String _$version(FlutterSdkRelease v) => v.version;
  static const Field<FlutterSdkRelease, String> _f$version = Field(
    'version',
    _$version,
  );
  static DateTime _$releaseDate(FlutterSdkRelease v) => v.releaseDate;
  static const Field<FlutterSdkRelease, DateTime> _f$releaseDate = Field(
    'releaseDate',
    _$releaseDate,
    key: r'release_date',
  );
  static String _$archive(FlutterSdkRelease v) => v.archive;
  static const Field<FlutterSdkRelease, String> _f$archive = Field(
    'archive',
    _$archive,
  );
  static String _$sha256(FlutterSdkRelease v) => v.sha256;
  static const Field<FlutterSdkRelease, String> _f$sha256 = Field(
    'sha256',
    _$sha256,
  );
  static String? _$dartSdkArch(FlutterSdkRelease v) => v.dartSdkArch;
  static const Field<FlutterSdkRelease, String> _f$dartSdkArch = Field(
    'dartSdkArch',
    _$dartSdkArch,
    key: r'dart_sdk_arch',
  );
  static String? _$dartSdkVersion(FlutterSdkRelease v) => v.dartSdkVersion;
  static const Field<FlutterSdkRelease, String> _f$dartSdkVersion = Field(
    'dartSdkVersion',
    _$dartSdkVersion,
    key: r'dart_sdk_version',
  );
  static bool _$activeChannel(FlutterSdkRelease v) => v.activeChannel;
  static const Field<FlutterSdkRelease, bool> _f$activeChannel = Field(
    'activeChannel',
    _$activeChannel,
    key: r'active_channel',
    opt: true,
    def: false,
  );
  static String _$channelName(FlutterSdkRelease v) => v.channelName;
  static const Field<FlutterSdkRelease, String> _f$channelName = Field(
    'channelName',
    _$channelName,
  );
  static String _$archiveUrl(FlutterSdkRelease v) => v.archiveUrl;
  static const Field<FlutterSdkRelease, String> _f$archiveUrl = Field(
    'archiveUrl',
    _$archiveUrl,
  );

  @override
  final MappableFields<FlutterSdkRelease> fields = const {
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

  static FlutterSdkRelease _instantiate(DecodingData data) {
    return FlutterSdkRelease(
      hash: data.dec(_f$hash),
      channel: data.dec(_f$channel),
      version: data.dec(_f$version),
      releaseDate: data.dec(_f$releaseDate),
      archive: data.dec(_f$archive),
      sha256: data.dec(_f$sha256),
      dartSdkArch: data.dec(_f$dartSdkArch),
      dartSdkVersion: data.dec(_f$dartSdkVersion),
      activeChannel: data.dec(_f$activeChannel),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FlutterSdkRelease fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FlutterSdkRelease>(map);
  }

  static FlutterSdkRelease fromJson(String json) {
    return ensureInitialized().decodeJson<FlutterSdkRelease>(json);
  }
}

mixin FlutterSdkReleaseMappable {
  String toJson() {
    return FlutterSdkReleaseMapper.ensureInitialized()
        .encodeJson<FlutterSdkRelease>(this as FlutterSdkRelease);
  }

  Map<String, dynamic> toMap() {
    return FlutterSdkReleaseMapper.ensureInitialized()
        .encodeMap<FlutterSdkRelease>(this as FlutterSdkRelease);
  }

  FlutterSdkReleaseCopyWith<FlutterSdkRelease, FlutterSdkRelease,
          FlutterSdkRelease>
      get copyWith =>
          _FlutterSdkReleaseCopyWithImpl<FlutterSdkRelease, FlutterSdkRelease>(
            this as FlutterSdkRelease,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return FlutterSdkReleaseMapper.ensureInitialized().stringifyValue(
      this as FlutterSdkRelease,
    );
  }

  @override
  bool operator ==(Object other) {
    return FlutterSdkReleaseMapper.ensureInitialized().equalsValue(
      this as FlutterSdkRelease,
      other,
    );
  }

  @override
  int get hashCode {
    return FlutterSdkReleaseMapper.ensureInitialized().hashValue(
      this as FlutterSdkRelease,
    );
  }
}

extension FlutterSdkReleaseValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FlutterSdkRelease, $Out> {
  FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, $Out>
      get $asFlutterSdkRelease => $base.as(
            (v, t, t2) => _FlutterSdkReleaseCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

abstract class FlutterSdkReleaseCopyWith<$R, $In extends FlutterSdkRelease,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? hash,
    FlutterChannel? channel,
    String? version,
    DateTime? releaseDate,
    String? archive,
    String? sha256,
    String? dartSdkArch,
    String? dartSdkVersion,
    bool? activeChannel,
  });
  FlutterSdkReleaseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FlutterSdkReleaseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FlutterSdkRelease, $Out>
    implements FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, $Out> {
  _FlutterSdkReleaseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FlutterSdkRelease> $mapper =
      FlutterSdkReleaseMapper.ensureInitialized();
  @override
  $R call({
    String? hash,
    FlutterChannel? channel,
    String? version,
    DateTime? releaseDate,
    String? archive,
    String? sha256,
    Object? dartSdkArch = $none,
    Object? dartSdkVersion = $none,
    bool? activeChannel,
  }) =>
      $apply(
        FieldCopyWithData({
          if (hash != null) #hash: hash,
          if (channel != null) #channel: channel,
          if (version != null) #version: version,
          if (releaseDate != null) #releaseDate: releaseDate,
          if (archive != null) #archive: archive,
          if (sha256 != null) #sha256: sha256,
          if (dartSdkArch != $none) #dartSdkArch: dartSdkArch,
          if (dartSdkVersion != $none) #dartSdkVersion: dartSdkVersion,
          if (activeChannel != null) #activeChannel: activeChannel,
        }),
      );
  @override
  FlutterSdkRelease $make(CopyWithData data) => FlutterSdkRelease(
        hash: data.get(#hash, or: $value.hash),
        channel: data.get(#channel, or: $value.channel),
        version: data.get(#version, or: $value.version),
        releaseDate: data.get(#releaseDate, or: $value.releaseDate),
        archive: data.get(#archive, or: $value.archive),
        sha256: data.get(#sha256, or: $value.sha256),
        dartSdkArch: data.get(#dartSdkArch, or: $value.dartSdkArch),
        dartSdkVersion: data.get(#dartSdkVersion, or: $value.dartSdkVersion),
        activeChannel: data.get(#activeChannel, or: $value.activeChannel),
      );

  @override
  FlutterSdkReleaseCopyWith<$R2, FlutterSdkRelease, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _FlutterSdkReleaseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ChannelsMapper extends ClassMapperBase<Channels> {
  ChannelsMapper._();

  static ChannelsMapper? _instance;
  static ChannelsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelsMapper._());
      FlutterSdkReleaseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Channels';

  static FlutterSdkRelease _$beta(Channels v) => v.beta;
  static const Field<Channels, FlutterSdkRelease> _f$beta = Field(
    'beta',
    _$beta,
  );
  static FlutterSdkRelease _$dev(Channels v) => v.dev;
  static const Field<Channels, FlutterSdkRelease> _f$dev = Field('dev', _$dev);
  static FlutterSdkRelease _$stable(Channels v) => v.stable;
  static const Field<Channels, FlutterSdkRelease> _f$stable = Field(
    'stable',
    _$stable,
  );

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
      stable: data.dec(_f$stable),
    );
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
    return ChannelsMapper.ensureInitialized().encodeJson<Channels>(
      this as Channels,
    );
  }

  Map<String, dynamic> toMap() {
    return ChannelsMapper.ensureInitialized().encodeMap<Channels>(
      this as Channels,
    );
  }

  ChannelsCopyWith<Channels, Channels, Channels> get copyWith =>
      _ChannelsCopyWithImpl<Channels, Channels>(
        this as Channels,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChannelsMapper.ensureInitialized().stringifyValue(this as Channels);
  }

  @override
  bool operator ==(Object other) {
    return ChannelsMapper.ensureInitialized().equalsValue(
      this as Channels,
      other,
    );
  }

  @override
  int get hashCode {
    return ChannelsMapper.ensureInitialized().hashValue(this as Channels);
  }
}

extension ChannelsValueCopy<$R, $Out> on ObjectCopyWith<$R, Channels, $Out> {
  ChannelsCopyWith<$R, Channels, $Out> get $asChannels =>
      $base.as((v, t, t2) => _ChannelsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChannelsCopyWith<$R, $In extends Channels, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease> get beta;
  FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease> get dev;
  FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease>
      get stable;
  $R call({
    FlutterSdkRelease? beta,
    FlutterSdkRelease? dev,
    FlutterSdkRelease? stable,
  });
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
  FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease>
      get beta => $value.beta.copyWith.$chain((v) => call(beta: v));
  @override
  FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease> get dev =>
      $value.dev.copyWith.$chain((v) => call(dev: v));
  @override
  FlutterSdkReleaseCopyWith<$R, FlutterSdkRelease, FlutterSdkRelease>
      get stable => $value.stable.copyWith.$chain((v) => call(stable: v));
  @override
  $R call({
    FlutterSdkRelease? beta,
    FlutterSdkRelease? dev,
    FlutterSdkRelease? stable,
  }) =>
      $apply(
        FieldCopyWithData({
          if (beta != null) #beta: beta,
          if (dev != null) #dev: dev,
          if (stable != null) #stable: stable,
        }),
      );
  @override
  Channels $make(CopyWithData data) => Channels(
        beta: data.get(#beta, or: $value.beta),
        dev: data.get(#dev, or: $value.dev),
        stable: data.get(#stable, or: $value.stable),
      );

  @override
  ChannelsCopyWith<$R2, Channels, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _ChannelsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
