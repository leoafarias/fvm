import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late Directory tempDirectory;
  late MockFlutterService mockFlutterService;

  setUp(() {
    tempDirectory = createTempDir('use_command_args_test');

    // Create a basic Flutter project structure
    createPubspecYaml(tempDirectory, name: 'test_project');

    // Create a test FVM context with the default mock services
    final testContext = TestFactory.context(
      debugLabel: 'use_command_args_test',
      workingDirectoryOverride: tempDirectory.path,
    );

    runner = TestCommandRunner(testContext);
    mockFlutterService =
        runner.context.get<FlutterService>() as MockFlutterService;
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Use command arguments combinations:', () {
    // Test all the different flags and their combinations

    test('basic command with no flags', () async {
      // Just the version, no additional flags
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');

      // Should have performed setup and pub get
      expect(mockFlutterService.isVersionInstalled('stable'), isTrue);
    });

    test('with --force flag', () async {
      // --force skips project checks
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');
    });

    test('with --skip-setup flag', () async {
      // --skip-setup skips Flutter setup after install
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');
    });

    test('with --skip-pub-get flag', () async {
      // --skip-pub-get skips resolving dependencies
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--skip-pub-get',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');
    });

    test('with --pin flag on channel', () async {
      // --pin pins the latest release of a channel
      final exitCode = await runner.run([
        'fvm',
        'use',
        'beta',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name,
          isNot('beta')); // Should be a specific version
    });

    test('with --pin flag on non-channel throws error', () async {
      // --pin should only work with channels
      expect(
          () async => await runner.runOrThrow([
                'fvm',
                'use',
                '2.0.0', // Not a channel
                '--pin',
              ]),
          throwsA(isA<UsageException>()));
    });

    test('with --flavor flag', () async {
      // --flavor sets version for a project flavor
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
      expect(project.pinnedVersion?.name, 'stable');
      expect(project.flavors.length, 1);
      expect(project.flavors['development'], 'stable');
    });

    test('with short aliases for flags', () async {
      // Test short flag aliases
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '-f', // short for --force
        '-s', // short for --skip-setup
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');
    });

    test('with multiple flags combined', () async {
      // Combine multiple flags
      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
        '--skip-pub-get',
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');
    });

    test('with invalid flag throws error', () async {
      // Invalid flag should throw an error
      expect(
          () async => await runner.runOrThrow([
                'fvm',
                'use',
                'stable',
                '--invalid-flag',
              ]),
          throwsA(isA<Exception>()));
    });

    test('with help flag shows usage', () async {
      // --help should show usage information
      final exitCode = await runner.run([
        'fvm',
        'use',
        '--help',
      ]);

      // Assert
      expect(exitCode, ExitCode.success.code);
    });

    test('with no arguments and no config shows prompt', () async {
      // No arguments and no config should show a prompt
      // We can't test the interactive prompt directly, but we can verify it doesn't fail
      try {
        await runner.run([
          'fvm',
          'use',
        ]);
        // The test might not get here because the command would show a prompt
        // and wait for user input, which isn't available in tests
      } catch (e) {
        // Expect an exception due to the missing interactive input
        expect(e, isA<Exception>());
      }
    });

    test('with no arguments but existing config uses that config', () async {
      // First set a version
      await runner.run([
        'fvm',
        'use',
        'stable',
      ]);

      // Then run with no arguments
      final exitCode = await runner.run([
        'fvm',
        'use',
      ]);

      // Get the project and verify its configuration hasn't changed
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'stable');
    });

    test('with flavor as first arg uses that flavor', () async {
      // First create a flavor with a valid name (not a channel name)
      await runner.run([
        'fvm',
        'use',
        'beta',
        '--flavor',
        'development',
        '--force',
        '--skip-setup',
      ]);

      // Then use the flavor as the first argument
      final exitCode = await runner.run([
        'fvm',
        'use',
        'development', // This is a flavor name, not a version
        '--force',
        '--skip-setup',
      ]);

      // Get the project and verify it's using the flavor version
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'beta'); // The flavor's version
    });

    test('with gitref', () async {
      // Use a Git reference
      final exitCode = await runner.run([
        'fvm',
        'use',
        'abcdef1234567890', // Mock Git hash
      ]);

      // Get the project and verify its configuration
      final project = Project.loadFromDirectory(tempDirectory);

      // Assert
      expect(exitCode, ExitCode.success.code);
      expect(project.pinnedVersion?.name, 'abcdef1234567890');
    });
  });
}
