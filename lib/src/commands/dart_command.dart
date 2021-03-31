import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../services/flutter_tools.dart';
import '../services/project_service.dart';
import '../utils/commands.dart';
import '../utils/logger.dart';
import '../workflows/ensure_cache.workflow.dart';

/// Proxies Dart Commands
class DartCommand extends Command<int> {
  @override
  final name = 'dart';
  @override
  final description = 'Proxies Dart Commands';
  @override
  final argParser = ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final version = await ProjectService.findVersion();
    final args = argResults.arguments;

    if (version != null) {
      // Make sure version is valid
      final validVersion = await FlutterTools.inferValidVersion(version);
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(validVersion);

      FvmLogger.info('fvm: running Dart from Flutter "$version"');
      FvmLogger.spacer();
      // Runs flutter command with pinned version
      return await dartCmd(cacheVersion, args);
    } else {
      FvmLogger.info('Running using Flutter version configured in path.');
      FvmLogger.spacer();
      // Running null will default to flutter version on path
      return await dartGlobalCmd(args);
    }
  }
}
