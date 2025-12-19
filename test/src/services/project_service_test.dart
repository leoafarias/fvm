import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
// Import the service and model classes.
// Adjust these imports based on your project structure.
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('ProjectService', () {
    late FvmContext context;
    late ProjectService projectService;
    late TempDirectoryTracker tempDirs;

    setUp(() {
      context = TestFactory.context(
        debugLabel: 'project-service-test',
        privilegedAccess: true,
      );
      projectService = ProjectService(context);
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });

    test(
      'findAncestor returns project in current directory if config exists',
      () {
        final tempDir = tempDirs.create();

        createProjectConfig(
          ProjectConfig(flutter: '2.2.3', flavors: {'dev': '2.2.3'}),
          tempDir,
        );

        final project = projectService.findAncestor(directory: tempDir);
        expect(project, isProjectMatcher(expectedDirectory: tempDir));
      },
    );

    test('findAncestor traverses upward to find project config', () {
      // Create a parent directory with a config file and a child directory without one.
      final parentDir = tempDirs.create();
      final childDir = Directory(p.join(parentDir.path, 'child'))..createSync();

      final config = ProjectConfig(flutter: '2.2.3', flavors: {'dev': '2.2.3'});
      createProjectConfig(config, parentDir);

      final project = projectService.findAncestor(directory: childDir);

      expect(project, isProjectMatcher(expectedDirectory: parentDir));
    });

    test(
      'findVersion returns pinned version if config exists',
      () {
        // Skip this test as it requires workingDirectoryOverride which TestFactory doesn't support
        // TODO: Consider alternative approach for testing findVersion without workingDirectoryOverride
      },
      skip:
          'Requires workingDirectoryOverride which TestFactory does not support',
    );

    test('update writes new configuration correctly', () {
      final tempDir = tempDirs.create();

      final config = ProjectConfig(flutter: '2.2.3', flavors: {'dev': '2.2.3'});
      createProjectConfig(config, tempDir);

      // Write an initial config file.
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_project');

      // Load the project from the temporary directory.
      final project = Project.loadFromDirectory(tempDir);

      // Update the project with new configuration values.
      projectService.update(
        project,
        flavors: {'prod': '2.3.0'},
        flutterSdkVersion: '2.3.0',
        updateVscodeSettings: true,
      );

      // Read back the updated configuration files.
      final updatedProject = projectService.findAncestor(directory: tempDir);

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
      final tempDir = tempDirs.create();

      final project = projectService.findAncestor(directory: tempDir);
      // When no config is found, it returns the context's working directory
      expect(project.hasConfig, isFalse);
      expect(project.path, isNotNull);
    });

    test('update preserves updateVscodeSettings when not specified', () {
      final tempDir = tempDirs.create();

      // Create initial config with updateVscodeSettings: false
      final config = ProjectConfig(
        flutter: '3.10.0',
        updateVscodeSettings: false,
      );
      createProjectConfig(config, tempDir);

      // Create pubspec.yaml
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_project');

      // Load the project
      final project = Project.loadFromDirectory(tempDir);

      // Update without specifying updateVscodeSettings (should preserve false)
      projectService.update(
        project,
        flutterSdkVersion: '3.16.0',
      );

      // Read back the updated configuration
      final updatedProject = projectService.findAncestor(directory: tempDir);
      final updatedConfig = updatedProject.config;

      expect(updatedConfig, isNotNull);
      expect(updatedConfig!.flutter, equals('3.16.0'));
      // This is the key assertion: updateVscodeSettings should be preserved
      expect(updatedConfig.updateVscodeSettings, isFalse);
    });

    test('findAncestor loads legacy .fvm/fvm_config.json file', () {
      final tempDir = tempDirs.create();

      // Create the legacy config structure: .fvm/fvm_config.json
      final fvmDir = Directory(p.join(tempDir.path, '.fvm'));
      fvmDir.createSync(recursive: true);

      final legacyConfigFile = File(p.join(fvmDir.path, 'fvm_config.json'));
      legacyConfigFile.writeAsStringSync(
        '{"flutterSdkVersion": "3.38.3"}',
      );

      final project = projectService.findAncestor(directory: tempDir);

      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      expect(project.config!.flutter, equals('3.38.3'));
      expect(project.pinnedVersion?.name, equals('3.38.3'));
    });

    test('findAncestor prefers .fvmrc over legacy config', () {
      final tempDir = tempDirs.create();

      // Create both new and legacy config files
      final newConfigFile = File(p.join(tempDir.path, '.fvmrc'));
      newConfigFile.writeAsStringSync(
        '{"flutter": "3.16.0"}',
      );

      final fvmDir = Directory(p.join(tempDir.path, '.fvm'));
      fvmDir.createSync(recursive: true);

      final legacyConfigFile = File(p.join(fvmDir.path, 'fvm_config.json'));
      legacyConfigFile.writeAsStringSync(
        '{"flutterSdkVersion": "3.38.3"}',
      );

      final project = projectService.findAncestor(directory: tempDir);

      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      // Should use the new config file (.fvmrc)
      expect(project.config!.flutter, equals('3.16.0'));
      expect(project.pinnedVersion?.name, equals('3.16.0'));
    });

    test('findAncestor warns when loading from legacy config', () {
      final tempDir = tempDirs.create();

      // Create only the legacy config (no .fvmrc)
      final fvmDir = Directory(p.join(tempDir.path, '.fvm'));
      fvmDir.createSync(recursive: true);

      final legacyConfigFile = File(p.join(fvmDir.path, 'fvm_config.json'));
      legacyConfigFile.writeAsStringSync(
        '{"flutterSdkVersion": "3.38.3"}',
      );

      // Get the logger to check outputs
      final logger = context.get<Logger>();
      final outputsBefore = logger.outputs.length;

      final project = projectService.findAncestor(directory: tempDir);

      // Verify config was loaded
      expect(project.hasConfig, isTrue);
      expect(project.config!.flutter, equals('3.38.3'));

      // Verify warning was logged
      final newOutputs = logger.outputs.sublist(outputsBefore);
      expect(
        newOutputs.any((msg) => msg.contains('legacy config')),
        isTrue,
        reason: 'Expected warning about legacy config to be logged',
      );
    });
  });
}
