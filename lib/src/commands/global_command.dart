import 'package:io/io.dart';

import '../services/cache_service.dart';
import '../services/flutter_tools.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class GlobalCommand extends BaseCommand {
  @override
  final name = 'global';

  @override
  final description = 'Sets Flutter SDK Version as a global';

  /// Constructor
  GlobalCommand();

  @override
  Future<int> run() async {
    String version;

    // Show chooser if not version is provided
    if (argResults.rest.isEmpty) {
      version = await cacheVersionSelector();
    }

    // Get first arg if it was not empty
    version ??= argResults.rest[0];

    // Get valid flutter version
    final validVersion = await FlutterTools.inferValidVersion(version);

    // Ensure version is installed
    final cacheVersion = await ensureCacheWorkflow(validVersion);

    // Sets version as the global
    await CacheService.setGlobal(cacheVersion);

    final configured = await CacheService.isGlobalConfigured();

    FvmLogger.spacer();
    FvmLogger.fine('Flutter "$validVersion" has been set as global');
    if (!configured.isSetup) {
      FvmLogger.divider();
      FvmLogger.warning('However your "flutter" path current points to:');
      FvmLogger.spacer();
      FvmLogger.info(
          configured.currentPath ?? 'No version is configured on path.');
      FvmLogger.info(
          'to use global Flutter SDK through FVM you should change it to:');
      FvmLogger.info(configured.newPath);
    }
    FvmLogger.spacer();

    return ExitCode.success.code;
  }
}
