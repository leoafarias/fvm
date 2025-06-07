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

      createProjectConfig(
        ProjectConfig(flutter: TestVersions.validRelease, flavors: {'dev': TestVersions.validRelease}),
        tempDir,
      );

      final projectService = ProjectService(
        FvmContext.create(
          workingDirectoryOverride: tempDir.path,
        ),
      );

      final project = projectService.findAncestor();
      expect(project, isProjectMatcher(expectedDirectory: tempDir));
    });

    test('findAncestor traverses upward to find project config', () {
      // Create a parent directory with a config file and a child directory without one.
      final parentDir = createTempDir();
      final childDir = Directory(p.join(parentDir.path, 'child'))..createSync();

      final config = ProjectConfig(flutter: TestVersions.validRelease, flavors: {'dev': TestVersions.validRelease});
      createProjectConfig(config, parentDir);

      final projectService = ProjectService(FvmContext.create(
        workingDirectoryOverride: childDir.path,
      ));

      final project = projectService.findAncestor(directory: childDir);

      expect(project, isProjectMatcher(expectedDirectory: parentDir));
    });

    test('findVersion returns pinned version if config exists', () {
      // Create a config file with a pinned flutter version.
      final tempDir = createTempDir();
      final projectService = ProjectService(
        FvmContext.create(
          workingDirectoryOverride: tempDir.path,
        ),
      );

      final config = ProjectConfig(flutter: TestVersions.validRelease, flavors: {'dev': TestVersions.validRelease});
      createProjectConfig(config, tempDir);

      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_project');

      final version = projectService.findVersion();
      expect(version, equals(TestVersions.validRelease));
    });

    test('update writes new configuration correctly', () {
      final tempDir = createTempDir();
      final projectService = ProjectService(FvmContext.create(
        workingDirectoryOverride: tempDir.path,
      ));

      final config = ProjectConfig(flutter: TestVersions.validRelease, flavors: {'dev': TestVersions.validRelease});
      createProjectConfig(config, tempDir);

      // Write an initial config file.
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_project');

      // Load the project from the temporary directory.
      final project = Project.loadFromDirectory(tempDir);

      // Update the project with new configuration values.
      projectService.update(
        project,
        flavors: {'prod': '3.11.0'},
        flutterSdkVersion: '3.11.0',
        updateVscodeSettings: true,
      );

      // Read back the updated configuration files.
      final updatedProject = projectService.findAncestor();

      final updatedConfig = updatedProject.config;
      expect(updatedConfig, isNotNull);

      final flavors = updatedConfig!.flavors;
      expect(flavors, isNotNull);
      expect(flavors!.keys, contains('prod'));
      expect(flavors['prod'], equals('3.11.0'));
      expect(flavors.keys, contains('dev'));
      expect(flavors['dev'], equals(TestVersions.validRelease));

      // Verify that the updated config contains the new flutter version and merged flavors.
      expect(updatedConfig.flutter, equals('3.11.0'));

      expect(updatedConfig.updateVscodeSettings, isTrue);

      // Also, check that the updated project reflects the new configuration.
      expect(updatedProject.pinnedVersion?.name, equals('3.11.0'));
    });

    /// Project returns the working directory if no config is found
    test('returns working directory if no config is found', () {
      final tempDir = createTempDir();
      final projectService = ProjectService(FvmContext.create(
        workingDirectoryOverride: tempDir.path,
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
