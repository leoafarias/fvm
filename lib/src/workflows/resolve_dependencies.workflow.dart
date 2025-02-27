import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';

Future<void> resolveDependenciesWorkflow(
  Project project,
  CacheFlutterVersion version, {
  required bool force,
  required FvmController controller,
}) async {
  if (version.isNotSetup) return;

  if (project.dartToolVersion == version.flutterSdkVersion) {
    return;
  }

  if (!controller.context.runPubGetOnSdkChanges) {
    controller.logger
      ..info('Skipping "pub get" because of config setting.')
      ..spacer;

    return;
  }

  if (!project.hasPubspec) {
    controller.logger
      ..info('Skipping "pub get" because no pubspec.yaml found.')
      ..spacer;

    return;
  }

  final progress = controller.logger.progress('Resolving dependencies...');

  // Try to resolve offline
  ProcessResult pubGetResults = await controller.flutter.runFlutter(
    ['pub', 'get', '--offline'],
    version: version,
  );

  if (pubGetResults.exitCode != ExitCode.success.code) {
    controller.logger
        .detail('Could not resolve dependencies using offline mode.');

    progress.update('Trying to resolve dependencies...');

    pubGetResults = await controller.flutter.runFlutter(
      ['pub', 'get'],
      version: version,
    );

    if (pubGetResults.exitCode != ExitCode.success.code) {
      progress.fail('Could not resolve dependencies.');
      controller.logger
        ..spacer
        ..err(pubGetResults.stderr.toString());

      controller.logger.info(
        'The error could indicate incompatible dependencies to the SDK.',
      );

      if (force) {
        controller.logger.warn('Force pinning due to --force flag.');

        return;
      }

      final confirmation = controller.logger.confirm(
        'Would you like to continue pinning this version anyway?',
        defaultValue: false,
      );

      if (!confirmation) {
        throw AppException('Dependencies not resolved.');
      }

      return;
    }
  }

  progress.complete('Dependencies resolved.');

  if (pubGetResults.stdout != null) {
    controller.logger.detail(pubGetResults.stdout);
  }
}

void logDetails(
  CacheFlutterVersion version,
  Project project, {
  required FvmController controller,
}) {
  final logger = controller.logger;
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
    controller.logger
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
