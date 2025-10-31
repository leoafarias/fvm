// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'project_model.dart';

class ProjectMapper extends ClassMapperBase<Project> {
  ProjectMapper._();

  static ProjectMapper? _instance;
  static ProjectMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ProjectMapper._());
      MapperContainer.globals.useAll([PubspecMapper()]);
      ProjectConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Project';

  static ProjectConfig? _$config(Project v) => v.config;
  static const Field<Project, ProjectConfig> _f$config = Field(
    'config',
    _$config,
  );
  static String _$path(Project v) => v.path;
  static const Field<Project, String> _f$path = Field('path', _$path);
  static Pubspec? _$pubspec(Project v) => v.pubspec;
  static const Field<Project, Pubspec> _f$pubspec = Field('pubspec', _$pubspec);
  static String _$name(Project v) => v.name;
  static const Field<Project, String> _f$name = Field('name', _$name);
  static FlutterVersion? _$pinnedVersion(Project v) => v.pinnedVersion;
  static const Field<Project, FlutterVersion> _f$pinnedVersion = Field(
    'pinnedVersion',
    _$pinnedVersion,
  );
  static String? _$activeFlavor(Project v) => v.activeFlavor;
  static const Field<Project, String> _f$activeFlavor = Field(
    'activeFlavor',
    _$activeFlavor,
  );
  static Map<String, String> _$flavors(Project v) => v.flavors;
  static const Field<Project, Map<String, String>> _f$flavors = Field(
    'flavors',
    _$flavors,
  );
  static String? _$dartToolGeneratorVersion(Project v) =>
      v.dartToolGeneratorVersion;
  static const Field<Project, String> _f$dartToolGeneratorVersion = Field(
    'dartToolGeneratorVersion',
    _$dartToolGeneratorVersion,
  );
  static String? _$dartToolVersion(Project v) => v.dartToolVersion;
  static const Field<Project, String> _f$dartToolVersion = Field(
    'dartToolVersion',
    _$dartToolVersion,
  );
  static bool _$isFlutter(Project v) => v.isFlutter;
  static const Field<Project, bool> _f$isFlutter = Field(
    'isFlutter',
    _$isFlutter,
  );
  static String _$localFvmPath(Project v) => v.localFvmPath;
  static const Field<Project, String> _f$localFvmPath = Field(
    'localFvmPath',
    _$localFvmPath,
  );
  static String _$localVersionsCachePath(Project v) => v.localVersionsCachePath;
  static const Field<Project, String> _f$localVersionsCachePath = Field(
    'localVersionsCachePath',
    _$localVersionsCachePath,
  );
  static String _$localVersionSymlinkPath(Project v) =>
      v.localVersionSymlinkPath;
  static const Field<Project, String> _f$localVersionSymlinkPath = Field(
    'localVersionSymlinkPath',
    _$localVersionSymlinkPath,
  );
  static String _$gitIgnorePath(Project v) => v.gitIgnorePath;
  static const Field<Project, String> _f$gitIgnorePath = Field(
    'gitIgnorePath',
    _$gitIgnorePath,
  );
  static String _$pubspecPath(Project v) => v.pubspecPath;
  static const Field<Project, String> _f$pubspecPath = Field(
    'pubspecPath',
    _$pubspecPath,
  );
  static String _$configPath(Project v) => v.configPath;
  static const Field<Project, String> _f$configPath = Field(
    'configPath',
    _$configPath,
  );
  static String _$legacyConfigPath(Project v) => v.legacyConfigPath;
  static const Field<Project, String> _f$legacyConfigPath = Field(
    'legacyConfigPath',
    _$legacyConfigPath,
  );
  static bool _$hasConfig(Project v) => v.hasConfig;
  static const Field<Project, bool> _f$hasConfig = Field(
    'hasConfig',
    _$hasConfig,
  );
  static bool _$hasPubspec(Project v) => v.hasPubspec;
  static const Field<Project, bool> _f$hasPubspec = Field(
    'hasPubspec',
    _$hasPubspec,
  );

  @override
  final MappableFields<Project> fields = const {
    #config: _f$config,
    #path: _f$path,
    #pubspec: _f$pubspec,
    #name: _f$name,
    #pinnedVersion: _f$pinnedVersion,
    #activeFlavor: _f$activeFlavor,
    #flavors: _f$flavors,
    #dartToolGeneratorVersion: _f$dartToolGeneratorVersion,
    #dartToolVersion: _f$dartToolVersion,
    #isFlutter: _f$isFlutter,
    #localFvmPath: _f$localFvmPath,
    #localVersionsCachePath: _f$localVersionsCachePath,
    #localVersionSymlinkPath: _f$localVersionSymlinkPath,
    #gitIgnorePath: _f$gitIgnorePath,
    #pubspecPath: _f$pubspecPath,
    #configPath: _f$configPath,
    #legacyConfigPath: _f$legacyConfigPath,
    #hasConfig: _f$hasConfig,
    #hasPubspec: _f$hasPubspec,
  };

  static Project _instantiate(DecodingData data) {
    return Project(
      config: data.dec(_f$config),
      path: data.dec(_f$path),
      pubspec: data.dec(_f$pubspec),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Project fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Project>(map);
  }

  static Project fromJson(String json) {
    return ensureInitialized().decodeJson<Project>(json);
  }
}

mixin ProjectMappable {
  String toJson() {
    return ProjectMapper.ensureInitialized().encodeJson<Project>(
      this as Project,
    );
  }

  Map<String, dynamic> toMap() {
    return ProjectMapper.ensureInitialized().encodeMap<Project>(
      this as Project,
    );
  }

  ProjectCopyWith<Project, Project, Project> get copyWith =>
      _ProjectCopyWithImpl<Project, Project>(
        this as Project,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ProjectMapper.ensureInitialized().stringifyValue(this as Project);
  }

  @override
  bool operator ==(Object other) {
    return ProjectMapper.ensureInitialized().equalsValue(
      this as Project,
      other,
    );
  }

  @override
  int get hashCode {
    return ProjectMapper.ensureInitialized().hashValue(this as Project);
  }
}

extension ProjectValueCopy<$R, $Out> on ObjectCopyWith<$R, Project, $Out> {
  ProjectCopyWith<$R, Project, $Out> get $asProject =>
      $base.as((v, t, t2) => _ProjectCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ProjectCopyWith<$R, $In extends Project, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ProjectConfigCopyWith<$R, ProjectConfig, ProjectConfig>? get config;
  $R call({ProjectConfig? config, String? path, Pubspec? pubspec});
  ProjectCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ProjectCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Project, $Out>
    implements ProjectCopyWith<$R, Project, $Out> {
  _ProjectCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Project> $mapper =
      ProjectMapper.ensureInitialized();
  @override
  ProjectConfigCopyWith<$R, ProjectConfig, ProjectConfig>? get config =>
      $value.config?.copyWith.$chain((v) => call(config: v));
  @override
  $R call({Object? config = $none, String? path, Object? pubspec = $none}) =>
      $apply(
        FieldCopyWithData({
          if (config != $none) #config: config,
          if (path != null) #path: path,
          if (pubspec != $none) #pubspec: pubspec,
        }),
      );
  @override
  Project $make(CopyWithData data) => Project(
    config: data.get(#config, or: $value.config),
    path: data.get(#path, or: $value.path),
    pubspec: data.get(#pubspec, or: $value.pubspec),
  );

  @override
  ProjectCopyWith<$R2, Project, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ProjectCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

