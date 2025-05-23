import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late ServicesProvider services;
  late Directory tempDirectory;
  late MockFlutterService mockFlutterService;

  setUp(() {
    tempDirectory = createTempDir('use_command_flavor_test');

    // Create a basic Flutter project structure
    createPubspecYaml(tempDirectory, name: 'test_project');

    // Create a test FVM context with the default mock services
    final testContext = TestFactory.context(
      debugLabel: 'use_command_flavor_test',
      workingDirectoryOverride: tempDirectory.path,
    );

    runner = TestCommandRunner(testContext);
    services = runner.services;
    mockFlutterService =
        runner.context.get<FlutterService>() as MockFlutterService;
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Use command with flavors:', () {
    test('adds a new flavor when none exist', () async {
      // Run the use command with a new flavor
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--flavor',
        'development',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.flavors.containsKey('development'), isTrue);
      expect(project.flavors['development'], 'stable');
    });

    test('updates an existing flavor', () async {
      // Setup: Create project config with an existing flavor
      final config = ProjectConfig(
        flavors: {'development': 'beta'},
      );
      createProjectConfig(config, tempDirectory);

      // Run the use command to update the existing flavor
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--flavor',
        'development',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.flavors.containsKey('development'), isTrue);
      expect(project.flavors['development'], 'stable'); // Updated from 'beta'
    });

    test('preserves other flavors when adding or updating a flavor', () async {
      // Setup: Create project config with multiple flavors
      final config = ProjectConfig(
        flavors: {
          'development': 'beta',
          'production': 'stable',
          'staging': '2.0.0'
        },
      );
      createProjectConfig(config, tempDirectory);

      // Run the use command to update one flavor
      final exitCode = await runner.run([
        'fvm',
        'use',
        'beta',
        '--flavor',
        'test',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.flavors.length, 4); // Original 3 plus the new one
      expect(project.flavors.containsKey('test'), isTrue);
      expect(project.flavors['test'], 'beta');

      // Original flavors should be preserved
      expect(project.flavors['development'], 'beta');
      expect(project.flavors['production'], 'stable');
      expect(project.flavors['staging'], '2.0.0');
    });

    test('uses a flavor as the version argument', () async {
      // Setup: Create project config with flavors
      final config = ProjectConfig(
        flavors: {'development-flavor': 'beta', 'production-flavor': 'stable'},
      );
      createProjectConfig(config, tempDirectory);

      // Run the use command with a flavor name as the version
      final exitCode = await runner.run([
        'fvm',
        'use',
        'development-flavor',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name,
          'beta'); // The version for development-flavor
      // The mock service tracks installations during the test run
      expect(mockFlutterService.isVersionInstalled('beta'), isTrue);
    });

    test('activates a flavor correctly', () async {
      // Setup: Create project config with flavors and a default version
      final config = ProjectConfig(
        flutter: 'stable', // Default version
        flavors: {'development': 'beta', 'production': '2.0.0'},
      );
      createProjectConfig(config, tempDirectory);

      // First set up the default version
      await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
      ]);

      // Now activate the 'development' flavor
      final exitCode = await runner.run([
        'fvm',
        'use',
        'development',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration and links
      final project = Project.loadFromDirectory(tempDirectory);
      final link = project.localVersionSymlinkPath.link;
      final linkExists = link.existsSync();

      // The link should now point to the 'beta' version directory
      final targetPath = link.targetSync();
      final betaVersionDir =
          services.cache.getVersionCacheDir(FlutterVersion.parse('beta'));

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(linkExists, isTrue);
      expect(targetPath, betaVersionDir.path);
      expect(project.activeFlavor, 'development');
      expect(project.pinnedVersion?.name, 'beta');
    });

    test('handles invalid flavor name gracefully', () async {
      // Try to use a channel name as a flavor name (which is disallowed)
      final exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'stable', // Channel name as flavor - this is disallowed
        '--force',
        '--skip-setup',
      ]);

      // Should return an error exit code
      expect(exitCode, ExitCode.usage.code);
    });

    test('activating non-existent flavor succeeds as version install',
        () async {
      // When using a non-existent flavor name, it's treated as a version
      // (could be a commit hash, tag, or other reference)
      final exitCode = await runner.run([
        'fvm',
        'use',
        'non-existent-flavor',
        '--force',
        '--skip-setup',
      ]);

      // The command should succeed as it treats 'non-existent-flavor' as a version
      expect(exitCode, ExitCode.success.code);

      // Verify it was installed as a version, not a flavor
      final project = Project.loadFromDirectory(tempDirectory);
      expect(project.pinnedVersion?.name, 'non-existent-flavor');
      expect(project.flavors.containsKey('non-existent-flavor'), isFalse);
    });
  });
}
