import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Doctor command:', () {
    late TempDirectoryTracker tempDirs;

    setUp(() {
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });
    test(
        'should not crash when project has local.properties but no pinned version (issue #938)',
        () async {
      final testDir = tempDirs.create();

      // Create a Flutter project structure with pubspec.yaml
      createPubspecYaml(testDir);

      // Create android/local.properties pointing to a Flutter SDK path
      final androidDir = Directory(p.join(testDir.path, 'android'));
      androidDir.createSync();
      final localPropertiesFile =
          File(p.join(androidDir.path, 'local.properties'));
      localPropertiesFile
          .writeAsStringSync('flutter.sdk=.fvm/versions/stable\n');

      // Create runner with working directory but NO .fvmrc (no pinned version)
      final context = FvmContext.create(
        workingDirectoryOverride: testDir.path,
        isTest: true,
      );
      final runner = TestCommandRunner(context);

      // Run doctor command - this should NOT crash
      final exitCode = await runner.run(['fvm', 'doctor']);

      // Verify it completed successfully
      expect(exitCode, ExitCode.success.code);

      // Verify the project has no pinned version
      final project = context.get<ProjectService>().findAncestor();
      expect(project.pinnedVersion, isNull);
    });

    test('should handle missing symlink when version is pinned', () async {
      final testDir = tempDirs.create();

      // Create a Flutter project structure
      createPubspecYaml(testDir);

      // Create android/local.properties
      final androidDir = Directory(p.join(testDir.path, 'android'));
      androidDir.createSync();
      final localPropertiesFile =
          File(p.join(androidDir.path, 'local.properties'));
      localPropertiesFile
          .writeAsStringSync('flutter.sdk=.fvm/versions/stable\n');

      // Create .fvmrc with a pinned version using the helper function
      const config = ProjectConfig(flutter: 'stable');
      createProjectConfig(config, testDir);

      // DON'T create the actual symlink - simulate missing symlink

      // Create runner with working directory
      final context = FvmContext.create(
        workingDirectoryOverride: testDir.path,
        isTest: true,
      );
      final runner = TestCommandRunner(context);

      // Run doctor command - should not crash even with missing symlink
      final exitCode = await runner.run(['fvm', 'doctor']);

      // Verify it completed successfully
      expect(exitCode, ExitCode.success.code);

      // Verify the project has a pinned version
      final project = context.get<ProjectService>().findAncestor();
      expect(project.pinnedVersion, isNotNull);
      expect(project.pinnedVersion?.name, 'stable');
    });

    test('should handle project without android/local.properties', () async {
      final testDir = tempDirs.create();

      // Create a minimal Flutter project without android directory
      createPubspecYaml(testDir);

      // Create runner with working directory
      final context = FvmContext.create(
        workingDirectoryOverride: testDir.path,
        isTest: true,
      );
      final runner = TestCommandRunner(context);

      // Run doctor command
      final exitCode = await runner.run(['fvm', 'doctor']);

      // Verify it completed successfully
      expect(exitCode, ExitCode.success.code);
    });

    test('should handle project without flutter.sdk in local.properties',
        () async {
      final testDir = tempDirs.create();

      // Create a Flutter project structure
      createPubspecYaml(testDir);

      // Create android/local.properties WITHOUT flutter.sdk
      final androidDir = Directory(p.join(testDir.path, 'android'));
      androidDir.createSync();
      final localPropertiesFile =
          File(p.join(androidDir.path, 'local.properties'));
      localPropertiesFile
          .writeAsStringSync('some.other.property=value\n');

      // Create runner with working directory
      final context = FvmContext.create(
        workingDirectoryOverride: testDir.path,
        isTest: true,
      );
      final runner = TestCommandRunner(context);

      // Run doctor command
      final exitCode = await runner.run(['fvm', 'doctor']);

      // Verify it completed successfully
      expect(exitCode, ExitCode.success.code);
    });
  });
}
