import 'package:args/args.dart';

import '../../exceptions.dart';
import '../services/flutter_tools.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
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
    if (argResults.rest.isEmpty) {
      throw const FvmUsageException(
        'Need to provide a version to spawn a Flutter command',
      );
    }

    final version = argResults.rest[0];

    // Removes version from first arg
    final flutterArgs = [...argResults.rest]..removeAt(0);

    if (version != null) {
      final validVersion = await FlutterTools.inferValidVersion(version);
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(validVersion);
      // Runs flutter command with pinned version
      FvmLogger.info('fvm: Spawning version "$version"');
      FvmLogger.spacer();
      return await flutterCmd(cacheVersion, flutterArgs);
    } else {
      throw const FvmUsageException(
        'Need to provide a version to spawn a Flutter command',
      );
    }
  }
}
