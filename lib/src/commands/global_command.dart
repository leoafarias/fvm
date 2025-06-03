import 'package:mason_logger/mason_logger.dart';
import 'package:tint/tint.dart';

import '../models/cache_flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/which.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class GlobalCommand extends BaseFvmCommand {
  @override
  final name = 'global';

  @override
  final description = 'Sets a Flutter SDK version as the global default';

  GlobalCommand(super.context) {
    argParser
      ..addFlag(
        'unlink',
        abbr: 'u',
        help: 'Removes the global Flutter SDK version setting',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Bypasses Flutter SDK validation checks',
        defaultsTo: false,
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    final unlinkArg = boolArg('unlink');
    final forceArg = boolArg('force');

    final ensureCache = EnsureCacheWorkflow(context);
    final validateFlutterVersion = ValidateFlutterVersionWorkflow(context);
    final cacheService = get<CacheService>();

    if (unlinkArg) {
      final globalVersion = cacheService.getGlobal();

      if (globalVersion == null) {
        logger
          ..info('No global version is set')
          ..info();
      } else {
        cacheService.unlinkGlobal();
        logger
          ..success('Global version unlinked')
          ..info();
      }

      return ExitCode.success.code;
    }

    String? version;

    // Show chooser if not version is provided
    if (argResults!.rest.isEmpty) {
      final versions = await cacheService.getAllVersions();
      version = logger.cacheVersionSelector(versions);
    }

    // Get first arg if it was not empty
    version ??= argResults!.rest[0];

    final flutterVersion = validateFlutterVersion(version);

    // Ensure version is installed
    final cacheVersion = await ensureCache(flutterVersion, force: forceArg);

    // Sets version as the global
    cacheService.setGlobal(cacheVersion);

    final flutterInPath = which('flutter', binDir: true);

    // Get pinned version, for comparison on terminal
    final project = get<ProjectService>().findAncestor();

    final pinnedVersion = project.pinnedVersion;

    CacheFlutterVersion? pinnedCacheVersion;

    if (pinnedVersion != null) {
      pinnedCacheVersion = cacheService.getVersion(pinnedVersion);
    }

    final isDefaultInPath = flutterInPath == context.globalCacheBinPath;
    final isCachedVersionInPath = flutterInPath == cacheVersion.binPath;
    final isPinnedVersionInPath = flutterInPath == pinnedCacheVersion?.binPath;

    logger
      ..debug('')
      ..debug('Default in path: $isDefaultInPath')
      ..debug('Cached version in path: $isCachedVersionInPath')
      ..debug('Pinned version in path: $isPinnedVersionInPath')
      ..debug('')
      ..debug('flutterInPath: $flutterInPath')
      ..debug('context.globalCacheBinPath: ${context.globalCacheBinPath}')
      ..debug('cacheVersion.binPath: ${cacheVersion.binPath}')
      ..debug('pinnedCacheVersion?.binPath: ${pinnedCacheVersion?.binPath}')
      ..debug('');

    logger.info(
      'Flutter SDK: ${cyan.wrap(cacheVersion.printFriendlyName)} is now global',
    );

    if (!isDefaultInPath && !isCachedVersionInPath && !isPinnedVersionInPath) {
      logger
        ..info('')
        ..notice('However your configured "flutter" path is incorrect')
        ..info(
          'CURRENT: ${flutterInPath ?? 'No version is configured on path.'}'
              .brightRed(),
        )
        ..info('CHANGE TO: ${context.globalCacheBinPath}'.green())
        ..info();
    }

    if (isVsCode()) {
      logger
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
