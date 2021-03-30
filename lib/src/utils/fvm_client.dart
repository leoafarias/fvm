import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/services/git_tools.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/remove_version.workflow.dart';
import 'package:fvm/src/workflows/use_version.workflow.dart';

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
