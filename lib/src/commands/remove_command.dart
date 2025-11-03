import 'dart:io';

import 'package:io/io.dart';

import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../utils/constants.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class RemoveCommand extends BaseFvmCommand {
  @override
  final name = 'remove';

  @override
  final description = 'Removes Flutter SDK versions from the cache';

  RemoveCommand(super.context) {
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: 'Removes all cached Flutter SDK versions',
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
        final versionsCache = Directory(context.versionsCachePath);
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
      final versions = await get<CacheService>().getAllVersions();
      version = logger.cacheVersionSelector(versions);
    } else {
      version = argResults!.rest[0];
    }
    // Assign if its empty
    version ??= argResults!.rest[0];

    // Check if the version contains a wildcard pattern
    if (version.contains('*')) {
      final pattern = version.replaceAll('*', '.*');
      final versions = await CacheService.fromContext.getAllVersions();
      final matchingVersions = versions.where((v) {
        final regex = RegExp('^$pattern\$');
        return regex.hasMatch(v.name);
      }).toList();

      if (matchingVersions.isEmpty) {
        logger.info('No Flutter SDK versions found matching pattern: $version');
        return ExitCode.success.code;
      }

      final confirmRemoval = logger.confirm(
        'Found ${matchingVersions.length} versions matching pattern "$version". Do you want to remove them all?',
        defaultValue: false,
      );

      if (!confirmRemoval) {
        return ExitCode.success.code;
      }

      for (final matchingVersion in matchingVersions) {
        final progress = logger.progress('Removing ${matchingVersion.name}...');
        try {
          CacheService.fromContext.remove(matchingVersion);
          progress.complete('${matchingVersion.name} removed.');
        } on Exception {
          progress.fail('Could not remove ${matchingVersion.name}');
          rethrow;
        }
      }

      return ExitCode.success.code;
    }

    final validVersion = FlutterVersion.parse(version);
    final cacheVersion = get<CacheService>().getVersion(validVersion);

    // Check if version is installed
    if (cacheVersion == null) {
      logger.info('Flutter SDK: ${validVersion.name} is not installed');

      return ExitCode.success.code;
    }

    final progress = logger.progress('Removing ${validVersion.name}...');
    try {
      /// Remove if version is cached

      get<CacheService>().remove(cacheVersion);

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
