import 'package:args/args.dart';
import 'package:fvm/constants.dart';

import '../models/flutter_version_model.dart';
import '../services/project_service.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
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
    final version = await ProjectService.instance.findVersion();
    final args = argResults!.arguments;

    if (version != null) {
      // Make sure version is valid
      final validVersion = FlutterVersion.parse(version);
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(validVersion);

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
