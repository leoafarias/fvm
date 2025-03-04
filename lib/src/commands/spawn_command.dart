import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../workflows/ensure_cache.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';
import 'base_command.dart';

/// Spawn Flutter Commands in other versions
class SpawnCommand extends BaseFvmCommand {
  @override
  final name = 'spawn';
  @override
  final description = 'Spawns a command on a Flutter version';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  SpawnCommand(super.context);

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException(
        'Need to provide a version to spawn a Flutter command',
        usage,
      );
    }

    final validateFlutterVersion = ValidateFlutterVersionWorkflow(context);
    final ensureCache = EnsureCacheWorkflow(context);
    final version = argResults!.rest[0];
    // Removes version from first arg
    final flutterArgs = [...?argResults?.rest]..removeAt(0);

    final flutterVersion = await validateFlutterVersion(version);
    // Will install version if not already installed
    final cacheVersion = await ensureCache(flutterVersion);
    // Runs flutter command with pinned version
    logger.info('Spawning version "$version"...');

    final results = await services.flutter.runFlutter(
      cacheVersion,
      flutterArgs,
    );

    return results.exitCode;
  }
}
