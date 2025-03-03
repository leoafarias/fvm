import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
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
    logger.detail('----------------------------------------');

    // Print general information
    logger.detail('🔍  Verbose Details');
    logger.detail('');

    // Dart Information
    logger.detail('🎯 Dart Info:');
    logger.detail('   Dart Generator Version: $dartGeneratorVersion');
    logger.detail('   Dart SDK Version:       $dartSdkVersion');

    // Tool Information
    logger.detail('');
    logger.detail('🛠️ Tool Info:');
    logger.detail('   Dart Tool Version:      $dartToolVersion');
    logger.detail('   SDK Version:            $flutterSdkVersion');

    // Print another separator line for clarity
    logger.detail('----------------------------------------');

    if (dartToolVersion == flutterSdkVersion) {
      logger
          .detail('✅ Dart tool version matches SDK version, skipping resolve.');

      return;
    }

    // Print a warning for mismatch
    logger.detail('');
    logger.detail('⚠️ SDK version mismatch:');
    logger.detail('   Dart Tool Version:      $dartToolVersion');
    logger.detail('   Flutter SDK Version:    $flutterSdkVersion');
    logger.detail('');

    // Final separator line
    logger.detail('----------------------------------------');
  }

  Future<bool> call(
    Project project,
    CacheFlutterVersion version, {
    required bool force,
  }) async {
    if (version.isNotSetup) {
      logger.warn('Flutter SDK is not setup, skipping resolve dependencies.');

      return false;
    }

    if (project.dartToolVersion == version.flutterSdkVersion) {
      logger
        ..info('Dart tool version matches SDK version, skipping resolve.')
        ..lineBreak();

      return true;
    }

    if (!context.runPubGetOnSdkChanges) {
      logger
        ..warn('Skipping "pub get" because of config setting')
        ..lineBreak();

      return false;
    }

    if (!project.hasPubspec) {
      logger
        ..warn('Skipping "pub get" because no pubspec.yaml found.')
        ..lineBreak();

      return true;
    }

    final progress = logger.progress('Resolving dependencies...');

    // Try to resolve offline
    final pubGetOfflineResults = await services.flutter.runFlutter(
      version,
      ['pub', 'get', '--offline'],
    );

    if (pubGetOfflineResults.isSuccess) {
      progress.complete('Dependencies resolved offline.');

      return true;
    }

    progress.update('Trying to resolve dependencies...');

    final pubGetResults = await services.flutter.runFlutter(
      version,
      ['pub', 'get'],
    );

    if (pubGetResults.isSuccess) {
      progress.complete('Dependencies resolved.');

      return true;
    }

    progress.fail('Could not resolve dependencies.');
    logger
      ..lineBreak()
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
      logger.detail(pubGetResults.stdout);
    }

    return true;
  }
}
