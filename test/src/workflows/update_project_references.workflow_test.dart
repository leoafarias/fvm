import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/update_project_references.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('UpdateProjectReferencesWorkflow', () {
    late TestCommandRunner runner;
    late Directory cacheDir;

    setUp(() {
      runner = TestFactory.commandRunner();
      cacheDir = createTempDir();
    });

    // Helper function to create a properly structured cache version
    CacheFlutterVersion createCacheVersion(String version) {
      final versionDir = Directory(p.join(cacheDir.path, 'versions', version));
      versionDir.createSync(recursive: true);

      // Create bin directory
      final binDir = Directory(p.join(versionDir.path, 'bin'));
      binDir.createSync(recursive: true);

      // Create dart-sdk cache directory
      final dartSdkDir = Directory(p.join(binDir.path, 'cache', 'dart-sdk'));
      dartSdkDir.createSync(recursive: true);

      // Create version files
      File(p.join(versionDir.path, 'version')).writeAsStringSync(version);
      File(p.join(dartSdkDir.path, 'version')).writeAsStringSync('2.19.0');

      // Create a base FlutterVersion
      final flutterVersion = FlutterVersion.parse(version);

      // Return a CacheFlutterVersion with proper structure
      return CacheFlutterVersion(
        flutterVersion,
        directory: versionDir.path,
      );
    }

    test('should successfully update project references', () async {
      final testDir = createTempDir();
      // Create test project
      createPubspecYaml(testDir, name: 'test_project');
      createProjectConfig(ProjectConfig(), testDir);

      final project = runner.services.project.findAncestor(directory: testDir);
      expect(project.name, equals('test_project'));

      // Create cache version
      final cacheVersion = createCacheVersion('3.10.0');

      final workflow = UpdateProjectReferencesWorkflow(runner.context);

      // Run workflow
      final updatedProject = await workflow.call(
        project,
        cacheVersion,
        force: true,
      );

      // Verify files were created
      final versionFile = File(p.join(
        testDir.path,
        '.fvm',
        UpdateProjectReferencesWorkflow.versionFile,
      ));
      expect(versionFile.existsSync(), isTrue);

      final releaseFile = File(p.join(
        testDir.path,
        '.fvm',
        UpdateProjectReferencesWorkflow.releaseFile,
      ));
      expect(releaseFile.existsSync(), isTrue);
      expect(releaseFile.readAsStringSync(), equals(cacheVersion.name));

      // Verify the project was updated with the correct version
      expect(updatedProject.pinnedVersion, equals(cacheVersion.name));
    });

    test('should update with flavor when provided', () async {
      final testDir = createTempDir();
      createPubspecYaml(testDir);
      createProjectConfig(ProjectConfig(), testDir);

      final project = runner.services.project.findAncestor(directory: testDir);
      final cacheVersion = createCacheVersion('3.10.0');

      final workflow = UpdateProjectReferencesWorkflow(runner.context);

      // Run workflow with flavor
      final updatedProject = await workflow.call(
        project,
        cacheVersion,
        flavor: 'dev',
        force: true,
      );

      // Verify flavor was added
      final flavor = updatedProject.flavors['dev'];
      expect(flavor, equals(cacheVersion.name));
    });

    test('should create symlinks when privileged access is available',
        () async {
      // Skip on Windows where symlinks require admin rights
      if (Platform.isWindows) {
        return;
      }

      final testDir = createTempDir();
      createPubspecYaml(testDir);
      createProjectConfig(ProjectConfig(), testDir);

      final project = runner.services.project.findAncestor(directory: testDir);
      final cacheVersion = createCacheVersion('3.10.0');

      // Ensure context has privilegedAccess set to true
      final privilegedContext = TestFactory.context(privilegedAccess: true);

      final workflow = UpdateProjectReferencesWorkflow(privilegedContext);

      // Run workflow
      await workflow.call(project, cacheVersion, force: true);

      // Verify symlinks were created
      final flutterSdkLink = Link(p.join(
        testDir.path,
        '.fvm',
        UpdateProjectReferencesWorkflow.flutterSdkLink,
      ));

      expect(flutterSdkLink.existsSync(), isTrue);
      expect(flutterSdkLink.targetSync(), equals(cacheVersion.directory));
    });

    test('should not create symlinks when privileged access is unavailable',
        () async {
      final testDir = createTempDir();
      createPubspecYaml(testDir);
      createProjectConfig(ProjectConfig(), testDir);

      final project = runner.services.project.findAncestor(directory: testDir);
      final cacheVersion = createCacheVersion('3.10.0');

      // Create context with privilegedAccess set to false
      final nonPrivilegedContext = TestFactory.context(privilegedAccess: false);

      final workflow = UpdateProjectReferencesWorkflow(nonPrivilegedContext);

      // Run workflow
      await workflow.call(project, cacheVersion, force: true);

      // Version files should still be created
      final versionFile = File(p.join(
        testDir.path,
        '.fvm',
        UpdateProjectReferencesWorkflow.versionFile,
      ));
      expect(versionFile.existsSync(), isTrue);

      // But symlinks should not be created
      final flutterSdkLink = Link(p.join(
        testDir.path,
        '.fvm',
        UpdateProjectReferencesWorkflow.flutterSdkLink,
      ));
      expect(flutterSdkLink.existsSync(), isFalse);
    });

    test('should clean up and recreate existing symlinks', () async {
      // Skip on Windows where symlinks require admin rights
      if (Platform.isWindows) {
        return;
      }

      final testDir = createTempDir();
      createPubspecYaml(testDir);
      createProjectConfig(ProjectConfig(), testDir);

      // Create initial .fvm directory with symlinks
      final fvmDir = Directory(p.join(testDir.path, '.fvm'));
      fvmDir.createSync();

      // Create a temporary directory to initially link to
      final tempDir = createTempDir();

      // Create initial symlink pointing to temp directory
      final flutterSdkLink = Link(p.join(
        fvmDir.path,
        UpdateProjectReferencesWorkflow.flutterSdkLink,
      ));
      flutterSdkLink.createSync(tempDir.path);

      expect(flutterSdkLink.existsSync(), isTrue);
      expect(flutterSdkLink.targetSync(), equals(tempDir.path));

      // Now run the workflow with a different target
      final project = runner.services.project.findAncestor(directory: testDir);
      final cacheVersion = createCacheVersion('3.10.0');

      final workflow = UpdateProjectReferencesWorkflow(runner.context);
      await workflow.call(project, cacheVersion, force: true);

      // Verify the symlink now points to the new location
      expect(flutterSdkLink.existsSync(), isTrue);
      expect(flutterSdkLink.targetSync(), equals(cacheVersion.directory));
    });

    test('should handle file system errors gracefully', () async {
      // Skip on Windows where file permissions are different
      if (Platform.isWindows) {
        return;
      }

      final testDir = createTempDir();
      createPubspecYaml(testDir);
      createProjectConfig(ProjectConfig(), testDir);

      // Create an unwritable .fvm directory to cause errors
      final fvmDir = Directory(p.join(testDir.path, '.fvm'));
      fvmDir.createSync();

      // Make the directory read-only
      await Process.run('chmod', ['555', fvmDir.path]);

      try {
        final project =
            runner.services.project.findAncestor(directory: testDir);
        final cacheVersion = createCacheVersion('3.10.0');

        final workflow = UpdateProjectReferencesWorkflow(runner.context);

        // Should throw an exception due to permission error
        expect(
          () => workflow.call(project, cacheVersion, force: true),
          throwsA(isA<AppDetailedException>()),
        );
      } finally {
        // Restore permissions for cleanup
        await Process.run('chmod', ['755', fvmDir.path]);
      }
    });

    test('should handle project constraints issues', () async {
      final testDir = createTempDir();
      final pubspecFile = createPubspecYaml(testDir,
          name: 'test_project', sdkConstraint: '>=2.17.0 <4.0.0');

      print(pubspecFile.readAsStringSync());
      createProjectConfig(ProjectConfig(), testDir);

      // Create version with incompatible Dart SDK version
      final cacheVersion = createCacheVersion('3.10.0');

      // Override the dart-sdk version file with an incompatible version
      final dartSdkDir = Directory(p.join(
        cacheVersion.directory,
        'bin',
        'cache',
        'dart-sdk',
      ));

      File(p.join(dartSdkDir.path, 'version'))
          .writeAsStringSync('3.0.0'); // Incompatible with ^2.0.0

      final project = runner.services.project.findAncestor(directory: testDir);
      final workflow = UpdateProjectReferencesWorkflow(runner.context);

      // When run with force=false, it should ask for confirmation and throw if rejected
      // Since we can't interact with the prompt, we expect it to throw
      expect(
        () => workflow.call(project, cacheVersion),
        throwsA(isA<AppDetailedException>()),
      );

      // With force=true, it should skip confirmation
      final result = await workflow.call(project, cacheVersion, force: true);
      expect(result, isA<Project>());
    });

    test('should handle missing cache directories gracefully', () async {
      final testDir = createTempDir();
      createPubspecYaml(testDir);
      createProjectConfig(ProjectConfig(), testDir);

      final project = runner.services.project.findAncestor(directory: testDir);

      // Create a FlutterVersion without proper directory structure
      final flutterVersion = FlutterVersion.parse('3.10.0');
      final invalidCacheVersion = CacheFlutterVersion(
        flutterVersion,
        directory: p.join(cacheDir.path, 'non-existent-directory'),
      );

      final workflow = UpdateProjectReferencesWorkflow(runner.context);

      // Should throw an exception since the directory doesn't exist
      expect(
        () => workflow.call(project, invalidCacheVersion, force: true),
        throwsA(isA<AppDetailedException>()),
      );
    });
  });
}
