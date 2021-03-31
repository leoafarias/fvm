import 'dart:io';

import 'package:path/path.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

import '../../constants.dart';
import '../models/project_model.dart';
import '../models/valid_version_model.dart';
import 'config_service.dart';

/// Flutter Project Services
/// APIs for interacting with local Flutter projects
class ProjectService {
  /// Returns projects by providing a [directory]
  static Future<Project> getByDirectory(Directory directory) async {
    final pubspec = await _getPubspec(directory);
    final config = await ConfigService.read(directory);

    return Project(
      name: pubspec == null ? null : pubspec.name,
      config: config,
      projectDir: directory,
      pubspec: pubspec,
      isFlutterProject: await isFlutterProject(directory),
    );
  }

  /// Returns a list of projects by providing a list of [paths]
  static Future<List<Project>> fetchProjects(List<String> paths) async {
    return Future.wait(
      paths.map(
        (path) async => await getByDirectory(Directory(path)),
      ),
    );
  }

  /// Updates the link to make sure its always correct
  static Future<void> updateLink() async {
    // Ensure the config link and symlink are updated
    final project = await ProjectService.findAncestor();
    if (project != null &&
        project.pinnedVersion != null &&
        project.config != null) {
      await ConfigService.updateSdkLink(project.config);
    }
  }

  /// Search for version configured
  static Future<String> findVersion() async {
    final project = await ProjectService.findAncestor();
    return project?.pinnedVersion;
  }

  /// Scans for Flutter projects found in the rootDir
  static Future<List<Project>> scanDirectory({Directory rootDir}) async {
    final paths = <String>[];

    if (rootDir == null) {
      return [];
    }
    // Find directories recursively
    await for (FileSystemEntity entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      // Check if entity is directory
      if (entity is Directory) {
        // Add only if its flutter project
        if (await isFlutterProject(entity)) {
          paths.add(entity.path);
        }
      }
    }
    return await fetchProjects(paths);
  }

  /// Pins a [validVersion] to a Flutter [project].
  /// Can pin to a specific [environment] if provided
  static Future<void> pinVersion(
    Project project,
    ValidVersion validVersion, {
    String environment,
  }) async {
    final config = project.config;
    // Attach as main version if no environment is set
    if (environment == null) {
      config.flutterSdkVersion = validVersion.name;
    } else {
      // Pin as an environment version
      config.environment[environment] = validVersion.name;
    }
    await ConfigService.save(config);
  }

  /// Returns a [pubspec] from a [directory]
  static Future<PubspecYaml> _getPubspec(Directory directory) async {
    final pubspecFile = File(join(directory.path, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      final pubspec = await pubspecFile.readAsString();
      return pubspec.toPubspecYaml();
    } else {
      return null;
    }
  }

  /// Checks if flutter [directory] is a Flutter project
  static Future<bool> isFlutterProject(Directory directory) async {
    try {
      final pubspec = await _getPubspec(directory);
      if (pubspec == null) {
        return false;
      }
      final isFlutter = pubspec.dependencies.firstWhere(
        // ignore: invalid_use_of_protected_member
        (dependency) => dependency.sdk != null,
        orElse: () => null,
      );
      return isFlutter != null;
    } on Exception {
      return false;
    }
  }

  /// Recursive look up to find nested project directory
  /// Can start at a specific [directory] if provided
  static Future<Project> findAncestor({Directory directory}) async {
    // Get directory, defined root or current
    directory ??= kWorkingDirectory;

    // Checks if the directory is root
    final isRootDir = rootPrefix(directory.path) == directory.path;

    // Gets project from directory
    final project = await getByDirectory(directory);

    // If project has a config return it
    if (project.config.exists != null) {
      return project;
    }

    // Return working directory if has reached root
    if (isRootDir) {
      return await getByDirectory(kWorkingDirectory);
    }

    return await findAncestor(directory: directory.parent);
  }
}
