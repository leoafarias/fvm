import 'package:io/io.dart';

import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import '../workflows/remove_version.workflow.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class RemoveCommand extends BaseCommand {
  RemoveCommand();

  @override
  final name = 'remove';

  @override
  final description = 'Removes Flutter SDK Version';

  @override
  String get invocation => 'fvm remove {version}';

  /// Constructor

  @override
  Future<int> run() async {
    String? version;

    if (argResults!.rest.isEmpty) {
      version = await cacheVersionSelector();
    }
    // Assign if its empty
    version ??= argResults!.rest[0];
    final validVersion = ValidVersion(version);
    final cacheVersion = await CacheService.getVersionCache(validVersion);

    // Check if version is installed
    if (cacheVersion == null) {
      logger.info('Flutter SDK: $validVersion is not installed');
      return ExitCode.success.code;
    }

    await removeWorkflow(validVersion);

    return ExitCode.success.code;
  }
}
