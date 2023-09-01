import 'package:mason_logger/mason_logger.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../models/valid_version_model.dart';
import '../services/flutter_tools.dart';
import '../services/project_service.dart';
import '../utils/logger.dart';
import 'ensure_cache.workflow.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow(
  ValidVersion validVersion, {
  bool force = false,
  String? flavor,
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
  final cacheVersion = await ensureCacheWorkflow(validVersion);

  if (cacheVersion.needSetup) {
    await FlutterTools.runSetup(cacheVersion);
  }

  await ProjectService.pinVersion(
    project,
    validVersion,
    flavor: flavor,
  );

  // Ensure the config link and symlink are updated
  await ProjectService.updateLink();

  final dartToolVersion = await ProjectService.getDartToolVersion(project);

  print('dartToolVersion: $dartToolVersion');
  print('cacheVersion.sdkVersion: ${cacheVersion.sdkVersion}\n');

  if (dartToolVersion != cacheVersion.sdkVersion) {
    logger
      ..spacer
      ..detail('dart_tool version mismatch.\n')
      ..detail('Dart tool version: $dartToolVersion')
      ..detail('SDK Version: ${cacheVersion.sdkVersion}\n');

    final progress = logger.progress('Resolving dependencies...');
    try {
      await FlutterTools.runPubGet(cacheVersion);
      progress.complete('Dependencies resolved.');
    } on Exception {
      final dartToolVersion = await ProjectService.getDartToolVersion(project);
      if (dartToolVersion == cacheVersion.sdkVersion) {
        progress.complete('Dependencies resolved.');
      } else {
        progress.fail('Could not resolve dependencies.');
        rethrow;
      }
    }
    await FlutterTools.runPubGet(cacheVersion);
  }

  final versionLabel = cyan.wrap(validVersion.printFriendlyName);
  // Different message if configured environment
  if (flavor != null) {
    logger
      ..complete(
          'Project now uses Flutter SDK: $versionLabel on [$flavor] flavor.')
      ..spacer;
  } else {
    logger
      ..complete(
        'Project now uses Flutter SDK : $versionLabel',
      )
      ..spacer;
  }
}
