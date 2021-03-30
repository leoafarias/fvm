import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/valid_version_model.dart';

import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:io/io.dart';

import '../utils/logger.dart';

Future<CacheVersion> ensureCacheWorkflow(
  ValidVersion validVersion, {
  bool skipConfirmation = false,
}) async {
  try {
    assert(validVersion != null);

    // If it's installed correctly just return and use cached
    final cacheVersion = await CacheService.isVersionCached(validVersion);

    if (cacheVersion != null) {
      logger.trace('Version: $validVersion - already installed.');
      return cacheVersion;
    }

    // Ensure the config link and symlink are updated
    // If there is an app
    await FlutterAppService.updateLink();

    FvmLogger.info('Flutter "$validVersion" is not installed.');

    // Install if input is confirmed, allows ot skip confirmation for testing purpose
    if (skipConfirmation || await confirm('Would you like to install it?')) {
      FvmLogger.fine('Installing version: $validVersion');
      return await CacheService.cacheVersion(validVersion);
    } else {
      // Exit if don't want to install
      exit(ExitCode.success.code);
    }
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw FvmInternalError('Could not install <$validVersion>');
  }
}
