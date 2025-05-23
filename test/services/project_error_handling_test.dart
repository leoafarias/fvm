import 'dart:io';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../mocks/mock_file_system.dart';
import '../testing_utils.dart';

void main() {
  late MockFileSystem mockFileSystem;
  late Directory projectDir;
  late FvmContext testContext;
  late ProjectService projectService;

  setUp(() {
    mockFileSystem = MockFileSystem();

    // Create a mock project directory
    projectDir = mockFileSystem.directory('/test/project');
    projectDir.createSync(recursive: true);

    // Set up test context
    testContext = TestFactory.context(
      debugLabel: 'project_error_handling_test',
    );

    projectService = ProjectService(testContext);

    // Set working directory to our project directory
    Directory.current = projectDir;
  });

  group('Project error handling:', () {
    test('handles invalid config JSON format', () {
      // Create an invalid JSON config file
      final configFile = mockFileSystem.file(p.join(projectDir.path, '.fvmrc'));
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
      final configFile = mockFileSystem.file(p.join(projectDir.path, '.fvmrc'));
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
      final configFile = mockFileSystem.file(p.join(projectDir.path, '.fvmrc'));
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
      final configFile = mockFileSystem.file(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": 123,
        "flavors": {"dev": 456}
      }
      ''');

      // Try to load the project - should handle the type error gracefully
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded but with parsing errors for the version
      expect(project.path, projectDir.path);
      expect(project.config, isNotNull);
      expect(project.hasConfig, isTrue);

      // These would likely be null or default values since the parsing would fail
      expect(project.pinnedVersion, isNull);
      expect(project.flavors, isEmpty);
    });

    test('handles access errors when reading config', () {
      // Create a config file
      final configFile = mockFileSystem.file(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('{"flutter": "stable"}');

      // Simulate a file read error
      mockFileSystem.simulateFailure(
        'readAsStringSync:${p.join(projectDir.path, '.fvmrc')}',
        FileSystemException('Permission denied'),
      );

      // Try to load the project - should handle the error gracefully
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // The project should be loaded but the config should be null
      expect(project.path, projectDir.path);
      expect(project.config, isNull);
      expect(project.hasConfig, isFalse);
    });

    test('handles write errors when updating config', () {
      // Create a valid initial config
      final initialConfig = ProjectConfig(
        flutter: 'beta',
        cachePath: testContext.config.cachePath,
        useGitCache: testContext.config.useGitCache,
        gitCachePath: testContext.config.gitCachePath,
        flutterUrl: testContext.config.flutterUrl,
        privilegedAccess: testContext.config.privilegedAccess,
        runPubGetOnSdkChanges: true,
        updateVscodeSettings: true,
        updateGitIgnore: true,
      );
      createProjectConfig(initialConfig, Directory(projectDir.path));

      // Load the project with existing config
      final project = Project.loadFromDirectory(Directory(projectDir.path));

      // Simulate a file write error
      mockFileSystem.simulateFailure(
        'writeAsStringSync:${p.join(projectDir.path, '.fvmrc')}',
        FileSystemException('Permission denied'),
      );

      // Try to update the project - should throw an exception
      expect(
        () => projectService.update(project, flutterSdkVersion: 'stable'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('handles legacy config correctly', () {
      // Create only a legacy config file
      final legacyConfigFile =
          mockFileSystem.file(p.join(projectDir.path, 'fvm_config.json'));
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
      final configFile = mockFileSystem.file(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": "stable",
        "flavors": {"new": "stable"}
      }
      ''');

      final legacyConfigFile =
          mockFileSystem.file(p.join(projectDir.path, 'fvm_config.json'));
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
          mockFileSystem.directory('/test/project/src/nested/deeper');
      nestedDir.createSync(recursive: true);

      // Set working directory to the nested directory
      Directory.current = nestedDir;

      // Try to find ancestor - should return a default project at current directory
      final project = projectService.findAncestor();

      // The project should be based on the current directory
      expect(project.path, nestedDir.path);
      expect(project.config, isNull);
      expect(project.hasConfig, isFalse);
    });
  });
}
