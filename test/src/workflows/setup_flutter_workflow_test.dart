import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/workflows/setup_flutter.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

class _FailingProcessService extends ProcessService {
  _FailingProcessService(super.context);

  bool? lastThrowOnError;
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
    lastThrowOnError = throwOnError;
    lastRunInShell = runInShell;

    if (throwOnError) {
      throw ProcessException(command, args, 'setup failed', 42);
    }

    return ProcessResult(0, 42, '', 'setup failed');
  }
}

void main() {
  test('non-zero Flutter setup is reported as failure, never success',
      () async {
    late _FailingProcessService processService;
    final context = TestFactory.context(
      generators: {
        ProcessService: (context) {
          processService = _FailingProcessService(context);

          return processService;
        },
      },
    );
    final version = CacheFlutterVersion.fromVersion(
      FlutterVersion.parse('stable'),
      directory: p.join(context.versionsCachePath, 'stable'),
    );

    await expectLater(
      () => SetupFlutterWorkflow(context)(version),
      throwsA(
        isA<ProcessException>()
            .having((error) => error.errorCode, 'errorCode', 42)
            .having((error) => error.message, 'message', 'setup failed'),
      ),
    );

    final output = context.get<Logger>().outputs.join('\n');
    expect(processService.lastThrowOnError, isTrue);
    expect(processService.lastRunInShell, isTrue);
    expect(output, contains('Failed to setup Flutter SDK'));
    expect(output, isNot(contains('is setup')));
  });
}
