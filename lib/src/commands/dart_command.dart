import 'package:args/args.dart';

import '../models/cache_flutter_version_model.dart';
import '../utils/constants.dart';
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

  DartCommand(super.controller);

  @override
  Future<int> run() async {
    final version = controller.project.findVersion();
    final args = argResults!.arguments;

    CacheFlutterVersion? cacheVersion;

    if (version != null) {
      // Will install version if not already installed
      cacheVersion = await ensureCacheWorkflow(
        version,
        controller: controller,
      );

      logger
        ..detail('$kPackageName: running Dart from Flutter SDK "$version"')
        ..detail('');
    } else {
      logger
        ..detail('$kPackageName: Running Dart version configured in PATH.')
        ..detail('');
    }
    // Running null will default to dart version on path
    final results = await controller.flutter.runDart(
      args,
      version: cacheVersion,
    );

    return results.exitCode;
  }
}
