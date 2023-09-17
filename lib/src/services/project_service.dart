import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/io_utils.dart';
import 'package:path/path.dart';

/// Flutter Project Services
/// APIs for interacting with local Flutter projects
///
/// This class provides methods for interacting with local Flutter projects.
class ProjectService {
  ProjectService();

  static ProjectService get instance => ctx.get<ProjectService>();

  /// Recursive look up to find nested project directory
  /// Can start at a specific [directory] if provided
  ///
  /// This method performs a recursive search to find the nearest ancestor
  /// directory that contains a Flutter project. If a specific [directory] is provided,
  /// the search starts from that directory. Otherwise, the search starts from the
  /// current working directory.
  ///
  /// Returns the [Project] instance for the found project.
  Future<Project> findAncestor({Directory? directory}) async {
    // Get directory, defined root or current
    directory ??= Directory(ctx.workingDirectory);

    // Checks if the directory is root
    final isRootDir = rootPrefix(directory.path) == directory.path;

    // Gets project from directory
    final project = Project.loadFromPath(directory.path);

    // If project has a config return it
    if (project.hasConfig) return project;

    // Return working directory if has reached root
    if (isRootDir) return Project.loadFromPath(ctx.workingDirectory);

    return await findAncestor(
      directory: directory.parent,
    );
  }

  /// Updates the link to make sure its always correct
  ///
  /// This method updates the .fvm symlink in the provided [project] to point to the cache
  /// directory of the currently pinned Flutter SDK version. It also cleans up legacy links
  /// that are no longer needed.
  ///
  /// Throws an [AppException] if the project doesn't have a pinned Flutter SDK version.
  void updateFlutterSdkReference(Project project) {
    // Ensure the config link and symlink are updated
    final sdkVersion = project.pinnedVersion;
    if (sdkVersion == null) {
      throw AppException(
          'Cannot update link of project without a Flutter SDK version');
    }

    final sdkVersionDir = CacheService.instance.getVersionCacheDir(sdkVersion);

    // Clean up pre 3.0 links
    if (project.legacyCacheVersionSymlink.existsSync()) {
      project.legacyCacheVersionSymlink.deleteSync();
    }

    if (project.fvmCachePath.existsSync()) {
      project.fvmCachePath.deleteSync(recursive: true);
    }
    project.fvmCachePath.createSync(recursive: true);

    createLink(
      project.cacheVersionSymlink,
      sdkVersionDir,
    );
  }

  /// Search for version configured
  ///
  /// This method searches for the version of the Flutter SDK that is configured for
  /// the current project. It uses the [findAncestor] method to find the project directory.
  ///
  /// Returns the pinned Flutter SDK version for the project, or `null` if no version is configured.
  Future<String?> findVersion() async {
    final project = await findAncestor();
    return project.pinnedVersion;
  }
}
