import 'package:mason_logger/mason_logger.dart';
import 'package:tint/tint.dart';

import '../models/cache_flutter_version_model.dart';
import '../utils/console_utils.dart';
import '../utils/constants.dart';
import '../utils/context.dart';
import '../utils/helpers.dart';
import '../utils/which.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class GlobalCommand extends BaseCommand {
  @override
  final name = 'global';

  @override
  final description = 'Sets Flutter SDK Version as a global';

  /// Constructor
  GlobalCommand() {
    argParser
      ..addFlag(
        'unlink',
        abbr: 'u',
        help: 'Unlinks the global version',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Skips validation checks',
        defaultsTo: false,
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    final unlinkArg = boolArg('unlink');
    final forceArg = boolArg('force');

    if (unlinkArg) {
      final globalVersion = ctx.globalVersionService.getGlobal();

      if (globalVersion == null) {
        ctx.loggerService
          ..info('No global version is set')
          ..spacer;
      } else {
        ctx.globalVersionService.unlinkGlobal();
        ctx.loggerService
          ..success('Global version unlinked')
          ..spacer;
      }

      return ExitCode.success.code;
    }

    String? version;

    // Show chooser if not version is provided
    if (argResults!.rest.isEmpty) {
      final versions = await ctx.cacheService.getAllVersions();
      version = cacheVersionSelector(versions);
    }

    // Get first arg if it was not empty
    version ??= argResults!.rest[0];

    // Ensure version is installed
    final cacheVersion = await ensureCacheWorkflow(version, force: forceArg);

    // Sets version as the global
    ctx.globalVersionService.setGlobal(cacheVersion);

    final flutterInPath = which('flutter', binDir: true);

    // Get pinned version, for comparison on terminal
    final project = ctx.projectService.findAncestor();

    final pinnedVersion = project.pinnedVersion;

    CacheFlutterVersion? pinnedCacheVersion;

    if (pinnedVersion != null) {
      //TODO: Should run validation on this
      pinnedCacheVersion = ctx.cacheService.getVersion(pinnedVersion);
    }

    final isDefaultInPath = flutterInPath == ctx.globalCacheBinPath;
    final isCachedVersionInPath = flutterInPath == cacheVersion.binPath;
    final isPinnedVersionInPath = flutterInPath == pinnedCacheVersion?.binPath;

    ctx.loggerService
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

    ctx.loggerService.info(
      'Flutter SDK: ${cyan.wrap(cacheVersion.printFriendlyName)} is now global',
    );

    if (!isDefaultInPath && !isCachedVersionInPath && !isPinnedVersionInPath) {
      ctx.loggerService
        ..info('')
        ..notice('However your configured "flutter" path is incorrect')
        ..info(
          'CURRENT: ${flutterInPath ?? 'No version is configured on path.'}'
              .brightRed(),
        )
        ..info('CHANGE TO: ${ctx.globalCacheBinPath}'.green())
        ..spacer;
    }

    if (isVsCode()) {
      ctx.loggerService
        ..notice(
          '$kVsCode might override the PATH to the Flutter in their terminal',
        )
        ..info('Run the command outside of the IDE to verify.');
    }

    return ExitCode.success.code;
  }

  @override
  String get invocation => 'fvm global {version}';
}
