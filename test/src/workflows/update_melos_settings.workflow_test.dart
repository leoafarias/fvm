import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/workflows/update_melos_settings.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../testing_utils.dart';

void main() {
  group('UpdateMelosSettingsWorkflow', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('should detect and update melos.yaml', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        testDir,
      );

      // Create a melos.yaml file
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was updated
      final melosContent = melosFile.readAsStringSync();
      final yaml = loadYaml(melosContent) as Map;

      expect(yaml['sdkPath'], isNotNull);
      expect(yaml['sdkPath'], contains('.fvm/flutter_sdk'));
    });

    test('should skip melos update if sdkPath already exists', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        testDir,
      );

      // Create a melos.yaml with existing sdkPath
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
sdkPath: /any/existing/path
''');

      final originalContent = melosFile.readAsStringSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was NOT changed
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
    });

    test('should find melos.yaml in parent directory', () async {
      final testDir = createTempDir();
      // Create test project in a subdirectory
      final subDir = Directory(p.join(testDir.path, 'subproject'));
      subDir.createSync();
      
      createPubspecYaml(subDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        subDir,
      );

      // Create a melos.yaml in parent directory
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - subproject/**
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: subDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was found and updated
      final melosContent = melosFile.readAsStringSync();
      final yaml = loadYaml(melosContent) as Map;

      expect(yaml['sdkPath'], isNotNull);
      // Should be relative path from parent to subproject's FVM
      expect(yaml['sdkPath'], 'subproject/.fvm/flutter_sdk');
    });

    test('should not modify melos.yaml with existing non-FVM sdkPath', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        testDir,
      );

      // Create a melos.yaml with existing non-FVM sdkPath
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
sdkPath: /usr/local/flutter
''');

      final originalContent = melosFile.readAsStringSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify sdkPath was NOT modified
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);

      final yaml = loadYaml(newContent) as Map;
      expect(yaml['sdkPath'], '/usr/local/flutter');
    });

    test('should calculate correct relative path for nested melos', () async {
      final testDir = createTempDir();
      
      // Create a nested structure
      final nestedDir = Directory(p.join(testDir.path, 'apps', 'mobile'));
      nestedDir.createSync(recursive: true);
      
      createPubspecYaml(nestedDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        nestedDir,
      );

      // Create melos.yaml in the nested directory
      final melosFile = File(p.join(nestedDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - lib/**
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: nestedDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify relative path is correct
      final melosContent = melosFile.readAsStringSync();
      final yaml = loadYaml(melosContent) as Map;

      expect(yaml['sdkPath'], '.fvm/flutter_sdk');
    });

    test('should not update melos settings when config disables it', () async {
      final testDir = createTempDir();
      // Create test project with config
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(updateMelosSettings: false),
        testDir,
      );

      // Create a melos.yaml file
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
''');

      final originalContent = melosFile.readAsStringSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was not modified
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
    });

    test('should handle invalid YAML in melos file', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        testDir,
      );

      // Create a melos.yaml with invalid YAML
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
  this is invalid yaml
''');

      final originalContent = melosFile.readAsStringSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow - should fail gracefully
      await workflow(project);

      // Verify file remains unchanged
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
    });

    test('should update existing FVM path if different', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        testDir,
      );

      // Create a melos.yaml with old FVM path format
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
sdkPath: .fvm/versions/3.10.0
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify sdkPath was updated to new format
      final melosContent = melosFile.readAsStringSync();
      final yaml = loadYaml(melosContent) as Map;

      expect(yaml['sdkPath'], '.fvm/flutter_sdk');
    });

    test('should skip update when no pinned version', () async {
      final testDir = createTempDir();
      // Create test project without pinned version
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(), // No flutter version
        testDir,
      );

      // Create a melos.yaml file
      final melosFile = File(p.join(testDir.path, 'melos.yaml'));
      melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
''');

      final originalContent = melosFile.readAsStringSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was not modified
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
    });
  });
}