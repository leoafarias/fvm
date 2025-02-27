import 'dart:io';

import 'package:io/io.dart';

import '../models/flutter_version_model.dart';
import '../services/logger_service.dart';
import '../utils/console_utils.dart';
import '../utils/constants.dart';
import '../utils/context.dart';
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
      abbr: 'a',
      help: 'Removes all versions',
      negatable: false,
    );
  }

  /// Constructor

  @override
  Future<int> run() async {
    final all = boolArg('all');

    if (all) {
      final confirmRemoval = ctx.loggerService.confirm(
        'Are you sure you want to remove all versions in your $kPackageName cache ?',
        defaultValue: false,
      );
      if (confirmRemoval) {
        final versionsCache = Directory(ctx.versionsCachePath);
        if (versionsCache.existsSync()) {
          versionsCache.deleteSync(recursive: true);

          ctx.loggerService.success(
            '$kPackageName Directory ${versionsCache.path} has been deleted',
          );
        }
      }

      return ExitCode.success.code;
    }

    String? version;

    if (argResults!.rest.isEmpty) {
      final versions = await ctx.cacheService.getAllVersions();
      version = cacheVersionSelector(versions);
    }
    // Assign if its empty
    version ??= argResults!.rest[0];
    final validVersion = FlutterVersion.parse(version);
    final cacheVersion = ctx.cacheService.getVersion(validVersion);

    // Check if version is installed
    if (cacheVersion == null) {
      ctx.loggerService
          .info('Flutter SDK: ${validVersion.name} is not installed');

      return ExitCode.success.code;
    }

    final progress =
        ctx.loggerService.progress('Removing ${validVersion.name}...');
    try {
      /// Remove if version is cached

      ctx.cacheService.remove(cacheVersion);

      progress.complete('${validVersion.name} removed.');
    } on Exception {
      progress.fail('Could not remove $validVersion');
      rethrow;
    }

    return ExitCode.success.code;
  }

  @override
  String get invocation => 'fvm remove {version}';
}
