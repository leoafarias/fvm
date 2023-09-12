import 'dart:io';

import 'package:interact/interact.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../exceptions.dart';
import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

// const logMessages = {
//   'checkCache': 'Checking if Flutter SDK {version} is cached...',
//   'notInstalled': 'Flutter SDK version {version} is not available locally.',
//   'askInstall': 'Would you like to install it now?',
//   'installing':
//       'Installing Flutter SDK version {version}... This might take a while.',
//   'installed':
//       'Success! Flutter SDK version {version} is installed and ready to use.',
//   'failed': 'Failed to cache Flutter SDK version {version}. Please try again.',
// };

/// Ensures that the specified Flutter SDK version is cached locally.
///
/// Returns a [CacheFlutterVersion] which represents the locally cached version.
Future<CacheFlutterVersion> ensureCacheWorkflow(
  FlutterVersion validVersion, {
  bool shouldInstall = false,
}) async {
  try {
    final cacheVersion = CacheService.instance.getVersion(validVersion);

    if (cacheVersion != null) {
      final integrity =
          await CacheService.instance.verifyCacheIntegrity(cacheVersion);

      if (integrity == CacheIntegrity.invalid) {
        return _handleNonExecutable(
          cacheVersion,
          shouldInstall: shouldInstall,
        );
      }

      if (integrity == CacheIntegrity.versionMismatch) {
        return _handleVersionMismatch(cacheVersion,
            shouldInstall: shouldInstall);
      }

      // If shouldl install notifiy the user that is already installed
      if (shouldInstall) {
        logger.complete(
          'Flutter SDK: ${cyan.wrap(cacheVersion.printFriendlyName)} is already installed.',
        );
      }

      return cacheVersion;
    }

    if (validVersion.isCustom) {
      exit(ExitCode.success.code);
    }

    logger.info(
      'Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)} is not cached.',
    );

    final shouldInstallConfirmed = shouldInstall ||
        logger.confirm(
          'Would you like to install it now?',
          defaultValue: true,
        );

    if (!shouldInstallConfirmed) {
      exit(ExitCode.success.code);
    }

    logger
      ..info(
          'Installing Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)}')
      ..spacer;

    await CacheService.instance.cacheVersion(validVersion);

    final newCacheVersion = CacheService.instance.getVersion(validVersion);
    if (newCacheVersion == null) {
      throw AppException('Could not cache version $validVersion');
    }

    logger
      ..spacer
      ..complete(
        'Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)} installed!',
      );

    return newCacheVersion;
  } on Exception {
    logger.fail('Failed to ensure $validVersion is cached.');
    rethrow;
  }
}

// More user-friendly explanation of what went wrong and what will happen next
Future<CacheFlutterVersion> _handleNonExecutable(
  CacheFlutterVersion version, {
  required bool shouldInstall,
}) async {
  logger
    ..notice(
      'Flutter SDK: ${version.name} is not executable. The cache may be corrupt.',
    )
    ..spacer;

  final shouldReinstall = logger.confirm(
      'Would you like to reinstall this version to resolve the issue?',
      defaultValue: true);

  if (shouldReinstall) {
    CacheService.instance.remove(version);
    logger.info(
      'Removing corrupted SDK version and initiating reinstallation...',
    );
    return ensureCacheWorkflow(
      FlutterVersion.parse(version.name),
      shouldInstall: shouldInstall,
    );
  }

  throw AppException('Flutter SDK: ${version.name} is not executable.');
}

// Clarity on why the version mismatch happened and how it can be fixed
Future<CacheFlutterVersion> _handleVersionMismatch(
  CacheFlutterVersion version, {
  required bool shouldInstall,
}) async {
  logger
    ..notice(
      'Version mismatch detected: cache version is ${version.flutterSdkVersion}, but expected ${version.name}.',
    )
    ..info(
        'This can occur if you manually run "flutter upgrade" on a cached SDK.')
    ..spacer;

  final selectedOption = Select(
          prompt: 'How would you like to resolve this?',
          options: [
            'Move ${version.flutterSdkVersion} to the correct cache directory and reinstall ${version.name}',
            'Remove incorrect version and reinstall ${version.name}',
          ],
          initialIndex: 0)
      .interact();

  if (selectedOption == 0) {
    logger.info('Moving SDK to the correct cache directory...');
    CacheService.instance.moveToSdkVersionDiretory(version);
  }

  logger.info('Removing incorrect SDK version...');
  CacheService.instance.remove(version);

  return ensureCacheWorkflow(
    FlutterVersion.parse(version.name),
    shouldInstall: shouldInstall,
  );
}
