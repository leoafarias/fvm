import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
// Import the service and model classes.
// Adjust these imports based on your project structure.
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('ProjectService', () {
    test('findAncestor returns project in current directory if config exists',
        () {
      final tempDir = createTempDir();

      createFvmConfig(
        ProjectConfig(flutter: '2.2.3', flavors: {'dev': '2.2.3'}),
        tempDir,
      );

      final projectService = ProjectService(
        FVMContext.create(
          workingDirectory: tempDir.path,
        ),
      );

      final project = projectService.findAncestor();
      expect(project, isProjectMatcher(expectedDirectory: tempDir));
    });

    test('findAncestor traverses upward to find project config', () {
      // Create a parent directory with a config file and a child directory without one.
      final parentDir = createTempDir();
      final childDir = Directory(p.join(parentDir.path, 'child'))..createSync();

      final config = ProjectConfig(flutter: '2.2.3', flavors: {'dev': '2.2.3'});
      createFvmConfig(config, parentDir);

      final projectService = ProjectService(FVMContext.create(
        workingDirectory: childDir.path,
      ));

      final project = projectService.findAncestor(directory: childDir);

      expect(project, isProjectMatcher(expectedDirectory: parentDir));
    });

    test('findVersion returns pinned version if config exists', () {
      // Create a config file with a pinned flutter version.
      final tempDir = createTempDir();
      final projectService = ProjectService(
        FVMContext.create(
          workingDirectory: tempDir.path,
        ),
      );

      final config = ProjectConfig(flutter: '2.2.3', flavors: {'dev': '2.2.3'});
      createFvmConfig(config, tempDir);

      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_project');

      final version = projectService.findVersion();
      expect(version, equals('2.2.3'));
    });

    test('update writes new configuration correctly', () {
      final tempDir = createTempDir();
      final projectService = ProjectService(FVMContext.create(
        workingDirectory: tempDir.path,
      ));

      final config = ProjectConfig(flutter: '2.2.3', flavors: {'dev': '2.2.3'});
      createFvmConfig(config, tempDir);

      // Write an initial config file.
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_project');

      // Load the project from the temporary directory.
      final project = Project.loadFromPath(tempDir.path);

      // Update the project with new configuration values.
      projectService.update(
        project,
        flavors: {'prod': '2.3.0'},
        flutterSdkVersion: '2.3.0',
        updateVscodeSettings: true,
      );

      // Read back the updated configuration files.
      final updatedProject = projectService.findAncestor();

      final updatedConfig = updatedProject.config;
      expect(updatedConfig, isNotNull);

      final flavors = updatedConfig!.flavors;
      expect(flavors, isNotNull);
      expect(flavors!.keys, contains('prod'));
      expect(flavors['prod'], equals('2.3.0'));
      expect(flavors.keys, contains('dev'));
      expect(flavors['dev'], equals('2.2.3'));

      // Verify that the updated config contains the new flutter version and merged flavors.
      expect(updatedConfig.flutter, equals('2.3.0'));

      expect(updatedConfig.updateVscodeSettings, isTrue);

      // Also, check that the updated project reflects the new configuration.
      expect(updatedProject.pinnedVersion?.name, equals('2.3.0'));
    });

    /// Project returns the working directory if no config is found
    test('returns working directory if no config is found', () {
      final tempDir = createTempDir();
      final projectService = ProjectService(FVMContext.create(
        workingDirectory: tempDir.path,
      ));

      final project = projectService.findAncestor();
      expect(
          project,
          isProjectMatcher(
            expectedDirectory: tempDir,
            hasConfig: false,
          ));
    });
  });
}
