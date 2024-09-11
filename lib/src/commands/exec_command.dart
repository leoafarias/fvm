import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../models/cache_flutter_version_model.dart';
import '../services/logger_service.dart';
import '../services/project_service.dart';
import '../utils/commands.dart';
import '../utils/constants.dart';
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
    final version = ProjectService.fromContext.findVersion();

    if (argResults!.rest.isEmpty) {
      throw UsageException('No command was provided to be executed', usage);
    }

    final cmd = argResults!.rest[0];

    // Removes version from first arg
    final execArgs = [...?argResults?.rest]..removeAt(0);

    // If no version is provided try to use global
    CacheFlutterVersion? cacheVersion;

    if (version != null) {
      // Will install version if not already installed
      cacheVersion = await ensureCacheWorkflow(version);
      logger
        ..info('$kPackageName: Running version: "$version"')
        ..spacer;
    }

    // Runs exec command with pinned version
    final results = await execCmd(cmd, execArgs, cacheVersion);

    return results.exitCode;
  }
}
