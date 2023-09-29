import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../services/logger_service.dart';
import '../utils/commands.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Spawn Flutter Commands in other versions
class SpawnCommand extends BaseCommand {
  @override
  final name = 'spawn';
  @override
  final description = 'Spawns a command on a Flutter version';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  SpawnCommand();

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException(
        'Need to provide a version to spawn a Flutter command',
        usage,
      );
    }

    final version = argResults!.rest[0];

    // Removes version from first arg
    final flutterArgs = [...argResults!.rest]..removeAt(0);

    // Will install version if not already instaled
    final cacheVersion = await ensureCacheWorkflow(version);
    // Runs flutter command with pinned version
    logger.info('Spawning version "$version"...');

    final results = await runFlutter(flutterArgs, version: cacheVersion);
    return results.exitCode;
  }
}
