import 'dart:convert';
import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/io_utils.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/utils/pretty_json.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

import '../../constants.dart';

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

  /// Adds to .gitignore paths that should be ignored for fvm
  ///
  /// This method adds the given [pathToAdd] to the .gitignore file of the provided [project].
  /// If the .gitignore file doesn't exist, it will be created. The method checks if
  /// the given path already exists in the .gitignore file before adding it.
  ///
  /// The method prompts the user for confirmation before actually adding the path,
  /// unless running in a test environment.
  void addToGitignore(Project project, String pathToAdd) {
    bool alreadyExists = false;

    // Check if .gitignore exists, and if not, create it.
    if (!project.gitignoreFile.existsSync()) {
      project.gitignoreFile.createSync();
    }

    // Read existing lines.
    List<String> lines = project.gitignoreFile.readAsLinesSync();

    // Check if path already exists in .gitignore
    for (var line in lines) {
      if (line.trim() == pathToAdd) {
        alreadyExists = true;
        break;
      }
    }

    if (alreadyExists) {
      return;
    }

    logger
      ..spacer
      ..info(
        'You should add the $kPackageName version directory "${cyan.wrap(pathToAdd)}" to .gitignore?',
      );

    if (ctx.isTest ||
        logger.confirm(
          'Would you like to do that now?',
        )) {
      // Add the new path if it doesn't exist.
      lines.add('');
      lines.add('# FVM Version Cache');
      lines.add(pathToAdd);
      project.gitignoreFile.writeAsStringSync('${lines.join('\n')}\n');
      logger
        ..spacer
        ..complete('Added $pathToAdd to .gitignore')
        ..spacer;
    }
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

  /// Updates VS Code configuration for the project
  ///
  /// This method updates the VS Code configuration for the provided [project].
  /// It sets the correct exclude settings in the VS Code settings file to exclude
  /// the .fvm/versions directory from search and file watchers.
  ///
  /// The method also updates the "dart.flutterSdkPath" setting to use the relative
  /// path of the .fvm symlink.
  void updateVsCodeConfig(
    Project project,
  ) {
    final vscodeDir = Directory(join(
      project.path,
      '.vscode',
    ));

    final vsCodeSettingsFile = File(join(
      vscodeDir.path,
      'settings.json',
    ));

    if (!vscodeDir.existsSync()) {
      return;
    }

    Map<String, dynamic> recommendedSettings = {
      'search.exclude': {'**/.fvm/versions': true},
      'files.watcherExclude': {'**/.fvm/versions': true},
      'files.exclude': {'**/.fvm/versions': true}
    };

    if (!vsCodeSettingsFile.existsSync()) {
      logger.detail('VSCode settings not found, to update.');
      vsCodeSettingsFile.createSync(recursive: true);
    }

    Map<String, dynamic> currentSettings = {};

    // Check if settings.json exists; if not, create it.
    if (vsCodeSettingsFile.existsSync()) {
      String contents = vsCodeSettingsFile.readAsStringSync();
      final sanitizedContent = contents.replaceAll(RegExp(r'\/\/.*'), '');
      if (sanitizedContent.isNotEmpty) {
        currentSettings = json.decode(sanitizedContent);
      }
    } else {
      vsCodeSettingsFile.create(recursive: true);
    }

    bool isUpdated = false;

    recommendedSettings.forEach((key, value) {
      final recommendedValue = value as Map<String, dynamic>;

      if (currentSettings.containsKey(key)) {
        final currentValue = currentSettings[key] as Map<String, dynamic>;

        recommendedValue.forEach((key, value) {
          if (!currentValue.containsKey(key) || currentValue[key] != value) {
            currentValue[key] = value;
            isUpdated = true;
          }
        });
      } else {
        currentSettings[key] = value;
        isUpdated = true;
      }
    });

    // Write updated settings back to settings.json
    if (isUpdated) {
      logger.complete(
        'VSCode $kPackageName settings has been updated. with correct exclude settings\n',
      );
    }

    final relativePath = relative(
      project.cacheVersionSymlinkCompat.path,
      from: project.path,
    );

    currentSettings["dart.flutterSdkPath"] = relativePath;

    vsCodeSettingsFile.writeAsStringSync(prettyJson(currentSettings));
  }
}
