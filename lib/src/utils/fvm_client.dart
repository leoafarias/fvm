import '../models/cache_version_model.dart';
import '../services/cache_service.dart';
import '../services/flutter_tools.dart';
import '../services/git_tools.dart';
import '../services/releases_service/releases_client.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/remove_version.workflow.dart';
import '../workflows/use_version.workflow.dart';
import 'logger.dart';

// ignore: avoid_classes_with_only_static_members
/// Client for FVM APIs for other apps or packages.
class FVMClient {
  /// Triggers install workflow for [versionName]
  static Future<CacheVersion> install(String versionName) async {
    final validVersion = await FlutterTools.inferValidVersion(versionName);
    return await ensureCacheWorkflow(validVersion, skipConfirmation: true);
  }

  /// Triggers remove
  static Future<void> remove(String versionName) async {
    final validVersion = await FlutterTools.inferValidVersion(versionName);
    return await removeWorkflow(validVersion);
  }

  /// Triggers use workflow for [versionName]
  static Future<void> use(String versionName) async {
    final validVersion = await FlutterTools.inferValidVersion(versionName);
    return await useVersionWorkflow(validVersion);
  }

  /// Triggers finish setup (sdk dependency downloads) for [versionName]
  static Future<void> setup(String versionName) async {
    final validVersion = await FlutterTools.inferValidVersion(versionName);
    final cacheVersion = await CacheService.isVersionCached(validVersion);
    if (cacheVersion == null) {
      throw Exception('Cannot setup version that is not in cache');
    }
    await FlutterTools.setupSdk(cacheVersion);
  }

  /// Triggers disable trackgin for [versionName]
  static Future<void> disableTracking(String versionName) async {
    final cacheVersion = await CacheService.getByVersionName(versionName);
    if (cacheVersion == null) {
      throw Exception('Cannot disable tracking version that is not in cache');
    }
    await FlutterTools.disableTracking(cacheVersion);
  }

  /// Triggers flutter upgrade for [channelName]
  static Future<void> upgradeChannel(String channelName) async {
    final cacheVersion = await CacheService.getByVersionName(channelName);
    if (cacheVersion == null) {
      throw Exception('Cannot upgrade channel that is not in cache');
    }
    await FlutterTools.upgradeChannel(cacheVersion);
  }

  /// Helpers and tools to interact with git
  static final gitTools = GitTools();

  /// Console controller for streams of process output
  static final console = consoleController;

  /// Fetches all flutter releases
  static final getFlutterReleases = fetchFlutterReleases;
}
