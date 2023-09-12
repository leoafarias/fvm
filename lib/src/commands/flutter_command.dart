import 'package:args/args.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/utils/logger.dart';

import '../models/flutter_version_model.dart';
import '../services/project_service.dart';
import '../utils/commands.dart';
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
  FlutterCommand();

  @override
  Future<int> run() async {
    final version = await ProjectService.instance.findVersion();
    final args = [...argResults!.arguments];

    if (version != null) {
      final validVersion = FlutterVersion.parse(version);
      // Will install version if not already installed
      final cacheVersion = await ensureCacheWorkflow(validVersion);

      logger
        ..detail('$kPackageName: Running Flutter SDK from version $version')
        ..detail('');

      void _checkIfUpgradeCommand(List<String> args) {
        if (args.isNotEmpty && args.first == 'upgrade') {
          throw AppException(
            'You should not upgrade a release version. '
            'Please install a channel instead to upgrade it. ',
          );
        }
      }

      // If its not a channel silence version check
      if (!validVersion.isChannel) {
        _checkIfUpgradeCommand(args);
      }
      // Runs flutter command with pinned version
      return runFlutter(cacheVersion, args);
    } else {
      logger
        ..detail('$kPackageName: Running Flutter SDK from PATH')
        ..detail('');
      // Running null will default to flutter version on paths
      return runFlutterGlobal(args);
    }
  }
}
