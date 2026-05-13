import 'dart:io';

import 'package:fvm/src/services/process_service.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  late TestCommandRunner runner;

  setUp(() {
    runner = TestFactory.commandRunner();
  });

  group('ProcessService', () {
    test('successful command returns ProcessResult', () async {
      final processService = runner.context.get<ProcessService>();
      final result = await processService.run('echo', args: ['hello']);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), contains('hello'));
    });

    test('throwOnError=true throws on failure', () async {
      final processService = runner.context.get<ProcessService>();

      expect(
        () => processService.run('false', throwOnError: true),
        throwsA(isA<ProcessException>()),
      );
    });

    test('throwOnError=false returns failed result', () async {
      final processService = runner.context.get<ProcessService>();
      final result = await processService.run('false', throwOnError: false);

      expect(result.exitCode, isNot(0));
    });

    test('environment variables are passed through', () async {
      final processService = runner.context.get<ProcessService>();
      final result = await processService.run(
        Platform.isWindows ? 'cmd' : 'sh',
        args: Platform.isWindows
            ? ['/c', 'echo %TEST_VAR%']
            : ['-c', 'echo \$TEST_VAR'],
        environment: {'TEST_VAR': 'test_value'},
      );

      expect(result.stdout.toString(), contains('test_value'));
    });

    test('echoOutput is disabled in test mode', () async {
      final processService = runner.context.get<ProcessService>();
      final result = await processService.run(
        'echo',
        args: ['test'],
        echoOutput: true,
      );

      expect(result.exitCode, equals(0));
    });

    test('register tracks a process and killAllChildren cleans it up',
        () async {
      final processService = runner.context.get<ProcessService>();
      // Spawn a long-running process; we'll kill it via the registry.
      final process = await Process.start(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows
            ? ['/c', 'ping -n 60 127.0.0.1']
            : ['-c', 'sleep 30'],
      );
      processService.register(process);

      // No exit yet.
      final raceWinner = await Future.any<Object?>([
        process.exitCode.then((c) => 'exited:$c'),
        Future<Object?>.delayed(
          const Duration(milliseconds: 100),
          () => 'still running',
        ),
      ]);
      expect(raceWinner, equals('still running'));

      await processService.killAllChildren(
        graceful: const Duration(milliseconds: 500),
      );

      // After cleanup, exit should resolve quickly.
      final code = await process.exitCode.timeout(const Duration(seconds: 3));
      expect(code, isNot(0));
    });

    test('killAllChildren is a no-op when no children are tracked', () async {
      final processService = runner.context.get<ProcessService>();
      // Should complete immediately without error.
      await processService.killAllChildren().timeout(const Duration(seconds: 1));
    });

    test('tracked process is removed from registry when it exits naturally',
        () async {
      final processService = runner.context.get<ProcessService>();
      final process = await Process.start(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows ? ['/c', 'echo done'] : ['-c', 'true'],
      );
      processService.register(process);
      await process.exitCode;
      // Allow the whenComplete callback to fire.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Subsequent killAllChildren has nothing to kill.
      await processService.killAllChildren().timeout(const Duration(seconds: 1));
    });
  });
}
