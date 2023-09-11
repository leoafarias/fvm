import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/utils/which.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/cache_service.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class GlobalCommand extends BaseCommand {
  @override
  final name = 'global';

  @override
  final description = 'Sets Flutter SDK Version as a global';

  /// Constructor
  GlobalCommand();

  @override
  String get invocation => 'fvm global {version}';

  @override
  Future<int> run() async {
    String? version;

    // Show chooser if not version is provided
    if (argResults!.rest.isEmpty) {
      version = await cacheVersionSelector();
    }

    // Get first arg if it was not empty
    version ??= argResults!.rest[0];

    // Get valid flutter version
    final validVersion = FlutterVersion.parse(version);

    // Ensure version is installed
    final cacheVersion = await ensureCacheWorkflow(validVersion);

    // Sets version as the global
    CacheService.instance.setGlobal(cacheVersion);

    final flutterInPath = which('flutter');

    final pinnedVersion = await ProjectService.instance.findVersion();

    CacheFlutterVersion? pinnedCacheVersion;

    if (pinnedVersion != null) {
      //TODO: Should run validation on this
      final flutterPinnedVersion = FlutterVersion.parse(pinnedVersion);
      pinnedCacheVersion =
          CacheService.instance.getVersion(flutterPinnedVersion);
    }

    final isDefaultInPath = flutterInPath == ctx.globalCacheBinPath;
    final isCachedVersionInPath = flutterInPath == cacheVersion.binPath;
    final isPinnedVersionInPath = flutterInPath == pinnedCacheVersion?.binPath;

    logger
      ..detail('')
      ..detail('Default in path: $isDefaultInPath')
      ..detail('Cached version in path: $isCachedVersionInPath')
      ..detail('Pinned version in path: $isPinnedVersionInPath')
      ..detail('')
      ..detail('flutterInPath: $flutterInPath')
      ..detail('ctx.globalCacheBinPath: ${ctx.globalCacheBinPath}')
      ..detail('cacheVersion.binPath: ${cacheVersion.binPath}')
      ..detail('pinnedCacheVersion?.binPath: ${pinnedCacheVersion?.binPath}')
      ..detail('');

    logger.info(
      'Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)} is now global',
    );

    if (!isDefaultInPath && !isCachedVersionInPath && !isPinnedVersionInPath) {
      logger
        ..info('')
        ..notice('However your configured "flutter" path is incorrect')
        ..spacer
        ..info(
          'CURRENT: ${flutterInPath ?? 'No version is configured on path.'}',
        )
        ..spacer
        ..info('to use global Flutter SDK through FVM you should change it to:')
        ..spacer
        ..info('NEW: ${ctx.globalCacheBinPath}')
        ..spacer
        ..info(
          'You should also configure it in FLUTTER_ROOT environment variable, as some IDEs use it.',
        );
    }
    return ExitCode.success.code;
  }
}
