import 'dart:io';

import '../models/cache_flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/flutter_service.dart';
import '../services/process_service.dart';
import '../services/project_service.dart';
import '../utils/constants.dart';
import 'ensure_cache.workflow.dart';
import 'validate_flutter_version.workflow.dart';
import 'workflow.dart';

class RunConfiguredFlutterWorkflow extends Workflow {
  const RunConfiguredFlutterWorkflow(super.context);

  Future<ProcessResult> call(String cmd, {required List<String> args}) async {
    // Try to select a version: project version has priority, then global.

    CacheFlutterVersion? selectedVersion;
    final projectVersion = get<ProjectService>().findVersion();

    if (projectVersion != null) {
      final version = get<ValidateFlutterVersionWorkflow>().call(
        projectVersion,
      );
      selectedVersion = await get<EnsureCacheWorkflow>().call(version);
      logger.debug(
        '$kPackageName: Running Flutter from version "$projectVersion"',
      );
    } else {
      final globalVersion = get<CacheService>().getGlobal();
      if (globalVersion != null) {
        selectedVersion = globalVersion;
        logger.debug(
          '$kPackageName: Running Flutter from global version "${globalVersion.flutterSdkVersion}"',
        );
      }
    }

    // Execute using the selected version if available.
    if (selectedVersion != null) {
      logger.info();

      return get<FlutterService>().run(cmd, args, selectedVersion);
    }

    // Fallback: run using the system's PATH.
    logger.debug('$kPackageName: Running Flutter version configured in PATH.');
    logger.debug('');

    return get<ProcessService>().run(cmd, args: args);
  }
}
