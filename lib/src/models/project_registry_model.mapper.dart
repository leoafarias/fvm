// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'project_registry_model.dart';

class ProjectRegistryDocumentMapper
    extends ClassMapperBase<ProjectRegistryDocument> {
  ProjectRegistryDocumentMapper._();

  static ProjectRegistryDocumentMapper? _instance;
  static ProjectRegistryDocumentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals
          .use(_instance = ProjectRegistryDocumentMapper._());
      ProjectRegistryEntryMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ProjectRegistryDocument';

  static int _$schemaVersion(ProjectRegistryDocument v) => v.schemaVersion;
  static const Field<ProjectRegistryDocument, int> _f$schemaVersion =
      Field('schemaVersion', _$schemaVersion);
  static List<ProjectRegistryEntry> _$projects(ProjectRegistryDocument v) =>
      v.projects;
  static const Field<ProjectRegistryDocument, List<ProjectRegistryEntry>>
      _f$projects = Field('projects', _$projects);

  @override
  final MappableFields<ProjectRegistryDocument> fields = const {
    #schemaVersion: _f$schemaVersion,
    #projects: _f$projects,
  };

  static ProjectRegistryDocument _instantiate(DecodingData data) {
    return ProjectRegistryDocument(
        schemaVersion: data.dec(_f$schemaVersion),
        projects: data.dec(_f$projects));
  }

  @override
  final Function instantiate = _instantiate;

  static ProjectRegistryDocument fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ProjectRegistryDocument>(map);
  }

  static ProjectRegistryDocument fromJson(String json) {
    return ensureInitialized().decodeJson<ProjectRegistryDocument>(json);
  }
}

mixin ProjectRegistryDocumentMappable {
  String toJson() {
    return ProjectRegistryDocumentMapper.ensureInitialized()
        .encodeJson<ProjectRegistryDocument>(this as ProjectRegistryDocument);
  }

  Map<String, dynamic> toMap() {
    return ProjectRegistryDocumentMapper.ensureInitialized()
        .encodeMap<ProjectRegistryDocument>(this as ProjectRegistryDocument);
  }

  ProjectRegistryDocumentCopyWith<ProjectRegistryDocument,
          ProjectRegistryDocument, ProjectRegistryDocument>
      get copyWith => _ProjectRegistryDocumentCopyWithImpl<
              ProjectRegistryDocument, ProjectRegistryDocument>(
          this as ProjectRegistryDocument, $identity, $identity);
  @override
  String toString() {
    return ProjectRegistryDocumentMapper.ensureInitialized()
        .stringifyValue(this as ProjectRegistryDocument);
  }

  @override
  bool operator ==(Object other) {
    return ProjectRegistryDocumentMapper.ensureInitialized()
        .equalsValue(this as ProjectRegistryDocument, other);
  }

  @override
  int get hashCode {
    return ProjectRegistryDocumentMapper.ensureInitialized()
        .hashValue(this as ProjectRegistryDocument);
  }
}

extension ProjectRegistryDocumentValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ProjectRegistryDocument, $Out> {
  ProjectRegistryDocumentCopyWith<$R, ProjectRegistryDocument, $Out>
      get $asProjectRegistryDocument => $base.as((v, t, t2) =>
          _ProjectRegistryDocumentCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ProjectRegistryDocumentCopyWith<
    $R,
    $In extends ProjectRegistryDocument,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
      $R,
      ProjectRegistryEntry,
      ProjectRegistryEntryCopyWith<$R, ProjectRegistryEntry,
          ProjectRegistryEntry>> get projects;
  $R call({int? schemaVersion, List<ProjectRegistryEntry>? projects});
  ProjectRegistryDocumentCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ProjectRegistryDocumentCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ProjectRegistryDocument, $Out>
    implements
        ProjectRegistryDocumentCopyWith<$R, ProjectRegistryDocument, $Out> {
  _ProjectRegistryDocumentCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ProjectRegistryDocument> $mapper =
      ProjectRegistryDocumentMapper.ensureInitialized();
  @override
  ListCopyWith<
      $R,
      ProjectRegistryEntry,
      ProjectRegistryEntryCopyWith<$R, ProjectRegistryEntry,
          ProjectRegistryEntry>> get projects => ListCopyWith($value.projects,
      (v, t) => v.copyWith.$chain(t), (v) => call(projects: v));
  @override
  $R call({int? schemaVersion, List<ProjectRegistryEntry>? projects}) =>
      $apply(FieldCopyWithData({
        if (schemaVersion != null) #schemaVersion: schemaVersion,
        if (projects != null) #projects: projects
      }));
  @override
  ProjectRegistryDocument $make(CopyWithData data) => ProjectRegistryDocument(
      schemaVersion: data.get(#schemaVersion, or: $value.schemaVersion),
      projects: data.get(#projects, or: $value.projects));

  @override
  ProjectRegistryDocumentCopyWith<$R2, ProjectRegistryDocument, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ProjectRegistryDocumentCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ProjectRegistryEntryMapper extends ClassMapperBase<ProjectRegistryEntry> {
  ProjectRegistryEntryMapper._();

  static ProjectRegistryEntryMapper? _instance;
  static ProjectRegistryEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ProjectRegistryEntryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ProjectRegistryEntry';

  static String _$path(ProjectRegistryEntry v) => v.path;
  static const Field<ProjectRegistryEntry, String> _f$path =
      Field('path', _$path);
  static String _$name(ProjectRegistryEntry v) => v.name;
  static const Field<ProjectRegistryEntry, String> _f$name =
      Field('name', _$name);
  static String? _$flutter(ProjectRegistryEntry v) => v.flutter;
  static const Field<ProjectRegistryEntry, String> _f$flutter =
      Field('flutter', _$flutter);
  static Map<String, String> _$flavors(ProjectRegistryEntry v) => v.flavors;
  static const Field<ProjectRegistryEntry, Map<String, String>> _f$flavors =
      Field('flavors', _$flavors);
  static DateTime _$firstSeenAt(ProjectRegistryEntry v) => v.firstSeenAt;
  static const Field<ProjectRegistryEntry, DateTime> _f$firstSeenAt =
      Field('firstSeenAt', _$firstSeenAt);
  static DateTime _$lastSeenAt(ProjectRegistryEntry v) => v.lastSeenAt;
  static const Field<ProjectRegistryEntry, DateTime> _f$lastSeenAt =
      Field('lastSeenAt', _$lastSeenAt);

  @override
  final MappableFields<ProjectRegistryEntry> fields = const {
    #path: _f$path,
    #name: _f$name,
    #flutter: _f$flutter,
    #flavors: _f$flavors,
    #firstSeenAt: _f$firstSeenAt,
    #lastSeenAt: _f$lastSeenAt,
  };

  static ProjectRegistryEntry _instantiate(DecodingData data) {
    return ProjectRegistryEntry(
        path: data.dec(_f$path),
        name: data.dec(_f$name),
        flutter: data.dec(_f$flutter),
        flavors: data.dec(_f$flavors),
        firstSeenAt: data.dec(_f$firstSeenAt),
        lastSeenAt: data.dec(_f$lastSeenAt));
  }

  @override
  final Function instantiate = _instantiate;

  static ProjectRegistryEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ProjectRegistryEntry>(map);
  }

  static ProjectRegistryEntry fromJson(String json) {
    return ensureInitialized().decodeJson<ProjectRegistryEntry>(json);
  }
}

mixin ProjectRegistryEntryMappable {
  String toJson() {
    return ProjectRegistryEntryMapper.ensureInitialized()
        .encodeJson<ProjectRegistryEntry>(this as ProjectRegistryEntry);
  }

  Map<String, dynamic> toMap() {
    return ProjectRegistryEntryMapper.ensureInitialized()
        .encodeMap<ProjectRegistryEntry>(this as ProjectRegistryEntry);
  }

  ProjectRegistryEntryCopyWith<ProjectRegistryEntry, ProjectRegistryEntry,
      ProjectRegistryEntry> get copyWith => _ProjectRegistryEntryCopyWithImpl<
          ProjectRegistryEntry, ProjectRegistryEntry>(
      this as ProjectRegistryEntry, $identity, $identity);
  @override
  String toString() {
    return ProjectRegistryEntryMapper.ensureInitialized()
        .stringifyValue(this as ProjectRegistryEntry);
  }

  @override
  bool operator ==(Object other) {
    return ProjectRegistryEntryMapper.ensureInitialized()
        .equalsValue(this as ProjectRegistryEntry, other);
  }

  @override
  int get hashCode {
    return ProjectRegistryEntryMapper.ensureInitialized()
        .hashValue(this as ProjectRegistryEntry);
  }
}

extension ProjectRegistryEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ProjectRegistryEntry, $Out> {
  ProjectRegistryEntryCopyWith<$R, ProjectRegistryEntry, $Out>
      get $asProjectRegistryEntry => $base.as(
          (v, t, t2) => _ProjectRegistryEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ProjectRegistryEntryCopyWith<
    $R,
    $In extends ProjectRegistryEntry,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get flavors;
  $R call(
      {String? path,
      String? name,
      String? flutter,
      Map<String, String>? flavors,
      DateTime? firstSeenAt,
      DateTime? lastSeenAt});
  ProjectRegistryEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ProjectRegistryEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ProjectRegistryEntry, $Out>
    implements ProjectRegistryEntryCopyWith<$R, ProjectRegistryEntry, $Out> {
  _ProjectRegistryEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ProjectRegistryEntry> $mapper =
      ProjectRegistryEntryMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get flavors => MapCopyWith($value.flavors,
          (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(flavors: v));
  @override
  $R call(
          {String? path,
          String? name,
          Object? flutter = $none,
          Map<String, String>? flavors,
          DateTime? firstSeenAt,
          DateTime? lastSeenAt}) =>
      $apply(FieldCopyWithData({
        if (path != null) #path: path,
        if (name != null) #name: name,
        if (flutter != $none) #flutter: flutter,
        if (flavors != null) #flavors: flavors,
        if (firstSeenAt != null) #firstSeenAt: firstSeenAt,
        if (lastSeenAt != null) #lastSeenAt: lastSeenAt
      }));
  @override
  ProjectRegistryEntry $make(CopyWithData data) => ProjectRegistryEntry(
      path: data.get(#path, or: $value.path),
      name: data.get(#name, or: $value.name),
      flutter: data.get(#flutter, or: $value.flutter),
      flavors: data.get(#flavors, or: $value.flavors),
      firstSeenAt: data.get(#firstSeenAt, or: $value.firstSeenAt),
      lastSeenAt: data.get(#lastSeenAt, or: $value.lastSeenAt));

  @override
  ProjectRegistryEntryCopyWith<$R2, ProjectRegistryEntry, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ProjectRegistryEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
