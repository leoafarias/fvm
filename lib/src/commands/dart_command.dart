import 'package:args/args.dart';

import '../models/valid_version_model.dart';
import '../services/project_service.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Proxies Dart Commands
class DartCommand extends BaseCommand {
  @override
  final name = 'dart';
  @override
  final description = 'Proxies Dart Commands';
  @override
  final argParser = ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final version = await ProjectService.findVersion();
    final args = argResults!.arguments;

    if (version != null) {
      // Make sure version is valid
      final validVersion = ValidVersion(version);
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(validVersion);

      logger.trace('fvm: running Dart from Flutter "$version"\n');

      // Runs flutter command with pinned version
      return await dartCmd(cacheVersion, args);
    } else {
      logger.trace('Running using Flutter version configured in path.\n');

      // Running null will default to flutter version on path
      return await dartGlobalCmd(args);
    }
  }
}
