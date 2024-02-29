// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'config_model.dart';

class ConfigKeysMapper extends EnumMapper<ConfigKeys> {
  ConfigKeysMapper._();

  static ConfigKeysMapper? _instance;
  static ConfigKeysMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ConfigKeysMapper._());
    }
    return _instance!;
  }

  static ConfigKeys fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ConfigKeys decode(dynamic value) {
    switch (value) {
      case 'cachePath':
        return ConfigKeys.cachePath;
      case 'useGitCache':
        return ConfigKeys.useGitCache;
      case 'gitCachePath':
        return ConfigKeys.gitCachePath;
      case 'flutterUrl':
        return ConfigKeys.flutterUrl;
      case 'priviledgedAccess':
        return ConfigKeys.priviledgedAccess;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ConfigKeys self) {
    switch (self) {
      case ConfigKeys.cachePath:
        return 'cachePath';
      case ConfigKeys.useGitCache:
        return 'useGitCache';
      case ConfigKeys.gitCachePath:
        return 'gitCachePath';
      case ConfigKeys.flutterUrl:
        return 'flutterUrl';
      case ConfigKeys.priviledgedAccess:
        return 'priviledgedAccess';
    }
  }
}

extension ConfigKeysMapperExtension on ConfigKeys {
  String toValue() {
    ConfigKeysMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ConfigKeys>(this) as String;
  }
}

class BaseConfigMapper extends ClassMapperBase<BaseConfig> {
  BaseConfigMapper._();

  static BaseConfigMapper? _instance;
  static BaseConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BaseConfigMapper._());
      EnvConfigMapper.ensureInitialized();
      FileConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'BaseConfig';

  static String? _$cachePath(BaseConfig v) => v.cachePath;
  static const Field<BaseConfig, String> _f$cachePath =
      Field('cachePath', _$cachePath);
  static bool? _$useGitCache(BaseConfig v) => v.useGitCache;
  static const Field<BaseConfig, bool> _f$useGitCache =
      Field('useGitCache', _$useGitCache);
  static String? _$gitCachePath(BaseConfig v) => v.gitCachePath;
  static const Field<BaseConfig, String> _f$gitCachePath =
      Field('gitCachePath', _$gitCachePath);
  static String? _$flutterUrl(BaseConfig v) => v.flutterUrl;
  static const Field<BaseConfig, String> _f$flutterUrl =
      Field('flutterUrl', _$flutterUrl);

  @override
  final MappableFields<BaseConfig> fields = const {
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
  };

  static BaseConfig _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('BaseConfig');
  }

  @override
  final Function instantiate = _instantiate;

  static BaseConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BaseConfig>(map);
  }

  static BaseConfig fromJson(String json) {
    return ensureInitialized().decodeJson<BaseConfig>(json);
  }
}

mixin BaseConfigMappable {
  String toJson();
  Map<String, dynamic> toMap();
  BaseConfigCopyWith<BaseConfig, BaseConfig, BaseConfig> get copyWith;
}

abstract class BaseConfigCopyWith<$R, $In extends BaseConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? cachePath,
      bool? useGitCache,
      String? gitCachePath,
      String? flutterUrl});
  BaseConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class EnvConfigMapper extends ClassMapperBase<EnvConfig> {
  EnvConfigMapper._();

  static EnvConfigMapper? _instance;
  static EnvConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnvConfigMapper._());
      BaseConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'EnvConfig';

  static String? _$cachePath(EnvConfig v) => v.cachePath;
  static const Field<EnvConfig, String> _f$cachePath =
      Field('cachePath', _$cachePath);
  static bool? _$useGitCache(EnvConfig v) => v.useGitCache;
  static const Field<EnvConfig, bool> _f$useGitCache =
      Field('useGitCache', _$useGitCache);
  static String? _$gitCachePath(EnvConfig v) => v.gitCachePath;
  static const Field<EnvConfig, String> _f$gitCachePath =
      Field('gitCachePath', _$gitCachePath);
  static String? _$flutterUrl(EnvConfig v) => v.flutterUrl;
  static const Field<EnvConfig, String> _f$flutterUrl =
      Field('flutterUrl', _$flutterUrl);

  @override
  final MappableFields<EnvConfig> fields = const {
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
  };

  static EnvConfig _instantiate(DecodingData data) {
    return EnvConfig(
        cachePath: data.dec(_f$cachePath),
        useGitCache: data.dec(_f$useGitCache),
        gitCachePath: data.dec(_f$gitCachePath),
        flutterUrl: data.dec(_f$flutterUrl));
  }

  @override
  final Function instantiate = _instantiate;

  static EnvConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EnvConfig>(map);
  }

  static EnvConfig fromJson(String json) {
    return ensureInitialized().decodeJson<EnvConfig>(json);
  }
}

mixin EnvConfigMappable {
  String toJson() {
    return EnvConfigMapper.ensureInitialized()
        .encodeJson<EnvConfig>(this as EnvConfig);
  }

  Map<String, dynamic> toMap() {
    return EnvConfigMapper.ensureInitialized()
        .encodeMap<EnvConfig>(this as EnvConfig);
  }

  EnvConfigCopyWith<EnvConfig, EnvConfig, EnvConfig> get copyWith =>
      _EnvConfigCopyWithImpl(this as EnvConfig, $identity, $identity);
  @override
  String toString() {
    return EnvConfigMapper.ensureInitialized()
        .stringifyValue(this as EnvConfig);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            EnvConfigMapper.ensureInitialized()
                .isValueEqual(this as EnvConfig, other));
  }

  @override
  int get hashCode {
    return EnvConfigMapper.ensureInitialized().hashValue(this as EnvConfig);
  }
}

extension EnvConfigValueCopy<$R, $Out> on ObjectCopyWith<$R, EnvConfig, $Out> {
  EnvConfigCopyWith<$R, EnvConfig, $Out> get $asEnvConfig =>
      $base.as((v, t, t2) => _EnvConfigCopyWithImpl(v, t, t2));
}

abstract class EnvConfigCopyWith<$R, $In extends EnvConfig, $Out>
    implements BaseConfigCopyWith<$R, $In, $Out> {
  @override
  $R call(
      {String? cachePath,
      bool? useGitCache,
      String? gitCachePath,
      String? flutterUrl});
  EnvConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _EnvConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EnvConfig, $Out>
    implements EnvConfigCopyWith<$R, EnvConfig, $Out> {
  _EnvConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EnvConfig> $mapper =
      EnvConfigMapper.ensureInitialized();
  @override
  $R call(
          {Object? cachePath = $none,
          Object? useGitCache = $none,
          Object? gitCachePath = $none,
          Object? flutterUrl = $none}) =>
      $apply(FieldCopyWithData({
        if (cachePath != $none) #cachePath: cachePath,
        if (useGitCache != $none) #useGitCache: useGitCache,
        if (gitCachePath != $none) #gitCachePath: gitCachePath,
        if (flutterUrl != $none) #flutterUrl: flutterUrl
      }));
  @override
  EnvConfig $make(CopyWithData data) => EnvConfig(
      cachePath: data.get(#cachePath, or: $value.cachePath),
      useGitCache: data.get(#useGitCache, or: $value.useGitCache),
      gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
      flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl));

  @override
  EnvConfigCopyWith<$R2, EnvConfig, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _EnvConfigCopyWithImpl($value, $cast, t);
}

class FileConfigMapper extends ClassMapperBase<FileConfig> {
  FileConfigMapper._();

  static FileConfigMapper? _instance;
  static FileConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FileConfigMapper._());
      BaseConfigMapper.ensureInitialized();
      AppConfigMapper.ensureInitialized();
      ProjectConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FileConfig';

  static String? _$cachePath(FileConfig v) => v.cachePath;
  static const Field<FileConfig, String> _f$cachePath =
      Field('cachePath', _$cachePath);
  static bool? _$useGitCache(FileConfig v) => v.useGitCache;
  static const Field<FileConfig, bool> _f$useGitCache =
      Field('useGitCache', _$useGitCache);
  static String? _$gitCachePath(FileConfig v) => v.gitCachePath;
  static const Field<FileConfig, String> _f$gitCachePath =
      Field('gitCachePath', _$gitCachePath);
  static String? _$flutterUrl(FileConfig v) => v.flutterUrl;
  static const Field<FileConfig, String> _f$flutterUrl =
      Field('flutterUrl', _$flutterUrl);
  static bool? _$priviledgedAccess(FileConfig v) => v.priviledgedAccess;
  static const Field<FileConfig, bool> _f$priviledgedAccess =
      Field('priviledgedAccess', _$priviledgedAccess);
  static bool? _$runPubGetOnSdkChanges(FileConfig v) => v.runPubGetOnSdkChanges;
  static const Field<FileConfig, bool> _f$runPubGetOnSdkChanges =
      Field('runPubGetOnSdkChanges', _$runPubGetOnSdkChanges);
  static bool? _$updateVscodeSettings(FileConfig v) => v.updateVscodeSettings;
  static const Field<FileConfig, bool> _f$updateVscodeSettings =
      Field('updateVscodeSettings', _$updateVscodeSettings);
  static bool? _$updateGitIgnore(FileConfig v) => v.updateGitIgnore;
  static const Field<FileConfig, bool> _f$updateGitIgnore =
      Field('updateGitIgnore', _$updateGitIgnore);

  @override
  final MappableFields<FileConfig> fields = const {
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #priviledgedAccess: _f$priviledgedAccess,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #updateVscodeSettings: _f$updateVscodeSettings,
    #updateGitIgnore: _f$updateGitIgnore,
  };

  static FileConfig _instantiate(DecodingData data) {
    return FileConfig(
        cachePath: data.dec(_f$cachePath),
        useGitCache: data.dec(_f$useGitCache),
        gitCachePath: data.dec(_f$gitCachePath),
        flutterUrl: data.dec(_f$flutterUrl),
        priviledgedAccess: data.dec(_f$priviledgedAccess),
        runPubGetOnSdkChanges: data.dec(_f$runPubGetOnSdkChanges),
        updateVscodeSettings: data.dec(_f$updateVscodeSettings),
        updateGitIgnore: data.dec(_f$updateGitIgnore));
  }

  @override
  final Function instantiate = _instantiate;

  static FileConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FileConfig>(map);
  }

  static FileConfig fromJson(String json) {
    return ensureInitialized().decodeJson<FileConfig>(json);
  }
}

mixin FileConfigMappable {
  String toJson() {
    return FileConfigMapper.ensureInitialized()
        .encodeJson<FileConfig>(this as FileConfig);
  }

  Map<String, dynamic> toMap() {
    return FileConfigMapper.ensureInitialized()
        .encodeMap<FileConfig>(this as FileConfig);
  }

  FileConfigCopyWith<FileConfig, FileConfig, FileConfig> get copyWith =>
      _FileConfigCopyWithImpl(this as FileConfig, $identity, $identity);
  @override
  String toString() {
    return FileConfigMapper.ensureInitialized()
        .stringifyValue(this as FileConfig);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            FileConfigMapper.ensureInitialized()
                .isValueEqual(this as FileConfig, other));
  }

  @override
  int get hashCode {
    return FileConfigMapper.ensureInitialized().hashValue(this as FileConfig);
  }
}

extension FileConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FileConfig, $Out> {
  FileConfigCopyWith<$R, FileConfig, $Out> get $asFileConfig =>
      $base.as((v, t, t2) => _FileConfigCopyWithImpl(v, t, t2));
}

abstract class FileConfigCopyWith<$R, $In extends FileConfig, $Out>
    implements BaseConfigCopyWith<$R, $In, $Out> {
  @override
  $R call(
      {String? cachePath,
      bool? useGitCache,
      String? gitCachePath,
      String? flutterUrl,
      bool? priviledgedAccess,
      bool? runPubGetOnSdkChanges,
      bool? updateVscodeSettings,
      bool? updateGitIgnore});
  FileConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FileConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FileConfig, $Out>
    implements FileConfigCopyWith<$R, FileConfig, $Out> {
  _FileConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FileConfig> $mapper =
      FileConfigMapper.ensureInitialized();
  @override
  $R call(
          {Object? cachePath = $none,
          Object? useGitCache = $none,
          Object? gitCachePath = $none,
          Object? flutterUrl = $none,
          Object? priviledgedAccess = $none,
          Object? runPubGetOnSdkChanges = $none,
          Object? updateVscodeSettings = $none,
          Object? updateGitIgnore = $none}) =>
      $apply(FieldCopyWithData({
        if (cachePath != $none) #cachePath: cachePath,
        if (useGitCache != $none) #useGitCache: useGitCache,
        if (gitCachePath != $none) #gitCachePath: gitCachePath,
        if (flutterUrl != $none) #flutterUrl: flutterUrl,
        if (priviledgedAccess != $none) #priviledgedAccess: priviledgedAccess,
        if (runPubGetOnSdkChanges != $none)
          #runPubGetOnSdkChanges: runPubGetOnSdkChanges,
        if (updateVscodeSettings != $none)
          #updateVscodeSettings: updateVscodeSettings,
        if (updateGitIgnore != $none) #updateGitIgnore: updateGitIgnore
      }));
  @override
  FileConfig $make(CopyWithData data) => FileConfig(
      cachePath: data.get(#cachePath, or: $value.cachePath),
      useGitCache: data.get(#useGitCache, or: $value.useGitCache),
      gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
      flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl),
      priviledgedAccess:
          data.get(#priviledgedAccess, or: $value.priviledgedAccess),
      runPubGetOnSdkChanges:
          data.get(#runPubGetOnSdkChanges, or: $value.runPubGetOnSdkChanges),
      updateVscodeSettings:
          data.get(#updateVscodeSettings, or: $value.updateVscodeSettings),
      updateGitIgnore: data.get(#updateGitIgnore, or: $value.updateGitIgnore));

  @override
  FileConfigCopyWith<$R2, FileConfig, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FileConfigCopyWithImpl($value, $cast, t);
}

class AppConfigMapper extends ClassMapperBase<AppConfig> {
  AppConfigMapper._();

  static AppConfigMapper? _instance;
  static AppConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AppConfigMapper._());
      FileConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AppConfig';

  static bool? _$disableUpdateCheck(AppConfig v) => v.disableUpdateCheck;
  static const Field<AppConfig, bool> _f$disableUpdateCheck =
      Field('disableUpdateCheck', _$disableUpdateCheck, opt: true);
  static DateTime? _$lastUpdateCheck(AppConfig v) => v.lastUpdateCheck;
  static const Field<AppConfig, DateTime> _f$lastUpdateCheck =
      Field('lastUpdateCheck', _$lastUpdateCheck, opt: true);
  static String? _$cachePath(AppConfig v) => v.cachePath;
  static const Field<AppConfig, String> _f$cachePath =
      Field('cachePath', _$cachePath, opt: true);
  static bool? _$useGitCache(AppConfig v) => v.useGitCache;
  static const Field<AppConfig, bool> _f$useGitCache =
      Field('useGitCache', _$useGitCache, opt: true);
  static String? _$gitCachePath(AppConfig v) => v.gitCachePath;
  static const Field<AppConfig, String> _f$gitCachePath =
      Field('gitCachePath', _$gitCachePath, opt: true);
  static String? _$flutterUrl(AppConfig v) => v.flutterUrl;
  static const Field<AppConfig, String> _f$flutterUrl =
      Field('flutterUrl', _$flutterUrl, opt: true);
  static bool? _$priviledgedAccess(AppConfig v) => v.priviledgedAccess;
  static const Field<AppConfig, bool> _f$priviledgedAccess =
      Field('priviledgedAccess', _$priviledgedAccess, opt: true);
  static bool? _$runPubGetOnSdkChanges(AppConfig v) => v.runPubGetOnSdkChanges;
  static const Field<AppConfig, bool> _f$runPubGetOnSdkChanges =
      Field('runPubGetOnSdkChanges', _$runPubGetOnSdkChanges, opt: true);
  static bool? _$updateVscodeSettings(AppConfig v) => v.updateVscodeSettings;
  static const Field<AppConfig, bool> _f$updateVscodeSettings =
      Field('updateVscodeSettings', _$updateVscodeSettings, opt: true);
  static bool? _$updateGitIgnore(AppConfig v) => v.updateGitIgnore;
  static const Field<AppConfig, bool> _f$updateGitIgnore =
      Field('updateGitIgnore', _$updateGitIgnore, opt: true);

  @override
  final MappableFields<AppConfig> fields = const {
    #disableUpdateCheck: _f$disableUpdateCheck,
    #lastUpdateCheck: _f$lastUpdateCheck,
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #priviledgedAccess: _f$priviledgedAccess,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #updateVscodeSettings: _f$updateVscodeSettings,
    #updateGitIgnore: _f$updateGitIgnore,
  };
  @override
  final bool ignoreNull = true;

  static AppConfig _instantiate(DecodingData data) {
    return AppConfig(
        disableUpdateCheck: data.dec(_f$disableUpdateCheck),
        lastUpdateCheck: data.dec(_f$lastUpdateCheck),
        cachePath: data.dec(_f$cachePath),
        useGitCache: data.dec(_f$useGitCache),
        gitCachePath: data.dec(_f$gitCachePath),
        flutterUrl: data.dec(_f$flutterUrl),
        priviledgedAccess: data.dec(_f$priviledgedAccess),
        runPubGetOnSdkChanges: data.dec(_f$runPubGetOnSdkChanges),
        updateVscodeSettings: data.dec(_f$updateVscodeSettings),
        updateGitIgnore: data.dec(_f$updateGitIgnore));
  }

  @override
  final Function instantiate = _instantiate;

  static AppConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AppConfig>(map);
  }

  static AppConfig fromJson(String json) {
    return ensureInitialized().decodeJson<AppConfig>(json);
  }
}

mixin AppConfigMappable {
  String toJson() {
    return AppConfigMapper.ensureInitialized()
        .encodeJson<AppConfig>(this as AppConfig);
  }

  Map<String, dynamic> toMap() {
    return AppConfigMapper.ensureInitialized()
        .encodeMap<AppConfig>(this as AppConfig);
  }

  AppConfigCopyWith<AppConfig, AppConfig, AppConfig> get copyWith =>
      _AppConfigCopyWithImpl(this as AppConfig, $identity, $identity);
  @override
  String toString() {
    return AppConfigMapper.ensureInitialized()
        .stringifyValue(this as AppConfig);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            AppConfigMapper.ensureInitialized()
                .isValueEqual(this as AppConfig, other));
  }

  @override
  int get hashCode {
    return AppConfigMapper.ensureInitialized().hashValue(this as AppConfig);
  }
}

extension AppConfigValueCopy<$R, $Out> on ObjectCopyWith<$R, AppConfig, $Out> {
  AppConfigCopyWith<$R, AppConfig, $Out> get $asAppConfig =>
      $base.as((v, t, t2) => _AppConfigCopyWithImpl(v, t, t2));
}

abstract class AppConfigCopyWith<$R, $In extends AppConfig, $Out>
    implements FileConfigCopyWith<$R, $In, $Out> {
  @override
  $R call(
      {bool? disableUpdateCheck,
      DateTime? lastUpdateCheck,
      String? cachePath,
      bool? useGitCache,
      String? gitCachePath,
      String? flutterUrl,
      bool? priviledgedAccess,
      bool? runPubGetOnSdkChanges,
      bool? updateVscodeSettings,
      bool? updateGitIgnore});
  AppConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AppConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AppConfig, $Out>
    implements AppConfigCopyWith<$R, AppConfig, $Out> {
  _AppConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AppConfig> $mapper =
      AppConfigMapper.ensureInitialized();
  @override
  $R call(
          {Object? disableUpdateCheck = $none,
          Object? lastUpdateCheck = $none,
          Object? cachePath = $none,
          Object? useGitCache = $none,
          Object? gitCachePath = $none,
          Object? flutterUrl = $none,
          Object? priviledgedAccess = $none,
          Object? runPubGetOnSdkChanges = $none,
          Object? updateVscodeSettings = $none,
          Object? updateGitIgnore = $none}) =>
      $apply(FieldCopyWithData({
        if (disableUpdateCheck != $none)
          #disableUpdateCheck: disableUpdateCheck,
        if (lastUpdateCheck != $none) #lastUpdateCheck: lastUpdateCheck,
        if (cachePath != $none) #cachePath: cachePath,
        if (useGitCache != $none) #useGitCache: useGitCache,
        if (gitCachePath != $none) #gitCachePath: gitCachePath,
        if (flutterUrl != $none) #flutterUrl: flutterUrl,
        if (priviledgedAccess != $none) #priviledgedAccess: priviledgedAccess,
        if (runPubGetOnSdkChanges != $none)
          #runPubGetOnSdkChanges: runPubGetOnSdkChanges,
        if (updateVscodeSettings != $none)
          #updateVscodeSettings: updateVscodeSettings,
        if (updateGitIgnore != $none) #updateGitIgnore: updateGitIgnore
      }));
  @override
  AppConfig $make(CopyWithData data) => AppConfig(
      disableUpdateCheck:
          data.get(#disableUpdateCheck, or: $value.disableUpdateCheck),
      lastUpdateCheck: data.get(#lastUpdateCheck, or: $value.lastUpdateCheck),
      cachePath: data.get(#cachePath, or: $value.cachePath),
      useGitCache: data.get(#useGitCache, or: $value.useGitCache),
      gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
      flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl),
      priviledgedAccess:
          data.get(#priviledgedAccess, or: $value.priviledgedAccess),
      runPubGetOnSdkChanges:
          data.get(#runPubGetOnSdkChanges, or: $value.runPubGetOnSdkChanges),
      updateVscodeSettings:
          data.get(#updateVscodeSettings, or: $value.updateVscodeSettings),
      updateGitIgnore: data.get(#updateGitIgnore, or: $value.updateGitIgnore));

  @override
  AppConfigCopyWith<$R2, AppConfig, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _AppConfigCopyWithImpl($value, $cast, t);
}

class ProjectConfigMapper extends ClassMapperBase<ProjectConfig> {
  ProjectConfigMapper._();

  static ProjectConfigMapper? _instance;
  static ProjectConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ProjectConfigMapper._());
      FileConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ProjectConfig';

  static String? _$flutterSdkVersion(ProjectConfig v) => v.flutterSdkVersion;
  static const Field<ProjectConfig, String> _f$flutterSdkVersion =
      Field('flutterSdkVersion', _$flutterSdkVersion, opt: true);
  static Map<String, String>? _$flavors(ProjectConfig v) => v.flavors;
  static const Field<ProjectConfig, Map<String, String>> _f$flavors =
      Field('flavors', _$flavors, opt: true);
  static String? _$cachePath(ProjectConfig v) => v.cachePath;
  static const Field<ProjectConfig, String> _f$cachePath =
      Field('cachePath', _$cachePath, opt: true);
  static bool? _$useGitCache(ProjectConfig v) => v.useGitCache;
  static const Field<ProjectConfig, bool> _f$useGitCache =
      Field('useGitCache', _$useGitCache, opt: true);
  static String? _$gitCachePath(ProjectConfig v) => v.gitCachePath;
  static const Field<ProjectConfig, String> _f$gitCachePath =
      Field('gitCachePath', _$gitCachePath, opt: true);
  static String? _$flutterUrl(ProjectConfig v) => v.flutterUrl;
  static const Field<ProjectConfig, String> _f$flutterUrl =
      Field('flutterUrl', _$flutterUrl, opt: true);
  static bool? _$priviledgedAccess(ProjectConfig v) => v.priviledgedAccess;
  static const Field<ProjectConfig, bool> _f$priviledgedAccess =
      Field('priviledgedAccess', _$priviledgedAccess, opt: true);
  static bool? _$runPubGetOnSdkChanges(ProjectConfig v) =>
      v.runPubGetOnSdkChanges;
  static const Field<ProjectConfig, bool> _f$runPubGetOnSdkChanges =
      Field('runPubGetOnSdkChanges', _$runPubGetOnSdkChanges, opt: true);
  static bool? _$updateVscodeSettings(ProjectConfig v) =>
      v.updateVscodeSettings;
  static const Field<ProjectConfig, bool> _f$updateVscodeSettings =
      Field('updateVscodeSettings', _$updateVscodeSettings, opt: true);
  static bool? _$updateGitIgnore(ProjectConfig v) => v.updateGitIgnore;
  static const Field<ProjectConfig, bool> _f$updateGitIgnore =
      Field('updateGitIgnore', _$updateGitIgnore, opt: true);

  @override
  final MappableFields<ProjectConfig> fields = const {
    #flutterSdkVersion: _f$flutterSdkVersion,
    #flavors: _f$flavors,
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #priviledgedAccess: _f$priviledgedAccess,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #updateVscodeSettings: _f$updateVscodeSettings,
    #updateGitIgnore: _f$updateGitIgnore,
  };
  @override
  final bool ignoreNull = true;

  static ProjectConfig _instantiate(DecodingData data) {
    return ProjectConfig(
        flutterSdkVersion: data.dec(_f$flutterSdkVersion),
        flavors: data.dec(_f$flavors),
        cachePath: data.dec(_f$cachePath),
        useGitCache: data.dec(_f$useGitCache),
        gitCachePath: data.dec(_f$gitCachePath),
        flutterUrl: data.dec(_f$flutterUrl),
        priviledgedAccess: data.dec(_f$priviledgedAccess),
        runPubGetOnSdkChanges: data.dec(_f$runPubGetOnSdkChanges),
        updateVscodeSettings: data.dec(_f$updateVscodeSettings),
        updateGitIgnore: data.dec(_f$updateGitIgnore));
  }

  @override
  final Function instantiate = _instantiate;

  static ProjectConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ProjectConfig>(map);
  }

  static ProjectConfig fromJson(String json) {
    return ensureInitialized().decodeJson<ProjectConfig>(json);
  }
}

mixin ProjectConfigMappable {
  String toJson() {
    return ProjectConfigMapper.ensureInitialized()
        .encodeJson<ProjectConfig>(this as ProjectConfig);
  }

  Map<String, dynamic> toMap() {
    return ProjectConfigMapper.ensureInitialized()
        .encodeMap<ProjectConfig>(this as ProjectConfig);
  }

  ProjectConfigCopyWith<ProjectConfig, ProjectConfig, ProjectConfig>
      get copyWith => _ProjectConfigCopyWithImpl(
          this as ProjectConfig, $identity, $identity);
  @override
  String toString() {
    return ProjectConfigMapper.ensureInitialized()
        .stringifyValue(this as ProjectConfig);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            ProjectConfigMapper.ensureInitialized()
                .isValueEqual(this as ProjectConfig, other));
  }

  @override
  int get hashCode {
    return ProjectConfigMapper.ensureInitialized()
        .hashValue(this as ProjectConfig);
  }
}

extension ProjectConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ProjectConfig, $Out> {
  ProjectConfigCopyWith<$R, ProjectConfig, $Out> get $asProjectConfig =>
      $base.as((v, t, t2) => _ProjectConfigCopyWithImpl(v, t, t2));
}

abstract class ProjectConfigCopyWith<$R, $In extends ProjectConfig, $Out>
    implements FileConfigCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get flavors;
  @override
  $R call(
      {String? flutterSdkVersion,
      Map<String, String>? flavors,
      String? cachePath,
      bool? useGitCache,
      String? gitCachePath,
      String? flutterUrl,
      bool? priviledgedAccess,
      bool? runPubGetOnSdkChanges,
      bool? updateVscodeSettings,
      bool? updateGitIgnore});
  ProjectConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ProjectConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ProjectConfig, $Out>
    implements ProjectConfigCopyWith<$R, ProjectConfig, $Out> {
  _ProjectConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ProjectConfig> $mapper =
      ProjectConfigMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get flavors => $value.flavors != null
          ? MapCopyWith(
              $value.flavors!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(flavors: v))
          : null;
  @override
  $R call(
          {Object? flutterSdkVersion = $none,
          Object? flavors = $none,
          Object? cachePath = $none,
          Object? useGitCache = $none,
          Object? gitCachePath = $none,
          Object? flutterUrl = $none,
          Object? priviledgedAccess = $none,
          Object? runPubGetOnSdkChanges = $none,
          Object? updateVscodeSettings = $none,
          Object? updateGitIgnore = $none}) =>
      $apply(FieldCopyWithData({
        if (flutterSdkVersion != $none) #flutterSdkVersion: flutterSdkVersion,
        if (flavors != $none) #flavors: flavors,
        if (cachePath != $none) #cachePath: cachePath,
        if (useGitCache != $none) #useGitCache: useGitCache,
        if (gitCachePath != $none) #gitCachePath: gitCachePath,
        if (flutterUrl != $none) #flutterUrl: flutterUrl,
        if (priviledgedAccess != $none) #priviledgedAccess: priviledgedAccess,
        if (runPubGetOnSdkChanges != $none)
          #runPubGetOnSdkChanges: runPubGetOnSdkChanges,
        if (updateVscodeSettings != $none)
          #updateVscodeSettings: updateVscodeSettings,
        if (updateGitIgnore != $none) #updateGitIgnore: updateGitIgnore
      }));
  @override
  ProjectConfig $make(CopyWithData data) => ProjectConfig(
      flutterSdkVersion:
          data.get(#flutterSdkVersion, or: $value.flutterSdkVersion),
      flavors: data.get(#flavors, or: $value.flavors),
      cachePath: data.get(#cachePath, or: $value.cachePath),
      useGitCache: data.get(#useGitCache, or: $value.useGitCache),
      gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
      flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl),
      priviledgedAccess:
          data.get(#priviledgedAccess, or: $value.priviledgedAccess),
      runPubGetOnSdkChanges:
          data.get(#runPubGetOnSdkChanges, or: $value.runPubGetOnSdkChanges),
      updateVscodeSettings:
          data.get(#updateVscodeSettings, or: $value.updateVscodeSettings),
      updateGitIgnore: data.get(#updateGitIgnore, or: $value.updateGitIgnore));

  @override
  ProjectConfigCopyWith<$R2, ProjectConfig, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ProjectConfigCopyWithImpl($value, $cast, t);
}
