// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'cleanup_model.dart';

class CleanupActionMapper extends ClassMapperBase<CleanupAction> {
  CleanupActionMapper._();

  static CleanupActionMapper? _instance;
  static CleanupActionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CleanupActionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CleanupAction';

  static List<String> _$arguments(CleanupAction v) => v.arguments;
  static const Field<CleanupAction, List<String>> _f$arguments =
      Field('arguments', _$arguments);
  static String? _$workingDirectory(CleanupAction v) => v.workingDirectory;
  static const Field<CleanupAction, String> _f$workingDirectory =
      Field('workingDirectory', _$workingDirectory, opt: true);

  @override
  final MappableFields<CleanupAction> fields = const {
    #arguments: _f$arguments,
    #workingDirectory: _f$workingDirectory,
  };
  @override
  final bool ignoreNull = true;

  static CleanupAction _instantiate(DecodingData data) {
    return CleanupAction(
        arguments: data.dec(_f$arguments),
        workingDirectory: data.dec(_f$workingDirectory));
  }

  @override
  final Function instantiate = _instantiate;

  static CleanupAction fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CleanupAction>(map);
  }

  static CleanupAction fromJson(String json) {
    return ensureInitialized().decodeJson<CleanupAction>(json);
  }
}

mixin CleanupActionMappable {
  String toJson() {
    return CleanupActionMapper.ensureInitialized()
        .encodeJson<CleanupAction>(this as CleanupAction);
  }

  Map<String, dynamic> toMap() {
    return CleanupActionMapper.ensureInitialized()
        .encodeMap<CleanupAction>(this as CleanupAction);
  }

  CleanupActionCopyWith<CleanupAction, CleanupAction, CleanupAction>
      get copyWith => _CleanupActionCopyWithImpl<CleanupAction, CleanupAction>(
          this as CleanupAction, $identity, $identity);
  @override
  String toString() {
    return CleanupActionMapper.ensureInitialized()
        .stringifyValue(this as CleanupAction);
  }

  @override
  bool operator ==(Object other) {
    return CleanupActionMapper.ensureInitialized()
        .equalsValue(this as CleanupAction, other);
  }

  @override
  int get hashCode {
    return CleanupActionMapper.ensureInitialized()
        .hashValue(this as CleanupAction);
  }
}

extension CleanupActionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CleanupAction, $Out> {
  CleanupActionCopyWith<$R, CleanupAction, $Out> get $asCleanupAction =>
      $base.as((v, t, t2) => _CleanupActionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CleanupActionCopyWith<$R, $In extends CleanupAction, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get arguments;
  $R call({List<String>? arguments, String? workingDirectory});
  CleanupActionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CleanupActionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CleanupAction, $Out>
    implements CleanupActionCopyWith<$R, CleanupAction, $Out> {
  _CleanupActionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CleanupAction> $mapper =
      CleanupActionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get arguments =>
      ListCopyWith($value.arguments, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(arguments: v));
  @override
  $R call({List<String>? arguments, Object? workingDirectory = $none}) =>
      $apply(FieldCopyWithData({
        if (arguments != null) #arguments: arguments,
        if (workingDirectory != $none) #workingDirectory: workingDirectory
      }));
  @override
  CleanupAction $make(CopyWithData data) => CleanupAction(
      arguments: data.get(#arguments, or: $value.arguments),
      workingDirectory:
          data.get(#workingDirectory, or: $value.workingDirectory));

  @override
  CleanupActionCopyWith<$R2, CleanupAction, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CleanupActionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PatchUpgradeMapper extends ClassMapperBase<PatchUpgrade> {
  PatchUpgradeMapper._();

  static PatchUpgradeMapper? _instance;
  static PatchUpgradeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PatchUpgradeMapper._());
      CleanupActionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PatchUpgrade';

  static String _$fromVersion(PatchUpgrade v) => v.fromVersion;
  static const Field<PatchUpgrade, String> _f$fromVersion =
      Field('fromVersion', _$fromVersion);
  static String _$toVersion(PatchUpgrade v) => v.toVersion;
  static const Field<PatchUpgrade, String> _f$toVersion =
      Field('toVersion', _$toVersion);
  static String _$reason(PatchUpgrade v) => v.reason;
  static const Field<PatchUpgrade, String> _f$reason =
      Field('reason', _$reason);
  static List<CleanupAction> _$actions(PatchUpgrade v) => v.actions;
  static const Field<PatchUpgrade, List<CleanupAction>> _f$actions =
      Field('actions', _$actions);

  @override
  final MappableFields<PatchUpgrade> fields = const {
    #fromVersion: _f$fromVersion,
    #toVersion: _f$toVersion,
    #reason: _f$reason,
    #actions: _f$actions,
  };

  static PatchUpgrade _instantiate(DecodingData data) {
    return PatchUpgrade(
        fromVersion: data.dec(_f$fromVersion),
        toVersion: data.dec(_f$toVersion),
        reason: data.dec(_f$reason),
        actions: data.dec(_f$actions));
  }

  @override
  final Function instantiate = _instantiate;

  static PatchUpgrade fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PatchUpgrade>(map);
  }

  static PatchUpgrade fromJson(String json) {
    return ensureInitialized().decodeJson<PatchUpgrade>(json);
  }
}

mixin PatchUpgradeMappable {
  String toJson() {
    return PatchUpgradeMapper.ensureInitialized()
        .encodeJson<PatchUpgrade>(this as PatchUpgrade);
  }

  Map<String, dynamic> toMap() {
    return PatchUpgradeMapper.ensureInitialized()
        .encodeMap<PatchUpgrade>(this as PatchUpgrade);
  }

  PatchUpgradeCopyWith<PatchUpgrade, PatchUpgrade, PatchUpgrade> get copyWith =>
      _PatchUpgradeCopyWithImpl<PatchUpgrade, PatchUpgrade>(
          this as PatchUpgrade, $identity, $identity);
  @override
  String toString() {
    return PatchUpgradeMapper.ensureInitialized()
        .stringifyValue(this as PatchUpgrade);
  }

  @override
  bool operator ==(Object other) {
    return PatchUpgradeMapper.ensureInitialized()
        .equalsValue(this as PatchUpgrade, other);
  }

  @override
  int get hashCode {
    return PatchUpgradeMapper.ensureInitialized()
        .hashValue(this as PatchUpgrade);
  }
}

extension PatchUpgradeValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PatchUpgrade, $Out> {
  PatchUpgradeCopyWith<$R, PatchUpgrade, $Out> get $asPatchUpgrade =>
      $base.as((v, t, t2) => _PatchUpgradeCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PatchUpgradeCopyWith<$R, $In extends PatchUpgrade, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, CleanupAction,
      CleanupActionCopyWith<$R, CleanupAction, CleanupAction>> get actions;
  $R call(
      {String? fromVersion,
      String? toVersion,
      String? reason,
      List<CleanupAction>? actions});
  PatchUpgradeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PatchUpgradeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PatchUpgrade, $Out>
    implements PatchUpgradeCopyWith<$R, PatchUpgrade, $Out> {
  _PatchUpgradeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PatchUpgrade> $mapper =
      PatchUpgradeMapper.ensureInitialized();
  @override
  ListCopyWith<$R, CleanupAction,
          CleanupActionCopyWith<$R, CleanupAction, CleanupAction>>
      get actions => ListCopyWith($value.actions,
          (v, t) => v.copyWith.$chain(t), (v) => call(actions: v));
  @override
  $R call(
          {String? fromVersion,
          String? toVersion,
          String? reason,
          List<CleanupAction>? actions}) =>
      $apply(FieldCopyWithData({
        if (fromVersion != null) #fromVersion: fromVersion,
        if (toVersion != null) #toVersion: toVersion,
        if (reason != null) #reason: reason,
        if (actions != null) #actions: actions
      }));
  @override
  PatchUpgrade $make(CopyWithData data) => PatchUpgrade(
      fromVersion: data.get(#fromVersion, or: $value.fromVersion),
      toVersion: data.get(#toVersion, or: $value.toVersion),
      reason: data.get(#reason, or: $value.reason),
      actions: data.get(#actions, or: $value.actions));

  @override
  PatchUpgradeCopyWith<$R2, PatchUpgrade, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _PatchUpgradeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
