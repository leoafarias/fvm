import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/models/flutter_app_model.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/config_service.dart';
import 'package:path/path.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

class FlutterAppService {
  static Future<FlutterApp> getByDirectory(Directory directory) async {
    final pubspec = await _getPubspec(directory);
    final config = await ConfigService.read(directory);

    return FlutterApp(
      name: pubspec == null ? null : pubspec.name,
      config: config,
      projectDir: directory,
      pubspec: pubspec,
      isFlutterProject: await isFlutterProject(directory),
    );
  }

  static Future<List<FlutterApp>> fetchProjects(List<String> paths) async {
    return Future.wait(
      paths.map(
        (path) async => await getByDirectory(Directory(path)),
      ),
    );
  }

  /// Updates the link to make sure its always correct
  static Future<void> updateLink() async {
    // Ensure the config link and symlink are updated
    final project = await FlutterAppService.findAncestor();
    if (project != null &&
        project.pinnedVersion != null &&
        project.config != null) {
      await ConfigService.updateSdkLink(project.config);
    }
  }

  /// Search for version configured
  static Future<String> findVersion() async {
    final project = await FlutterAppService.findAncestor();
    return project?.pinnedVersion;
  }

  /// Scans for Flutter projects found in the rootDir
  static Future<List<FlutterApp>> scanDirectory({Directory rootDir}) async {
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

  static Future<void> pinVersion(
    FlutterApp project,
    ValidVersion validVersion, {
    String environment,
  }) async {
    final config = project.config;
    // Attach as main version if no environment is set
    if (environment == null) {
      config.flutterSdkVersion = validVersion.version;
    } else {
      // Pin as an environment version
      config.environment[environment] = validVersion.version;
    }
    await ConfigService.save(config);
  }

  static Future<PubspecYaml> _getPubspec(Directory directory) async {
    final pubspecFile = File(join(directory.path, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      final pubspec = await pubspecFile.readAsString();
      return pubspec.toPubspecYaml();
    } else {
      return null;
    }
  }

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
  static Future<FlutterApp> findAncestor({Directory dir}) async {
    // Get directory, defined root or current
    dir ??= kWorkingDirectory;

    final isRootDir = rootPrefix(dir.path) == dir.path;

    final directory = Directory(dir.path);

    final project = await getByDirectory(directory);

    if (project.config.exists != null) {
      return project;
    }

    // Return working directory if has reached root
    if (isRootDir) {
      return await getByDirectory(kWorkingDirectory);
    }

    return await findAncestor(dir: dir.parent);
  }
}
