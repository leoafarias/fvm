import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:io/io.dart';

import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/logger_service.dart';
import '../utils/console_utils.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class RemoveCommand extends BaseCommand {
  @override
  final name = 'remove';

  @override
  final description = 'Removes Flutter SDK Version';

  RemoveCommand() {
    argParser.addFlag(
      'all',
      help: 'Removes all versions',
      abbr: 'a',
      negatable: false,
    );
  }

  /// Constructor

  @override
  Future<int> run() async {
    final all = boolArg('all');

    if (all) {
      final confirmRemoval = logger.confirm(
        'Are you sure you want to remove all versions in your $kPackageName cache ?',
        defaultValue: false,
      );
      if (confirmRemoval) {
        final versionsCache = Directory(ctx.versionsCachePath);
        if (versionsCache.existsSync()) {
          versionsCache.deleteSync(recursive: true);

          logger.success(
            '$kPackageName Directory ${versionsCache.path} has been deleted',
          );
        }
      }
      return ExitCode.success.code;
    }

    String? version;

    if (argResults!.rest.isEmpty) {
      final versions = await CacheService.fromContext.getAllVersions();
      version = await cacheVersionSelector(versions);
    }
    // Assign if its empty
    version ??= argResults!.rest[0];
    final validVersion = FlutterVersion.parse(version);
    final cacheVersion = CacheService.fromContext.getVersion(validVersion);

    // Check if version is installed
    if (cacheVersion == null) {
      logger.info('Flutter SDK: $validVersion is not installed');
      return ExitCode.success.code;
    }

    final progress = logger.progress('Removing $validVersion...');
    try {
      /// Remove if version is cached

      CacheService.fromContext.remove(cacheVersion);

      progress.complete('$validVersion removed.');
    } on Exception {
      progress.fail('Could not remove $validVersion');
      rethrow;
    }

    return ExitCode.success.code;
  }

  @override
  String get invocation => 'fvm remove {version}';
}
