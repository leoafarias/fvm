import 'dart:io';

import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/workflows/run_configured_flutter.workflow.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

class _FakeProcessService extends ProcessService {
  _FakeProcessService(super.context);

  bool? lastRunInShell;

  @override
  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = false,
  }) async {
    lastRunInShell = runInShell;

    return ProcessResult(0, 0, '', '');
  }
}

void main() {
  test('system PATH fallback uses shell execution for platform resolution',
      () async {
    late _FakeProcessService processService;
    final context = TestFactory.context(
      generators: {
        ProcessService: (context) {
          processService = _FakeProcessService(context);

          return processService;
        },
      },
    );

    await RunConfiguredFlutterWorkflow(context)(
      'flutter',
      args: const ['--version'],
    );

    expect(processService.lastRunInShell, isTrue);
  });
}
