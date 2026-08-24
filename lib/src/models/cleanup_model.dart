import 'package:dart_mappable/dart_mappable.dart';

part 'cleanup_model.mapper.dart';

/// An `fvm` invocation that applies a cached patch upgrade.
@MappableClass(ignoreNull: true)
class CleanupAction with CleanupActionMappable {
  /// Arguments after `fvm`, for example `['use', '3.10.5']`.
  final List<String> arguments;

  /// Directory where the command should run for project-scoped actions.
  final String? workingDirectory;

  static final fromMap = CleanupActionMapper.fromMap;
  static final fromJson = CleanupActionMapper.fromJson;

  const CleanupAction({required this.arguments, this.workingDirectory});
}

/// Move a pin from [fromVersion] to a newer cached patch, [toVersion].
@MappableClass()
class PatchUpgrade with PatchUpgradeMappable {
  final String fromVersion;
  final String toVersion;
  final String reason;
  final List<CleanupAction> actions;

  static final fromMap = PatchUpgradeMapper.fromMap;
  static final fromJson = PatchUpgradeMapper.fromJson;

  const PatchUpgrade({
    required this.fromVersion,
    required this.toVersion,
    required this.reason,
    required this.actions,
  });
}
