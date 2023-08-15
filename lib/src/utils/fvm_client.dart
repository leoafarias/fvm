import '../models/cache_version_model.dart';
import '../models/project_model.dart';
import '../models/settings_dto.dart';
import '../models/valid_version_model.dart';
import '../services/cache_service.dart';
import '../services/context.dart';
import '../services/flutter_tools.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../services/settings_service.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/remove_version.workflow.dart';

// ignore: avoid_classes_with_only_static_members
/// Client for FVM APIs for other apps or packages.
class FVMClient {
  /// Returns FVM cache directory
  static final context = ctx;

  /// Triggers install workflow for [versionName]
  static Future<CacheVersion> install(String versionName) async {
    final validVersion = ValidVersion(versionName);
    return await ensureCacheWorkflow(validVersion, skipConfirmation: true);
  }

  /// Triggers remove
  static Future<void> remove(String versionName) async {
    final validVersion = ValidVersion(versionName);
    return await removeWorkflow(validVersion);
  }

  /// Triggers use workflow for [versionName]
  static Future<void> pinVersion(Project project, String versionName) async {
    final validVersion = ValidVersion(versionName);
    return await ProjectService.pinVersion(project, validVersion);
  }

  /// Triggers finish setup (sdk dependency downloads) for [versionName]
  static Future<void> setup(String versionName) async {
    final validVersion = ValidVersion(versionName);
    final cacheVersion = await CacheService.isVersionCached(validVersion);
    if (cacheVersion == null) {
      throw Exception('Cannot setup version that is not in cache');
    }
    await FlutterTools.setupSdk(cacheVersion);
  }

  /// Upgrades cached channel [version]
  static final upgradeChannel = FlutterTools.upgrade;

  /// Returns the setup sdk version of a [versionName]
  static String? getSdkVersionSync(CacheVersion cacheVersion) {
    return cacheVersion.sdkVersion;
  }

  /// Returns projects by providing a [directory]
  static final getProjectByDirectory = ProjectService.getByDirectory;

  /// Returns a list of projects by providing a list of [directories]
  static final fetchProjects = ProjectService.fetchProjects;

  /// Scans for Flutter projects found in the rootDir
  static final scanDirectory = ProjectService.scanDirectory;

  /// Get all cached Flutter SDK versions
  static final getCachedVersions = CacheService.getAllVersions;

  /// Returns [SettingsDto]
  static final readSettings = SettingsService.read;

  /// Saves FVM [settings]
  static final saveSettings = SettingsService.save;

  /// Fetches all flutter releases
  static final getFlutterReleases = fetchFlutterReleases;
}
