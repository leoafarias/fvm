import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:path/path.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_project/fvm_config_repo.dart';

class FlutterProjectRepo {
  static Future<FlutterProject> getOne(Directory directory) async {
    final pubspec = await _getPubspec(directory);
    final config = await FvmConfigRepo.read(directory);

    return FlutterProject(
      name: pubspec == null ? null : pubspec.name,
      config: config,
      projectDir: directory,
      isFlutterProject: await isFlutterProject(directory),
    );
  }

  static Future<List<FlutterProject>> fetchProjects(List<String> paths) async {
    return Future.wait(
      paths.map(
        (path) async => await getOne(
          Directory(path),
        ),
      ),
    );
  }

  /// Scans for Flutter projects found in the rootDir
  static Future<List<FlutterProject>> scanDirectory({Directory rootDir}) async {
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

  static Future<void> pinVersion(FlutterProject project, String version) async {
    final config = project.config;
    config.flutterSdkVersion = version;
    await FvmConfigRepo.save(config);
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
  static Future<FlutterProject> findAncestor({Directory dir}) async {
    // Get directory, defined root or current
    dir ??= kWorkingDirectory;

    final isRootDir = rootPrefix(dir.path) == dir.path;

    final directory = Directory(dir.path);

    final project = await getOne(directory);

    if (project.isFlutterProject) {
      return project;
    }

    // Return working directory if has reached root
    if (isRootDir) {
      return await getOne(kWorkingDirectory);
    }

    return await findAncestor(dir: dir.parent);
  }
}
