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
  required FVMContext context,
}) async {
  if (version.isNotSetup) return;

  final services = context.services;
  final logger = context.logger;

  if (project.dartToolVersion == version.flutterSdkVersion) {
    return;
  }

  if (!context.runPubGetOnSdkChanges) {
    logger
      ..info('Skipping "pub get" because of config setting.')
      ..lineBreak();

    return;
  }

  if (!project.hasPubspec) {
    logger
      ..info('Skipping "pub get" because no pubspec.yaml found.')
      ..lineBreak();

    return;
  }

  final progress = logger.progress('Resolving dependencies...');

  // Try to resolve offline
  ProcessResult pubGetResults = await services.flutter.runFlutter(
    version,
    ['pub', 'get', '--offline'],
  );

  if (pubGetResults.exitCode != ExitCode.success.code) {
    logger.detail('Could not resolve dependencies using offline mode.');

    progress.update('Trying to resolve dependencies...');

    pubGetResults = await services.flutter.runFlutter(
      version,
      ['pub', 'get'],
    );

    if (pubGetResults.exitCode != ExitCode.success.code) {
      progress.fail('Could not resolve dependencies.');
      logger
        ..lineBreak()
        ..err(pubGetResults.stderr.toString());

      logger.info(
        'The error could indicate incompatible dependencies to the SDK.',
      );

      if (force) {
        logger.warn('Force pinning due to --force flag.');

        return;
      }

      final confirmation = logger.confirm(
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
    logger.detail(pubGetResults.stdout);
  }
}

void logDetails(
  CacheFlutterVersion version,
  Project project, {
  required FVMContext context,
}) {
  final logger = context.logger;
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
    logger.detail('✅ Dart tool version matches SDK version, skipping resolve.');

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
