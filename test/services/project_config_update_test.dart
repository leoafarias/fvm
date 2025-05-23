import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late Directory projectDir;
  late Directory originalDir;
  late FvmContext testContext;
  late ProjectService projectService;

  setUp(() {
    // Store original directory to restore later
    originalDir = Directory.current;

    // Create a real temporary directory for tests that need to change working directory
    projectDir = createTempDir('project_config_update_test');

    // Set up test context
    testContext = TestFactory.context(
      debugLabel: 'project_config_update_test',
    );

    projectService = ProjectService(testContext);

    // Change to project directory
    Directory.current = projectDir;
  });

  tearDown(() {
    // Restore original directory
    Directory.current = originalDir;

    // Clean up temp directory
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
    }
  });

  group('Project configuration update edge cases:', () {
    test('creates new config file when none exists', () {
      // Create a Project with no config
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // Check initial state
      expect(project.hasConfig, isFalse);
      expect(project.pinnedVersion, isNull);

      // Update the project with a new version
      final updatedProject = projectService.update(
        project,
        flutterSdkVersion: 'stable',
      );

      // Verify the update
      expect(updatedProject.hasConfig, isTrue);
      expect(updatedProject.pinnedVersion?.name, 'stable');

      // Verify config file was created
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      expect(configFile.existsSync(), isTrue);
    });

    test('updates existing config correctly', () {
      // Create an initial config
      final initialConfig = ProjectConfig(
        flutter: 'beta',
        flavors: {'dev': 'beta', 'prod': 'stable'},
      );
      createProjectConfig(initialConfig, Directory(projectDir.path));

      // Load the project with existing config
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // Check initial state
      expect(project.hasConfig, isTrue);
      expect(project.pinnedVersion?.name, 'beta');
      expect(project.flavors.length, 2);

      // Update the project
      final updatedProject = projectService.update(
        project,
        flutterSdkVersion: 'stable',
        flavors: {'test': 'dev'},
      );

      // Verify the update
      expect(updatedProject.hasConfig, isTrue);
      expect(updatedProject.pinnedVersion?.name, 'stable');
      expect(updatedProject.flavors.length, 3); // Original 2 plus new one
      expect(updatedProject.flavors['test'], 'dev');
      expect(updatedProject.flavors['dev'], 'beta'); // Original preserved
      expect(updatedProject.flavors['prod'], 'stable'); // Original preserved
    });

    test('handles config file write failures', () {
      // Create a read-only directory to simulate write failure
      final readOnlyDir = Directory(p.join(projectDir.path, 'readonly'));
      readOnlyDir.createSync();

      // Make the directory read-only (this may not work on all platforms)
      try {
        // Try to make directory read-only
        Process.runSync('chmod', ['444', readOnlyDir.path]);

        // Create a project in the read-only directory
        final readOnlyProject = Project.loadFromDirectory(readOnlyDir);

        // Attempt to update the project (should fail due to permissions)
        expect(
          () => projectService.update(readOnlyProject,
              flutterSdkVersion: 'stable'),
          throwsA(isA<Exception>()),
        );
      } finally {
        // Restore permissions for cleanup
        try {
          Process.runSync('chmod', ['755', readOnlyDir.path]);
        } catch (_) {
          // Ignore cleanup errors
        }
      }
    });

    test('handles non-existent project directory', () {
      // Create a project with a non-existent directory
      final nonExistentDir = Directory('/non/existent/dir');
      final project = Project.loadFromDirectory(nonExistentDir);

      // Attempt to update the project
      expect(
        () => projectService.update(project, flutterSdkVersion: 'stable'),
        throwsA(isA<Exception>()),
      );
    });

    test('preserves existing settings when updating partial config', () {
      // Create an initial config with various settings
      final initialConfig = ProjectConfig(
        flutter: 'beta',
        flavors: {'dev': 'beta', 'prod': 'stable'},
      );
      createProjectConfig(initialConfig, Directory(projectDir.path));

      // Load the project with existing config
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // Update only the Flutter version
      final updatedProject = projectService.update(
        project,
        flutterSdkVersion: 'stable',
      );

      // Verify only the Flutter version was updated, flavors preserved
      expect(updatedProject.pinnedVersion?.name, 'stable');
      expect(updatedProject.flavors.length, 2);
      expect(updatedProject.flavors['dev'], 'beta');
      expect(updatedProject.flavors['prod'], 'stable');
    });

    test('creates legacy config file alongside new config', () {
      // Create a Project with no config
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // Update the project with a new version
      projectService.update(
        project,
        flutterSdkVersion: 'stable',
      );

      // Verify both new and legacy config files were created
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      final legacyConfigFile =
          File(p.join(projectDir.path, '.fvm', 'fvm_config.json'));

      expect(configFile.existsSync(), isTrue);
      expect(legacyConfigFile.existsSync(), isTrue);

      // Verify legacy config format
      final legacyContent = legacyConfigFile.readAsStringSync();
      expect(legacyContent.contains('"flutterSdkVersion"'), isTrue);
    });

    test('updates config for a flavor without changing the default version',
        () {
      // Create an initial config with a default version
      final initialConfig = ProjectConfig(
        flutter: 'stable',
      );
      createProjectConfig(initialConfig, Directory(projectDir.path));

      // Load the project with existing config
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // Add a flavor without changing the default version
      final updatedProject = projectService.update(
        project,
        flavors: {'dev': 'beta'},
      );

      // Verify the flavor was added but default version remains unchanged
      expect(updatedProject.pinnedVersion?.name, 'stable');
      expect(updatedProject.flavors.length, 1);
      expect(updatedProject.flavors['dev'], 'beta');
    });
  });
}
