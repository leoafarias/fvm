import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/base_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:fvm/src/utils/pretty_json.dart';
import 'package:path/path.dart' as path;

/// Flutter Project Services
/// APIs for interacting with local Flutter projects
///
/// This class provides methods for interacting with local Flutter projects.
class ProjectService extends ContextService {
  const ProjectService(super.context);

  /// Gets project service from context
  static ProjectService get fromContext => getProvider();

  /// Recursive look up to find nested project directory
  /// Can start at a specific [directory] if provided
  ///
  /// This method performs a recursive search to find the nearest ancestor
  /// directory that contains a Flutter project. If a specific [directory] is provided,
  /// the search starts from that directory. Otherwise, the search starts from the
  /// current working directory.
  ///
  /// Returns the [Project] instance for the found project.
  Project findAncestor({Directory? directory}) {
    // Get directory, defined root or current
    directory ??= Directory(context.workingDirectory);

    // Checks if the directory is root
    final isRootDir = path.rootPrefix(directory.path) == directory.path;

    // Gets project from directory
    final project = Project.loadFromPath(directory.path);

    // If project has a config return it
    if (project.hasConfig) return project;

    // if project has a pubspec file return it
    // if (project.hasPubspec) return project;

    // Return working directory if has reached root
    if (isRootDir) return Project.loadFromPath(context.workingDirectory);

    return findAncestor(directory: directory.parent);
  }

  /// Search for version configured
  ///
  /// This method searches for the version of the Flutter SDK that is configured for
  /// the current project. It uses the [findAncestor] method to find the project directory.
  ///
  /// Returns the pinned Flutter SDK version for the project, or `null` if no version is configured.
  String? findVersion() {
    final project = findAncestor();
    return project.pinnedVersion?.name;
  }

  /// Update the project with new configurations
  ///
  /// The [project] parameter is the project to be updated. The optional parameters are:
  /// - [flavors]: A map of flavor configurations.
  /// - [pinnedVersion]: The new pinned version of the Flutter SDK.
  ///
  /// This method updates the project's configuration with the provided parameters. It creates
  /// or updates the project's config file. The updated project is returned.
  Project update(
    Project project, {
    Map<String, String> flavors = const {},
    String? flutterSdkVersion,
    bool? updateVscodeSettings,
  }) {
    final newConfig = project.config ?? ProjectConfig();

    final config = newConfig.copyWith(
      flavors: flavors,
      flutterSdkVersion: flutterSdkVersion,
      updateVscodeSettings: updateVscodeSettings,
    );

    // Update flavors
    final configFile = project.configPath.file;

    // If config file does not exists create it
    if (!configFile.existsSync()) {
      configFile.createSync(recursive: true);
    }

    final jsonContents = prettyJson(config.toMap());

    configFile.write(jsonContents);

    return Project.loadFromPath(project.path);
  }
}
