import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/services/process_service.dart';
import 'package:path/path.dart' as p;
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
      final result = await _runFixture(processService, 'arguments', ['hello']);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), contains('hello'));
    });

    test('throwOnError=true throws on failure', () async {
      final processService = runner.context.get<ProcessService>();

      expect(
        () => _runFixture(
          processService,
          'failure',
          const [],
          throwOnError: true,
        ),
        throwsA(
          isA<ProcessException>()
              .having((error) => error.errorCode, 'errorCode', 23)
              .having((error) => error.message, 'message', 'stderr'),
        ),
      );
    });

    test('throwOnError=false returns failed result', () async {
      final processService = runner.context.get<ProcessService>();
      final result = await _runFixture(
        processService,
        'failure',
        const [],
        throwOnError: false,
      );

      expect(result.exitCode, isNot(0));
    });

    test('environment variables are passed through', () async {
      final processService = runner.context.get<ProcessService>();
      final result = await _runFixture(
        processService,
        'environment',
        const [],
        environment: {'TEST_VAR': 'test_value'},
      );

      expect(result.stdout.toString(), contains('test_value'));
    });

    test('echoOutput is disabled in test mode', () async {
      final processService = runner.context.get<ProcessService>();
      final result = await _runFixture(processService, 'arguments', [
        'test',
      ], echoOutput: true);

      expect(result.exitCode, equals(0));
    });

    test(
      'passes literal spaces and shell metacharacters to the executable',
      () async {
        final processService = runner.context.get<ProcessService>();
        const arguments = [
          'value with spaces',
          r'$HOME',
          r'$(whoami)',
          ';',
          '&&',
          '|',
          '>file',
          '"quoted"',
        ];

        final result = await _runFixture(
          processService,
          'arguments',
          arguments,
        );

        expect(jsonDecode(result.stdout.toString()), equals(arguments));
      },
    );

    test('runStreaming reports and captures both streams', () async {
      final processService = runner.context.get<ProcessService>();
      final stdoutLines = <String>[];
      final stderrLines = <String>[];

      final result = await _runStreamingFixture(
        processService,
        'streaming',
        onStdoutLine: stdoutLines.add,
        onStderrLine: stderrLines.add,
      );

      expect(stdoutLines, ['stdout-1', 'stdout-2']);
      expect(stderrLines, ['stderr-1', 'stderr-2']);
      expect(result.stdout, 'stdout-1\nstdout-2\n');
      expect(result.stderr, 'stderr-1\nstderr-2\n');
    });

    test('runStreaming preserves throw-on-error behavior', () async {
      final processService = runner.context.get<ProcessService>();

      await expectLater(
        _runStreamingFixture(processService, 'failure'),
        throwsA(
          isA<ProcessException>()
              .having((error) => error.errorCode, 'errorCode', 23)
              .having((error) => error.message, 'message', 'stderr'),
        ),
      );
    });

    test(
      'runStreaming terminates an attached process on cancellation',
      () async {
        final processService = runner.context.get<ProcessService>();
        final cancellation = ProcessCancellation();
        final ready = Completer<void>();

        final running = _runStreamingFixture(
          processService,
          'wait-for-cancel',
          cancellation: cancellation,
          onStdoutLine: (line) {
            if (line == 'ready' && !ready.isCompleted) ready.complete();
          },
        );

        await ready.future.timeout(const Duration(seconds: 10));
        cancellation.cancel();

        await expectLater(running, throwsA(isA<OperationCanceledException>()));
        expect(cancellation.isCancelled, isTrue);
      },
    );
  });
}

Future<ProcessResult> _runFixture(
  ProcessService processService,
  String operation,
  List<String> arguments, {
  Map<String, String>? environment,
  bool throwOnError = true,
  bool echoOutput = false,
}) {
  return processService.run(
    Platform.resolvedExecutable,
    args: [
      p.join(
        Directory.current.path,
        'test',
        'fixtures',
        'process_service_worker.dart',
      ),
      operation,
      ...arguments,
    ],
    environment: environment,
    throwOnError: throwOnError,
    echoOutput: echoOutput,
  );
}

Future<ProcessResult> _runStreamingFixture(
  ProcessService processService,
  String operation, {
  bool throwOnError = true,
  void Function(String)? onStdoutLine,
  void Function(String)? onStderrLine,
  ProcessCancellation? cancellation,
}) {
  return processService.runStreaming(
    Platform.resolvedExecutable,
    args: [
      p.join(
        Directory.current.path,
        'test',
        'fixtures',
        'process_service_worker.dart',
      ),
      operation,
    ],
    throwOnError: throwOnError,
    onStdoutLine: onStdoutLine,
    onStderrLine: onStderrLine,
    cancellation: cancellation,
  );
}
