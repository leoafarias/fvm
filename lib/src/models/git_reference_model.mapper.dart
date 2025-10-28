// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'git_reference_model.dart';

class GitReferenceMapper extends ClassMapperBase<GitReference> {
  GitReferenceMapper._();

  static GitReferenceMapper? _instance;
  static GitReferenceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GitReferenceMapper._());
      GitBranchMapper.ensureInitialized();
      GitTagMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GitReference';

  static String _$sha(GitReference v) => v.sha;
  static const Field<GitReference, String> _f$sha = Field('sha', _$sha);
  static String _$name(GitReference v) => v.name;
  static const Field<GitReference, String> _f$name = Field('name', _$name);

  @override
  final MappableFields<GitReference> fields = const {
    #sha: _f$sha,
    #name: _f$name,
  };

  static GitReference _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('GitReference');
  }

  @override
  final Function instantiate = _instantiate;

  static GitReference fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GitReference>(map);
  }

  static GitReference fromJson(String json) {
    return ensureInitialized().decodeJson<GitReference>(json);
  }
}

mixin GitReferenceMappable {
  String toJson();
  Map<String, dynamic> toMap();
  GitReferenceCopyWith<GitReference, GitReference, GitReference> get copyWith;
}

abstract class GitReferenceCopyWith<$R, $In extends GitReference, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? sha, String? name});
  GitReferenceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class GitBranchMapper extends ClassMapperBase<GitBranch> {
  GitBranchMapper._();

  static GitBranchMapper? _instance;
  static GitBranchMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GitBranchMapper._());
      GitReferenceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GitBranch';

  static String _$sha(GitBranch v) => v.sha;
  static const Field<GitBranch, String> _f$sha = Field('sha', _$sha);
  static String _$name(GitBranch v) => v.name;
  static const Field<GitBranch, String> _f$name = Field('name', _$name);

  @override
  final MappableFields<GitBranch> fields = const {#sha: _f$sha, #name: _f$name};

  static GitBranch _instantiate(DecodingData data) {
    return GitBranch(sha: data.dec(_f$sha), name: data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static GitBranch fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GitBranch>(map);
  }

  static GitBranch fromJson(String json) {
    return ensureInitialized().decodeJson<GitBranch>(json);
  }
}

mixin GitBranchMappable {
  String toJson() {
    return GitBranchMapper.ensureInitialized().encodeJson<GitBranch>(
      this as GitBranch,
    );
  }

  Map<String, dynamic> toMap() {
    return GitBranchMapper.ensureInitialized().encodeMap<GitBranch>(
      this as GitBranch,
    );
  }

  GitBranchCopyWith<GitBranch, GitBranch, GitBranch> get copyWith =>
      _GitBranchCopyWithImpl<GitBranch, GitBranch>(
        this as GitBranch,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GitBranchMapper.ensureInitialized().stringifyValue(
      this as GitBranch,
    );
  }

  @override
  bool operator ==(Object other) {
    return GitBranchMapper.ensureInitialized().equalsValue(
      this as GitBranch,
      other,
    );
  }

  @override
  int get hashCode {
    return GitBranchMapper.ensureInitialized().hashValue(this as GitBranch);
  }
}

extension GitBranchValueCopy<$R, $Out> on ObjectCopyWith<$R, GitBranch, $Out> {
  GitBranchCopyWith<$R, GitBranch, $Out> get $asGitBranch =>
      $base.as((v, t, t2) => _GitBranchCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GitBranchCopyWith<$R, $In extends GitBranch, $Out>
    implements GitReferenceCopyWith<$R, $In, $Out> {
  @override
  $R call({String? sha, String? name});
  GitBranchCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _GitBranchCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GitBranch, $Out>
    implements GitBranchCopyWith<$R, GitBranch, $Out> {
  _GitBranchCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GitBranch> $mapper =
      GitBranchMapper.ensureInitialized();
  @override
  $R call({String? sha, String? name}) => $apply(
        FieldCopyWithData({
          if (sha != null) #sha: sha,
          if (name != null) #name: name,
        }),
      );
  @override
  GitBranch $make(CopyWithData data) => GitBranch(
        sha: data.get(#sha, or: $value.sha),
        name: data.get(#name, or: $value.name),
      );

  @override
  GitBranchCopyWith<$R2, GitBranch, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _GitBranchCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GitTagMapper extends ClassMapperBase<GitTag> {
  GitTagMapper._();

  static GitTagMapper? _instance;
  static GitTagMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GitTagMapper._());
      GitReferenceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GitTag';

  static String _$sha(GitTag v) => v.sha;
  static const Field<GitTag, String> _f$sha = Field('sha', _$sha);
  static String _$name(GitTag v) => v.name;
  static const Field<GitTag, String> _f$name = Field('name', _$name);

  @override
  final MappableFields<GitTag> fields = const {#sha: _f$sha, #name: _f$name};

  static GitTag _instantiate(DecodingData data) {
    return GitTag(sha: data.dec(_f$sha), name: data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static GitTag fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GitTag>(map);
  }

  static GitTag fromJson(String json) {
    return ensureInitialized().decodeJson<GitTag>(json);
  }
}

mixin GitTagMappable {
  String toJson() {
    return GitTagMapper.ensureInitialized().encodeJson<GitTag>(this as GitTag);
  }

  Map<String, dynamic> toMap() {
    return GitTagMapper.ensureInitialized().encodeMap<GitTag>(this as GitTag);
  }

  GitTagCopyWith<GitTag, GitTag, GitTag> get copyWith =>
      _GitTagCopyWithImpl<GitTag, GitTag>(this as GitTag, $identity, $identity);
  @override
  String toString() {
    return GitTagMapper.ensureInitialized().stringifyValue(this as GitTag);
  }

  @override
  bool operator ==(Object other) {
    return GitTagMapper.ensureInitialized().equalsValue(this as GitTag, other);
  }

  @override
  int get hashCode {
    return GitTagMapper.ensureInitialized().hashValue(this as GitTag);
  }
}

extension GitTagValueCopy<$R, $Out> on ObjectCopyWith<$R, GitTag, $Out> {
  GitTagCopyWith<$R, GitTag, $Out> get $asGitTag =>
      $base.as((v, t, t2) => _GitTagCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GitTagCopyWith<$R, $In extends GitTag, $Out>
    implements GitReferenceCopyWith<$R, $In, $Out> {
  @override
  $R call({String? sha, String? name});
  GitTagCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _GitTagCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, GitTag, $Out>
    implements GitTagCopyWith<$R, GitTag, $Out> {
  _GitTagCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GitTag> $mapper = GitTagMapper.ensureInitialized();
  @override
  $R call({String? sha, String? name}) => $apply(
        FieldCopyWithData({
          if (sha != null) #sha: sha,
          if (name != null) #name: name,
        }),
      );
  @override
  GitTag $make(CopyWithData data) => GitTag(
        sha: data.get(#sha, or: $value.sha),
        name: data.get(#name, or: $value.name),
      );

  @override
  GitTagCopyWith<$R2, GitTag, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _GitTagCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
