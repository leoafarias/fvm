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
      final command = Platform.isWindows ? 'cmd' : 'sh';
      final args = Platform.isWindows
          ? ['/c', 'echo stdout & echo stderr 1>&2 & exit /b 23']
          : ['-c', 'echo stdout; echo stderr >&2; exit 23'];

      expect(
        () => processService.run(command, args: args, throwOnError: true),
        throwsA(
          isA<ProcessException>()
              .having((error) => error.errorCode, 'errorCode', 23)
              .having((error) => error.message, 'message', 'stderr'),
        ),
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
  });
}
