import 'dart:io';

import 'package:fvm/src/workflows/flutter_setup.workflow.dart';
import 'package:fvm/src/workflows/update_project_version.workflow.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../constants.dart';
import '../models/flutter_version_model.dart';
import '../services/flutter_tools.dart';
import '../services/project_service.dart';
import '../utils/logger.dart';
import 'ensure_cache.workflow.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow(
  FlutterVersion validVersion, {
  bool force = false,
  String? flavor,
}) async {
  // Get project from working directory
  // TODO: Switch this to find ancestor
  final project = await ProjectService.loadByDirectory(kWorkingDirectory);

  // If project use check that is Flutter project
  if (!project.isFlutter && !force) {
    final proceed = logger.confirm(
        'You are running "use" on a project that does not use Flutter. Would you like to continue?');

    if (!proceed) exit(ExitCode.success.code);
  }

  // Run install workflow
  final cacheVersion = await ensureCacheWorkflow(validVersion);

  await setupFlutterWorkflow(cacheVersion);

  updateSdkVersionWorkflow(
    project,
    cacheVersion.name,
    flavor: flavor,
  );

  final dartToolVersion = project.dartToolVersion;

  logger
    ..detail('')
    ..detail('dartToolVersion: $dartToolVersion')
    ..detail('cacheVersion.sdkVersion: ${cacheVersion.sdkVersion}')
    ..detail('');

  if (dartToolVersion != cacheVersion.sdkVersion) {
    logger
      ..detail('')
      ..detail('dart_tool version mismatch.\n')
      ..detail('Dart tool version: $dartToolVersion')
      ..detail('SDK Version: ${cacheVersion.sdkVersion}')
      ..detail('');

    final progress = logger.progress('Resolving dependencies...');
    try {
      await FlutterTools.runPubGet(cacheVersion);
      progress.complete('Dependencies resolved.');
    } on Exception {
      if (project.dartToolVersion == cacheVersion.sdkVersion) {
        progress.complete('Dependencies resolved.');
      } else {
        progress.fail('Could not resolve dependencies.');
        rethrow;
      }
    }
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

  return;
}
