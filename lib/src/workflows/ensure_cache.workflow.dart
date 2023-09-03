import 'dart:io';

import 'package:fvm/src/workflows/ensure_cache_integrity.workflow.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../exceptions.dart';
import '../models/cache_version_model.dart';
import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

/// Triggers a workflow for [validVersion]
/// to ensure that it is cached locally
/// returns a [CacheVersion]
Future<CacheVersion> ensureCacheWorkflow(
  ValidVersion validVersion, {
  bool shouldInstall = false,
}) async {
  try {
    // If it's installed correctly just return and use cached
    final cacheVersion = await CacheService.getVersionCache(validVersion);

    // Returns cache if already exists
    if (cacheVersion != null) {
      final integrity = await ensureCacheIntegrity(cacheVersion);
      if (integrity.isValid) {
        return cacheVersion;
      }

      if (integrity.isNeedReinstall) {
        return ensureCacheWorkflow(
          validVersion,
          shouldInstall: true,
        );
      }

      if (integrity.isInvalid) {
        logger.err('Flutter SDK: ${validVersion.name} is not valid.');
        exit(ExitCode.success.code);
      }
    }

    // TODO: Review custom version logic
    // If its a custom version do not proceed on install process
    if (validVersion.custom == true) {
      exit(ExitCode.success.code);
    }

    final shoulldInstall = shouldInstall ||
        logger.confirm(
          'Flutter SDK: ${validVersion.name} is not installed.',
          defaultValue: true,
        );

    // Install if input is confirmed
    // allows ot skip confirmation for testing purpose
    if (!shoulldInstall) {
      // Exit if don't want to install
      exit(ExitCode.success.code);
    } else {
      final printVersionLabel = '${cyan.wrap(validVersion.printFriendlyName)}';

      logger
        ..info('Installing Flutter SDK: ${cyan.wrap(printVersionLabel)}')
        ..spacer;

      // Cache version locally
      await CacheService.cacheVersion(validVersion);

      final cacheVersion = await CacheService.getVersionCache(validVersion);
      if (cacheVersion == null) {
        throw FvmError('Could not cache version $validVersion');
      }

      logger
        ..spacer
        ..complete('Flutter SDK: ${cyan.wrap(printVersionLabel)} installed!')
        ..spacer;

      return cacheVersion;
    }
  } on Exception catch (err) {
    if (err is FvmException) {
      rethrow;
    } else {
      throw FvmError('Failed to ensure $validVersion is cached.');
    }
  }
}
