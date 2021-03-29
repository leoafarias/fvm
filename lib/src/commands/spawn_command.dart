import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/exceptions.dart';

import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/commands.dart';

import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';

/// Spawn Flutter Commands in other versions
class SpawnCommand extends Command<int> {
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
      final validVersion = await FlutterTools.inferVersion(version);
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(validVersion);
      // Runs flutter command with pinned version
      FvmLogger.info('fvm: running version "$version"');
      return await flutterCmd(cacheVersion, flutterArgs);
    } else {
      throw const FvmUsageException(
        'Need to provide a version to spawn a Flutter command',
      );
    }
  }
}
