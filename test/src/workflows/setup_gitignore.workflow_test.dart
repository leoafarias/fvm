import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/workflows/setup_gitignore.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('SetupGitignoreWorkflow', () {
    late TestCommandRunner runner;
    late TempDirectoryTracker tempDirs;

    setUp(() {
      runner = TestFactory.commandRunner();
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });

    test('should create and update .gitignore when force is true', () async {
      final testDir = tempDirs.create();
      // Create test project
      createPubspecYaml(testDir, name: 'test_project_2');

      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);

      expect(project.name, equals('test_project_2'));

      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow
      final result = workflow.call(project);
      expect(result, isTrue);

      // Verify .gitignore was created and contains expected content
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      expect(gitignore.existsSync(), isTrue);

      final contents = gitignore.readAsLinesSync();
      expect(contents, contains(SetupGitIgnoreWorkflow.kGitIgnoreHeading));
      expect(contents, contains(SetupGitIgnoreWorkflow.kFvmPathToAdd));
    });

    test('should not update .gitignore when config disables it', () async {
      final testDir = tempDirs.create();
      // Create test project with config
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(updateGitIgnore: false),
        testDir,
      );

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow
      final result = workflow.call(project);
      expect(result, isTrue);

      // Verify .gitignore was not created
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      expect(gitignore.existsSync(), isFalse);
    });

    test('should not duplicate entries in existing .gitignore', () {
      final testDir = tempDirs.create();
      // Create test project with existing .gitignore
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      gitignore.writeAsStringSync('.fvm/\n');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow
      final result = workflow.call(project);
      expect(result, isTrue);

      // Verify .gitignore wasn't modified
      final contents = gitignore.readAsLinesSync();
      expect(
          contents.where((line) => line.trim() == '.fvm/').length, equals(1));
    });

    test('should handle and clean empty lines correctly', () {
      final testDir = tempDirs.create();
      // Create test project with .gitignore containing multiple empty lines
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      gitignore.writeAsStringSync('''
# Existing content
/build/


.dart_tool/



# More ignored files
/coverage/
''');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow
      final result = workflow.call(project);
      expect(result, isTrue);

      // Verify .gitignore was updated without duplicate blank lines
      final contents = gitignore.readAsLinesSync();

      // Check that adjacent blank lines were properly folded
      final hasTripleEmptyLines = contents.join('\n').contains('\n\n\n');
      expect(hasTripleEmptyLines, isFalse);

      // Ensure content is preserved
      expect(contents, contains('# Existing content'));
      expect(contents, contains('.dart_tool/'));
      expect(contents, contains('# More ignored files'));
      expect(contents, contains('/coverage/'));

      // New content is added
      expect(contents, contains(SetupGitIgnoreWorkflow.kGitIgnoreHeading));
      expect(contents, contains(SetupGitIgnoreWorkflow.kFvmPathToAdd));
    });

    test('should handle file permission errors gracefully', () async {
      // Skip on Windows where file permissions are different
      if (Platform.isWindows) {
        return;
      }

      final testDir = tempDirs.create();
      // Create test project with a read-only .gitignore
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      // Create a gitignore that doesn't include .fvm/
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      gitignore.writeAsStringSync('# Some content\n/build/\n');

      // Make the file read-only
      await Process.run('chmod', ['444', gitignore.path]);

      try {
        final project = runner.context
            .get<ProjectService>()
            .findAncestor(directory: testDir);
        final workflow = SetupGitIgnoreWorkflow(runner.context);

        // Run workflow - should fail gracefully
        final result = workflow.call(project);
        expect(result, isFalse);

        // Content should remain unchanged
        final contents = gitignore.readAsStringSync();
        expect(contents, equals('# Some content\n/build/\n'));
      } finally {
        // Restore permissions for cleanup
        await Process.run('chmod', ['644', gitignore.path]);
      }
    });

    test('should handle non-existent parent directories correctly', () {
      final testDir = tempDirs.create();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      // Create a nested directory structure that doesn't exist yet
      final nestedDir =
          Directory(p.join(testDir.path, 'deeply', 'nested', 'dir'));

      // Mock a project with this non-existent path
      final mockProject = Project(
        config: ProjectConfig(),
        path: nestedDir.path,
        pubspec: null,
      );

      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow - should create parent directories
      final result = workflow.call(mockProject);
      expect(result, isTrue);

      // Verify .gitignore was created
      final gitignore = File(p.join(nestedDir.path, '.gitignore'));
      expect(gitignore.existsSync(), isTrue);
    });

    test('should preserve existing formatting when possible', () {
      final testDir = tempDirs.create();
      // Create test project with specially formatted .gitignore
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      // Create a .gitignore with tabs instead of spaces and CRLF line endings
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      gitignore.writeAsStringSync('# Begin comments\r\n'
          '\t/bin/\r\n'
          '\t/build/\r\n'
          '# End comments\r\n');

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow
      final result = workflow.call(project);
      expect(result, isTrue);

      // Verify original formatting (tabs) was preserved in existing content
      final contents = gitignore.readAsStringSync();
      expect(contents, contains('\t/bin/'));
      expect(contents, contains('\t/build/'));

      // New entries should be added with proper formatting
      expect(contents, contains(SetupGitIgnoreWorkflow.kGitIgnoreHeading));
      expect(contents, contains(SetupGitIgnoreWorkflow.kFvmPathToAdd));
    });

    test('should work with git repositories', () async {
      // Only run if git is available
      final gitResult = await Process.run('git', ['--version']);
      if (gitResult.exitCode != 0) {
        return; // Skip if git is not available
      }

      final testDir = tempDirs.create();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      // Initialize git repository
      await Process.run('git', ['init'], workingDirectory: testDir.path);

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow
      final result = workflow.call(project);
      expect(result, isTrue);

      // Verify .gitignore was created
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      expect(gitignore.existsSync(), isTrue);

      // Check content
      final contents = gitignore.readAsLinesSync();
      expect(contents, contains(SetupGitIgnoreWorkflow.kGitIgnoreHeading));
      expect(contents, contains(SetupGitIgnoreWorkflow.kFvmPathToAdd));
    });

    test('should add trailing newline to prevent concatenation issues', () {
      final testDir = tempDirs.create();
      // Create test project
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(),
        testDir,
      );

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = SetupGitIgnoreWorkflow(runner.context);

      // Run workflow
      final result = workflow.call(project);
      expect(result, isTrue);

      // Verify .gitignore was created and ends with newline
      final gitignore = File(p.join(testDir.path, '.gitignore'));
      expect(gitignore.existsSync(), isTrue);

      // Read raw content to check for trailing newline
      final rawContent = gitignore.readAsStringSync();
      expect(rawContent.endsWith('\n'), isTrue, 
        reason: 'gitignore file should end with newline to prevent concatenation issues');
      
      // Verify that appending content would work correctly
      final bytesBeforeAppend = gitignore.lengthSync();
      gitignore.writeAsStringSync('${rawContent}# Additional comment\n');
      final newContent = gitignore.readAsStringSync();
      
      // Should not have '.fvm/# Additional comment' on same line
      expect(newContent.contains('.fvm/# Additional comment'), isFalse,
        reason: 'Appended content should be on a new line');
    });
  });
}
