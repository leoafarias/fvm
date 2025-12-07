import 'dart:async';

import 'package:path/path.dart' as p;

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../services/git_service.dart';
import '../services/project_service.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';
import 'check_project_constraints.workflow.dart';
import 'workflow.dart';

class UpdateProjectReferencesWorkflow extends Workflow {
  // Constants
  static const String versionFile = 'version';
  static const String releaseFile = 'release';
  static const String flutterSdkLink = 'flutter_sdk';

  const UpdateProjectReferencesWorkflow(super.context);

  /// Updates the link to make sure it's always correct
  ///
  /// This method updates the .fvm symlink in the provided [project] to point to the cache
  /// directory of the currently pinned Flutter SDK version. It also cleans up legacy links
  /// that are no longer needed.
  void _updateLocalSdkReference(Project project, CacheFlutterVersion version) {
    try {
      // Only create the directory if it doesn't exist
      if (!project.localFvmPath.dir.existsSync()) {
        project.localFvmPath.dir.createSync(recursive: true);
      }
    } on Exception catch (_) {
      logger.err('Failed to create local FVM path');

      rethrow;
    }

    final sdkVersionFile = p.join(project.localFvmPath, versionFile);
    final sdkReleaseFile = p.join(project.localFvmPath, releaseFile);

    try {
      sdkVersionFile.file.write(project.dartToolVersion ?? '');
    } on Exception catch (_) {
      logger.err('Failed to write to version file');

      rethrow;
    }

    try {
      sdkReleaseFile.file.write(version.name);
    } on Exception catch (_) {
      logger.err('Failed to write to release file');

      rethrow;
    }

    if (!context.privilegedAccess) {
      logger.debug('Skipping symlink creation: no privileged access');

      return;
    }

    try {
      project.localVersionsCachePath.dir
        ..deleteIfExists()
        ..createSync(recursive: true);

      if (version.fromFork) {
        final forkDir = p.join(project.localVersionsCachePath, version.fork!);
        if (!forkDir.dir.existsSync()) {
          forkDir.dir.createSync(recursive: true);
        }
      }
    } on Exception catch (_) {
      logger.err('Failed to prepare versions cache directory');

      rethrow;
    }

    try {
      if (project.localVersionSymlinkPath.link.existsSync()) {
        project.localVersionSymlinkPath.link.deleteSync();
      }
      project.localVersionSymlinkPath.link.createLink(version.directory);
    } on Exception catch (_) {
      logger.err('Failed to create version symlink');

      rethrow;
    }
  }

  /// Updates the `flutter_sdk` link to ensure it always points to the pinned SDK version.
  ///
  /// This is required for Android Studio to work with different Flutter SDK versions.
  ///
  /// Throws an [AppException] if the project doesn't have a pinned Flutter SDK version.
  void _updateCurrentSdkReference(
    Project project,
    CacheFlutterVersion version,
  ) {
    final currentSdkLink = p.join(project.localFvmPath, flutterSdkLink);

    if (currentSdkLink.link.existsSync()) {
      try {
        currentSdkLink.link.deleteSync();
      } on Exception catch (_) {
        logger.err('Failed to delete existing flutter_sdk symlink');

        rethrow;
      }
    }

    if (!context.privilegedAccess) {
      logger.debug('Skipping symlink creation: no privileged access');

      return;
    }

    try {
      currentSdkLink.link.createLink(version.directory);
    } on Exception catch (_) {
      logger.err('Failed to create flutter_sdk symlink');

      rethrow;
    }
  }

  /// Updates all SDK references in the project
  FutureOr<Project> call(
    Project project,
    CacheFlutterVersion version, {
    String? flavor,
    bool force = false,
  }) async {
    try {
      await get<CheckProjectConstraintsWorkflow>().call(
        project,
        version,
        force: force,
      );

      logger
        ..debug()
        ..debug('Updating project config')
        ..debug('Project name: ${project.name}')
        ..debug('Project path: ${project.path}')
        ..debug('Flutter version: ${version.nameWithAlias}')
        ..debug('');

      // Resolve commit hash to full SHA if this is an unknown ref (commit)
      String versionToStore = version.name;
      if (version.isUnknownRef) {
        // Use version.version to get the version part without fork prefix
        // This ensures we resolve the actual commit hash, not a fork-prefixed string
        final fullHash = await get<GitService>().resolveCommitHash(
          version.version,
          version,
        );
        if (fullHash != null) {
          versionToStore = fullHash;
          logger.debug('Resolved commit hash: ${version.name} -> $fullHash');
        }
      }

      final updatedProject = get<ProjectService>().update(
        project,
        flavors: {if (flavor != null) flavor: versionToStore},
        flutterSdkVersion: versionToStore,
      );

      _updateLocalSdkReference(updatedProject, version);

      _updateCurrentSdkReference(updatedProject, version);

      return updatedProject;
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        AppDetailedException('Error updating project references', e.toString()),
        stackTrace,
      );
    }
  }
}
