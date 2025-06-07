import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/convert_posix_path.dart';
import 'package:fvm/src/workflows/update_vscode_settings.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('UpdateVsCodeSettingsWorkflow', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('should handle relative vs absolute paths based on privileged access',
        () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: TestVersions.validRelease),
        testDir,
      );

      // Create .vscode directory
      final vscodeDir = Directory(p.join(testDir.path, '.vscode'));
      vscodeDir.createSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);

      // Test with privileged access

      final privilegedWorkflow = UpdateVsCodeSettingsWorkflow(
          TestFactory.context(privilegedAccess: true));

      await privilegedWorkflow(project);

      // Verify relative path is used with privileged access
      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      final privilegedContents = settingsFile.readAsStringSync();
      expect(privilegedContents,
          contains('"dart.flutterSdkPath": ".fvm/versions/${TestVersions.validRelease}"'));

      final nonPrivilegedWorkflow = UpdateVsCodeSettingsWorkflow(
          TestFactory.context(privilegedAccess: false));

      await nonPrivilegedWorkflow(project);

      // Verify absolute path is used without privileged access
      // Note: Path should be converted to POSIX format for JSON compatibility
      final nonPrivilegedContents = settingsFile.readAsStringSync();
      final expectedPath = convertToPosixPath(project.localVersionSymlinkPath);
      expect(nonPrivilegedContents,
          contains('"dart.flutterSdkPath": "$expectedPath"'));
    });

    test('should create and update VS Code settings when force is true',
        () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir, name: 'test_project_2');
      createProjectConfig(
        ProjectConfig(flutter: TestVersions.validRelease),
        testDir,
      );

      // Create .vscode directory to simulate VS Code project
      final vscodeDir = Directory(p.join(testDir.path, '.vscode'));
      vscodeDir.createSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      expect(project.name, equals('test_project_2'));

      final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify settings.json was created and contains expected content
      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      expect(settingsFile.existsSync(), isTrue);

      final contents = settingsFile.readAsStringSync();
      expect(contents, contains('dart.flutterSdkPath'));
      expect(contents, contains('.fvm/versions/${TestVersions.validRelease}'));
    });

    test('should not update VS Code settings when config disables it',
        () async {
      final testDir = createTempDir();
      // Create test project with config
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(updateVscodeSettings: false),
        testDir,
      );

      // Create .vscode directory
      final vscodeDir = Directory(p.join(testDir.path, '.vscode'));
      vscodeDir.createSync();

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify settings.json was not created
      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      expect(settingsFile.existsSync(), isFalse);
    });

    test(
        'should skip when no VS Code files are detected and not running from VS Code',
        () async {
      final testDir = createTempDir();
      // Create test project without .vscode directory
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);

      // Create workflow with test context that doesn't simulate VS Code environment
      final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Check if VS Code directory was created
      final vscodeDir = Directory(p.join(testDir.path, '.vscode'));
      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));

      // The behavior depends on whether isVsCode() returns true (running from VS Code)
      // When running tests from VS Code, settings will be created
      // When running from command line, they should not be created
      final isRunningFromVsCode =
          Platform.environment['TERM_PROGRAM'] == 'vscode';

      if (isRunningFromVsCode) {
        // If running from VS Code, settings should be created
        expect(settingsFile.existsSync(), isTrue);
      } else {
        // If not running from VS Code, settings should not be created
        expect(settingsFile.existsSync(), isFalse);
      }
    });

    test('should update existing VS Code settings correctly', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: TestVersions.validRelease),
        testDir,
      );

      // Create .vscode directory with existing settings
      final vscodeDir = Directory(p.join(testDir.path, '.vscode'));
      vscodeDir.createSync();

      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      settingsFile.writeAsStringSync('''
{
  "editor.formatOnSave": true,
  "editor.fontSize": 14,
  "dart.flutterSdkPath": "/some/old/path"
}
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify settings were updated correctly
      final contents = settingsFile.readAsStringSync();
      expect(contents, contains('"editor.formatOnSave": true'));
      expect(contents, contains('"editor.fontSize": 14'));
      expect(contents, contains('"dart.flutterSdkPath":'));
      expect(contents, contains('.fvm/versions/${TestVersions.validRelease}'));
      expect(contents, isNot(contains('/some/old/path')));
    });

    test('should handle invalid JSON in settings file', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      // Create .vscode directory with invalid settings
      final vscodeDir = Directory(p.join(testDir.path, '.vscode'));
      vscodeDir.createSync();

      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      settingsFile.writeAsStringSync('''
{
  "editor.formatOnSave": true,
  "editor.fontSize": 14,
  "dart.flutterSdkPath": "/some/old/path"
  this is invalid json
}
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

      // Run workflow - should fail gracefully
      await workflow(project);

      // Verify settings file remains unchanged
      final contents = settingsFile.readAsStringSync();
      expect(contents, contains('this is invalid json'));
    });

    test('should handle file permission errors gracefully', () async {
      // Skip on Windows where file permissions are different
      if (Platform.isWindows) {
        return;
      }

      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      // Create .vscode directory with read-only settings
      final vscodeDir = Directory(p.join(testDir.path, '.vscode'));
      vscodeDir.createSync();

      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      settingsFile.writeAsStringSync('{"editor.formatOnSave": true}');

      // Make the file read-only
      await Process.run('chmod', ['444', settingsFile.path]);

      try {
        final project = runner.context
            .get<ProjectService>()
            .findAncestor(directory: testDir);
        final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

        // Run workflow - should fail gracefully
        await workflow(project);

        // Content should remain unchanged
        final contents = settingsFile.readAsStringSync();
        expect(contents, equals('{"editor.formatOnSave": true}'));
      } finally {
        // Restore permissions for cleanup
        await Process.run('chmod', ['644', settingsFile.path]);
      }
    });

    test('should update workspace file when it exists', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: TestVersions.validRelease),
        testDir,
      );

      // Create a workspace file
      final workspaceFile =
          File(p.join(testDir.path, 'project.code-workspace'));
      workspaceFile.writeAsStringSync('''
{
  "folders": [
    {
      "path": "."
    }
  ],
  "settings": {
    "editor.formatOnSave": true
  }
}
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(project);

      // Verify workspace file was updated
      final contents = workspaceFile.readAsStringSync();
      expect(
          contents, contains('"dart.flutterSdkPath": ".fvm/versions/${TestVersions.validRelease}"'));
      expect(contents, contains('"editor.formatOnSave": true'));
    });

    test('should handle non-existent parent directories correctly', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      // Create a nested directory structure that doesn't exist yet
      final nestedDir =
          Directory(p.join(testDir.path, 'deeply', 'nested', 'dir'));

      // Create .vscode directory in the nested path
      final vscodeDir = Directory(p.join(nestedDir.path, '.vscode'));
      vscodeDir.createSync(recursive: true);

      // Mock a project with this nested path
      final mockProject = Project(
        config: ProjectConfig(),
        path: nestedDir.path,
        pubspec: null,
      );

      final workflow = UpdateVsCodeSettingsWorkflow(runner.context);

      // Run workflow
      await workflow(mockProject);

      // Verify settings.json was created
      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      expect(settingsFile.existsSync(), isTrue);
    });
  });
}
