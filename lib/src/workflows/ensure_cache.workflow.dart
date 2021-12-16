import 'dart:io';

import 'package:io/io.dart';

import '../../exceptions.dart';
import '../models/cache_version_model.dart';
import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
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
    final cacheVersion = await CacheService.isVersionCached(validVersion);

    // Returns cache if already exists
    if (cacheVersion != null) {
      logger.trace('Version: $validVersion - already installed.');
      // Ensure the config link and symlink are updated
      await ProjectService.updateLink();
      return cacheVersion;
    }

    Logger.info('Flutter "$validVersion" is not installed.');

    // If its a custom version do not proceed on install process
    if (validVersion.custom == true) {
      exit(ExitCode.success.code);
    }

    // Install if input is confirmed
    // allows ot skip confirmation for testing purpose
    if (skipConfirmation || await confirm('Would you like to install it?')) {
      Logger.spacer();
      Logger.fine('Installing version: $validVersion...');

      // Cache version locally
      await CacheService.cacheVersion(validVersion);

      final cacheVersion = await CacheService.isVersionCached(validVersion);
      if (cacheVersion == null) {
        throw FvmInternalError('Could not cache version $validVersion');
      }
      // Ensure the config link and symlink are updated
      await ProjectService.updateLink();
      return cacheVersion;
    } else {
      // Exit if don't want to install
      exit(ExitCode.success.code);
    }
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw FvmInternalError('Could not install $validVersion');
  }
}
