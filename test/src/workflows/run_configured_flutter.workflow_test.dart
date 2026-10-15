import 'dart:io';

import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/workflows/run_configured_flutter.workflow.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

class _RecordingProcessService extends ProcessService {
  _RecordingProcessService(super.context);

  String? lastCmd;
  List<String>? lastArgs;
  bool? lastEchoOutput;
  bool? lastThrowOnError;
  int nextExitCode = 0;

  @override
  Future<ProcessResult> run(
    String cmd, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = true,
  }) async {
    lastCmd = cmd;
    lastArgs = List<String>.from(args);
    lastEchoOutput = echoOutput;
    lastThrowOnError = throwOnError;

    return ProcessResult(pid, nextExitCode, '', '');
  }
}

void main() {
  group('RunConfiguredFlutterWorkflow system PATH fallback', () {
    test(
      'passes echoOutput: true and throwOnError: false when no project or global SDK is configured',
      () async {
        late _RecordingProcessService processService;
        final context = TestFactory.fastContext(
          generators: {
            ProcessService: (ctx) => processService =
                _RecordingProcessService(ctx)..nextExitCode = 42,
          },
        );

        final result = await RunConfiguredFlutterWorkflow(context).call(
          'flutter',
          args: ['test', '--name=smoke'],
        );

        expect(processService.lastCmd, 'flutter');
        expect(processService.lastArgs, ['test', '--name=smoke']);
        expect(processService.lastEchoOutput, isTrue);
        expect(processService.lastThrowOnError, isFalse);
        expect(result.exitCode, 42);
      },
    );

    test(
      'returns non-zero exit code instead of throwing ProcessException on PATH fallback',
      () async {
        final context = TestFactory.fastContext();
        final workflow = RunConfiguredFlutterWorkflow(context);

        final result = await workflow.call(
          Platform.isWindows ? 'cmd' : 'sh',
          args: Platform.isWindows ? ['/c', 'exit 17'] : ['-c', 'exit 17'],
        );

        expect(result.exitCode, 17);
      },
    );
  });
}
