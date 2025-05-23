import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/flutter_service.dart';
import '../services/git_service.dart';
import '../utils/exceptions.dart';
import '../utils/helpers.dart';
import 'workflow.dart';

class EnsureCacheWorkflow extends Workflow {
  const EnsureCacheWorkflow(super.context);

  /// Simplified cache corruption handling - auto-fix without user prompts
  Future<CacheFlutterVersion> _handleCorruptedCache(
    CacheFlutterVersion version, {
    required bool shouldInstall,
  }) {
    logger.info(
      'Flutter SDK ${version.name} cache is corrupted. Removing and reinstalling...',
    );

    get<CacheService>().remove(version);

    return call(version, shouldInstall: shouldInstall);
  }

  /// Simplified version mismatch handling - auto-fix without user prompts
  Future<CacheFlutterVersion> _handleVersionMismatch(
    CacheFlutterVersion version,
  ) {
    logger.info(
      'Version mismatch detected for ${version.name}. Removing and reinstalling...',
    );

    get<CacheService>().remove(version);

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
  /// Simplified approach:
  /// - If cache exists and is valid, return it
  /// - If cache exists but is invalid, auto-remove and reinstall
  /// - If cache doesn't exist, install it (with confirmation only in interactive mode)
  /// - Minimal user prompts - fail fast on errors
  Future<CacheFlutterVersion> call(
    FlutterVersion version, {
    bool shouldInstall = false,
    bool force = false,
  }) async {
    _validateContext();
    _validateGit();
    // Get valid flutter version
    final cacheService = get<CacheService>();
    final flutterService = get<FlutterService>();
    final gitService = get<GitService>();

    final cacheVersion = cacheService.getVersion(version);

    if (cacheVersion != null) {
      final integrity = await cacheService.verifyCacheIntegrity(cacheVersion);

      if (integrity == CacheIntegrity.invalid) {
        return await _handleCorruptedCache(
          cacheVersion,
          shouldInstall: shouldInstall,
        );
      }

      if (integrity == CacheIntegrity.versionMismatch &&
          !force &&
          !version.isCustom) {
        return await _handleVersionMismatch(cacheVersion);
      } else if (force) {
        logger.warn(
          'Not checking for version mismatch as --force flag is set.',
        );
      } else if (version.isCustom) {
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

    if (version.isCustom) {
      throw AppException('Local Flutter SDKs must be installed manually.');
    }

    // For non-interactive environments or when forced, proceed with installation
    if (!shouldInstall && !force && !context.skipInput) {
      logger.info(
        'Flutter SDK: ${cyan.wrap(version.printFriendlyName)} is not installed.',
      );
      throw AppException(
        'Version ${version.name} is not installed. Use --force to install automatically '
        'or run: fvm install ${version.name}',
      );
    }

    bool useGitCache = context.gitCache;

    // Set up git cache if enabled
    if (useGitCache) {
      try {
        await gitService.updateLocalMirror();
      } on Exception catch (e) {
        logger.warn(
          'Failed to setup local git cache: $e. Falling back to direct clone.',
        );
        // Continue without git cache - don't fail the whole operation
      }
    }

    // Install the version
    final progress = logger.progress(
      'Installing Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
    );

    try {
      await flutterService.install(version);
      progress.complete(
        'Flutter SDK: ${cyan.wrap(version.printFriendlyName)} installed!',
      );
    } on Exception {
      progress.fail('Failed to install ${version.name}');
      rethrow;
    }

    // Verify installation worked
    final newCacheVersion = cacheService.getVersion(version);
    if (newCacheVersion == null) {
      throw AppException(
        'Installation completed but could not verify cache version $version',
      );
    }

    return newCacheVersion;
  }
}
