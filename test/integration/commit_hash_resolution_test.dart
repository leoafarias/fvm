import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/workflows/update_project_references.workflow.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Commit Hash Resolution Integration Test', () {
    late TestCommandRunner runner;
    late Directory testProjectDir;
    late Directory testGitRepoDir;
    late String fullCommitHash;
    late String shortCommitHash;

    setUp(() async {
      runner = TestFactory.commandRunner();
      testProjectDir = createTempDir('test-project');
      testGitRepoDir = createTempDir('test-git-repo');

      // Create a test git repository
      await runGit(['init'], processWorkingDir: testGitRepoDir.path);
      await runGit(
        ['config', 'user.name', 'Test User'],
        processWorkingDir: testGitRepoDir.path,
      );
      await runGit(
        ['config', 'user.email', 'test@example.com'],
        processWorkingDir: testGitRepoDir.path,
      );

      // Create bin directory structure
      final binDir = Directory(p.join(testGitRepoDir.path, 'bin'));
      binDir.createSync(recursive: true);

      // Create a version file
      final versionFile = File(p.join(testGitRepoDir.path, 'version'));
      versionFile.writeAsStringSync('3.10.0');

      // Create some commits
      await runGit(['add', '.'], processWorkingDir: testGitRepoDir.path);
      await runGit(
        ['commit', '-m', 'Initial commit'],
        processWorkingDir: testGitRepoDir.path,
      );

      // Get the commit hash
      final gitDir = await GitDir.fromExisting(testGitRepoDir.path);
      final result = await gitDir.runCommand(['rev-parse', 'HEAD']);
      fullCommitHash = (result.stdout as String).trim();
      shortCommitHash = fullCommitHash.substring(0, 10);

      expect(fullCommitHash.length, 40);
      expect(shortCommitHash.length, 10);

      // Create a test Flutter project
      createPubspecYaml(testProjectDir, name: 'test_project');
      createProjectConfig(ProjectConfig(), testProjectDir);
    });

    tearDown(() {
      if (testProjectDir.existsSync()) {
        testProjectDir.deleteSync(recursive: true);
      }
      if (testGitRepoDir.existsSync()) {
        testGitRepoDir.deleteSync(recursive: true);
      }
    });

    test('should resolve short commit hash to full hash in config', () async {
      // Create a cache version using the short hash
      final shortVersion = FlutterVersion.parse(shortCommitHash);
      final versionDir =
          runner.context.get<CacheService>().getVersionCacheDir(shortVersion);

      // Create version directory and clone test repository
      versionDir.createSync(recursive: true);

      await runGit(
        ['clone', testGitRepoDir.path, versionDir.path],
      );

      // Create the CacheFlutterVersion
      final cacheVersion = CacheFlutterVersion.fromVersion(
        shortVersion,
        directory: versionDir.path,
      );

      // Load the project
      final project = runner.context.get<ProjectService>().findAncestor(
            directory: testProjectDir,
          );

      // Run the update workflow
      final workflow = UpdateProjectReferencesWorkflow(runner.context);
      await workflow.call(project, cacheVersion, force: true);

      // Read the config file
      final configFile = File(p.join(testProjectDir.path, '.fvmrc'));
      expect(configFile.existsSync(), isTrue);

      final configContent = configFile.readAsStringSync();
      final config = jsonDecode(configContent) as Map<String, dynamic>;

      // The flutter field should contain the full 40-character hash
      expect(config['flutter'], isNotNull);
      expect(config['flutter'], fullCommitHash);
      expect((config['flutter'] as String).length, 40);
    });

    test('should keep full commit hash as-is in config', () async {
      // Create a cache version using the full hash
      final fullVersion = FlutterVersion.parse(fullCommitHash);
      final versionDir =
          runner.context.get<CacheService>().getVersionCacheDir(fullVersion);

      // Create version directory and clone test repository
      versionDir.createSync(recursive: true);

      await runGit(
        ['clone', testGitRepoDir.path, versionDir.path],
      );

      // Create the CacheFlutterVersion
      final cacheVersion = CacheFlutterVersion.fromVersion(
        fullVersion,
        directory: versionDir.path,
      );

      // Load the project
      final project = runner.context.get<ProjectService>().findAncestor(
            directory: testProjectDir,
          );

      // Run the update workflow
      final workflow = UpdateProjectReferencesWorkflow(runner.context);
      await workflow.call(project, cacheVersion, force: true);

      // Read the config file
      final configFile = File(p.join(testProjectDir.path, '.fvmrc'));
      expect(configFile.existsSync(), isTrue);

      final configContent = configFile.readAsStringSync();
      final config = jsonDecode(configContent) as Map<String, dynamic>;

      // The flutter field should contain the full 40-character hash
      expect(config['flutter'], fullCommitHash);
      expect((config['flutter'] as String).length, 40);
    });

    test('should not expand non-commit versions', () async {
      // Create a cache version using a semantic version
      const versionStr = '3.10.0';
      final version = FlutterVersion.parse(versionStr);
      final versionDir =
          runner.context.get<CacheService>().getVersionCacheDir(version);

      // Create basic directory structure
      versionDir.createSync(recursive: true);
      final binDir = Directory(p.join(versionDir.path, 'bin'));
      binDir.createSync(recursive: true);
      final versionFile = File(p.join(versionDir.path, 'version'));
      versionFile.writeAsStringSync(versionStr);

      // Create the CacheFlutterVersion
      final cacheVersion = CacheFlutterVersion.fromVersion(
        version,
        directory: versionDir.path,
      );

      // Load the project
      final project = runner.context.get<ProjectService>().findAncestor(
            directory: testProjectDir,
          );

      // Run the update workflow
      final workflow = UpdateProjectReferencesWorkflow(runner.context);
      await workflow.call(project, cacheVersion, force: true);

      // Read the config file
      final configFile = File(p.join(testProjectDir.path, '.fvmrc'));
      expect(configFile.existsSync(), isTrue);

      final configContent = configFile.readAsStringSync();
      final config = jsonDecode(configContent) as Map<String, dynamic>;

      // The flutter field should contain the original semantic version
      expect(config['flutter'], versionStr);
    });
  });
}
