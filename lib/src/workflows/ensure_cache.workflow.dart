import 'dart:io';

import 'package:io/io.dart';

import '../../exceptions.dart';
import '../models/cache_version_model.dart';
import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';

/// Triggers a workflow for [validVersion]
/// to ensure that it is cached locally
/// returns a [CacheVersion]
Future<CacheVersion> ensureCacheWorkflow(
  ValidVersion validVersion, {
  bool skipConfirmation = false,
}) async {
  try {
    // If it's installed correctly just return and use cached
    final cacheVersion = await CacheService.getVersionCache(validVersion);

    // Returns cache if already exists
    if (cacheVersion != null) {
      logger.info('Flutter SDK: $validVersion - already installed.');

      return cacheVersion;
    }

    logger.info('Flutter SDK: $validVersion is not installed.');

    // If its a custom version do not proceed on install process
    if (validVersion.custom == true) {
      exit(ExitCode.success.code);
    }

    // Install if input is confirmed
    // allows ot skip confirmation for testing purpose
    if (skipConfirmation || await confirm('Would you like to install it?')) {
      final progress = logger.progress('Installing version: $validVersion...');

      // Cache version locally
      await CacheService.cacheVersion(validVersion);

      final cacheVersion = await CacheService.getVersionCache(validVersion);
      if (cacheVersion == null) {
        progress.fail('Could not install $validVersion');
        throw FvmError('Could not cache version $validVersion');
      }
      progress.complete();
      return cacheVersion;
    } else {
      // Exit if don't want to install
      exit(ExitCode.success.code);
    }
  } on Exception catch (err) {
    if (err is FvmException) {
      rethrow;
    } else {
      throw FvmError('Failed to ensure $validVersion is cached.');
    }
  }
}
