import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/settings_service.dart';

import '../models/cache_version_model.dart';
import '../models/project_model.dart';
import '../services/cache_service.dart';
import '../services/flutter_tools.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/remove_version.workflow.dart';
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
  static Future<void> pinVersion(Project project, String versionName) async {
    final validVersion = await FlutterTools.inferValidVersion(versionName);
    return await ProjectService.pinVersion(project, validVersion);
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
  // ignore: avoid_positional_boolean_parameters
  static Future<void> setFlutterAnalytics(bool enabled) async {
    await FlutterTools.setAnalytics(enabled);
  }

  /// Triggers disable trackgin for [versionName]
  static Future<bool> checkFlutterAnalytics() async {
    return await FlutterTools.checkAnalyticsEnabled();
  }

  /// Triggers flutter upgrade for [channelName]
  static Future<void> upgradeChannel(String channelName) async {
    final cacheVersion = await CacheService.getByVersionName(channelName);
    if (cacheVersion == null) {
      throw Exception('Cannot upgrade channel that is not in cache');
    }
    await FlutterTools.upgradeChannel(cacheVersion);
  }

  /// Returns the setup sdk version of a [versionName]
  static String getSdkVersionSync(CacheVersion version) {
    if (version == null) return null;
    return CacheService.getSdkVersionSync(version);
  }

  /// Returns projects by providing a [directory]
  static Future<Project> getProjectByDirectory(Directory directory) async {
    return await ProjectService.getByDirectory(directory);
  }

  /// Returns a list of projects by providing a list of [paths]
  static Future<List<Project>> fetchProjects(
    List<Directory> directories,
  ) async {
    return Future.wait(directories.map(getProjectByDirectory));
  }

  /// Scans for Flutter projects found in the rootDir
  static Future<List<Project>> scanDirectory({Directory rootDir}) async {
    return await ProjectService.scanDirectory(rootDir: rootDir);
  }

  /// Get all cached Flutter SDK versions
  static Future<List<CacheVersion>> getCachedVersions() async {
    return await CacheService.getAllVersions();
  }

  /// Returns [FvmSettings]
  static Future<FvmSettings> readSettings() async {
    return await SettingsService.read();
  }

  /// Saves FVM [settings]
  static Future<void> saveSettings(FvmSettings settings) async {
    return await SettingsService.save(settings);
  }

  /// Console controller for streams of process output
  static final console = consoleController;

  /// Fetches all flutter releases
  static final getFlutterReleases = fetchFlutterReleases;
}
