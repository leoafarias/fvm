// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'context.dart';

class FVMContextMapper extends ClassMapperBase<FVMContext> {
  FVMContextMapper._();

  static FVMContextMapper? _instance;
  static FVMContextMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FVMContextMapper._());
      AppConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FVMContext';

  static String _$id(FVMContext v) => v.id;
  static const Field<FVMContext, String> _f$id = Field('id', _$id, opt: true);
  static List<String> _$args(FVMContext v) => v.args;
  static const Field<FVMContext, List<String>> _f$args =
      Field('args', _$args, opt: true);
  static const Field<FVMContext, AppConfig> _f$configOverrides =
      Field('configOverrides', null, mode: FieldMode.param, opt: true);
  static String _$workingDirectory(FVMContext v) => v.workingDirectory;
  static const Field<FVMContext, String> _f$workingDirectory =
      Field('workingDirectory', _$workingDirectory, opt: true);
  static const Field<FVMContext, Map<Type, dynamic>> _f$generatorOverrides =
      Field('generatorOverrides', null, mode: FieldMode.param, opt: true);
  static const Field<FVMContext, Map<String, String>> _f$environmentOverrides =
      Field('environmentOverrides', null, mode: FieldMode.param, opt: true);
  static bool _$isTest(FVMContext v) => v.isTest;
  static const Field<FVMContext, bool> _f$isTest =
      Field('isTest', _$isTest, opt: true, def: false);
  static Map<Type, ContextService Function(FVMContext)> _$generators(
          FVMContext v) =>
      v.generators;
  static const Field<FVMContext, Map<Type, ContextService Function(FVMContext)>>
      _f$generators = Field('generators', _$generators, mode: FieldMode.member);
  static AppConfig _$config(FVMContext v) => v.config;
  static const Field<FVMContext, AppConfig> _f$config =
      Field('config', _$config, mode: FieldMode.member);
  static Map<String, String> _$environment(FVMContext v) => v.environment;
  static const Field<FVMContext, Map<String, String>> _f$environment =
      Field('environment', _$environment, mode: FieldMode.member);
  static String _$fvmDir(FVMContext v) => v.fvmDir;
  static const Field<FVMContext, String> _f$fvmDir = Field('fvmDir', _$fvmDir);
  static bool _$gitCache(FVMContext v) => v.gitCache;
  static const Field<FVMContext, bool> _f$gitCache =
      Field('gitCache', _$gitCache);
  static bool _$runPubGetOnSdkChanges(FVMContext v) => v.runPubGetOnSdkChanges;
  static const Field<FVMContext, bool> _f$runPubGetOnSdkChanges =
      Field('runPubGetOnSdkChanges', _$runPubGetOnSdkChanges);
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
  static bool _$priviledgedAccess(FVMContext v) => v.priviledgedAccess;
  static const Field<FVMContext, bool> _f$priviledgedAccess =
      Field('priviledgedAccess', _$priviledgedAccess);
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

  @override
  final MappableFields<FVMContext> fields = const {
    #id: _f$id,
    #args: _f$args,
    #configOverrides: _f$configOverrides,
    #workingDirectory: _f$workingDirectory,
    #generatorOverrides: _f$generatorOverrides,
    #environmentOverrides: _f$environmentOverrides,
    #isTest: _f$isTest,
    #generators: _f$generators,
    #config: _f$config,
    #environment: _f$environment,
    #fvmDir: _f$fvmDir,
    #gitCache: _f$gitCache,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #lastUpdateCheck: _f$lastUpdateCheck,
    #updateCheckDisabled: _f$updateCheckDisabled,
    #priviledgedAccess: _f$priviledgedAccess,
    #globalCacheLink: _f$globalCacheLink,
    #globalCacheBinPath: _f$globalCacheBinPath,
    #versionsCachePath: _f$versionsCachePath,
    #configPath: _f$configPath,
    #isCI: _f$isCI,
  };

  static FVMContext _instantiate(DecodingData data) {
    return FVMContext.create(
        id: data.dec(_f$id),
        args: data.dec(_f$args),
        configOverrides: data.dec(_f$configOverrides),
        workingDirectory: data.dec(_f$workingDirectory),
        generatorOverrides: data.dec(_f$generatorOverrides),
        environmentOverrides: data.dec(_f$environmentOverrides),
        isTest: data.dec(_f$isTest));
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
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            FVMContextMapper.ensureInitialized()
                .isValueEqual(this as FVMContext, other));
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
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get args;
  $R call(
      {String? id,
      List<String>? args,
      AppConfig? configOverrides,
      String? workingDirectory,
      Map<Type, dynamic>? generatorOverrides,
      Map<String, String>? environmentOverrides,
      bool? isTest});
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
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get args =>
      ListCopyWith($value.args, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(args: v));
  @override
  $R call(
          {Object? id = $none,
          Object? args = $none,
          AppConfig? configOverrides,
          Object? workingDirectory = $none,
          Map<Type, dynamic>? generatorOverrides,
          Map<String, String>? environmentOverrides,
          bool? isTest}) =>
      $apply(FieldCopyWithData({
        if (id != $none) #id: id,
        if (args != $none) #args: args,
        #configOverrides: configOverrides,
        if (workingDirectory != $none) #workingDirectory: workingDirectory,
        #generatorOverrides: generatorOverrides,
        #environmentOverrides: environmentOverrides,
        if (isTest != null) #isTest: isTest
      }));
  @override
  FVMContext $make(CopyWithData data) => FVMContext.create(
      id: data.get(#id, or: $value.id),
      args: data.get(#args, or: $value.args),
      configOverrides: data.get(#configOverrides),
      workingDirectory:
          data.get(#workingDirectory, or: $value.workingDirectory),
      generatorOverrides: data.get(#generatorOverrides),
      environmentOverrides: data.get(#environmentOverrides),
      isTest: data.get(#isTest, or: $value.isTest));

  @override
  FVMContextCopyWith<$R2, FVMContext, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FVMContextCopyWithImpl($value, $cast, t);
}
