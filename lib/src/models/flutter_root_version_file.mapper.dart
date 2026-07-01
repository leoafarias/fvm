// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'flutter_root_version_file.dart';

class FlutterRootVersionFileMapper
    extends ClassMapperBase<FlutterRootVersionFile> {
  FlutterRootVersionFileMapper._();

  static FlutterRootVersionFileMapper? _instance;
  static FlutterRootVersionFileMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FlutterRootVersionFileMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FlutterRootVersionFile';

  static String? _$frameworkVersion(FlutterRootVersionFile v) =>
      v.frameworkVersion;
  static const Field<FlutterRootVersionFile, String> _f$frameworkVersion =
      Field('frameworkVersion', _$frameworkVersion, opt: true);
  static String? _$flutterVersion(FlutterRootVersionFile v) => v.flutterVersion;
  static const Field<FlutterRootVersionFile, String> _f$flutterVersion =
      Field('flutterVersion', _$flutterVersion, opt: true);
  static String? _$channel(FlutterRootVersionFile v) => v.channel;
  static const Field<FlutterRootVersionFile, String> _f$channel =
      Field('channel', _$channel, opt: true);
  static String? _$repositoryUrl(FlutterRootVersionFile v) => v.repositoryUrl;
  static const Field<FlutterRootVersionFile, String> _f$repositoryUrl =
      Field('repositoryUrl', _$repositoryUrl, opt: true);
  static String? _$frameworkRevision(FlutterRootVersionFile v) =>
      v.frameworkRevision;
  static const Field<FlutterRootVersionFile, String> _f$frameworkRevision =
      Field('frameworkRevision', _$frameworkRevision, opt: true);
  static String? _$frameworkCommitDate(FlutterRootVersionFile v) =>
      v.frameworkCommitDate;
  static const Field<FlutterRootVersionFile, String> _f$frameworkCommitDate =
      Field('frameworkCommitDate', _$frameworkCommitDate, opt: true);
  static String? _$engineRevision(FlutterRootVersionFile v) => v.engineRevision;
  static const Field<FlutterRootVersionFile, String> _f$engineRevision =
      Field('engineRevision', _$engineRevision, opt: true);
  static String? _$engineCommitDate(FlutterRootVersionFile v) =>
      v.engineCommitDate;
  static const Field<FlutterRootVersionFile, String> _f$engineCommitDate =
      Field('engineCommitDate', _$engineCommitDate, opt: true);
  static String? _$engineContentHash(FlutterRootVersionFile v) =>
      v.engineContentHash;
  static const Field<FlutterRootVersionFile, String> _f$engineContentHash =
      Field('engineContentHash', _$engineContentHash, opt: true);
  static String? _$engineBuildDate(FlutterRootVersionFile v) =>
      v.engineBuildDate;
  static const Field<FlutterRootVersionFile, String> _f$engineBuildDate =
      Field('engineBuildDate', _$engineBuildDate, opt: true);
  static String? _$dartSdkVersion(FlutterRootVersionFile v) => v.dartSdkVersion;
  static const Field<FlutterRootVersionFile, String> _f$dartSdkVersion =
      Field('dartSdkVersion', _$dartSdkVersion, opt: true);
  static String? _$devToolsVersion(FlutterRootVersionFile v) =>
      v.devToolsVersion;
  static const Field<FlutterRootVersionFile, String> _f$devToolsVersion =
      Field('devToolsVersion', _$devToolsVersion, opt: true);

  @override
  final MappableFields<FlutterRootVersionFile> fields = const {
    #frameworkVersion: _f$frameworkVersion,
    #flutterVersion: _f$flutterVersion,
    #channel: _f$channel,
    #repositoryUrl: _f$repositoryUrl,
    #frameworkRevision: _f$frameworkRevision,
    #frameworkCommitDate: _f$frameworkCommitDate,
    #engineRevision: _f$engineRevision,
    #engineCommitDate: _f$engineCommitDate,
    #engineContentHash: _f$engineContentHash,
    #engineBuildDate: _f$engineBuildDate,
    #dartSdkVersion: _f$dartSdkVersion,
    #devToolsVersion: _f$devToolsVersion,
  };
  @override
  final bool ignoreNull = true;

  static FlutterRootVersionFile _instantiate(DecodingData data) {
    return FlutterRootVersionFile(
        frameworkVersion: data.dec(_f$frameworkVersion),
        flutterVersion: data.dec(_f$flutterVersion),
        channel: data.dec(_f$channel),
        repositoryUrl: data.dec(_f$repositoryUrl),
        frameworkRevision: data.dec(_f$frameworkRevision),
        frameworkCommitDate: data.dec(_f$frameworkCommitDate),
        engineRevision: data.dec(_f$engineRevision),
        engineCommitDate: data.dec(_f$engineCommitDate),
        engineContentHash: data.dec(_f$engineContentHash),
        engineBuildDate: data.dec(_f$engineBuildDate),
        dartSdkVersion: data.dec(_f$dartSdkVersion),
        devToolsVersion: data.dec(_f$devToolsVersion));
  }

  @override
  final Function instantiate = _instantiate;

  static FlutterRootVersionFile fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FlutterRootVersionFile>(map);
  }

  static FlutterRootVersionFile fromJson(String json) {
    return ensureInitialized().decodeJson<FlutterRootVersionFile>(json);
  }
}

mixin FlutterRootVersionFileMappable {
  String toJson() {
    return FlutterRootVersionFileMapper.ensureInitialized()
        .encodeJson<FlutterRootVersionFile>(this as FlutterRootVersionFile);
  }

  Map<String, dynamic> toMap() {
    return FlutterRootVersionFileMapper.ensureInitialized()
        .encodeMap<FlutterRootVersionFile>(this as FlutterRootVersionFile);
  }

  FlutterRootVersionFileCopyWith<FlutterRootVersionFile, FlutterRootVersionFile,
          FlutterRootVersionFile>
      get copyWith => _FlutterRootVersionFileCopyWithImpl<
              FlutterRootVersionFile, FlutterRootVersionFile>(
          this as FlutterRootVersionFile, $identity, $identity);
  @override
  String toString() {
    return FlutterRootVersionFileMapper.ensureInitialized()
        .stringifyValue(this as FlutterRootVersionFile);
  }

  @override
  bool operator ==(Object other) {
    return FlutterRootVersionFileMapper.ensureInitialized()
        .equalsValue(this as FlutterRootVersionFile, other);
  }

  @override
  int get hashCode {
    return FlutterRootVersionFileMapper.ensureInitialized()
        .hashValue(this as FlutterRootVersionFile);
  }
}

extension FlutterRootVersionFileValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FlutterRootVersionFile, $Out> {
  FlutterRootVersionFileCopyWith<$R, FlutterRootVersionFile, $Out>
      get $asFlutterRootVersionFile => $base.as((v, t, t2) =>
          _FlutterRootVersionFileCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FlutterRootVersionFileCopyWith<
    $R,
    $In extends FlutterRootVersionFile,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? frameworkVersion,
      String? flutterVersion,
      String? channel,
      String? repositoryUrl,
      String? frameworkRevision,
      String? frameworkCommitDate,
      String? engineRevision,
      String? engineCommitDate,
      String? engineContentHash,
      String? engineBuildDate,
      String? dartSdkVersion,
      String? devToolsVersion});
  FlutterRootVersionFileCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _FlutterRootVersionFileCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FlutterRootVersionFile, $Out>
    implements
        FlutterRootVersionFileCopyWith<$R, FlutterRootVersionFile, $Out> {
  _FlutterRootVersionFileCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FlutterRootVersionFile> $mapper =
      FlutterRootVersionFileMapper.ensureInitialized();
  @override
  $R call(
          {Object? frameworkVersion = $none,
          Object? flutterVersion = $none,
          Object? channel = $none,
          Object? repositoryUrl = $none,
          Object? frameworkRevision = $none,
          Object? frameworkCommitDate = $none,
          Object? engineRevision = $none,
          Object? engineCommitDate = $none,
          Object? engineContentHash = $none,
          Object? engineBuildDate = $none,
          Object? dartSdkVersion = $none,
          Object? devToolsVersion = $none}) =>
      $apply(FieldCopyWithData({
        if (frameworkVersion != $none) #frameworkVersion: frameworkVersion,
        if (flutterVersion != $none) #flutterVersion: flutterVersion,
        if (channel != $none) #channel: channel,
        if (repositoryUrl != $none) #repositoryUrl: repositoryUrl,
        if (frameworkRevision != $none) #frameworkRevision: frameworkRevision,
        if (frameworkCommitDate != $none)
          #frameworkCommitDate: frameworkCommitDate,
        if (engineRevision != $none) #engineRevision: engineRevision,
        if (engineCommitDate != $none) #engineCommitDate: engineCommitDate,
        if (engineContentHash != $none) #engineContentHash: engineContentHash,
        if (engineBuildDate != $none) #engineBuildDate: engineBuildDate,
        if (dartSdkVersion != $none) #dartSdkVersion: dartSdkVersion,
        if (devToolsVersion != $none) #devToolsVersion: devToolsVersion
      }));
  @override
  FlutterRootVersionFile $make(CopyWithData data) => FlutterRootVersionFile(
      frameworkVersion:
          data.get(#frameworkVersion, or: $value.frameworkVersion),
      flutterVersion: data.get(#flutterVersion, or: $value.flutterVersion),
      channel: data.get(#channel, or: $value.channel),
      repositoryUrl: data.get(#repositoryUrl, or: $value.repositoryUrl),
      frameworkRevision:
          data.get(#frameworkRevision, or: $value.frameworkRevision),
      frameworkCommitDate:
          data.get(#frameworkCommitDate, or: $value.frameworkCommitDate),
      engineRevision: data.get(#engineRevision, or: $value.engineRevision),
      engineCommitDate:
          data.get(#engineCommitDate, or: $value.engineCommitDate),
      engineContentHash:
          data.get(#engineContentHash, or: $value.engineContentHash),
      engineBuildDate: data.get(#engineBuildDate, or: $value.engineBuildDate),
      dartSdkVersion: data.get(#dartSdkVersion, or: $value.dartSdkVersion),
      devToolsVersion: data.get(#devToolsVersion, or: $value.devToolsVersion));

  @override
  FlutterRootVersionFileCopyWith<$R2, FlutterRootVersionFile, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _FlutterRootVersionFileCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
