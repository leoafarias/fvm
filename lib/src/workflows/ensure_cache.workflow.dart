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

  // Auto-fix corrupted cache for improved user experience
  Future<CacheFlutterVersion> _handleNonExecutable(
    CacheFlutterVersion version, {
    required bool shouldInstall,
    required bool force,
    int retryCount = 0,
  }) {
    const maxRetries = 2;
    if (retryCount >= maxRetries) {
      throw AppException(
        'Failed to fix corrupted cache after $maxRetries attempts. '
        'Please check disk space and permissions, then try again.',
      );
    }

    logger
      ..notice(
        'Flutter SDK version: ${version.name} isn\'t executable, indicating the cache is corrupted.',
      )
      ..info(
        'Auto-fixing corrupted cache by reinstalling (attempt ${retryCount + 1}/$maxRetries)...',
      );

    // Always auto-fix corrupted cache - no prompting needed
    // Corrupted cache is always a problem that needs fixing
    get<CacheService>().remove(version);
    logger.info(
      'The corrupted SDK version is now being removed and a reinstallation will follow...',
    );

    return call(
      version,
      shouldInstall: shouldInstall,
      force: force,
      retryCount: retryCount + 1,
    );
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

    String selectedOption;
    if (context.skipInput) {
      // In CI/non-interactive mode, automatically choose safe default: remove and reinstall
      logger.warn(
        'CI/non-interactive mode detected: Auto-selecting to remove and reinstall',
      );
      selectedOption = secondOption;
    } else {
      // Interactive mode: show prompt
      selectedOption = logger.select(
        'How would you like to resolve this?',
        options: [firstOption, secondOption],
      );
    }

    if (selectedOption == firstOption) {
      logger.info('Moving SDK to the correct cache directory...');
      get<CacheService>().moveToSdkVersionDirectory(version);
    }

    logger.info('Removing incorrect SDK version...');
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
    try {
      // `Process.runSync` throws a [ProcessException] when the executable
      // cannot be found. If Git is installed, it returns a [ProcessResult]
      // whose [exitCode] is `0` on success.
      final isGitInstalled =
          Process.runSync('git', ['--version']).exitCode == 0;
      if (!isGitInstalled) {
        throw const AppException('Git is not installed');
      }
    } on ProcessException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const AppException('Git is not installed'),
        stackTrace,
      );
    }
  }

  /// Ensures that the specified Flutter SDK version is cached locally.
  ///
  /// Returns a [CacheFlutterVersion] which represents the locally cached version.
  Future<CacheFlutterVersion> call(
    FlutterVersion version, {
    bool shouldInstall = false,
    bool force = false,
    int retryCount = 0,
  }) async {
    _validateContext();
    _validateGit();
    // Get valid flutter version
    final cacheService = get<CacheService>();
    final flutterService = get<FlutterService>();
    final gitService = get<GitService>();

    final cacheVersion = cacheService.getVersion(version);

    // Migrate legacy non-bare caches if present, but avoid refreshing the mirror
    // unless we are about to install or the version is missing.
    final useGitCache = context.gitCache;
    if (!version.fromFork) {
      try {
        await gitService.ensureBareCacheIfPresent();
        if (useGitCache && (cacheVersion == null || shouldInstall)) {
          await gitService.updateLocalMirror();
        }
      } on Exception catch (e) {
        logger.debug('Local cache setup exception: $e');
        logger.warn('Failed to setup local cache. Falling back to git clone.');
      }
    }

    if (cacheVersion != null) {
      final integrity = await cacheService.verifyCacheIntegrity(cacheVersion);

      if (integrity == CacheIntegrity.invalid) {
        return await _handleNonExecutable(
          cacheVersion,
          shouldInstall: shouldInstall,
          force: force,
          retryCount: retryCount,
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

    if (!shouldInstall) {
      logger.info(
        'Flutter SDK: ${cyan.wrap(version.printFriendlyName)} is not installed.',
      );
      logger.info('Installing Flutter SDK automatically...');
    }

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

    final newCacheVersion = cacheService.getVersion(version);
    if (newCacheVersion == null) {
      throw AppException('Could not verify cache version $version');
    }

    return newCacheVersion;
  }
}
