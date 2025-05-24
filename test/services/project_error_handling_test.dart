import 'dart:io';

import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late Directory projectDir;
  late Directory originalWorkingDir;
  late FvmContext testContext;
  late ProjectService projectService;

  setUp(() {
    // Save the original working directory
    originalWorkingDir = Directory.current;

    // Create a real temporary directory for testing
    projectDir = createTempDir('project_error_handling_test');

    // Set up test context
    testContext = TestFactory.context(
      debugLabel: 'project_error_handling_test',
      workingDirectoryOverride: projectDir.path,
    );

    projectService = ProjectService(testContext);

    // Set working directory to our project directory
    Directory.current = projectDir;
  });

  tearDown(() {
    // Restore the original working directory
    Directory.current = originalWorkingDir;

    // Clean up the temporary directory
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
    }
  });

  group('Project error handling:', () {
    test('handles invalid config JSON format', () {
      // Create an invalid JSON config file
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('{ invalid json }');

      // Try to load the project - should not throw but handle gracefully
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded but the config should be null
      expect(project.path, projectDir.path);
      expect(project.config, isNull);
      expect(project.hasConfig, isFalse);
    });

    test('handles missing config file directory gracefully', () {
      // Delete the project directory
      projectDir.deleteSync();

      // Try to load project from non-existent directory
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded but the config should be null
      expect(project.path, projectDir.path);
      expect(project.config, isNull);
      expect(project.hasConfig, isFalse);
    });

    test('handles project with empty config file', () {
      // Create an empty config file
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('');

      // Try to load the project
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded but the config should be null
      expect(project.path, projectDir.path);
      expect(project.config, isNull);
      expect(project.hasConfig, isFalse);
    });

    test('handles project with null values in config', () {
      // Create a config with null values for some fields
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": null,
        "flavors": null,
        "privilegedAccess": null
      }
      ''');

      // Try to load the project
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded with default values for null fields
      expect(project.path, projectDir.path);
      expect(project.config, isNotNull);
      expect(project.hasConfig, isTrue);
      expect(project.pinnedVersion, isNull);
      expect(project.flavors, isEmpty);
    });

    test('handles config with non-string version', () {
      // Create a config with non-string version
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": 123,
        "flavors": {"dev": 456}
      }
      ''');

      // Try to load the project - should handle the type error gracefully
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded and the system should convert the number to string
      expect(project.path, projectDir.path);
      expect(project.config, isNotNull);
      expect(project.hasConfig, isTrue);

      // The system is robust and converts the number to a string
      expect(project.pinnedVersion?.name, '123');
      // Flavors with non-string values are also converted to strings
      expect(project.flavors, {'dev': '456'});
    });

    test('handles access errors when reading config', () {
      // Skip this test for now since we're using real files
      // TODO: Implement a way to simulate file access errors with real files
    }, skip: 'Requires file access error simulation');

    test('handles write errors when updating config', () {
      // Skip this test for now since we're using real files
      // TODO: Implement a way to simulate file write errors with real files
    }, skip: 'Requires file write error simulation');

    test('handles legacy config correctly', () {
      // Create only a legacy config file in the .fvm directory
      final fvmDir = Directory(p.join(projectDir.path, '.fvm'));
      fvmDir.createSync(recursive: true);
      final legacyConfigFile = File(p.join(fvmDir.path, 'fvm_config.json'));
      legacyConfigFile.writeAsStringSync('''
      {
        "flutterSdkVersion": "stable",
        "flavors": {"dev": "beta"}
      }
      ''');

      // Try to load the project
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded with data from the legacy config
      expect(project.path, projectDir.path);
      expect(project.config, isNotNull);
      expect(project.hasConfig, isTrue);
      expect(project.pinnedVersion?.name, 'stable');
      expect(project.flavors.length, 1);
      expect(project.flavors['dev'], 'beta');
    });

    test('prioritizes new config over legacy config', () {
      // Create both new and legacy config files with different values
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": "stable",
        "flavors": {"new": "stable"}
      }
      ''');

      final fvmDir = Directory(p.join(projectDir.path, '.fvm'));
      fvmDir.createSync(recursive: true);
      final legacyConfigFile = File(p.join(fvmDir.path, 'fvm_config.json'));
      legacyConfigFile.writeAsStringSync('''
      {
        "flutterSdkVersion": "beta",
        "flavors": {"legacy": "beta"}
      }
      ''');

      // Load the project
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // Should use the new config format
      expect(project.pinnedVersion?.name, 'stable');
      expect(project.flavors.length, 1);
      expect(project.flavors['new'], 'stable');
      expect(project.flavors['legacy'], isNull);
    });

    test('findAncestor handles no Flutter project found', () {
      // Create a deeply nested directory structure with no Flutter project
      final nestedDir =
          Directory(p.join(projectDir.path, 'src', 'nested', 'deeper'));
      nestedDir.createSync(recursive: true);

      // Set working directory to the nested directory
      Directory.current = nestedDir;

      // Try to find ancestor - should return a default project at working directory
      final project = projectService.findAncestor();

      // The project should fall back to the working directory (projectDir)
      // since no config was found in the nested directory or its ancestors
      expect(project.path, projectDir.path);
      expect(project.config, isNull);
      expect(project.hasConfig, isFalse);
    });
  });
}
