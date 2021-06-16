import 'package:io/io.dart';

import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import '../workflows/remove_version.workflow.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class RemoveCommand extends BaseCommand {
  @override
  final name = 'remove';

  @override
  final description = 'Removes Flutter SDK Version';

  @override
  String get invocation => 'fvm remove {version}';

  /// Constructor

  RemoveCommand() {
    argParser.addFlag(
      'force',
      help: 'Skips version global check.',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final force = boolArg('force');
    String? version;

    if (argResults!.rest.isEmpty) {
      version = await cacheVersionSelector();
    }
    // Assign if its empty
    version ??= argResults!.rest[0];
    final validVersion = ValidVersion(version);
    final cacheVersion = await CacheService.isVersionCached(validVersion);

    // Check if version is installed
    if (cacheVersion == null) {
      FvmLogger.info('Flutter SDK: $validVersion is not installed');
      return ExitCode.success.code;
    }

    final isGlobal = await CacheService.isGlobal(cacheVersion);

    if (!isGlobal || force) {
      await removeWorkflow(validVersion);
    } else {
      final confirmation = await confirm(
        '$validVersion is current configured as "global". '
        'Do you still would like to remove?',
      );

      if (confirmation) {
        await removeWorkflow(validVersion);
      }
    }

    return ExitCode.success.code;
  }
}
