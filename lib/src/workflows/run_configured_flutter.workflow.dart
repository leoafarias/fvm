import 'dart:io';

import '../models/cache_flutter_version_model.dart';
import '../utils/constants.dart';
import 'ensure_cache.workflow.dart';
import 'workflow.dart';

class RunConfiguredFlutterWorkflow extends Workflow {
  RunConfiguredFlutterWorkflow(super.context);

  Future<ProcessResult> call(String cmd, {required List<String> args}) async {
    // Try to select a version: project version has priority, then global.
    CacheFlutterVersion? selectedVersion;
    final projectVersion = services.project.findVersion();

    if (projectVersion != null) {
      selectedVersion = await EnsureCacheWorkflow(context).call(projectVersion);
      logger.detail(
        '$kPackageName: Running Flutter from version "$projectVersion"',
      );
    } else {
      final globalVersion = services.cache.getGlobal();
      if (globalVersion != null) {
        selectedVersion = globalVersion;
        logger.detail(
          '$kPackageName: Running Flutter from global version "${globalVersion.flutterSdkVersion}"',
        );
      }
    }

    // Execute using the selected version if available.
    if (selectedVersion != null) {
      logger.lineBreak();

      if (cmd == 'flutter') {
        return services.flutter.runFlutter(selectedVersion, args);
      } else if (cmd == 'dart') {
        return services.flutter.runDart(selectedVersion, args);
      }

      return services.flutter.run(selectedVersion, cmd, args);
    }

    // Fallback: run using the system's PATH.
    logger.detail('$kPackageName: Running Flutter version configured in PATH.');
    logger.detail('');

    return services.process.run(cmd, args: args);
  }
}
