import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../services/flutter_service.dart';
import '../services/process_service.dart';
import '../utils/exceptions.dart';
import 'workflow.dart';

class ResolveProjectDependenciesWorkflow extends Workflow {
  const ResolveProjectDependenciesWorkflow(super.context);

  Future<bool> call(
    Project project,
    CacheFlutterVersion version, {
    required bool force,
  }) async {
    final flutterService = get<FlutterService>();

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

    // Try to resolve offline
    final pubGetOfflineResults = await flutterService.pubGet(
      version,
      offline: true,
    );

    if (pubGetOfflineResults.isSuccess) {
      logger.info('Dependencies resolved offline.');

      return true;
    }

    logger.info('Trying to resolve dependencies online...');
    final pubGetResults = await flutterService.pubGet(version);

    if (pubGetResults.isSuccess) {
      logger.info('Dependencies resolved.');

      return true;
    }

    logger.err('Could not resolve dependencies.');
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
