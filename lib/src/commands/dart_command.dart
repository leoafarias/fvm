import 'package:args/args.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/commands.dart';

import '../services/logger_service.dart';
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

  DartCommand();

  @override
  Future<int> run() async {
    final version = ProjectService.fromContext.findVersion();
    final args = argResults!.arguments;

    CacheFlutterVersion? cacheVersion;

    if (version != null) {
      // Will install version if not already instaled
      cacheVersion = await ensureCacheWorkflow(version);

      logger
        ..detail('$kPackageName: running Dart from Flutter SDK "$version"')
        ..detail('');
    } else {
      logger
        ..detail('$kPackageName: Running Dart version configured in path.')
        ..detail('');

      // Running null will default to dart version on path
    }
    final results = await runDart(args, version: cacheVersion);
    return results.exitCode;
  }
}
