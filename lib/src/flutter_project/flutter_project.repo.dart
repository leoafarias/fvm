import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart';

class FlutterProjectRepo {
  final Directory rootDir;
  FlutterProjectRepo(this.rootDir);

  /// Retrieves all Flutter projects in rootDir
  Future<List<FlutterProject>> getAll() async {
    final projects = <FlutterProject>[];
    // Find directories recursively
    await for (FileSystemEntity entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      // Check if entity is directory
      final pubspecFile = File(join(entity.path, 'pubspec.yaml'));

      if (entity is Directory && await pubspecFile.exists()) {
        final project = FlutterProject(entity);
        // Add only if its flutter project
        if (await project.isFlutterProject()) {
          projects.add(project);
        }
      }
    }
    return projects;
  }
}
