import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Fork commands:', () {
    const testForkName = 'testfork';
    const testForkUrl = 'https://github.com/testuser/flutter.git';

    // Ensure global config directory exists before running fork tests
    setUpAll(() {
      ensureGlobalConfigDirectoryExists();
    });

    test('Add a fork', () async {
      final runner = TestFactory.commandRunner();

      // Make sure the fork doesn't exist first
      LocalAppConfig.read()
        ..forks.removeWhere((f) => f.name == testForkName)
        ..save();

      final exitCode = await runner
          .runOrThrow(['fvm', 'fork', 'add', testForkName, testForkUrl]);

      expect(exitCode, ExitCode.success.code);

      // Check that the fork was added correctly
      final config = LocalAppConfig.read();
      final fork = config.forks.firstWhere(
        (f) => f.name == testForkName,
        orElse: () => const FlutterFork(name: '', url: ''),
      );

      expect(fork.name, testForkName);
      expect(fork.url, testForkUrl);
    });

    test('Reject invalid fork URL', () async {
      final runner = TestFactory.commandRunner();
      final invalidUrl = 'invalid-url';

      expect(
        () => runner.runOrThrow(['fvm', 'fork', 'add', 'invalid', invalidUrl]),
        throwsA(isA<Exception>()),
      );
    });

    test('Reject duplicate fork name', () async {
      final runner = TestFactory.commandRunner();

      // Add a fork first
      LocalAppConfig.read()
        ..forks.add(const FlutterFork(name: testForkName, url: testForkUrl))
        ..save();

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

    test('List forks', () async {
      final runner = TestFactory.commandRunner();

      // Add a test fork
      LocalAppConfig.read()
        ..forks.add(const FlutterFork(name: testForkName, url: testForkUrl))
        ..save();

      final exitCode = await runner.runOrThrow(['fvm', 'fork', 'list']);

      expect(exitCode, ExitCode.success.code);
    });

    test('Remove a fork', () async {
      final runner = TestFactory.commandRunner();

      // Add a test fork first
      LocalAppConfig.read()
        ..forks.add(const FlutterFork(name: testForkName, url: testForkUrl))
        ..save();

      final exitCode = await runner.runOrThrow([
        'fvm',
        'fork',
        'remove',
        testForkName,
      ]);

      expect(exitCode, ExitCode.success.code);

      // Check that the fork was removed
      final config = LocalAppConfig.read();
      final hasTestFork = config.forks.any((f) => f.name == testForkName);

      expect(hasTestFork, false);
    });
  });
}
