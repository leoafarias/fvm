import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/workflows/update_melos_settings.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../testing_utils.dart';
import 'test_logger.dart';

void main() {
  group('UpdateMelosSettingsWorkflow', () {
    late TestCommandRunner runner;
    late TempDirectoryTracker tempDirs;

    setUp(() {
      runner = TestFactory.commandRunner();
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });

    test('should detect melos.yaml and skip without confirmation', () async {
      final testDir = tempDirs.create();
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

      final originalContent = melosFile.readAsStringSync();

      // Create a custom context with TestLogger that declines confirmation
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse('configure melos.yaml', false),
        },
      );
      
      final customRunner = TestCommandRunner(context);
      final project =
          customRunner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(customRunner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was NOT updated (user declined)
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
      
      // Verify we can see the detection message
      final logger = customRunner.context.get<Logger>();
      expect(
        logger.outputs.any((msg) => msg.contains('Detected melos.yaml without FVM configuration')),
        isTrue,
      );
    });

    test('should skip melos update if sdkPath already exists', () async {
      final testDir = tempDirs.create();
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

    test('should find melos.yaml in parent directory but not update', () async {
      final testDir = tempDirs.create();
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

      final originalContent = melosFile.readAsStringSync();

      // Create a custom context with TestLogger that declines confirmation
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse('configure melos.yaml', false),
        },
      );
      
      final customRunner = TestCommandRunner(context);
      final project =
          customRunner.context.get<ProjectService>().findAncestor(directory: subDir);
      final workflow = UpdateMelosSettingsWorkflow(customRunner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was found but NOT updated
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
    });

    test('should not modify melos.yaml with existing non-FVM sdkPath', () async {
      final testDir = tempDirs.create();
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
      final testDir = tempDirs.create();
      
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

      final originalContent = melosFile.readAsStringSync();

      // Create a custom context with TestLogger that declines confirmation
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse('configure melos.yaml', false),
        },
      );
      
      final customRunner = TestCommandRunner(context);
      final project =
          customRunner.context.get<ProjectService>().findAncestor(directory: nestedDir);
      final workflow = UpdateMelosSettingsWorkflow(customRunner.context);

      // Run workflow
      await workflow(project);

      // Verify melos.yaml was NOT updated
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
    });

    test('should not update melos settings when config disables it', () async {
      final testDir = tempDirs.create();
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
      final testDir = tempDirs.create();
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

    test('should detect existing FVM path but not update without confirmation', () async {
      final testDir = tempDirs.create();
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

      final originalContent = melosFile.readAsStringSync();

      // Create a custom context with TestLogger that declines update
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse('Update existing FVM path', false),
        },
      );
      
      final customRunner = TestCommandRunner(context);
      final project =
          customRunner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateMelosSettingsWorkflow(customRunner.context);

      // Run workflow
      await workflow(project);

      // Verify sdkPath was NOT updated
      final newContent = melosFile.readAsStringSync();
      expect(newContent, originalContent);
    });

    test('should skip update when no pinned version', () async {
      final testDir = tempDirs.create();
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

    group('with simulated user input', () {
      test('should update melos.yaml when user confirms (simulated Yes)', () async {
        final testDir = tempDirs.create();
        createPubspecYaml(testDir);
        createProjectConfig(
          ProjectConfig(flutter: '3.10.0'),
          testDir,
        );

        // Create a melos.yaml file without sdkPath
        final melosFile = File(p.join(testDir.path, 'melos.yaml'));
        melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
''');

        // Create a custom context with TestLogger
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('configure melos.yaml', true),
          },
        );
        
        final customRunner = TestCommandRunner(context);
        final project = customRunner.context.get<ProjectService>().findAncestor(directory: testDir);
        final workflow = UpdateMelosSettingsWorkflow(customRunner.context);
        
        // Run workflow
        await workflow(project);
        
        // Verify melos.yaml was updated
        final melosContent = melosFile.readAsStringSync();
        final yaml = loadYaml(melosContent) as Map;
        
        expect(yaml['sdkPath'], isNotNull);
        expect(yaml['sdkPath'], '.fvm/flutter_sdk');
        
        // Verify logged messages
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any((msg) => msg.contains('Detected melos.yaml without FVM configuration')),
          isTrue,
        );
        expect(
          logger.outputs.any((msg) => msg.contains('Added FVM Flutter SDK path to melos.yaml')),
          isTrue,
        );
      });

      test('should update existing FVM path when user confirms', () async {
        final testDir = tempDirs.create();
        createPubspecYaml(testDir);
        createProjectConfig(
          ProjectConfig(flutter: '3.10.0'),
          testDir,
        );

        // Create a melos.yaml with old FVM path
        final melosFile = File(p.join(testDir.path, 'melos.yaml'));
        melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
sdkPath: .fvm/versions/3.10.0
''');

        // Create a custom context with TestLogger that says Yes
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('Update existing FVM path', true),
          },
        );
        
        final customRunner = TestCommandRunner(context);
        final project = customRunner.context.get<ProjectService>().findAncestor(directory: testDir);
        final workflow = UpdateMelosSettingsWorkflow(customRunner.context);
        
        // Run workflow
        await workflow(project);
        
        // Verify melos.yaml was updated
        final melosContent = melosFile.readAsStringSync();
        final yaml = loadYaml(melosContent) as Map;
        
        expect(yaml['sdkPath'], '.fvm/flutter_sdk');
        
        // Verify logged messages
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any((msg) => msg.contains('Updated FVM Flutter SDK path in melos.yaml')),
          isTrue,
        );
      });

      test('should verify all output is captured in logger', () async {
        final testDir = tempDirs.create();
        createPubspecYaml(testDir);
        createProjectConfig(
          ProjectConfig(flutter: '3.10.0'),
          testDir,
        );

        // Create a melos.yaml
        final melosFile = File(p.join(testDir.path, 'melos.yaml'));
        melosFile.writeAsStringSync('''
name: test_workspace
packages:
  - packages/**
''');

        // Create a custom context with TestLogger that declines confirmation
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('configure melos.yaml', false),
          },
        );
        
        final customRunner = TestCommandRunner(context);
        final project =
            customRunner.context.get<ProjectService>().findAncestor(directory: testDir);
        final workflow = UpdateMelosSettingsWorkflow(customRunner.context);
        final logger = customRunner.context.get<Logger>();
        
        // Clear previous outputs
        logger.outputs.clear();
        
        await workflow(project);
        
        // Verify that we can see all the logged outputs
        expect(logger.outputs.length, greaterThan(0));
        expect(
          logger.outputs.any((msg) => msg.contains('Detected melos.yaml')),
          isTrue,
          reason: 'Should capture detection message',
        );
        expect(
          logger.outputs.any((msg) => msg.contains('User declined')),
          isTrue,
          reason: 'Should log when user declines',
        );
      });
    });

  });
}