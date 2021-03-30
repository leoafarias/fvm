import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import '../services/flutter_app_service.dart';
import '../services/flutter_tools.dart';
import '../utils/commands.dart';

import '../workflows/ensure_cache.workflow.dart';

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
      final validVersion = await FlutterTools.inferVersion(version);
      // Will install version if not already instaled
      final cacheVersion = await ensureCacheWorkflow(validVersion);

      // Runs flutter command with pinned version
      return await flutterCmd(cacheVersion, args);
    } else {
      // Running null will default to flutter version on path
      return await flutterGlobalCmd(args);
    }
  }
}
