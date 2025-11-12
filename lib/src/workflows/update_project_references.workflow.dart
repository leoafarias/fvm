import 'dart:async';

import 'package:path/path.dart' as p;

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
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
      // Ensure the directory exists
      project.localFvmPath.dir.ensureExists();
    } on Exception catch (e, stackTrace) {
      logger.err('Failed to create local FVM path');

      Error.throwWithStackTrace(e, stackTrace);
    }

    final sdkVersionFile = p.join(project.localFvmPath, versionFile);
    final sdkReleaseFile = p.join(project.localFvmPath, releaseFile);

    try {
      sdkVersionFile.file.write(project.dartToolVersion ?? '');
    } on Exception catch (e, stackTrace) {
      logger.err('Failed to write to version file');

      Error.throwWithStackTrace(e, stackTrace);
    }

    try {
      sdkReleaseFile.file.write(version.name);
    } on Exception catch (e, stackTrace) {
      logger.err('Failed to write to release file');

      Error.throwWithStackTrace(e, stackTrace);
    }

    if (!context.privilegedAccess) {
      logger.debug('Skipping symlink creation: no privileged access');

      return;
    }

    try {
      project.localVersionsCachePath.dir
        ..deleteIfExists()
        ..ensureExists();
    } on Exception catch (e, stackTrace) {
      logger.err('Failed to prepare versions cache directory');

      Error.throwWithStackTrace(e, stackTrace);
    }

    try {
      if (project.localVersionSymlinkPath.link.existsSync()) {
        project.localVersionSymlinkPath.link.deleteSync();
      }
      project.localVersionSymlinkPath.link.createLink(version.directory);
    } on Exception catch (e, stackTrace) {
      logger.err('Failed to create version symlink');

      Error.throwWithStackTrace(e, stackTrace);
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
      } on Exception catch (e, stackTrace) {
        logger.err('Failed to delete existing flutter_sdk symlink');

        Error.throwWithStackTrace(e, stackTrace);
      }
    }

    if (!context.privilegedAccess) {
      logger.debug('Skipping symlink creation: no privileged access');

      return;
    }

    try {
      currentSdkLink.link.createLink(version.directory);
    } on Exception catch (e, stackTrace) {
      logger.err('Failed to create flutter_sdk symlink');

      Error.throwWithStackTrace(e, stackTrace);
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
        ..debug('Flutter version: ${version.name}')
        ..debug('');

      final updatedProject = get<ProjectService>().update(
        project,
        flavors: {if (flavor != null) flavor: version.name},
        flutterSdkVersion: version.name,
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
