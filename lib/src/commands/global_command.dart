import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:io/io.dart';

import '../services/cache_service.dart';
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
  String get invocation => 'fvm global {version}';

  @override
  Future<int> run() async {
    String? version;

    // Show chooser if not version is provided
    if (argResults!.rest.isEmpty) {
      version = await cacheVersionSelector();
    }

    // Get first arg if it was not empty
    version ??= argResults!.rest[0];

    // Get valid flutter version
    final validVersion = ValidVersion(version);

    // Ensure version is installed
    final cacheVersion = await ensureCacheWorkflow(validVersion);

    // Sets version as the global
    await CacheService.setGlobal(cacheVersion);

    final configured = await CacheService.isGlobalConfigured();

    logger.info('Flutter "$validVersion" has been set as global');
    if (!configured.isSetup) {
      logger
        ..info('')
        ..warn('However your "flutter" path current points to:')
        ..info(
          configured.currentPath ?? 'No version is configured on path.',
        )
        ..info('to use global Flutter SDK through FVM you should change it to:')
        ..info(configured.correctPath);
    }
    return ExitCode.success.code;
  }
}
