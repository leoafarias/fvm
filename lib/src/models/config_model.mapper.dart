// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'config_model.dart';

class ConfigOptionsMapper extends EnumMapper<ConfigOptions> {
  ConfigOptionsMapper._();

  static ConfigOptionsMapper? _instance;
  static ConfigOptionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ConfigOptionsMapper._());
    }
    return _instance!;
  }

  static ConfigOptions fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ConfigOptions decode(dynamic value) {
    switch (value) {
      case r'cachePath':
        return ConfigOptions.cachePath;
      case r'useGitCache':
        return ConfigOptions.useGitCache;
      case r'gitCachePath':
        return ConfigOptions.gitCachePath;
      case r'flutterUrl':
        return ConfigOptions.flutterUrl;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ConfigOptions self) {
    switch (self) {
      case ConfigOptions.cachePath:
        return r'cachePath';
      case ConfigOptions.useGitCache:
        return r'useGitCache';
      case ConfigOptions.gitCachePath:
        return r'gitCachePath';
      case ConfigOptions.flutterUrl:
        return r'flutterUrl';
    }
  }
}

extension ConfigOptionsMapperExtension on ConfigOptions {
  String toValue() {
    ConfigOptionsMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ConfigOptions>(this) as String;
  }
}

class EnvConfigMapper extends ClassMapperBase<EnvConfig> {
  EnvConfigMapper._();

  static EnvConfigMapper? _instance;
  static EnvConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnvConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EnvConfig';

  static String? _$cachePath(EnvConfig v) => v.cachePath;
  static const Field<EnvConfig, String> _f$cachePath = Field(
    'cachePath',
    _$cachePath,
    opt: true,
  );
  static bool? _$useGitCache(EnvConfig v) => v.useGitCache;
  static const Field<EnvConfig, bool> _f$useGitCache = Field(
    'useGitCache',
    _$useGitCache,
    opt: true,
  );
  static String? _$gitCachePath(EnvConfig v) => v.gitCachePath;
  static const Field<EnvConfig, String> _f$gitCachePath = Field(
    'gitCachePath',
    _$gitCachePath,
    opt: true,
  );
  static String? _$flutterUrl(EnvConfig v) => v.flutterUrl;
  static const Field<EnvConfig, String> _f$flutterUrl = Field(
    'flutterUrl',
    _$flutterUrl,
    opt: true,
  );

  @override
  final MappableFields<EnvConfig> fields = const {
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
  };
  @override
  final bool ignoreNull = true;

  static EnvConfig _instantiate(DecodingData data) {
    return EnvConfig(
      cachePath: data.dec(_f$cachePath),
      useGitCache: data.dec(_f$useGitCache),
      gitCachePath: data.dec(_f$gitCachePath),
      flutterUrl: data.dec(_f$flutterUrl),
    );
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
    return EnvConfigMapper.ensureInitialized().encodeJson<EnvConfig>(
      this as EnvConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return EnvConfigMapper.ensureInitialized().encodeMap<EnvConfig>(
      this as EnvConfig,
    );
  }

  EnvConfigCopyWith<EnvConfig, EnvConfig, EnvConfig> get copyWith =>
      _EnvConfigCopyWithImpl<EnvConfig, EnvConfig>(
        this as EnvConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return EnvConfigMapper.ensureInitialized().stringifyValue(
      this as EnvConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return EnvConfigMapper.ensureInitialized().equalsValue(
      this as EnvConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return EnvConfigMapper.ensureInitialized().hashValue(this as EnvConfig);
  }
}

extension EnvConfigValueCopy<$R, $Out> on ObjectCopyWith<$R, EnvConfig, $Out> {
  EnvConfigCopyWith<$R, EnvConfig, $Out> get $asEnvConfig =>
      $base.as((v, t, t2) => _EnvConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class EnvConfigCopyWith<$R, $In extends EnvConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
  });
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
  $R call({
    Object? cachePath = $none,
    Object? useGitCache = $none,
    Object? gitCachePath = $none,
    Object? flutterUrl = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (cachePath != $none) #cachePath: cachePath,
          if (useGitCache != $none) #useGitCache: useGitCache,
          if (gitCachePath != $none) #gitCachePath: gitCachePath,
          if (flutterUrl != $none) #flutterUrl: flutterUrl,
        }),
      );
  @override
  EnvConfig $make(CopyWithData data) => EnvConfig(
        cachePath: data.get(#cachePath, or: $value.cachePath),
        useGitCache: data.get(#useGitCache, or: $value.useGitCache),
        gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
        flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl),
      );

  @override
  EnvConfigCopyWith<$R2, EnvConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _EnvConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class AppConfigMapper extends ClassMapperBase<AppConfig> {
  AppConfigMapper._();

  static AppConfigMapper? _instance;
  static AppConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AppConfigMapper._());
      LocalAppConfigMapper.ensureInitialized();
      FlutterForkMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AppConfig';

  static bool? _$disableUpdateCheck(AppConfig v) => v.disableUpdateCheck;
  static const Field<AppConfig, bool> _f$disableUpdateCheck = Field(
    'disableUpdateCheck',
    _$disableUpdateCheck,
    opt: true,
  );
  static DateTime? _$lastUpdateCheck(AppConfig v) => v.lastUpdateCheck;
  static const Field<AppConfig, DateTime> _f$lastUpdateCheck = Field(
    'lastUpdateCheck',
    _$lastUpdateCheck,
    opt: true,
  );
  static Set<FlutterFork> _$forks(AppConfig v) => v.forks;
  static const Field<AppConfig, Set<FlutterFork>> _f$forks = Field(
    'forks',
    _$forks,
    opt: true,
    def: const {},
  );
  static String? _$cachePath(AppConfig v) => v.cachePath;
  static const Field<AppConfig, String> _f$cachePath = Field(
    'cachePath',
    _$cachePath,
    opt: true,
  );
  static bool? _$useGitCache(AppConfig v) => v.useGitCache;
  static const Field<AppConfig, bool> _f$useGitCache = Field(
    'useGitCache',
    _$useGitCache,
    opt: true,
  );
  static String? _$gitCachePath(AppConfig v) => v.gitCachePath;
  static const Field<AppConfig, String> _f$gitCachePath = Field(
    'gitCachePath',
    _$gitCachePath,
    opt: true,
  );
  static String? _$flutterUrl(AppConfig v) => v.flutterUrl;
  static const Field<AppConfig, String> _f$flutterUrl = Field(
    'flutterUrl',
    _$flutterUrl,
    opt: true,
  );
  static bool? _$privilegedAccess(AppConfig v) => v.privilegedAccess;
  static const Field<AppConfig, bool> _f$privilegedAccess = Field(
    'privilegedAccess',
    _$privilegedAccess,
    opt: true,
  );
  static bool? _$runPubGetOnSdkChanges(AppConfig v) => v.runPubGetOnSdkChanges;
  static const Field<AppConfig, bool> _f$runPubGetOnSdkChanges = Field(
    'runPubGetOnSdkChanges',
    _$runPubGetOnSdkChanges,
    opt: true,
  );
  static bool? _$updateVscodeSettings(AppConfig v) => v.updateVscodeSettings;
  static const Field<AppConfig, bool> _f$updateVscodeSettings = Field(
    'updateVscodeSettings',
    _$updateVscodeSettings,
    opt: true,
  );
  static bool? _$updateGitIgnore(AppConfig v) => v.updateGitIgnore;
  static const Field<AppConfig, bool> _f$updateGitIgnore = Field(
    'updateGitIgnore',
    _$updateGitIgnore,
    opt: true,
  );
  static bool? _$updateMelosSettings(AppConfig v) => v.updateMelosSettings;
  static const Field<AppConfig, bool> _f$updateMelosSettings = Field(
    'updateMelosSettings',
    _$updateMelosSettings,
    opt: true,
  );

  @override
  final MappableFields<AppConfig> fields = const {
    #disableUpdateCheck: _f$disableUpdateCheck,
    #lastUpdateCheck: _f$lastUpdateCheck,
    #forks: _f$forks,
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #privilegedAccess: _f$privilegedAccess,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #updateVscodeSettings: _f$updateVscodeSettings,
    #updateGitIgnore: _f$updateGitIgnore,
    #updateMelosSettings: _f$updateMelosSettings,
  };
  @override
  final bool ignoreNull = true;

  static AppConfig _instantiate(DecodingData data) {
    return AppConfig(
      disableUpdateCheck: data.dec(_f$disableUpdateCheck),
      lastUpdateCheck: data.dec(_f$lastUpdateCheck),
      forks: data.dec(_f$forks),
      cachePath: data.dec(_f$cachePath),
      useGitCache: data.dec(_f$useGitCache),
      gitCachePath: data.dec(_f$gitCachePath),
      flutterUrl: data.dec(_f$flutterUrl),
      privilegedAccess: data.dec(_f$privilegedAccess),
      runPubGetOnSdkChanges: data.dec(_f$runPubGetOnSdkChanges),
      updateVscodeSettings: data.dec(_f$updateVscodeSettings),
      updateGitIgnore: data.dec(_f$updateGitIgnore),
      updateMelosSettings: data.dec(_f$updateMelosSettings),
    );
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
    return AppConfigMapper.ensureInitialized().encodeJson<AppConfig>(
      this as AppConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return AppConfigMapper.ensureInitialized().encodeMap<AppConfig>(
      this as AppConfig,
    );
  }

  AppConfigCopyWith<AppConfig, AppConfig, AppConfig> get copyWith =>
      _AppConfigCopyWithImpl<AppConfig, AppConfig>(
        this as AppConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AppConfigMapper.ensureInitialized().stringifyValue(
      this as AppConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return AppConfigMapper.ensureInitialized().equalsValue(
      this as AppConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return AppConfigMapper.ensureInitialized().hashValue(this as AppConfig);
  }
}

extension AppConfigValueCopy<$R, $Out> on ObjectCopyWith<$R, AppConfig, $Out> {
  AppConfigCopyWith<$R, AppConfig, $Out> get $asAppConfig =>
      $base.as((v, t, t2) => _AppConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AppConfigCopyWith<$R, $In extends AppConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    bool? disableUpdateCheck,
    DateTime? lastUpdateCheck,
    Set<FlutterFork>? forks,
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
    bool? privilegedAccess,
    bool? runPubGetOnSdkChanges,
    bool? updateVscodeSettings,
    bool? updateGitIgnore,
    bool? updateMelosSettings,
  });
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
  $R call({
    Object? disableUpdateCheck = $none,
    Object? lastUpdateCheck = $none,
    Set<FlutterFork>? forks,
    Object? cachePath = $none,
    Object? useGitCache = $none,
    Object? gitCachePath = $none,
    Object? flutterUrl = $none,
    Object? privilegedAccess = $none,
    Object? runPubGetOnSdkChanges = $none,
    Object? updateVscodeSettings = $none,
    Object? updateGitIgnore = $none,
    Object? updateMelosSettings = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (disableUpdateCheck != $none)
            #disableUpdateCheck: disableUpdateCheck,
          if (lastUpdateCheck != $none) #lastUpdateCheck: lastUpdateCheck,
          if (forks != null) #forks: forks,
          if (cachePath != $none) #cachePath: cachePath,
          if (useGitCache != $none) #useGitCache: useGitCache,
          if (gitCachePath != $none) #gitCachePath: gitCachePath,
          if (flutterUrl != $none) #flutterUrl: flutterUrl,
          if (privilegedAccess != $none) #privilegedAccess: privilegedAccess,
          if (runPubGetOnSdkChanges != $none)
            #runPubGetOnSdkChanges: runPubGetOnSdkChanges,
          if (updateVscodeSettings != $none)
            #updateVscodeSettings: updateVscodeSettings,
          if (updateGitIgnore != $none) #updateGitIgnore: updateGitIgnore,
          if (updateMelosSettings != $none)
            #updateMelosSettings: updateMelosSettings,
        }),
      );
  @override
  AppConfig $make(CopyWithData data) => AppConfig(
        disableUpdateCheck: data.get(
          #disableUpdateCheck,
          or: $value.disableUpdateCheck,
        ),
        lastUpdateCheck: data.get(#lastUpdateCheck, or: $value.lastUpdateCheck),
        forks: data.get(#forks, or: $value.forks),
        cachePath: data.get(#cachePath, or: $value.cachePath),
        useGitCache: data.get(#useGitCache, or: $value.useGitCache),
        gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
        flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl),
        privilegedAccess:
            data.get(#privilegedAccess, or: $value.privilegedAccess),
        runPubGetOnSdkChanges: data.get(
          #runPubGetOnSdkChanges,
          or: $value.runPubGetOnSdkChanges,
        ),
        updateVscodeSettings: data.get(
          #updateVscodeSettings,
          or: $value.updateVscodeSettings,
        ),
        updateGitIgnore: data.get(#updateGitIgnore, or: $value.updateGitIgnore),
        updateMelosSettings: data.get(
          #updateMelosSettings,
          or: $value.updateMelosSettings,
        ),
      );

  @override
  AppConfigCopyWith<$R2, AppConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _AppConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class LocalAppConfigMapper extends ClassMapperBase<LocalAppConfig> {
  LocalAppConfigMapper._();

  static LocalAppConfigMapper? _instance;
  static LocalAppConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LocalAppConfigMapper._());
      AppConfigMapper.ensureInitialized();
      FlutterForkMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LocalAppConfig';

  static bool? _$disableUpdateCheck(LocalAppConfig v) => v.disableUpdateCheck;
  static const Field<LocalAppConfig, bool> _f$disableUpdateCheck = Field(
    'disableUpdateCheck',
    _$disableUpdateCheck,
    opt: true,
  );
  static DateTime? _$lastUpdateCheck(LocalAppConfig v) => v.lastUpdateCheck;
  static const Field<LocalAppConfig, DateTime> _f$lastUpdateCheck = Field(
    'lastUpdateCheck',
    _$lastUpdateCheck,
    opt: true,
  );
  static String? _$cachePath(LocalAppConfig v) => v.cachePath;
  static const Field<LocalAppConfig, String> _f$cachePath = Field(
    'cachePath',
    _$cachePath,
    opt: true,
  );
  static bool? _$useGitCache(LocalAppConfig v) => v.useGitCache;
  static const Field<LocalAppConfig, bool> _f$useGitCache = Field(
    'useGitCache',
    _$useGitCache,
    opt: true,
  );
  static String? _$gitCachePath(LocalAppConfig v) => v.gitCachePath;
  static const Field<LocalAppConfig, String> _f$gitCachePath = Field(
    'gitCachePath',
    _$gitCachePath,
    opt: true,
  );
  static String? _$flutterUrl(LocalAppConfig v) => v.flutterUrl;
  static const Field<LocalAppConfig, String> _f$flutterUrl = Field(
    'flutterUrl',
    _$flutterUrl,
    opt: true,
  );
  static bool? _$privilegedAccess(LocalAppConfig v) => v.privilegedAccess;
  static const Field<LocalAppConfig, bool> _f$privilegedAccess = Field(
    'privilegedAccess',
    _$privilegedAccess,
    opt: true,
  );
  static bool? _$runPubGetOnSdkChanges(LocalAppConfig v) =>
      v.runPubGetOnSdkChanges;
  static const Field<LocalAppConfig, bool> _f$runPubGetOnSdkChanges = Field(
    'runPubGetOnSdkChanges',
    _$runPubGetOnSdkChanges,
    opt: true,
  );
  static bool? _$updateVscodeSettings(LocalAppConfig v) =>
      v.updateVscodeSettings;
  static const Field<LocalAppConfig, bool> _f$updateVscodeSettings = Field(
    'updateVscodeSettings',
    _$updateVscodeSettings,
    opt: true,
  );
  static bool? _$updateGitIgnore(LocalAppConfig v) => v.updateGitIgnore;
  static const Field<LocalAppConfig, bool> _f$updateGitIgnore = Field(
    'updateGitIgnore',
    _$updateGitIgnore,
    opt: true,
  );
  static bool? _$updateMelosSettings(LocalAppConfig v) => v.updateMelosSettings;
  static const Field<LocalAppConfig, bool> _f$updateMelosSettings = Field(
    'updateMelosSettings',
    _$updateMelosSettings,
    opt: true,
  );
  static Set<FlutterFork> _$forks(LocalAppConfig v) => v.forks;
  static const Field<LocalAppConfig, Set<FlutterFork>> _f$forks = Field(
    'forks',
    _$forks,
    opt: true,
  );

  @override
  final MappableFields<LocalAppConfig> fields = const {
    #disableUpdateCheck: _f$disableUpdateCheck,
    #lastUpdateCheck: _f$lastUpdateCheck,
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #privilegedAccess: _f$privilegedAccess,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #updateVscodeSettings: _f$updateVscodeSettings,
    #updateGitIgnore: _f$updateGitIgnore,
    #updateMelosSettings: _f$updateMelosSettings,
    #forks: _f$forks,
  };
  @override
  final bool ignoreNull = true;

  static LocalAppConfig _instantiate(DecodingData data) {
    return LocalAppConfig(
      disableUpdateCheck: data.dec(_f$disableUpdateCheck),
      lastUpdateCheck: data.dec(_f$lastUpdateCheck),
      cachePath: data.dec(_f$cachePath),
      useGitCache: data.dec(_f$useGitCache),
      gitCachePath: data.dec(_f$gitCachePath),
      flutterUrl: data.dec(_f$flutterUrl),
      privilegedAccess: data.dec(_f$privilegedAccess),
      runPubGetOnSdkChanges: data.dec(_f$runPubGetOnSdkChanges),
      updateVscodeSettings: data.dec(_f$updateVscodeSettings),
      updateGitIgnore: data.dec(_f$updateGitIgnore),
      updateMelosSettings: data.dec(_f$updateMelosSettings),
      forks: data.dec(_f$forks),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LocalAppConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LocalAppConfig>(map);
  }

  static LocalAppConfig fromJson(String json) {
    return ensureInitialized().decodeJson<LocalAppConfig>(json);
  }
}

mixin LocalAppConfigMappable {
  String toJson() {
    return LocalAppConfigMapper.ensureInitialized().encodeJson<LocalAppConfig>(
      this as LocalAppConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return LocalAppConfigMapper.ensureInitialized().encodeMap<LocalAppConfig>(
      this as LocalAppConfig,
    );
  }

  LocalAppConfigCopyWith<LocalAppConfig, LocalAppConfig, LocalAppConfig>
      get copyWith =>
          _LocalAppConfigCopyWithImpl<LocalAppConfig, LocalAppConfig>(
            this as LocalAppConfig,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return LocalAppConfigMapper.ensureInitialized().stringifyValue(
      this as LocalAppConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return LocalAppConfigMapper.ensureInitialized().equalsValue(
      this as LocalAppConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return LocalAppConfigMapper.ensureInitialized().hashValue(
      this as LocalAppConfig,
    );
  }
}

extension LocalAppConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LocalAppConfig, $Out> {
  LocalAppConfigCopyWith<$R, LocalAppConfig, $Out> get $asLocalAppConfig =>
      $base.as((v, t, t2) => _LocalAppConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LocalAppConfigCopyWith<$R, $In extends LocalAppConfig, $Out>
    implements AppConfigCopyWith<$R, $In, $Out> {
  @override
  $R call({
    bool? disableUpdateCheck,
    DateTime? lastUpdateCheck,
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
    bool? privilegedAccess,
    bool? runPubGetOnSdkChanges,
    bool? updateVscodeSettings,
    bool? updateGitIgnore,
    bool? updateMelosSettings,
    Set<FlutterFork>? forks,
  });
  LocalAppConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _LocalAppConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LocalAppConfig, $Out>
    implements LocalAppConfigCopyWith<$R, LocalAppConfig, $Out> {
  _LocalAppConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LocalAppConfig> $mapper =
      LocalAppConfigMapper.ensureInitialized();
  @override
  $R call({
    Object? disableUpdateCheck = $none,
    Object? lastUpdateCheck = $none,
    Object? cachePath = $none,
    Object? useGitCache = $none,
    Object? gitCachePath = $none,
    Object? flutterUrl = $none,
    Object? privilegedAccess = $none,
    Object? runPubGetOnSdkChanges = $none,
    Object? updateVscodeSettings = $none,
    Object? updateGitIgnore = $none,
    Object? updateMelosSettings = $none,
    Object? forks = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (disableUpdateCheck != $none)
            #disableUpdateCheck: disableUpdateCheck,
          if (lastUpdateCheck != $none) #lastUpdateCheck: lastUpdateCheck,
          if (cachePath != $none) #cachePath: cachePath,
          if (useGitCache != $none) #useGitCache: useGitCache,
          if (gitCachePath != $none) #gitCachePath: gitCachePath,
          if (flutterUrl != $none) #flutterUrl: flutterUrl,
          if (privilegedAccess != $none) #privilegedAccess: privilegedAccess,
          if (runPubGetOnSdkChanges != $none)
            #runPubGetOnSdkChanges: runPubGetOnSdkChanges,
          if (updateVscodeSettings != $none)
            #updateVscodeSettings: updateVscodeSettings,
          if (updateGitIgnore != $none) #updateGitIgnore: updateGitIgnore,
          if (updateMelosSettings != $none)
            #updateMelosSettings: updateMelosSettings,
          if (forks != $none) #forks: forks,
        }),
      );
  @override
  LocalAppConfig $make(CopyWithData data) => LocalAppConfig(
        disableUpdateCheck: data.get(
          #disableUpdateCheck,
          or: $value.disableUpdateCheck,
        ),
        lastUpdateCheck: data.get(#lastUpdateCheck, or: $value.lastUpdateCheck),
        cachePath: data.get(#cachePath, or: $value.cachePath),
        useGitCache: data.get(#useGitCache, or: $value.useGitCache),
        gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
        flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl),
        privilegedAccess:
            data.get(#privilegedAccess, or: $value.privilegedAccess),
        runPubGetOnSdkChanges: data.get(
          #runPubGetOnSdkChanges,
          or: $value.runPubGetOnSdkChanges,
        ),
        updateVscodeSettings: data.get(
          #updateVscodeSettings,
          or: $value.updateVscodeSettings,
        ),
        updateGitIgnore: data.get(#updateGitIgnore, or: $value.updateGitIgnore),
        updateMelosSettings: data.get(
          #updateMelosSettings,
          or: $value.updateMelosSettings,
        ),
        forks: data.get(#forks, or: $value.forks),
      );

  @override
  LocalAppConfigCopyWith<$R2, LocalAppConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _LocalAppConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ProjectConfigMapper extends ClassMapperBase<ProjectConfig> {
  ProjectConfigMapper._();

  static ProjectConfigMapper? _instance;
  static ProjectConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ProjectConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ProjectConfig';

  static String? _$flutter(ProjectConfig v) => v.flutter;
  static const Field<ProjectConfig, String> _f$flutter = Field(
    'flutter',
    _$flutter,
    opt: true,
  );
  static Map<String, String>? _$flavors(ProjectConfig v) => v.flavors;
  static const Field<ProjectConfig, Map<String, String>> _f$flavors = Field(
    'flavors',
    _$flavors,
    opt: true,
  );
  static String? _$cachePath(ProjectConfig v) => v.cachePath;
  static const Field<ProjectConfig, String> _f$cachePath = Field(
    'cachePath',
    _$cachePath,
    opt: true,
  );
  static bool? _$useGitCache(ProjectConfig v) => v.useGitCache;
  static const Field<ProjectConfig, bool> _f$useGitCache = Field(
    'useGitCache',
    _$useGitCache,
    opt: true,
  );
  static String? _$gitCachePath(ProjectConfig v) => v.gitCachePath;
  static const Field<ProjectConfig, String> _f$gitCachePath = Field(
    'gitCachePath',
    _$gitCachePath,
    opt: true,
  );
  static String? _$flutterUrl(ProjectConfig v) => v.flutterUrl;
  static const Field<ProjectConfig, String> _f$flutterUrl = Field(
    'flutterUrl',
    _$flutterUrl,
    opt: true,
  );
  static bool? _$privilegedAccess(ProjectConfig v) => v.privilegedAccess;
  static const Field<ProjectConfig, bool> _f$privilegedAccess = Field(
    'privilegedAccess',
    _$privilegedAccess,
    opt: true,
  );
  static bool? _$runPubGetOnSdkChanges(ProjectConfig v) =>
      v.runPubGetOnSdkChanges;
  static const Field<ProjectConfig, bool> _f$runPubGetOnSdkChanges = Field(
    'runPubGetOnSdkChanges',
    _$runPubGetOnSdkChanges,
    opt: true,
  );
  static bool? _$updateVscodeSettings(ProjectConfig v) =>
      v.updateVscodeSettings;
  static const Field<ProjectConfig, bool> _f$updateVscodeSettings = Field(
    'updateVscodeSettings',
    _$updateVscodeSettings,
    opt: true,
  );
  static bool? _$updateGitIgnore(ProjectConfig v) => v.updateGitIgnore;
  static const Field<ProjectConfig, bool> _f$updateGitIgnore = Field(
    'updateGitIgnore',
    _$updateGitIgnore,
    opt: true,
  );
  static bool? _$updateMelosSettings(ProjectConfig v) => v.updateMelosSettings;
  static const Field<ProjectConfig, bool> _f$updateMelosSettings = Field(
    'updateMelosSettings',
    _$updateMelosSettings,
    opt: true,
  );

  @override
  final MappableFields<ProjectConfig> fields = const {
    #flutter: _f$flutter,
    #flavors: _f$flavors,
    #cachePath: _f$cachePath,
    #useGitCache: _f$useGitCache,
    #gitCachePath: _f$gitCachePath,
    #flutterUrl: _f$flutterUrl,
    #privilegedAccess: _f$privilegedAccess,
    #runPubGetOnSdkChanges: _f$runPubGetOnSdkChanges,
    #updateVscodeSettings: _f$updateVscodeSettings,
    #updateGitIgnore: _f$updateGitIgnore,
    #updateMelosSettings: _f$updateMelosSettings,
  };
  @override
  final bool ignoreNull = true;

  static ProjectConfig _instantiate(DecodingData data) {
    return ProjectConfig(
      flutter: data.dec(_f$flutter),
      flavors: data.dec(_f$flavors),
      cachePath: data.dec(_f$cachePath),
      useGitCache: data.dec(_f$useGitCache),
      gitCachePath: data.dec(_f$gitCachePath),
      flutterUrl: data.dec(_f$flutterUrl),
      privilegedAccess: data.dec(_f$privilegedAccess),
      runPubGetOnSdkChanges: data.dec(_f$runPubGetOnSdkChanges),
      updateVscodeSettings: data.dec(_f$updateVscodeSettings),
      updateGitIgnore: data.dec(_f$updateGitIgnore),
      updateMelosSettings: data.dec(_f$updateMelosSettings),
    );
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
    return ProjectConfigMapper.ensureInitialized().encodeJson<ProjectConfig>(
      this as ProjectConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return ProjectConfigMapper.ensureInitialized().encodeMap<ProjectConfig>(
      this as ProjectConfig,
    );
  }

  ProjectConfigCopyWith<ProjectConfig, ProjectConfig, ProjectConfig>
      get copyWith => _ProjectConfigCopyWithImpl<ProjectConfig, ProjectConfig>(
            this as ProjectConfig,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return ProjectConfigMapper.ensureInitialized().stringifyValue(
      this as ProjectConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return ProjectConfigMapper.ensureInitialized().equalsValue(
      this as ProjectConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return ProjectConfigMapper.ensureInitialized().hashValue(
      this as ProjectConfig,
    );
  }
}

extension ProjectConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ProjectConfig, $Out> {
  ProjectConfigCopyWith<$R, ProjectConfig, $Out> get $asProjectConfig =>
      $base.as((v, t, t2) => _ProjectConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ProjectConfigCopyWith<$R, $In extends ProjectConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get flavors;
  $R call({
    String? flutter,
    Map<String, String>? flavors,
    String? cachePath,
    bool? useGitCache,
    String? gitCachePath,
    String? flutterUrl,
    bool? privilegedAccess,
    bool? runPubGetOnSdkChanges,
    bool? updateVscodeSettings,
    bool? updateGitIgnore,
    bool? updateMelosSettings,
  });
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
              (v) => call(flavors: v),
            )
          : null;
  @override
  $R call({
    Object? flutter = $none,
    Object? flavors = $none,
    Object? cachePath = $none,
    Object? useGitCache = $none,
    Object? gitCachePath = $none,
    Object? flutterUrl = $none,
    Object? privilegedAccess = $none,
    Object? runPubGetOnSdkChanges = $none,
    Object? updateVscodeSettings = $none,
    Object? updateGitIgnore = $none,
    Object? updateMelosSettings = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (flutter != $none) #flutter: flutter,
          if (flavors != $none) #flavors: flavors,
          if (cachePath != $none) #cachePath: cachePath,
          if (useGitCache != $none) #useGitCache: useGitCache,
          if (gitCachePath != $none) #gitCachePath: gitCachePath,
          if (flutterUrl != $none) #flutterUrl: flutterUrl,
          if (privilegedAccess != $none) #privilegedAccess: privilegedAccess,
          if (runPubGetOnSdkChanges != $none)
            #runPubGetOnSdkChanges: runPubGetOnSdkChanges,
          if (updateVscodeSettings != $none)
            #updateVscodeSettings: updateVscodeSettings,
          if (updateGitIgnore != $none) #updateGitIgnore: updateGitIgnore,
          if (updateMelosSettings != $none)
            #updateMelosSettings: updateMelosSettings,
        }),
      );
  @override
  ProjectConfig $make(CopyWithData data) => ProjectConfig(
        flutter: data.get(#flutter, or: $value.flutter),
        flavors: data.get(#flavors, or: $value.flavors),
        cachePath: data.get(#cachePath, or: $value.cachePath),
        useGitCache: data.get(#useGitCache, or: $value.useGitCache),
        gitCachePath: data.get(#gitCachePath, or: $value.gitCachePath),
        flutterUrl: data.get(#flutterUrl, or: $value.flutterUrl),
        privilegedAccess:
            data.get(#privilegedAccess, or: $value.privilegedAccess),
        runPubGetOnSdkChanges: data.get(
          #runPubGetOnSdkChanges,
          or: $value.runPubGetOnSdkChanges,
        ),
        updateVscodeSettings: data.get(
          #updateVscodeSettings,
          or: $value.updateVscodeSettings,
        ),
        updateGitIgnore: data.get(#updateGitIgnore, or: $value.updateGitIgnore),
        updateMelosSettings: data.get(
          #updateMelosSettings,
          or: $value.updateMelosSettings,
        ),
      );

  @override
  ProjectConfigCopyWith<$R2, ProjectConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _ProjectConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
