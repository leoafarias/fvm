import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/logger.dart';

Future<void> removeWorkflow(String version) async {
  FvmLogger.fine('Removing $version');
  try {
    final cacheVersion = await CacheService.isVersionCached(version);
    if (cacheVersion != null) {
      await CacheService.remove(cacheVersion);
    } else {
      FvmLogger.warning('Version is not installed: $version');
    }
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw InternalError('Could not remove $version');
  }
}
