import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../utils/exceptions.dart';
import '../utils/helpers.dart';
import 'workflow.dart';

class EnsureCacheWorkflow extends Workflow {
  EnsureCacheWorkflow(super.context);

  // More user-friendly explanation of what went wrong and what will happen next
  Future<CacheFlutterVersion> _handleNonExecutable(
    CacheFlutterVersion version, {
    required bool shouldInstall,
  }) async {
    logger
      ..notice(
        'Flutter SDK version: ${version.name} isn\'t executable, indicating the cache is corrupted.',
      )
      ..info();

    final shouldReinstall = logger.confirm(
      'Would you like to reinstall this version to resolve the issue?',
      defaultValue: true,
    );

    if (shouldReinstall) {
      services.cache.remove(version);
      logger.info(
        'The corrupted SDK version is now being removed and a reinstallation will follow...',
      );

      return call(version, shouldInstall: shouldInstall);
    }

    throw AppException('Flutter SDK: ${version.name} is not executable.');
  }

  // Clarity on why the version mismatch happened and how it can be fixed
  Future<CacheFlutterVersion> _handleVersionMismatch(
    CacheFlutterVersion version,
  ) {
    logger
      ..notice(
        'Version mismatch detected: cache version is ${version.flutterSdkVersion}, but expected ${version.name}.',
      )
      ..info(
        'This can occur if you manually run "flutter upgrade" on a cached SDK.',
      )
      ..info();

    final firstOption =
        'Move ${version.flutterSdkVersion} to the correct cache directory and reinstall ${version.name}';

    final secondOption =
        'Remove incorrect version and reinstall ${version.name}';

    final selectedOption = logger.select(
      'How would you like to resolve this?',
      options: [firstOption, secondOption],
    );

    if (selectedOption == firstOption) {
      logger.info('Moving SDK to the correct cache directory...');
      services.cache.moveToSdkVersionDirectory(version);
    }

    logger.info('Removing incorrect SDK version...');
    services.cache.remove(version);

    return call(version, shouldInstall: true);
  }

  void _validateContext() {
    final isValid = isValidGitUrl(context.flutterUrl);
    if (!isValid) {
      throw AppException(
        'Invalid Flutter URL: "${context.flutterUrl}". Please change config to a valid git url',
      );
    }
  }

  void _validateGit() {
    final isGitInstalled = Process.runSync('git', ['--version']).exitCode == 0;
    if (!isGitInstalled) {
      throw AppException('Git is not installed');
    }
  }

  /// Ensures that the specified Flutter SDK version is cached locally.
  ///
  /// Returns a [CacheFlutterVersion] which represents the locally cached version.
  Future<CacheFlutterVersion> call(
    FlutterVersion version, {
    bool shouldInstall = false,
    bool force = false,
  }) async {
    _validateContext();
    _validateGit();
    // Get valid flutter version

    try {
      final cacheVersion = services.cache.getVersion(version);

      if (cacheVersion != null) {
        final integrity =
            await services.cache.verifyCacheIntegrity(cacheVersion);

        if (integrity == CacheIntegrity.invalid) {
          return await _handleNonExecutable(
            cacheVersion,
            shouldInstall: shouldInstall,
          );
        }

        if (integrity == CacheIntegrity.versionMismatch &&
            !force &&
            !version.isLocal) {
          return await _handleVersionMismatch(cacheVersion);
        } else if (force) {
          logger.warn(
            'Not checking for version mismatch as --force flag is set.',
          );
        } else if (version.isLocal) {
          logger.warn(
            'Not checking for version mismatch as local version is being used.',
          );
        }

        // If should install notify the user that is already installed
        if (shouldInstall) {
          logger.success(
            'Flutter SDK: ${cyan.wrap(cacheVersion.printFriendlyName)} is already installed.',
          );
        }

        return cacheVersion;
      }

      if (version.isLocal) {
        throw AppException('Local Flutter SDKs must be installed manually.');
      }

      if (!shouldInstall) {
        logger.info(
          'Flutter SDK: ${cyan.wrap(version.printFriendlyName)} is not installed.',
        );

        if (!force) {
          final shouldInstallConfirmed = logger.confirm(
            'Would you like to install it now?',
            defaultValue: true,
          );

          if (!shouldInstallConfirmed) {
            exit(ExitCode.unavailable.code);
          }
        }
      }

      bool useGitCache = context.gitCache;

      if (useGitCache) {
        try {
          await services.git.updateLocalMirror();
        } on Exception {
          logger.warn(
            'Failed to setup local cache. Falling back to git clone.',
          );
          rethrow;
        }
      }

      final progress = logger.progress(
        'Installing Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
      );
      try {
        await services.flutter.install(version);

        progress.complete(
          'Flutter SDK: ${cyan.wrap(version.printFriendlyName)} installed!',
        );
      } on Exception {
        progress.fail('Failed to install ${version.name}');
        rethrow;
      }

      final newCacheVersion = services.cache.getVersion(version);
      if (newCacheVersion == null) {
        throw AppException('Could not verify cache version $version');
      }

      return newCacheVersion;
    } on Exception {
      logger.fail('Failed to ensure $version is cached.');
      rethrow;
    }
  }
}
