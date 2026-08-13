import 'package:io/io.dart';

import '../services/cache_service.dart';
import '../utils/cache_mutation_lock.dart';
import 'base_command.dart';

/// Deletes all cached Flutter SDK versions.
class DestroyCommand extends BaseFvmCommand {
  @override
  final name = 'destroy';

  @override
  final description = 'Removes all cached Flutter SDK versions';

  /// Constructor
  DestroyCommand(super.context) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Bypass confirmation prompt (use with caution)',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final force = boolArg('force');

    // Proceed if force flag is used OR user confirms
    // When skipInput is true, default to false (safe default for destructive operation)
    final shouldProceed = force ||
        logger.confirm(
          'Are you sure you want to delete all cached Flutter SDK versions?\n'
          'This action cannot be undone. Do you want to proceed?',
          defaultValue: false,
        );

    if (shouldProceed) {
      final cacheService = get<CacheService>();
      if (await withAllVersionsCacheMutationLock(
        context,
        cacheService.removeAll,
      )) {
        logger.success(
          'Cached Flutter SDK versions in ${context.versionsCachePath} have been deleted',
        );
      }
    }

    return ExitCode.success.code;
  }
}
