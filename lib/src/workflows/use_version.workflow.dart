import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/valid_version_model.dart';

import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow(
  ValidVersion validVersion, {
  bool force,
  String environment,
}) async {
  final project = await FlutterAppService.getByDirectory(kWorkingDirectory);

  // If project use check that is Flutter project
  if (!project.isFlutterProject && !force) {
    throw const FvmUsageException(
      'Not a Flutter project. Run this FVM command at the root of a Flutter project or use --force to bypass this.',
    );
  }

  // Run install workflow
  await ensureCacheWorkflow(validVersion);

  await FlutterAppService.pinVersion(
    project,
    validVersion,
    environment: environment,
  );

  FvmLogger.spacer();

  // Different message if configured environment
  if (environment != null) {
    FvmLogger.fine(
      'Project now uses Flutter [$validVersion] on [$environment] environment.',
    );
  } else {
    FvmLogger.fine('Project now uses Flutter [$validVersion]');
  }
  FvmLogger.spacer();
}
