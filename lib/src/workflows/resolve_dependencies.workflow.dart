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
}) async {
  if (version.isNotSetup) return;

  if (project.dartToolVersion == version.flutterSdkVersion) {
    return;
  }

  if (!ctx.runPubGetOnSdkChanges) {
    ctx.loggerService
      ..info('Skipping "pub get" because of config setting.')
      ..spacer;

    return;
  }

  if (!project.hasPubspec) {
    ctx.loggerService
      ..info('Skipping "pub get" because no pubspec.yaml found.')
      ..spacer;

    return;
  }

  final progress = ctx.loggerService.progress('Resolving dependencies...');

  // Try to resolve offline
  ProcessResult pubGetResults = await version.run('pub get --offline');

  if (pubGetResults.exitCode != ExitCode.success.code) {
    ctx.loggerService
        .detail('Could not resolve dependencies using offline mode.');

    progress.update('Trying to resolve dependencies...');

    pubGetResults = await version.run('pub get');

    if (pubGetResults.exitCode != ExitCode.success.code) {
      progress.fail('Could not resolve dependencies.');
      ctx.loggerService
        ..spacer
        ..err(pubGetResults.stderr.toString());

      ctx.loggerService.info(
        'The error could indicate incompatible dependencies to the SDK.',
      );

      if (force) {
        ctx.loggerService.warn('Force pinning due to --force flag.');

        return;
      }

      final confirmation = ctx.loggerService.confirm(
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
    ctx.loggerService.detail(pubGetResults.stdout);
  }
}

void logDetails(CacheFlutterVersion version, Project project) {
  final dartGeneratorVersion = project.dartToolGeneratorVersion;
  final dartToolVersion = project.dartToolVersion;
  final dartSdkVersion = version.dartSdkVersion;
  final flutterSdkVersion = version.flutterSdkVersion;
  // Print a separator line for easier reading
  ctx.loggerService.detail('----------------------------------------');

  // Print general information
  ctx.loggerService.detail('🔍  Verbose Details');
  ctx.loggerService.detail('');

  // Dart Information
  ctx.loggerService.detail('🎯 Dart Info:');
  ctx.loggerService.detail('   Dart Generator Version: $dartGeneratorVersion');
  ctx.loggerService.detail('   Dart SDK Version:       $dartSdkVersion');

  // Tool Information
  ctx.loggerService.detail('');
  ctx.loggerService.detail('🛠️ Tool Info:');
  ctx.loggerService.detail('   Dart Tool Version:      $dartToolVersion');
  ctx.loggerService.detail('   SDK Version:            $flutterSdkVersion');

  // Print another separator line for clarity
  ctx.loggerService.detail('----------------------------------------');

  if (dartToolVersion == flutterSdkVersion) {
    ctx.loggerService
        .detail('✅ Dart tool version matches SDK version, skipping resolve.');

    return;
  }

  // Print a warning for mismatch
  ctx.loggerService.detail('');
  ctx.loggerService.detail('⚠️ SDK version mismatch:');
  ctx.loggerService.detail('   Dart Tool Version:      $dartToolVersion');
  ctx.loggerService.detail('   Flutter SDK Version:    $flutterSdkVersion');
  ctx.loggerService.detail('');

  // Final separator line
  ctx.loggerService.detail('----------------------------------------');
}
