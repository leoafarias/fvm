import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import '../utils/helpers.dart';

/// Ensures that the specified Flutter SDK version is cached locally.
///
/// Returns a [CacheFlutterVersion] which represents the locally cached version.
Future<CacheFlutterVersion> ensureCacheWorkflow(
  String version, {
  bool shouldInstall = false,
  bool force = false,
  required FvmController controller,
}) async {
  _validateContext(controller);
  _validateGit();
  // Get valid flutter version
  final validVersion = await validateFlutterVersion(
    version,
    force: force,
    controller: controller,
  );
  try {
    final cacheVersion = controller.cache.getVersion(validVersion);

    if (cacheVersion != null) {
      final integrity =
          await controller.cache.verifyCacheIntegrity(cacheVersion);

      if (integrity == CacheIntegrity.invalid) {
        return await _handleNonExecutable(
          cacheVersion,
          shouldInstall: shouldInstall,
          controller: controller,
        );
      }

      if (integrity == CacheIntegrity.versionMismatch &&
          !force &&
          !validVersion.isCustom) {
        return await _handleVersionMismatch(
          cacheVersion,
          controller: controller,
        );
      } else if (force) {
        controller.logger
            .warn('Not checking for version mismatch as --force flag is set.');
      } else if (validVersion.isCustom) {
        controller.logger.warn(
          'Not checking for version mismatch as custom version is being used.',
        );
      }

      // If should install notify the user that is already installed
      if (shouldInstall) {
        controller.logger.success(
          'Flutter SDK: ${cyan.wrap(cacheVersion.printFriendlyName)} is already installed.',
        );
      }

      return cacheVersion;
    }

    if (validVersion.isCustom) {
      throw AppException('Custom Flutter SDKs must be installed manually.');
    }

    if (!shouldInstall) {
      controller.logger.info(
        'Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)} is not installed.',
      );

      if (!force) {
        final shouldInstallConfirmed = controller.logger.confirm(
          'Would you like to install it now?',
          defaultValue: true,
        );

        if (!shouldInstallConfirmed) {
          exit(ExitCode.unavailable.code);
        }
      }
    }

    bool useGitCache = controller.context.gitCache;

    if (useGitCache) {
      try {
        await controller.flutter.updateLocalMirror();
      } on Exception {
        controller.logger.warn(
          'Failed to setup local cache. Falling back to git clone.',
        );
        rethrow;
      }
    }

    final progress = controller.logger.progress(
      'Installing Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)}',
    );
    try {
      await controller.flutter.install(validVersion);

      progress.complete(
        'Flutter SDK: ${cyan.wrap(validVersion.printFriendlyName)} installed!',
      );
    } on Exception {
      progress.fail('Failed to install ${validVersion.name}');
      rethrow;
    }

    final newCacheVersion = controller.cache.getVersion(validVersion);
    if (newCacheVersion == null) {
      throw AppException('Could not verify cache version $validVersion');
    }

    return newCacheVersion;
  } on Exception {
    controller.logger.fail('Failed to ensure $validVersion is cached.');
    rethrow;
  }
}

// More user-friendly explanation of what went wrong and what will happen next
Future<CacheFlutterVersion> _handleNonExecutable(
  CacheFlutterVersion version, {
  required bool shouldInstall,
  required FvmController controller,
}) async {
  controller.logger
    ..notice(
      'Flutter SDK version: ${version.name} isn\'t executable, indicating the cache is corrupted.',
    )
    ..spacer;

  final shouldReinstall = controller.logger.confirm(
    'Would you like to reinstall this version to resolve the issue?',
    defaultValue: true,
  );

  if (shouldReinstall) {
    controller.cache.remove(version);
    controller.logger.info(
      'The corrupted SDK version is now being removed and a reinstallation will follow...',
    );

    return ensureCacheWorkflow(
      version.name,
      shouldInstall: shouldInstall,
      controller: controller,
    );
  }

  throw AppException('Flutter SDK: ${version.name} is not executable.');
}

// Clarity on why the version mismatch happened and how it can be fixed
Future<CacheFlutterVersion> _handleVersionMismatch(
  CacheFlutterVersion version, {
  required FvmController controller,
}) {
  controller.logger
    ..notice(
      'Version mismatch detected: cache version is ${version.flutterSdkVersion}, but expected ${version.name}.',
    )
    ..info(
      'This can occur if you manually run "flutter upgrade" on a cached SDK.',
    )
    ..spacer;

  final firstOption =
      'Move ${version.flutterSdkVersion} to the correct cache directory and reinstall ${version.name}';

  final secondOption = 'Remove incorrect version and reinstall ${version.name}';

  final selectedOption = controller.logger.select(
    'How would you like to resolve this?',
    options: [firstOption, secondOption],
  );

  if (selectedOption == firstOption) {
    controller.logger.info('Moving SDK to the correct cache directory...');
    controller.cache.moveToSdkVersionDirectory(version);
  }

  controller.logger.info('Removing incorrect SDK version...');
  controller.cache.remove(version);

  return ensureCacheWorkflow(
    version.name,
    shouldInstall: true,
    controller: controller,
  );
}

Future<FlutterVersion> validateFlutterVersion(
  String version, {
  bool force = false,
  required FvmController controller,
}) async {
  final flutterVersion = FlutterVersion.parse(version);

  if (force) {
    return flutterVersion;
  }

  // If its channel or commit no need for further validation
  if (flutterVersion.isChannel || flutterVersion.isCustom) {
    return flutterVersion;
  }

  if (flutterVersion.isRelease) {
    // Check version incase it as a releaseChannel i.e. 2.2.2@beta
    final isTag = await controller.flutter.isTag(flutterVersion.version);
    if (isTag) {
      return flutterVersion;
    }

    final isVersion =
        await controller.releases.isVersionValid(flutterVersion.version);

    if (isVersion) {
      return flutterVersion;
    }
  }

  if (flutterVersion.isCommit) {
    final commitSha = await controller.flutter.getReference(version);
    if (commitSha != null) {
      if (commitSha != flutterVersion.name) {
        return FlutterVersion.commit(commitSha);
      }

      return flutterVersion;
    }
  }

  controller.logger
      .notice('Flutter SDK: ($version) is not valid Flutter version');

  final askConfirmation = controller.logger.confirm(
    'Do you want to continue?',
    defaultValue: false,
  );
  if (askConfirmation) {
    // Jump a line after confirmation
    controller.logger.spacer;

    return flutterVersion;
  }

  throw AppException('$version is not a valid Flutter version');
}

void _validateContext(FvmController controller) {
  final isValid = isValidGitUrl(controller.context.flutterUrl);
  if (!isValid) {
    throw AppException(
      'Invalid Flutter URL: "${controller.context.flutterUrl}". Please change config to a valid git url',
    );
  }
}

void _validateGit() {
  final isGitInstalled = Process.runSync('git', ['--version']).exitCode == 0;
  if (!isGitInstalled) {
    throw AppException('Git is not installed');
  }
}
