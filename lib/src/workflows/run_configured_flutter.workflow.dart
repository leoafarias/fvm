import 'dart:io';

import '../models/cache_flutter_version_model.dart';
import '../utils/constants.dart';
import 'ensure_cache.workflow.dart';
import 'validate_flutter_version.workflow.dart';
import 'workflow.dart';

class RunConfiguredFlutterWorkflow extends Workflow {
  final ValidateFlutterVersionWorkflow _validateFlutterVersion;
  final EnsureCacheWorkflow _ensureCache;
  RunConfiguredFlutterWorkflow(super.context)
      : _validateFlutterVersion = context.get(),
        _ensureCache = context.get();

  Future<ProcessResult> call(String cmd, {required List<String> args}) async {
    // Try to select a version: project version has priority, then global.
    CacheFlutterVersion? selectedVersion;
    final projectVersion = services.project.findVersion();

    if (projectVersion != null) {
      final version = await _validateFlutterVersion(projectVersion);
      selectedVersion = await _ensureCache(version);
      logger.debug(
        '$kPackageName: Running Flutter from version "$projectVersion"',
      );
    } else {
      final globalVersion = services.cache.getGlobal();
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

      if (cmd == 'flutter') {
        return services.flutter.runFlutter(selectedVersion, args);
      } else if (cmd == 'dart') {
        return services.flutter.runDart(selectedVersion, args);
      }

      return services.flutter.run(selectedVersion, cmd, args);
    }

    // Fallback: run using the system's PATH.
    logger.debug('$kPackageName: Running Flutter version configured in PATH.');
    logger.debug('');

    return services.process.run(cmd, args: args);
  }
}
