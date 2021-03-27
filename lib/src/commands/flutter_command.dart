import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/src/services/flutter_app_service.dart';
import 'package:fvm/src/utils/commands.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';

/// Proxies Flutter Commands
class FlutterCommand extends Command<int> {
  // The [name] and [description] properties must be defined by every
  // subclass.

  @override
  final name = 'flutter';
  @override
  final description = 'Proxies Flutter Commands';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  FlutterCommand();

  @override
  Future<int> run() async {
    final version = await FlutterAppService.findVersion();
    final args = argResults.arguments;

    if (version != null) {
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(version);
      // Runs flutter command with pinned version
      FvmLogger.info('fvm: running version "$version"');
      return await flutterCmd(cacheVersion, args);
    } else {
      FvmLogger.info('Running using Flutter version configured in path.');
      // Running null will default to flutter version on path
      return await flutterGlobalCmd(args);
    }
  }
}
