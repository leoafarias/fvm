import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';

import 'package:fvm/fvm.dart';

import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/install_version.workflow.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow(
  String version, {
  bool global,
  bool force,
}) async {
  final project = await FlutterAppService.getOne(kWorkingDirectory);
  // If project use check that is Flutter project
  if (!project.isFlutterProject && !global && !force) {
    throw UsageException(
      'Not a Flutter project',
      'Run this FVM command at the root of a Flutter project or use --force to bypass this.',
    );
  }

  // Run install workflow
  await installWorkflow(version);

  if (global) {
    // Sets version as the global
    final cacheVersion = await CacheService.isVersionCached(version);
    await CacheService.setGlobal(cacheVersion);
  } else {
    await FlutterAppService.pinVersion(project, version);
  }

  FvmLogger.fine('Project now uses Flutter: $version');
}
