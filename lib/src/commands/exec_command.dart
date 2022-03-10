import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Executes scripts with the configured Flutter SDK
class ExecCommand extends BaseCommand {
  @override
  final name = 'exec';
  @override
  final description = 'Executes scripts with the configured Flutter SDK';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  ExecCommand();

  @override
  Future<int> run() async {
    final version = await ProjectService.findVersion();

    if (argResults!.rest.isEmpty) {
      throw UsageException(
        'No command was provided to be executed',
        usage,
      );
    }

    final cmd = argResults!.rest[0];

    // Removes version from first arg
    final execArgs = [...argResults!.rest]..removeAt(0);

    if (version != null) {
      final validVersion = ValidVersion(version);
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(validVersion);

      logger.trace('fvm: running version "$version"\n');
      // If its not a channel silence version check

      // Runs exec command with pinned version
      return await execCmd(cmd, cacheVersion, execArgs);
    } else {
      // Try to get fvm global version
      final cacheVersion = await CacheService.getGlobal();

      return await execCmd(cmd, cacheVersion, execArgs);
    }
  }
}
