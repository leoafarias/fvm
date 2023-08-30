import '../../exceptions.dart';
import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

/// Triggers the workflow to remove a [validVersion]
Future<void> removeWorkflow(ValidVersion validVersion) async {
  final progress = logger.progress('Removing $validVersion...');
  try {
    final cacheVersion = await CacheService.getVersionCache(validVersion);

    /// Remove if version is cached
    if (cacheVersion != null) {
      await CacheService.remove(cacheVersion);

      progress.complete('$validVersion removed.');
    } else {
      logger.warn('Version is not installed: $validVersion');
    }
  } on Exception catch (err) {
    logger.detail(err.toString());
    progress.fail('Could not remove $validVersion');
    throw FvmError('Could not remove $validVersion');
  }
}
