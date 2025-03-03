import 'dart:async';

import 'package:path/path.dart' as p;

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';
import 'check_project_constraints.workflow.dart';
import 'workflow.dart';

class UpdateProjectReferencesWorkflow extends Workflow {
  // Constants
  static const String versionFile = 'version';
  static const String releaseFile = 'release';
  static const String flutterSdkLink = 'flutter_sdk';

  late final CheckProjectConstraintsWorkflow _checkProjectConstraints;
  UpdateProjectReferencesWorkflow(super.context) {
    _checkProjectConstraints = get<CheckProjectConstraintsWorkflow>();
  }

  /// Updates the link to make sure its always correct
  ///
  /// This method updates the .fvm symlink in the provided [project] to point to the cache
  /// directory of the currently pinned Flutter SDK version. It also cleans up legacy links
  /// that are no longer needed.
  void _updateLocalSdkReference(
    Project project,
    CacheFlutterVersion version,
  ) {
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
      logger.detail('Skipping symlink creation: no privileged access');

      return;
    }

    try {
      project.localVersionsCachePath.dir
        ..deleteIfExists()
        ..createSync(recursive: true);
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
      logger.detail('Skipping symlink creation: no privileged access');

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
      await _checkProjectConstraints(project, version, force: force);

      final updatedProject = services.project.update(
        project,
        flavors: {if (flavor != null) flavor: version.name},
        flutterSdkVersion: version.name,
      );

      _updateLocalSdkReference(updatedProject, version);

      _updateCurrentSdkReference(updatedProject, version);

      return updatedProject;
    } on Exception catch (e, stackTrace) {
      Error.throwWithStackTrace(
        AppDetailedException(
          'Error updating project references',
          e.toString(),
        ),
        stackTrace,
      );
    }
  }
}
