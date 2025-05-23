import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late ServicesProvider services;
  late Directory tempDirectory;
  late MockFlutterService mockFlutterService;

  setUp(() {
    tempDirectory = createTempDir('use_command_test');

    // Create a test FVM context with the temp directory as working directory
    final testContext = TestFactory.context(
      debugLabel: 'use_command_edge_cases_test',
      workingDirectoryOverride: tempDirectory.path,
    );

    runner = TestCommandRunner(testContext);
    services = runner.services;
    mockFlutterService =
        runner.context.get<FlutterService>() as MockFlutterService;

    // Create a basic Flutter project structure
    createPubspecYaml(tempDirectory, name: 'test_project');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Use command edge cases:', () {
    test('handles no version argument by using project config', () async {
      // Setup: Create project config with a pinned version
      final config = ProjectConfig(
        flutter: 'stable',
      );
      createProjectConfig(config, tempDirectory);

      // Run the use command without specifying a version
      final exitCode = await runner.run([
        'fvm',
        'use',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');
      expect(mockFlutterService.isVersionInstalled('stable'), isTrue);
    });

    test('provides clear error when no version argument and no installations',
        () async {
      // Setup: Create a clean project with no config

      // Clear installed versions in the mock service
      mockFlutterService.clearInstalledVersions();

      // Run the use command without specifying a version
      // This should return exit code 64 (usage error)
      final exitCode = await runner.run([
        'fvm',
        'use',
        '--force',
        '--skip-setup',
      ]);

      expect(exitCode, equals(ExitCode.usage.code));
    });

    test(
        'shows version selector when no version argument but has installed versions',
        () async {
      // Setup: Create a clean project with no config but with installed versions
      // The mock service already has the stable channel "installed" by default

      // Run the use command without specifying a version
      // In test mode, the version selector will exit with usage code
      final exitCode = await runner.run([
        'fvm',
        'use',
        '--force',
        '--skip-setup',
      ]);

      // In test mode with skipInput, the selector exits with usage code
      expect(exitCode, ExitCode.usage.code);
    });

    test('handles flavor specified as argument correctly', () async {
      // Setup: Create project config with flavors
      final flavors = {'dev-flavor': 'beta', 'prod-flavor': 'stable'};
      final config = ProjectConfig(
        flavors: flavors,
      );
      createProjectConfig(config, tempDirectory);

      // Run the use command with a flavor name as the version
      final exitCode = await runner.run([
        'fvm',
        'use',
        'dev-flavor',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'beta'); // The version for dev-flavor
      expect(mockFlutterService.isVersionInstalled('beta'), isTrue);
    });

    test('rejects use of channel name as flavor flag value', () async {
      // This tests bug #9: Flavor option should not allow channel names

      // Run the use command with a flavor name as the version
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--flavor',
        'beta', // trying to use a channel name as a flavor
        '--force',
        '--skip-setup',
      ]);

      // Should return usage error exit code
      expect(exitCode, ExitCode.usage.code);
    });

    test('handles non-existent custom version gracefully', () async {
      // Simulate failure for non-existent version
      mockFlutterService.simulateFailure('install:custom-version',
          reason:
              'Reference "custom-version" was not found in the Flutter repository.');

      // Run the use command with a non-existent version
      final exitCode = await runner.run([
        'fvm',
        'use',
        'custom-version',
        '--force',
        '--skip-setup',
      ]);

      // Should return an error exit code (not success)
      expect(exitCode, isNot(ExitCode.success.code));
    });

    test('handles pin option correctly for channels', () async {
      // This tests the pin option logic which should fetch the latest release for a channel

      // Run the use command with pin option on a channel
      final exitCode = await runner.run([
        'fvm',
        'use',
        'beta',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // Since we're using mocks, we expect this to install a specific version
      // instead of the channel, as fetched from the release client

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name,
          isNot('beta')); // Should be a specific version, not the channel
    });

    test('rejects pin option for non-channel versions', () async {
      // Run the use command with pin option on a non-channel version
      final exitCode = await runner.run([
        'fvm',
        'use',
        '2.0.0', // Not a channel
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // Should return usage error exit code
      expect(exitCode, ExitCode.usage.code);
    });

    test('handles flavor flag correctly', () async {
      // Run the use command with flavor flag
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--flavor',
        'dev-env',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.flavors.containsKey('dev-env'), isTrue);
      expect(project.flavors['dev-env'], 'stable');
    });

    test('rejects using both flavor arg and flavor flag', () async {
      // Setup: Create project config with flavors
      final flavors = {'dev-flavor': 'beta'};
      final config = ProjectConfig(
        flavors: flavors,
      );
      createProjectConfig(config, tempDirectory);

      // Run the use command with both a flavor as arg and as flag
      final exitCode = await runner.run([
        'fvm',
        'use',
        'dev-flavor', // flavor as arg
        '--flavor',
        'prod-env', // flavor as flag
        '--force',
        '--skip-setup',
      ]);

      // Should exit with usage error
      expect(exitCode, equals(ExitCode.usage.code));
    });

    test('project symlinks are created correctly', () async {
      // Run the use command
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
      ]);

      // Verify symlinks
      final project = Project.loadFromDirectory(tempDirectory);
      final fvmDir = Directory(p.join(tempDirectory.path, '.fvm'));
      final flutterSdkLink = Link(p.join(fvmDir.path, 'flutter_sdk'));

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(fvmDir.existsSync(), isTrue);
      expect(flutterSdkLink.existsSync(), isTrue);
      expect(project.localVersionSymlinkPath.link.existsSync(), isTrue);

      // Check that symlinks point to correct targets
      final expectedDir =
          services.cache.getVersionCacheDir(FlutterVersion.parse('stable'));
      expect(flutterSdkLink.resolveSymbolicLinksSync(),
          equals(expectedDir.resolveSymbolicLinksSync()));
    });

    test('handles paths with spaces correctly', () async {
      // Create a temporary directory with spaces in the name
      final dirWithSpaces = createTempDir('use command test with spaces');

      // Create a basic Flutter project structure in the directory with spaces
      createPubspecYaml(dirWithSpaces, name: 'test_project_with_spaces');

      // Create a new test context with the directory with spaces as working directory
      final testContext = TestFactory.context(
        debugLabel: 'use_command_edge_cases_test_spaces',
        workingDirectoryOverride: dirWithSpaces.path,
      );
      runner = TestCommandRunner(testContext);
      services = runner.services;

      // Run the use command
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(dirWithSpaces);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');

      // Clean up
      dirWithSpaces.deleteSync(recursive: true);
    });
  });
}
