import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';

import 'package:fvm/src/services/flutter_tools.dart';

import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/logger.dart';

import 'package:fvm/src/workflows/ensure_cache.workflow.dart';

import 'package:io/io.dart';
import 'package:process_run/shell.dart';

/// Removes Flutter SDK
class GlobalCommand extends Command<int> {
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
    final validVersion = await FlutterTools.inferVersion(version);

    // Ensure version is installed
    final cacheVersion = await ensureCacheWorkflow(validVersion);

    // Sets version as the global
    await CacheService.setGlobal(cacheVersion);

    final isSetup = await CacheService.isGlobalConfigured();

    FvmLogger.spacer();
    FvmLogger.fine('Flutter "$validVersion" has been set as global');
    if (!isSetup) {
      FvmLogger.divider();
      FvmLogger.warning('However your "flutter" path current points to:');
      FvmLogger.spacer();
      FvmLogger.info(
          whichSync('flutter') ?? 'No version is configured on path.');
      FvmLogger.info(
          'to use global Flutter SDK through FVM you should change it to:');
      FvmLogger.info(kGlobalFlutterPath);
    }
    FvmLogger.spacer();

    return ExitCode.success.code;
  }
}
