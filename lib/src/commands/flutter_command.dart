import 'package:args/args.dart';

import '../models/cache_flutter_version_model.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Proxies Flutter Commands
class FlutterCommand extends BaseCommand {
  @override
  final name = 'flutter';
  @override
  final description = 'Proxies Flutter Commands';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  FlutterCommand(super.context);

  @override
  Future<int> run() async {
    final version = controller.projectService.findVersion();
    final args = [...?argResults?.arguments];

    CacheFlutterVersion? cacheVersion;

    if (version != null) {
      // Will install version if not already installed
      cacheVersion = await ensureCacheWorkflow(
        version,
        controller: controller,
      );

      logger
        ..detail('$kPackageName: Running Flutter SDK from version $version')
        ..detail('');

      void checkIfUpgradeCommand(List<String> args) {
        if (args.isNotEmpty && args.first == 'upgrade') {
          throw AppException(
            'You should not upgrade a release version. '
            'Please install a channel instead to upgrade it. ',
          );
        }
      }

      // If its not a channel silence version check
      if (!cacheVersion.isChannel) {
        checkIfUpgradeCommand(args);
      }
      // Runs flutter command with pinned version
    } else {
      logger
        ..detail('$kPackageName: Running Flutter SDK from PATH')
        ..detail('');
      // Running null will default to flutter version on paths
    }
    final results = await controller.flutterService.runFlutter(
      args,
      version: cacheVersion,
    );

    return results.exitCode;
  }
}
