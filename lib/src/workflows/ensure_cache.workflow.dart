import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../exceptions.dart';
import '../models/cache_flutter_version_model.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

/// Ensures that the specified Flutter SDK version is cached locally.
///
/// Returns a [CacheFlutterVersion] which represents the locally cached version.
Future<CacheFlutterVersion> ensureCacheWorkflow(
  String version, {
  bool shouldInstall = false,
}) async {
  // Get valid flutter version
  final validVersion = await validateFlutterVersion(version);
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
        return _handleVersionMismatch(
          cacheVersion,
          shouldInstall: shouldInstall,
        );
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
      'Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)} is not installed.',
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
      version.name,
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

  final firstOption =
      'Move ${version.flutterSdkVersion} to the correct cache directory and reinstall ${version.name}';

  final secondOption = 'Remove incorrect version and reinstall ${version.name}';

  final selectedOption = logger.select(
    'How would you like to resolve this?',
    options: [
      firstOption,
      secondOption,
    ],
  );

  if (selectedOption == firstOption) {
    logger.info('Moving SDK to the correct cache directory...');
    CacheService.instance.moveToSdkVersionDiretory(version);
  }

  logger.info('Removing incorrect SDK version...');
  CacheService.instance.remove(version);

  return ensureCacheWorkflow(
    version.name,
    shouldInstall: true,
  );
}

Future<FlutterVersion> validateFlutterVersion(String version) async {
  final flutterVersion = FlutterVersion.parse(version);
  // If its channel or commit no need for further validation
  if (flutterVersion.isChannel || flutterVersion.isCustom) {
    return flutterVersion;
  }

  if (flutterVersion.isRelease) {
    // Check version incase it as a releaseChannel i.e. 2.2.2@beta
    final isTag = await FlutterTools.instance.isTag(flutterVersion.version);
    if (isTag) return flutterVersion;
  }

  if (flutterVersion.isCommit) {
    final commitSha = await FlutterTools.instance.getReference(version);
    if (commitSha != null) {
      if (commitSha != flutterVersion.name) {
        throw AppException(
          'FVM only supports short commit SHAs (10 characters) should be ($commitSha)',
        );
      }
      return flutterVersion;
    }
  }

  logger.notice(
    'Flutter SDK: ($version) is not valid Flutter version',
  );

  final askConfirmation = logger.confirm(
    'Do you want to continue?',
    defaultValue: false,
  );
  if (askConfirmation) {
    // Jump a line after confirmation
    logger.spacer;
    return flutterVersion;
  }

  throw AppException(
    '$version is not a valid Flutter version',
  );
}
