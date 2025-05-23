import 'dart:async';

import 'package:path/path.dart' as p;

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';
import 'check_project_constraints.workflow.dart';
import 'workflow.dart';

/// Workflow for updating project references to Flutter SDK versions.
///
/// Note: This workflow intentionally avoids file locking mechanisms for symlink operations.
/// In typical CLI usage patterns, concurrent access issues are extremely rare, and we've
/// determined that the small risk of occasional race conditions is an acceptable trade-off
/// to reduce complexity in the codebase. The symlink operations include basic error handling
/// and retry logic to mitigate potential issues.
class UpdateProjectReferencesWorkflow extends Workflow {
  // Constants
  static const String versionFile = 'version';
  static const String releaseFile = 'release';
  static const String flutterSdkLink = 'flutter_sdk';

  UpdateProjectReferencesWorkflow(super.context);

  /// Updates the link to make sure its always correct
  ///
  /// This method updates the .fvm symlink in the provided [project] to point to the cache
  /// directory of the currently pinned Flutter SDK version. It also cleans up legacy links
  /// that are no longer needed.
  ///
  /// Note: This implementation intentionally avoids file locking for simplicity.
  /// In typical CLI usage, concurrent access issues are extremely rare.
  Future<void> _updateLocalSdkReference(
    Project project,
    CacheFlutterVersion version,
  ) async {
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
    } on Exception catch (_) {
      logger.err('Failed to prepare versions cache directory');

      rethrow;
    }

    // NOTE: File locking mechanism was intentionally removed.
    // In typical CLI usage patterns, concurrent access issues are extremely rare.
    // We accept the small risk of occasional race conditions for reduced complexity.
    try {
      // Attempt to delete the existing symlink if it exists
      try {
        if (project.localVersionSymlinkPath.link.existsSync()) {
          project.localVersionSymlinkPath.link.deleteSync();
        }
      } catch (e) {
        // Ignore errors during deletion - another process might have deleted it already
        logger.debug('Ignoring error during symlink deletion: $e');
      }

      // Verify target directory exists before creating symlink
      if (!version.directory.dir.existsSync()) {
        throw AppDetailedException(
          'Cannot create version symlink',
          'Target directory does not exist: ${version.directory}',
        );
      }

      // Create the symlink with retry logic
      try {
        project.localVersionSymlinkPath.link.createLink(version.directory);
      } catch (e) {
        // If creation fails, wait briefly and try once more
        logger.debug('Retrying symlink creation after error: $e');
        await Future.delayed(const Duration(milliseconds: 100));
        project.localVersionSymlinkPath.link.createLink(version.directory);
      }
    } on Exception catch (e) {
      logger.err('Failed to create version symlink: $e');
      rethrow;
    }
  }

  /// Updates the `flutter_sdk` link to ensure it always points to the pinned SDK version.
  ///
  /// This is required for Android Studio to work with different Flutter SDK versions.
  ///
  /// Throws an [AppException] if the project doesn't have a pinned Flutter SDK version.
  ///
  /// Note: This implementation intentionally avoids file locking for simplicity.
  /// In typical CLI usage, concurrent access issues are extremely rare.
  Future<void> _updateCurrentSdkReference(
    Project project,
    CacheFlutterVersion version,
  ) async {
    final currentSdkLink = p.join(project.localFvmPath, flutterSdkLink);

    if (!context.privilegedAccess) {
      logger.debug('Skipping symlink creation: no privileged access');

      return;
    }

    // NOTE: File locking mechanism was intentionally removed.
    // In typical CLI usage patterns, concurrent access issues are extremely rare.
    // We accept the small risk of occasional race conditions for reduced complexity.
    try {
      // Attempt to delete the existing symlink if it exists
      try {
        if (currentSdkLink.link.existsSync()) {
          currentSdkLink.link.deleteSync();
        }
      } catch (e) {
        // Ignore errors during deletion - another process might have deleted it already
        logger.debug('Ignoring error during flutter_sdk symlink deletion: $e');
      }

      // Verify target directory exists before creating symlink
      if (!version.directory.dir.existsSync()) {
        throw AppDetailedException(
          'Cannot create flutter_sdk symlink',
          'Target directory does not exist: ${version.directory}',
        );
      }

      // Create the symlink with retry logic
      try {
        currentSdkLink.link.createLink(version.directory);
      } catch (e) {
        // If creation fails, wait briefly and try once more
        logger.debug('Retrying flutter_sdk symlink creation after error: $e');
        await Future.delayed(const Duration(milliseconds: 100));
        currentSdkLink.link.createLink(version.directory);
      }
    } on Exception catch (e) {
      logger.err('Failed to create flutter_sdk symlink: $e');
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
        ..debug('Flutter version: ${version.name}')
        ..debug('');

      final updatedProject = get<ProjectService>().update(
        project,
        flavors: {if (flavor != null) flavor: version.name},
        flutterSdkVersion: version.name,
      );

      await _updateLocalSdkReference(updatedProject, version);

      await _updateCurrentSdkReference(updatedProject, version);

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
