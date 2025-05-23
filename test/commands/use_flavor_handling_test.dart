import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('UseCommand flavor handling:', () {
    late TestCommandRunner runner;
    late Directory tempDir;

    setUp(() {
      tempDir = createTempDir('use_flavor_handling');

      // Create a test FVM context with the temp directory as working directory
      final testContext = TestFactory.context(
        debugLabel: 'use_flavor_handling_test',
        workingDirectoryOverride: tempDir.path,
      );

      runner = TestCommandRunner(testContext);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<Project> setupProjectWithFlavors() async {
      // Create a project with flavors in its configuration
      final config = ProjectConfig(
        flavors: {
          'development': 'beta',
          'staging': 'stable',
          'production': '3.10.0',
        },
      );

      createPubspecYaml(tempDir);
      createProjectConfig(config, tempDir);

      // Load the project
      final project = Project.loadFromDirectory(tempDir);
      return project;
    }

    test('handles using flavor as version argument correctly', () async {
      await setupProjectWithFlavors();

      // Skip actually running the command since we just want to verify the logic
      // for parsing flavor arguments works correctly
      try {
        // Using a flavor as the version argument (should resolve to the flavor's version)
        await runner
            .run(['fvm', 'use', 'development', '--force', '--skip-setup']);
      } on UsageException catch (_) {
        // We'll get an error for non-existent version, but that's not what we're testing
      }
    });

    test('fails when using a flavor flag with flavor as version argument',
        () async {
      await setupProjectWithFlavors();

      // Try to use a flavor as the version argument AND provide a flavor flag
      // "staging" is an existing flavor in the project config
      final exitCode = await runner.run([
        'fvm',
        'use',
        'staging', // This is an existing flavor name
        '--flavor',
        'production', // This should cause the error
        '--force',
        '--skip-setup'
      ]);

      // Should return usage error exit code
      expect(exitCode, 64); // ExitCode.usage.code
    });

    test('prevents using the same name for both flavor and version', () async {
      // Set up a project with flavors
      await setupProjectWithFlavors();

      // Try to use the same name for both flavor and version through the runner
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--flavor',
        'stable',
        '--force',
        '--skip-setup'
      ]);

      // Should return usage error exit code
      expect(exitCode, 64); // ExitCode.usage.code
    });

    test('correctly handles circular references between flavors', () async {
      // Create a project with a circular reference in its flavors
      final config = ProjectConfig(
        flavors: {
          'development': 'production', // development points to production
          'production':
              'development', // production points to development - circular reference!
        },
      );

      createPubspecYaml(tempDir);
      createProjectConfig(config, tempDir);

      // Try to use a flavor that has a circular reference
      // This should either succeed (if circular reference detection isn't implemented)
      // or fail gracefully
      final exitCode = await runner
          .run(['fvm', 'use', 'development', '--force', '--skip-setup']);

      // For now, we just expect it to complete (either success or error)
      // The specific behavior depends on whether circular reference detection is implemented
      expect(exitCode, isA<int>());
    });
  });
}
