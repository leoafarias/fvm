import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Fork commands:', () {
    late TestCommandRunner runner;
    const testForkName = 'testfork';
    const testForkUrl = 'https://github.com/testuser/flutter.git';

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('Add a fork', () async {
      // Make sure the fork doesn't exist first
      LocalAppConfig.read(path: runner.context.appConfigPath)
        ..forks.removeWhere((f) => f.name == testForkName)
        ..save(path: runner.context.appConfigPath);

      final exitCode = await runner.runOrThrow([
        'fvm',
        'fork',
        'add',
        testForkName,
        testForkUrl,
      ]);

      expect(exitCode, ExitCode.success.code);

      // Check that the fork was added correctly
      final config = LocalAppConfig.read(path: runner.context.appConfigPath);
      final fork = config.forks.firstWhere(
        (f) => f.name == testForkName,
        orElse: () => const FlutterFork(name: '', url: ''),
      );

      expect(fork.name, testForkName);
      expect(fork.url, testForkUrl);
    });

    test('Add a fork with scp-style git URL', () async {
      const alias = 'sshfork';
      const scpUrl = 'git@github.com:flutter/flutter.git';

      LocalAppConfig.read(path: runner.context.appConfigPath)
        ..forks.removeWhere((f) => f.name == alias)
        ..save(path: runner.context.appConfigPath);

      final exitCode = await runner.runOrThrow([
        'fvm',
        'fork',
        'add',
        alias,
        scpUrl,
      ]);

      expect(exitCode, ExitCode.success.code);

      final config = LocalAppConfig.read(path: runner.context.appConfigPath);
      final fork = config.forks.firstWhere(
        (f) => f.name == alias,
        orElse: () => const FlutterFork(name: '', url: ''),
      );

      expect(fork.name, alias);
      expect(fork.url, scpUrl);
    });

    test('does not overwrite malformed configuration when adding a fork',
        () async {
      const malformedConfig = '{"forks":';
      final configFile = File(runner.context.appConfigPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(malformedConfig);

      final exitCode = await runner.run([
        'fvm',
        'fork',
        'add',
        testForkName,
        testForkUrl,
      ]);

      expect(exitCode, ExitCode.data.code);
      expect(configFile.readAsStringSync(), malformedConfig);
    });

    test('Reject invalid fork URL', () async {
      final invalidUrl = 'invalid-url';

      expect(
        () => runner.runOrThrow(['fvm', 'fork', 'add', 'invalid', invalidUrl]),
        throwsA(isA<Exception>()),
      );
    });

    test('Accept valid alias formats', () async {
      for (final alias in ['my-fork', 'my_fork.v2', 'FORK123', 'a']) {
        LocalAppConfig.read(path: runner.context.appConfigPath)
          ..forks.removeWhere((f) => f.name == alias)
          ..save(path: runner.context.appConfigPath);

        final exitCode = await runner.runOrThrow([
          'fvm',
          'fork',
          'add',
          alias,
          testForkUrl,
        ]);
        expect(exitCode, ExitCode.success.code, reason: 'alias "$alias"');

        // Cleanup
        LocalAppConfig.read(path: runner.context.appConfigPath)
          ..forks.removeWhere((f) => f.name == alias)
          ..save(path: runner.context.appConfigPath);
      }
    });

    test('Reject alias with slash', () async {
      expect(
        () => runner.runOrThrow(['fvm', 'fork', 'add', 'my/fork', testForkUrl]),
        throwsA(isA<Exception>()),
      );
    });

    test('Reject alias with spaces', () async {
      expect(
        () => runner.runOrThrow(['fvm', 'fork', 'add', 'my fork', testForkUrl]),
        throwsA(isA<Exception>()),
      );
    });

    test('Reject duplicate fork name', () async {
      // Add a fork first
      LocalAppConfig.read(path: runner.context.appConfigPath)
        ..forks.add(const FlutterFork(name: testForkName, url: testForkUrl))
        ..save(path: runner.context.appConfigPath);

      expect(
        () => runner.runOrThrow([
          'fvm',
          'fork',
          'add',
          testForkName,
          'https://github.com/other/flutter.git',
        ]),
        throwsA(isA<Exception>()),
      );
    });

    test('List forks', () async {
      // Add a test fork
      LocalAppConfig.read(path: runner.context.appConfigPath)
        ..forks.add(const FlutterFork(name: testForkName, url: testForkUrl))
        ..save(path: runner.context.appConfigPath);

      final exitCode = await runner.runOrThrow(['fvm', 'fork', 'list']);

      expect(exitCode, ExitCode.success.code);
    });

    test('Remove a fork', () async {
      // Add a test fork first
      LocalAppConfig.read(path: runner.context.appConfigPath)
        ..forks.add(const FlutterFork(name: testForkName, url: testForkUrl))
        ..save(path: runner.context.appConfigPath);

      final exitCode = await runner.runOrThrow([
        'fvm',
        'fork',
        'remove',
        testForkName,
      ]);

      expect(exitCode, ExitCode.success.code);

      // Check that the fork was removed
      final config = LocalAppConfig.read(path: runner.context.appConfigPath);
      final hasTestFork = config.forks.any((f) => f.name == testForkName);

      expect(hasTestFork, isFalse);
    });

    test('rejects invalid operand counts without changing configuration',
        () async {
      const existingFork = FlutterFork(
        name: testForkName,
        url: testForkUrl,
      );
      final invalidInvocations = <List<String>>[
        ['fvm', 'fork', 'add'],
        ['fvm', 'fork', 'add', 'newfork'],
        ['fvm', 'fork', 'add', 'newfork', testForkUrl, 'extra'],
        ['fvm', 'fork', 'remove'],
        ['fvm', 'fork', 'remove', testForkName, 'extra'],
        ['fvm', 'fork', 'list', 'extra'],
      ];

      for (final invocation in invalidInvocations) {
        LocalAppConfig(forks: {existingFork}).save(
          path: runner.context.appConfigPath,
        );
        final configBefore = File(
          runner.context.appConfigPath,
        ).readAsStringSync();

        final exitCode = await runner.run(invocation);

        expect(exitCode, ExitCode.usage.code, reason: invocation.join(' '));
        expect(
          File(runner.context.appConfigPath).readAsStringSync(),
          configBefore,
          reason: invocation.join(' '),
        );
      }
    });
  });
}
