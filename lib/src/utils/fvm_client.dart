import '../models/cache_version_model.dart';
import '../services/cache_service.dart';
import '../services/flutter_tools.dart';
import '../services/git_tools.dart';
import '../services/releases_service/releases_client.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/remove_version.workflow.dart';
import '../workflows/use_version.workflow.dart';
import 'logger.dart';

void _ifCachedContinue(CacheVersion cacheVersion) {
  if (cacheVersion == null) {
    throw Exception('Version is not cached');
  }
}

class FVMClient {
  // Flutter SDK
  // ignore: top_level_function_literal_block
  static final install = (String versionName) async {
    final validVersion = await FlutterTools.inferVersion(versionName);
    return await ensureCacheWorkflow(validVersion, skipConfirmation: true);
  };
  static final remove = removeWorkflow;
  static final use = useVersionWorkflow;
  // ignore: top_level_function_literal_block
  static final setup = (String versionName) async {
    final cachedVersion = await CacheService.getByVersionName(versionName);
    _ifCachedContinue(cachedVersion);
    await FlutterTools.setupSdk(cachedVersion);
  };
  // ignore: top_level_function_literal_block
  static final disableTracking = (String versionName) async {
    final cachedVersion = await CacheService.getByVersionName(versionName);
    _ifCachedContinue(cachedVersion);
    await FlutterTools.disableTracking(cachedVersion);
  };

  // ignore: top_level_function_literal_block
  static final upgradeChannel = (String channelName) async {
    final cachedVersion = await CacheService.getByVersionName(channelName);
    _ifCachedContinue(cachedVersion);
    await FlutterTools.upgradeChannel(cachedVersion);
  };

  static final gitTools = GitTools();
  static final console = consoleController;
  // Interaction with releases api
  static final getFlutterReleases = fetchFlutterReleases;
}
