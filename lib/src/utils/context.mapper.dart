// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'context.dart';

class FVMContextMapper extends ClassMapperBase<FVMContext> {
  FVMContextMapper._();

  static FVMContextMapper? _instance;
  static FVMContextMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FVMContextMapper._());
      MapperContainer.globals.useAll([GeneratorsMapper()]);
      AppConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FVMContext';

  static String _$id(FVMContext v) => v.id;
  static const Field<FVMContext, String> _f$id = Field('id', _$id);
  static String _$workingDirectory(FVMContext v) => v.workingDirectory;
  static const Field<FVMContext, String> _f$workingDirectory =
      Field('workingDirectory', _$workingDirectory);
  static AppConfig _$config(FVMContext v) => v.config;
  static const Field<FVMContext, AppConfig> _f$config =
      Field('config', _$config);
  static Map<String, String> _$environment(FVMContext v) => v.environment;
  static const Field<FVMContext, Map<String, String>> _f$environment =
      Field('environment', _$environment);
  static List<String> _$args(FVMContext v) => v.args;
  static const Field<FVMContext, List<String>> _f$args = Field('args', _$args);
  static bool _$_skipInput(FVMContext v) => v._skipInput;
  static const Field<FVMContext, bool> _f$_skipInput =
      Field('_skipInput', _$_skipInput, key: r'skipInput');
  static bool _$isTest(FVMContext v) => v.isTest;
  static const Field<FVMContext, bool> _f$isTest =
      Field('isTest', _$isTest, opt: true, def: false);
  static Level _$logLevel(FVMContext v) => v.logLevel;
  static const Field<FVMContext, Level> _f$logLevel =
      Field('logLevel', _$logLevel, opt: true, def: Level.info);
  static String _$fvmDir(FVMContext v) => v.fvmDir;
  static const Field<FVMContext, String> _f$fvmDir = Field('fvmDir', _$fvmDir);
  static bool _$gitCache(FVMContext v) => v.gitCache;
  static const Field<FVMContext, bool> _f$gitCache =
      Field('gitCache', _$gitCache);
  static bool _$runPubGetOnSdkChanges(FVMContext v) => v.runPubGetOnSdkChanges;
  static const Field<FVMContext, bool> _f$runPubGetOnSdkChanges =
      Field('runPubGetOnSdkChanges', _$runPubGetOnSdkChanges);
  static String _$fvmVersion(FVMContext v) => v.fvmVersion;
  static const Field<FVMContext, String> _f$fvmVersion =
      Field('fvmVersion', _$fvmVersion);
  static String _$gitCachePath(FVMContext v) => v.gitCachePath;
  static const Field<FVMContext, String> _f$gitCachePath =
      Field('gitCachePath', _$gitCachePath);
  static String _$flutterUrl(FVMContext v) => v.flutterUrl;
  static const Field<FVMContext, String> _f$flutterUrl =
      Field('flutterUrl', _$flutterUrl);
  static DateTime? _$lastUpdateCheck(FVMContext v) => v.lastUpdateCheck;
  static const Field<FVMContext, DateTime> _f$lastUpdateCheck =
      Field('lastUpdateCheck', _$lastUpdateCheck);
  static bool _$updateCheckDisabled(FVMContext v) => v.updateCheckDisabled;
  static const Field<FVMContext, bool> _f$updateCheckDisabled =
      Field('updateCheckDisabled', _$updateCheckDisabled);
  static bool _$privilegedAccess(FVMContext v) => v.privilegedAccess;
  static const Field<FVMContext, bool> _f$privilegedAccess =
      Field('privilegedAccess', _$privilegedAccess);
  static String _$globalCacheLink(FVMContext v) => v.globalCacheLink;
  static const Field<FVMContext, String> _f$globalCacheLink =
      Field('globalCacheLink', _$globalCacheLink);
  static String _$globalCacheBinPath(FVMContext v) => v.globalCacheBinPath;
  static const Field<FVMContext, String> _f$globalCacheBinPath =
      Field('globalCacheBinPath', _$globalCacheBinPath);
  static String _$versionsCachePath(FVMContext v) => v.versionsCachePath;
  static const Field<FVMContext, String> _f$versionsCachePath =
      Field('versionsCachePath', _$versionsCachePath);
  static String _$configPath(FVMContext v) => v.configPath;
  static const Field<FVMContext, String> _f$configPath =
      Field('configPath', _$configPath);
  static bool _$isCI(FVMContext v) => v.isCI;
  static const Field<FVMContext, bool> _f$isCI = Field('isCI', _$isCI);
  static bool _$skipInput(FVMContext v) => v.skipInput;
  static const Field<FVMContext, bool> _f$skipInput =
      Field('skipInput', _$skipInput);

  @override
  final MappableFields<FVMContext> fields = const {
    #id: _f$id,
    #workingDirectory: _f$workingDirectory,
    #config: _f$config,
    #environment: _f$environment,
    #args: _f$args,
    #_skipInput: _f$_skipInput,
    #isTest: _f$isTest,
    #logLevel: _f$logLevel,
    #fvmDir: _f$fvmDir,
    #gitCache: _f$gitCache,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #fvmVersion: _f$fvmVersion,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #lastUpdateCheck: _f$lastUpdateCheck,
    #updateCheckDisabled: _f$updateCheckDisabled,
    #privilegedAccess: _f$privilegedAccess,
    #globalCacheLink: _f$globalCacheLink,
    #globalCacheBinPath: _f$globalCacheBinPath,
    #versionsCachePath: _f$versionsCachePath,
    #configPath: _f$configPath,
    #isCI: _f$isCI,
    #skipInput: _f$skipInput,
  };

  static FVMContext _instantiate(DecodingData data) {
    return FVMContext.raw(
        id: data.dec(_f$id),
        workingDirectory: data.dec(_f$workingDirectory),
        config: data.dec(_f$config),
        environment: data.dec(_f$environment),
        args: data.dec(_f$args),
        skipInput: data.dec(_f$_skipInput),
        isTest: data.dec(_f$isTest),
        logLevel: data.dec(_f$logLevel));
  }

  @override
  final Function instantiate = _instantiate;

  static FVMContext fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FVMContext>(map);
  }

  static FVMContext fromJson(String json) {
    return ensureInitialized().decodeJson<FVMContext>(json);
  }
}

mixin FVMContextMappable {
  String toJson() {
    return FVMContextMapper.ensureInitialized()
        .encodeJson<FVMContext>(this as FVMContext);
  }

  Map<String, dynamic> toMap() {
    return FVMContextMapper.ensureInitialized()
        .encodeMap<FVMContext>(this as FVMContext);
  }

  FVMContextCopyWith<FVMContext, FVMContext, FVMContext> get copyWith =>
      _FVMContextCopyWithImpl(this as FVMContext, $identity, $identity);
  @override
  String toString() {
    return FVMContextMapper.ensureInitialized()
        .stringifyValue(this as FVMContext);
  }

  @override
  bool operator ==(Object other) {
    return FVMContextMapper.ensureInitialized()
        .equalsValue(this as FVMContext, other);
  }

  @override
  int get hashCode {
    return FVMContextMapper.ensureInitialized().hashValue(this as FVMContext);
  }
}

extension FVMContextValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FVMContext, $Out> {
  FVMContextCopyWith<$R, FVMContext, $Out> get $asFVMContext =>
      $base.as((v, t, t2) => _FVMContextCopyWithImpl(v, t, t2));
}

abstract class FVMContextCopyWith<$R, $In extends FVMContext, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  AppConfigCopyWith<$R, AppConfig, AppConfig> get config;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get environment;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get args;
  $R call(
      {String? id,
      String? workingDirectory,
      AppConfig? config,
      Map<String, String>? environment,
      List<String>? args,
      bool? skipInput,
      bool? isTest,
      Level? logLevel});
  FVMContextCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FVMContextCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FVMContext, $Out>
    implements FVMContextCopyWith<$R, FVMContext, $Out> {
  _FVMContextCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FVMContext> $mapper =
      FVMContextMapper.ensureInitialized();
  @override
  AppConfigCopyWith<$R, AppConfig, AppConfig> get config =>
      $value.config.copyWith.$chain((v) => call(config: v));
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get environment => MapCopyWith(
          $value.environment,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(environment: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get args =>
      ListCopyWith($value.args, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(args: v));
  @override
  $R call(
          {String? id,
          String? workingDirectory,
          AppConfig? config,
          Map<String, String>? environment,
          List<String>? args,
          bool? skipInput,
          bool? isTest,
          Level? logLevel}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (workingDirectory != null) #workingDirectory: workingDirectory,
        if (config != null) #config: config,
        if (environment != null) #environment: environment,
        if (args != null) #args: args,
        if (skipInput != null) #skipInput: skipInput,
        if (isTest != null) #isTest: isTest,
        if (logLevel != null) #logLevel: logLevel
      }));
  @override
  FVMContext $make(CopyWithData data) => FVMContext.raw(
      id: data.get(#id, or: $value.id),
      workingDirectory:
          data.get(#workingDirectory, or: $value.workingDirectory),
      config: data.get(#config, or: $value.config),
      environment: data.get(#environment, or: $value.environment),
      args: data.get(#args, or: $value.args),
      skipInput: data.get(#skipInput, or: $value._skipInput),
      isTest: data.get(#isTest, or: $value.isTest),
      logLevel: data.get(#logLevel, or: $value.logLevel));

  @override
  FVMContextCopyWith<$R2, FVMContext, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FVMContextCopyWithImpl($value, $cast, t);
}
