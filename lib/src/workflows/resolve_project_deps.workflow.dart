import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../services/cache_service.dart';
import '../services/flutter_service.dart';
import '../services/process_service.dart';
import '../utils/exceptions.dart';
import 'workflow.dart';

class ResolveProjectDependenciesWorkflow extends Workflow {
  ResolveProjectDependenciesWorkflow(super.context);

  void _logDetails(CacheFlutterVersion version, Project project) {
    final dartGeneratorVersion = project.dartToolGeneratorVersion;
    final dartToolVersion = project.dartToolVersion;
    final dartSdkVersion = version.dartSdkVersion;
    final flutterSdkVersion = version.flutterSdkVersion;
    // Print a separator line for easier reading
    logger.debug('----------------------------------------');

    // Print general information
    logger.debug('🔍  Verbose Details');
    logger.debug('');

    // Dart Information
    logger.debug('🎯 Dart Info:');
    logger.debug('   Dart Generator Version: $dartGeneratorVersion');
    logger.debug('   Dart SDK Version:       $dartSdkVersion');

    // Tool Information
    logger.debug('');
    logger.debug('🛠️ Tool Info:');
    logger.debug('   Dart Tool Version:      $dartToolVersion');
    logger.debug('   SDK Version:            $flutterSdkVersion');

    // Print another separator line for clarity
    logger.debug('----------------------------------------');

    if (dartToolVersion == flutterSdkVersion) {
      logger
          .debug('✅ Dart tool version matches SDK version, skipping resolve.');

      return;
    }

    // Print a warning for mismatch
    logger.debug('');
    logger.debug('⚠️ SDK version mismatch:');
    logger.debug('   Dart Tool Version:      $dartToolVersion');
    logger.debug('   Flutter SDK Version:    $flutterSdkVersion');
    logger.debug('');

    // Final separator line
    logger.debug('----------------------------------------');
  }

  Future<bool> call(
    Project project,
    CacheFlutterVersion version, {
    required bool force,
  }) async {
    final flutterService = get<FlutterService>();
    final cacheService = get<CacheService>();

    if (version.isNotSetup) {
      logger.warn('Flutter SDK is not setup, skipping resolve dependencies.');

      return false;
    }

    if (project.dartToolVersion == version.flutterSdkVersion) {
      logger
        ..info('Dart tool version matches SDK version, skipping resolve.')
        ..info();

      return true;
    }

    if (!context.runPubGetOnSdkChanges) {
      logger
        ..warn('Skipping "pub get" because of config setting')
        ..info();

      return false;
    }

    if (!project.hasPubspec) {
      logger
        ..warn('Skipping "pub get" because no pubspec.yaml found.')
        ..info();

      return true;
    }

    final progress = logger.progress('Resolving dependencies...');

    // Try to resolve offline
    final pubGetOfflineResults = await flutterService.pubGet(
      version,
      offline: true,
    );

    if (pubGetOfflineResults.isSuccess) {
      progress.complete('Dependencies resolved offline.');

      return true;
    }

    progress.update('Trying to resolve dependencies...');

    final pubGetResults = await flutterService.pubGet(version);

    if (pubGetResults.isSuccess) {
      progress.complete('Dependencies resolved.');

      return true;
    }

    progress.fail('Could not resolve dependencies.');
    logger
      ..info()
      ..err(pubGetResults.stderr.toString());

    logger.info(
      'The error could indicate incompatible dependencies to the SDK.',
    );

    if (force) {
      logger.warn('Force pinning due to --force flag.');

      return false;
    }

    final confirmation = logger.confirm(
      'Would you like to continue pinning this version anyway?',
      defaultValue: false,
    );

    if (!confirmation) {
      throw AppException('Dependencies not resolved.');
    }

    if (pubGetResults.stdout != null) {
      logger.debug(pubGetResults.stdout);
    }

    return true;
  }
}
