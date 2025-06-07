import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Enhanced Fork Integration Tests:', () {
    late TestCommandRunner runner;
    const testForkName = TestVersions.leoFork;
    const testForkUrl = TestVersions.leoForkUrl;

    setUp(() {
      runner = TestFactory.commandRunner();

      // Clean up any existing test fork
      LocalAppConfig.read()
        ..forks.removeWhere((f) => f.name == testForkName)
        ..save();
    });

    tearDown(() {
      // Clean up after tests
      LocalAppConfig.read()
        ..forks.removeWhere((f) => f.name == testForkName)
        ..save();
    });

    group('Fork workflow integration:', () {
      test('Complete fork add -> install -> use workflow', () async {
        // Step 1: Add fork
        final addExitCode = await runner
            .runOrThrow(['fvm', 'fork', 'add', testForkName, testForkUrl]);
        expect(addExitCode, ExitCode.success.code);

        // Verify fork was added
        final config = LocalAppConfig.read();
        final fork = config.forks.firstWhere(
          (f) => f.name == testForkName,
          orElse: () => const FlutterFork(name: '', url: ''),
        );
        expect(fork.name, testForkName);
        expect(fork.url, testForkUrl);

        // Create a new runner to pick up the updated global config with forks
        final installRunner = TestFactory.commandRunner();

        // Step 2: Install version from fork with specific branch
        final installExitCode = await installRunner
            .runOrThrow(['fvm', 'install', "\$testForkName/${TestVersions.customForkBranch}"]); 
        expect(installExitCode, ExitCode.success.code);

        // Step 3: Use version from fork
        final useExitCode = await installRunner.runOrThrow([
          'fvm',
          'use',
          "\$testForkName/${TestVersions.customForkBranch}",
          '--force',
          '--skip-setup'
        ]);
        expect(useExitCode, ExitCode.success.code);

        // Verify project is using fork version
        final project =
            installRunner.context.get<ProjectService>().findAncestor();
        expect(project.pinnedVersion?.name, equals(TestVersions.customForkBranch));
      });

      test('Fork list shows configured forks', () async {
        // Add a fork
        await runner
            .runOrThrow(['fvm', 'fork', 'add', testForkName, testForkUrl]);

        // List should succeed and show the fork
        final listExitCode = await runner.runOrThrow(['fvm', 'fork', 'list']);
        expect(listExitCode, ExitCode.success.code);
      });

      test('Fork remove cleans up properly', () async {
        // Add a fork
        await runner
            .runOrThrow(['fvm', 'fork', 'add', testForkName, testForkUrl]);

        // Remove the fork
        final removeExitCode =
            await runner.runOrThrow(['fvm', 'fork', 'remove', testForkName]);
        expect(removeExitCode, ExitCode.success.code);

        // Verify fork was removed
        final config = LocalAppConfig.read();
        final hasTestFork = config.forks.any((f) => f.name == testForkName);
        expect(hasTestFork, false);
      });
    });

    group('Fork error handling:', () {
      test('Install from non-existent fork fails gracefully', () async {
        expect(
          () =>
              runner.runOrThrow(['fvm', 'install', 'nonexistent/${TestVersions.customForkBranch}']),
          throwsA(
            predicate<Exception>(
              (e) => e
                  .toString()
                  .contains('Fork "nonexistent" has not been configured'),
            ),
          ),
        );
      });

      test('Use non-existent fork fails gracefully', () async {
        expect(
          () => runner.runOrThrow(['fvm', 'use', 'nonexistent/${TestVersions.customForkBranch}']),
          throwsA(
            predicate<Exception>(
              (e) => e
                  .toString()
                  .contains('Fork "nonexistent" has not been configured'),
            ),
          ),
        );
      });

      test('Fork add with invalid URL fails', () async {
        expect(
          () => runner
              .runOrThrow(['fvm', 'fork', 'add', 'invalid', 'not-a-git-url']),
          throwsA(isA<Exception>()),
        );
      });

      test('Fork add with duplicate name fails', () async {
        // Add a fork first
        await runner
            .runOrThrow(['fvm', 'fork', 'add', testForkName, testForkUrl]);

        // Try to add another fork with same name
        expect(
          () => runner.runOrThrow([
            'fvm',
            'fork',
            'add',
            testForkName,
            'https://github.com/other/flutter.git'
          ]),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Fork command validation:', () {
      test('Fork add requires both alias and URL', () async {
        expect(
          () => runner.runOrThrow(['fvm', 'fork', 'add']),
          throwsA(isA<Exception>()),
        );

        expect(
          () => runner.runOrThrow(['fvm', 'fork', 'add', 'onlyalias']),
          throwsA(isA<Exception>()),
        );
      });

      test('Fork remove requires alias', () async {
        expect(
          () => runner.runOrThrow(['fvm', 'fork', 'remove']),
          throwsA(isA<Exception>()),
        );
      });

      test('Fork list works with no forks configured', () async {
        // Ensure no forks exist
        LocalAppConfig.read()
          ..forks.clear()
          ..save();

        final exitCode = await runner.runOrThrow(['fvm', 'fork', 'list']);
        expect(exitCode, ExitCode.success.code);
      });
    });
  });
}
