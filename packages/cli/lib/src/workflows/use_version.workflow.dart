import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/local_versions/local_versions_tools.dart';
import 'package:fvm/src/utils/logger.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow(
  String version, {
  bool global,
  bool force,
}) async {
  final project = await FlutterProjectRepo.findAncestor();

  // If project use check that is Flutter project
  if (project == null && !global && !force) {
    throw const UsageError(
      'Run this FVM command at the root of a Flutter project or use --force to bypass this.',
    );
  }

  if (global) {
    // Sets version as the global
    setAsGlobalVersion(version);
  } else if (force) {
    // Updates the project config with version
    final rootProject = await FlutterProjectRepo.getOne(kWorkingDirectory);
    await FlutterProjectRepo.pinVersion(rootProject, version);
  } else {
    await FlutterProjectRepo.pinVersion(project, version);
  }

  FvmLogger.fine('Project now uses Flutter: $version');
}
