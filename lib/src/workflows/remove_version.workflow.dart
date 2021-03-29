import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/valid_version_model.dart';

import 'package:fvm/src/utils/logger.dart';

Future<void> removeWorkflow(ValidVersion validVersion) async {
  FvmLogger.fine('Removing $validVersion');
  try {
    final cacheVersion = await CacheService.isVersionCached(validVersion);

    /// Remove if version is cached
    if (cacheVersion != null) {
      await CacheService.remove(cacheVersion);
    } else {
      FvmLogger.warning('Version is not installed: $validVersion');
    }
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw FvmInternalError('Could not remove $validVersion');
  }
}
