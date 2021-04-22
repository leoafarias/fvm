import '../../constants.dart';
import '../../exceptions.dart';
import '../models/valid_version_model.dart';
import '../services/project_service.dart';
import '../utils/logger.dart';
import 'ensure_cache.workflow.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow(
  ValidVersion validVersion, {
  bool force = false,
  String? environment,
}) async {
  // Get project from working directory
  final project = await ProjectService.getByDirectory(kWorkingDirectory);

  // If project use check that is Flutter project
  if (!project.isFlutterProject && !force) {
    throw const FvmUsageException(
      'Not a Flutter project. Run this FVM command at'
      ' the root of a Flutter project or use --force to bypass this.',
    );
  }

  // Run install workflow
  await ensureCacheWorkflow(validVersion);

  await ProjectService.pinVersion(
    project,
    validVersion,
    environment: environment,
  );

  // Different message if configured environment
  if (environment != null) {
    FvmLogger.fine(
      'Project now uses Flutter [$validVersion]'
      ' on [$environment] environment.\n',
    );
  } else {
    FvmLogger.fine('Project now uses Flutter [$validVersion]\n');
  }
}
