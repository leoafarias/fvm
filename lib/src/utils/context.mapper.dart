// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'context.dart';

class FvmContextMapper extends ClassMapperBase<FvmContext> {
  FvmContextMapper._();

  static FvmContextMapper? _instance;
  static FvmContextMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FvmContextMapper._());
      MapperContainer.globals.useAll([GeneratorsMapper()]);
      AppConfigMapper.ensureInitialized();
      LevelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FvmContext';

  static String? _$debugLabel(FvmContext v) => v.debugLabel;
  static const Field<FvmContext, String> _f$debugLabel = Field(
    'debugLabel',
    _$debugLabel,
  );
  static String _$workingDirectory(FvmContext v) => v.workingDirectory;
  static const Field<FvmContext, String> _f$workingDirectory = Field(
    'workingDirectory',
    _$workingDirectory,
  );
  static AppConfig _$config(FvmContext v) => v.config;
  static const Field<FvmContext, AppConfig> _f$config = Field(
    'config',
    _$config,
  );
  static Map<Type, Contextual Function(FvmContext)> _$_generators(
    FvmContext v,
  ) =>
      v._generators;
  static const Field<FvmContext, Map<Type, Contextual Function(FvmContext)>>
      _f$_generators = Field('_generators', _$_generators, key: r'generators');
  static Map<String, String> _$environment(FvmContext v) => v.environment;
  static const Field<FvmContext, Map<String, String>> _f$environment = Field(
    'environment',
    _$environment,
  );
  static bool _$_skipInput(FvmContext v) => v._skipInput;
  static const Field<FvmContext, bool> _f$_skipInput = Field(
    '_skipInput',
    _$_skipInput,
    key: r'skipInput',
  );
  static bool _$isTest(FvmContext v) => v.isTest;
  static const Field<FvmContext, bool> _f$isTest = Field(
    'isTest',
    _$isTest,
    opt: true,
    def: false,
  );
  static Level _$logLevel(FvmContext v) => v.logLevel;
  static const Field<FvmContext, Level> _f$logLevel = Field(
    'logLevel',
    _$logLevel,
    opt: true,
    def: Level.info,
  );
  static String _$fvmDir(FvmContext v) => v.fvmDir;
  static const Field<FvmContext, String> _f$fvmDir = Field('fvmDir', _$fvmDir);
  static bool _$gitCache(FvmContext v) => v.gitCache;
  static const Field<FvmContext, bool> _f$gitCache = Field(
    'gitCache',
    _$gitCache,
  );
  static bool _$runPubGetOnSdkChanges(FvmContext v) => v.runPubGetOnSdkChanges;
  static const Field<FvmContext, bool> _f$runPubGetOnSdkChanges = Field(
    'runPubGetOnSdkChanges',
    _$runPubGetOnSdkChanges,
  );
  static String _$fvmVersion(FvmContext v) => v.fvmVersion;
  static const Field<FvmContext, String> _f$fvmVersion = Field(
    'fvmVersion',
    _$fvmVersion,
  );
  static String _$gitCachePath(FvmContext v) => v.gitCachePath;
  static const Field<FvmContext, String> _f$gitCachePath = Field(
    'gitCachePath',
    _$gitCachePath,
  );
  static String _$flutterUrl(FvmContext v) => v.flutterUrl;
  static const Field<FvmContext, String> _f$flutterUrl = Field(
    'flutterUrl',
    _$flutterUrl,
  );
  static DateTime? _$lastUpdateCheck(FvmContext v) => v.lastUpdateCheck;
  static const Field<FvmContext, DateTime> _f$lastUpdateCheck = Field(
    'lastUpdateCheck',
    _$lastUpdateCheck,
  );
  static bool _$updateCheckDisabled(FvmContext v) => v.updateCheckDisabled;
  static const Field<FvmContext, bool> _f$updateCheckDisabled = Field(
    'updateCheckDisabled',
    _$updateCheckDisabled,
  );
  static bool _$privilegedAccess(FvmContext v) => v.privilegedAccess;
  static const Field<FvmContext, bool> _f$privilegedAccess = Field(
    'privilegedAccess',
    _$privilegedAccess,
  );
  static String _$globalCacheLink(FvmContext v) => v.globalCacheLink;
  static const Field<FvmContext, String> _f$globalCacheLink = Field(
    'globalCacheLink',
    _$globalCacheLink,
  );
  static String _$globalCacheBinPath(FvmContext v) => v.globalCacheBinPath;
  static const Field<FvmContext, String> _f$globalCacheBinPath = Field(
    'globalCacheBinPath',
    _$globalCacheBinPath,
  );
  static String _$versionsCachePath(FvmContext v) => v.versionsCachePath;
  static const Field<FvmContext, String> _f$versionsCachePath = Field(
    'versionsCachePath',
    _$versionsCachePath,
  );
  static bool _$isCI(FvmContext v) => v.isCI;
  static const Field<FvmContext, bool> _f$isCI = Field('isCI', _$isCI);
  static bool _$skipInput(FvmContext v) => v.skipInput;
  static const Field<FvmContext, bool> _f$skipInput = Field(
    'skipInput',
    _$skipInput,
  );

  @override
  final MappableFields<FvmContext> fields = const {
    #debugLabel: _f$debugLabel,
    #workingDirectory: _f$workingDirectory,
    #config: _f$config,
    #_generators: _f$_generators,
    #environment: _f$environment,
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
    #isCI: _f$isCI,
    #skipInput: _f$skipInput,
  };

  static FvmContext _instantiate(DecodingData data) {
    return FvmContext.raw(
      debugLabel: data.dec(_f$debugLabel),
      workingDirectory: data.dec(_f$workingDirectory),
      config: data.dec(_f$config),
      generators: data.dec(_f$_generators),
      environment: data.dec(_f$environment),
      skipInput: data.dec(_f$_skipInput),
      isTest: data.dec(_f$isTest),
      logLevel: data.dec(_f$logLevel),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FvmContext fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FvmContext>(map);
  }

  static FvmContext fromJson(String json) {
    return ensureInitialized().decodeJson<FvmContext>(json);
  }
}

mixin FvmContextMappable {
  String toJson() {
    return FvmContextMapper.ensureInitialized().encodeJson<FvmContext>(
      this as FvmContext,
    );
  }

  Map<String, dynamic> toMap() {
    return FvmContextMapper.ensureInitialized().encodeMap<FvmContext>(
      this as FvmContext,
    );
  }

  FvmContextCopyWith<FvmContext, FvmContext, FvmContext> get copyWith =>
      _FvmContextCopyWithImpl<FvmContext, FvmContext>(
        this as FvmContext,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FvmContextMapper.ensureInitialized().stringifyValue(
      this as FvmContext,
    );
  }

  @override
  bool operator ==(Object other) {
    return FvmContextMapper.ensureInitialized().equalsValue(
      this as FvmContext,
      other,
    );
  }

  @override
  int get hashCode {
    return FvmContextMapper.ensureInitialized().hashValue(this as FvmContext);
  }
}

extension FvmContextValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FvmContext, $Out> {
  FvmContextCopyWith<$R, FvmContext, $Out> get $asFvmContext =>
      $base.as((v, t, t2) => _FvmContextCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FvmContextCopyWith<$R, $In extends FvmContext, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  AppConfigCopyWith<$R, AppConfig, AppConfig> get config;
  MapCopyWith<
      $R,
      Type,
      Contextual Function(FvmContext),
      ObjectCopyWith<$R, Contextual Function(FvmContext),
          Contextual Function(FvmContext)>> get _generators;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get environment;
  $R call({
    String? debugLabel,
    String? workingDirectory,
    AppConfig? config,
    Map<Type, Contextual Function(FvmContext)>? generators,
    Map<String, String>? environment,
    bool? skipInput,
    bool? isTest,
    Level? logLevel,
  });
  FvmContextCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FvmContextCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FvmContext, $Out>
    implements FvmContextCopyWith<$R, FvmContext, $Out> {
  _FvmContextCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FvmContext> $mapper =
      FvmContextMapper.ensureInitialized();
  @override
  AppConfigCopyWith<$R, AppConfig, AppConfig> get config =>
      $value.config.copyWith.$chain((v) => call(config: v));
  @override
  MapCopyWith<
      $R,
      Type,
      Contextual Function(FvmContext),
      ObjectCopyWith<$R, Contextual Function(FvmContext),
          Contextual Function(FvmContext)>> get _generators => MapCopyWith(
        $value._generators,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(generators: v),
      );
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get environment => MapCopyWith(
            $value.environment,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(environment: v),
          );
  @override
  $R call({
    Object? debugLabel = $none,
    String? workingDirectory,
    AppConfig? config,
    Map<Type, Contextual Function(FvmContext)>? generators,
    Map<String, String>? environment,
    bool? skipInput,
    bool? isTest,
    Level? logLevel,
  }) =>
      $apply(
        FieldCopyWithData({
          if (debugLabel != $none) #debugLabel: debugLabel,
          if (workingDirectory != null) #workingDirectory: workingDirectory,
          if (config != null) #config: config,
          if (generators != null) #generators: generators,
          if (environment != null) #environment: environment,
          if (skipInput != null) #skipInput: skipInput,
          if (isTest != null) #isTest: isTest,
          if (logLevel != null) #logLevel: logLevel,
        }),
      );
  @override
  FvmContext $make(CopyWithData data) => FvmContext.raw(
        debugLabel: data.get(#debugLabel, or: $value.debugLabel),
        workingDirectory:
            data.get(#workingDirectory, or: $value.workingDirectory),
        config: data.get(#config, or: $value.config),
        generators: data.get(#generators, or: $value._generators),
        environment: data.get(#environment, or: $value.environment),
        skipInput: data.get(#skipInput, or: $value._skipInput),
        isTest: data.get(#isTest, or: $value.isTest),
        logLevel: data.get(#logLevel, or: $value.logLevel),
      );

  @override
  FvmContextCopyWith<$R2, FvmContext, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _FvmContextCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
