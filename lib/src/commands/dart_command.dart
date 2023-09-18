import 'package:args/args.dart';
import 'package:fvm/constants.dart';

import '../services/logger_service.dart';
import '../services/project_service.dart';
import '../utils/commands.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Proxies Dart Commands
class DartCommand extends BaseCommand {
  DartCommand();

  @override
  final name = 'dart';
  @override
  final description = 'Proxies Dart Commands';
  @override
  final argParser = ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final version = await ProjectService.fromContext.findVersion();
    final args = argResults!.arguments;

    if (version != null) {
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(version);

      logger
        ..detail('$kPackageName: running Dart from Flutter SDK "$version"')
        ..detail('');

      // Runs flutter command with pinned version
      return await runDart(cacheVersion, args);
    } else {
      logger
        ..detail('$kPackageName: Running Dart version configured in path.')
        ..detail('');

      // Running null will default to dart version on path
      return await runDartGlobal(args);
    }
  }
}
