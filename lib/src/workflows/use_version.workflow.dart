import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'package:fvm/fvm.dart';

import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow(
  String version, {
  bool force,
}) async {
  final project = await FlutterAppService.getByDirectory(kWorkingDirectory);

  // If project use check that is Flutter project
  if (!project.isFlutterProject && !force) {
    throw const FvmUsageException(
      'Not a Flutter project. Run this FVM command at the root of a Flutter project or use --force to bypass this.',
    );
  }

  // Run install workflow
  await ensureCacheWorkflow(version);

  await FlutterAppService.pinVersion(project, version);

  FvmLogger.fine('Project now uses Flutter: $version');
}
