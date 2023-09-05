import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/workflows/update_project_version.workflow.dart';
import 'package:mason_logger/mason_logger.dart';

import '../utils/logger.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow({
  required CacheFlutterVersion version,
  required Project project,
  bool force = false,
  String? flavor,
}) async {
  // If project use check that is Flutter project
  if (!project.isFlutter && !force) {
    final proceed = logger.confirm(
        'You are running "use" on a project that does not use Flutter. Would you like to continue?');

    if (!proceed) exit(ExitCode.success.code);
  }

  // Run install workflow
  updateSdkVersionWorkflow(
    project,
    version.name,
    flavor: flavor,
  );

  final versionLabel = cyan.wrap(version.printFriendlyName);
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
