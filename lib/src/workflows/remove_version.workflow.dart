import '../../exceptions.dart';
import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

/// Triggers the workflow to remove a [validVersion]
Future<void> removeWorkflow(ValidVersion validVersion) async {
  FvmLogger.info('Removing $validVersion...');
  try {
    final cacheVersion = await CacheService.isVersionCached(validVersion);

    /// Remove if version is cached
    if (cacheVersion != null) {
      await CacheService.remove(cacheVersion);

      FvmLogger.fine('$validVersion removed.');
    } else {
      FvmLogger.warning('Version is not installed: $validVersion');
    }
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw FvmInternalError('Could not remove $validVersion');
  }
}
