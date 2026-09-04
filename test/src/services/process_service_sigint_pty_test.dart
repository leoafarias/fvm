import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _roleEnvironmentKey = 'FVM_PROCESS_SERVICE_PTY_ROLE';
const _parentRole = 'parent';
const _childRole = 'child';
const _markerPrefix = 'FVM_PTY_TEST:';

String _requirePython3() {
  try {
    final result = Process.runSync('python3', const [
      '-c',
      'import pty, termios',
    ]);
    if (result.exitCode == 0) return 'python3';
  } on ProcessException {
    // Report the same focused prerequisite error as a failed module import.
  }

  fail(
    'python3 with the POSIX pty and termios modules is required to run '
    'the ProcessService PTY test.',
  );
}

// The test runner launches this file through a Python-owned PTY. The same file
// then acts as the FVM parent and the delayed, signal-aware Flutter child.
Future<void> main() async {
  final role = Platform.environment[_roleEnvironmentKey];
  if (role == _parentRole) {
    await _runParent();
    return;
  }
  if (role == _childRole) {
    await _runChild();
    return;
  }

  test(
    'waits for child cleanup before exiting after terminal SIGINT',
    () async {
      final repositoryRoot = Directory.current.path;
      final result = await Process.run(
        _requirePython3(),
        [
          p.join(
            repositoryRoot,
            'test',
            'support_assets',
            'process_service_sigint_pty.py',
          ),
          '--dart',
          Platform.resolvedExecutable,
          '--harness',
          p.join(
            repositoryRoot,
            'test',
            'src',
            'services',
            'process_service_sigint_pty_test.dart',
          ),
          '--cwd',
          repositoryRoot,
        ],
        workingDirectory: repositoryRoot,
      );

      expect(
        result.exitCode,
        0,
        reason: '${result.stderr}\n${result.stdout}',
      );

      final report =
          jsonDecode(result.stdout as String) as Map<String, dynamic>;
      expect(report['forceExitAfterCleanup'], isTrue);
      expect(report['childRestoredTerminal'], isTrue);
      expect(report['childGone'], isTrue);
      expect(report['processGroupGone'], isTrue);
      expect(report['parentExitCode'], 130);
    },
    skip: Platform.isWindows ? 'POSIX pseudo-terminal required' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _runParent() async {
  final tempDirectory = await Directory.systemTemp.createTemp(
    'fvm_process_service_pty_',
  );

  try {
    final context = FvmContext.create(
      debugLabel: 'process-service-pty-parent',
      configOverrides: AppConfig(
        cachePath: p.join(tempDirectory.path, 'cache'),
        gitCachePath: p.join(tempDirectory.path, 'cache.git'),
        useGitCache: false,
        privilegedAccess: false,
        disableUpdateCheck: true,
      ),
      workingDirectoryOverride: Directory.current.path,
      appConfigPath: p.join(tempDirectory.path, 'config.json'),
      isTest: false,
    );
    final productionContext = !context.isTest && context.stdinHasTerminal;
    stdout.writeln('${_markerPrefix}PARENT_CONTEXT:$productionContext');
    await stdout.flush();

    if (!productionContext) {
      exitCode = 2;
      return;
    }

    try {
      final result = await context.get<ProcessService>().run(
            Platform.resolvedExecutable,
            args: [Platform.script.toFilePath()],
            environment: {
              ...Platform.environment,
              _roleEnvironmentKey: _childRole,
            },
            echoOutput: true,
            throwOnError: false,
          );
      stdout.writeln(
        '${_markerPrefix}PARENT_UNEXPECTED_RESULT:${result.exitCode}',
      );
      exitCode = 3;
    } on ForceExit catch (error) {
      stdout.writeln('${_markerPrefix}PARENT_FORCE_EXIT:${error.exitCode}');
      exitCode = error.exitCode;
    }
    await stdout.flush();
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}

Future<void> _runChild() async {
  final interrupted = Completer<void>();
  final subscription = ProcessSignal.sigint.watch().listen((_) {
    if (!interrupted.isCompleted) interrupted.complete();
  });

  try {
    stdout.writeln('${_markerPrefix}CHILD_READY:$pid');
    await stdout.flush();
    await interrupted.future;

    stdout.writeln('${_markerPrefix}CHILD_SIGINT');
    await stdout.flush();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!stdin.hasTerminal) {
      stdout.writeln('${_markerPrefix}CHILD_NO_TERMINAL');
      exitCode = 4;
      return;
    }

    try {
      stdin.lineMode = true;
      stdin.echoMode = true;
    } on StdinException catch (error) {
      stdout.writeln('${_markerPrefix}CHILD_TTY_ERROR:$error');
      exitCode = 5;
      return;
    }

    stdout.writeln('${_markerPrefix}CHILD_CLEANUP_DONE');
    await stdout.flush();
    exitCode = 130;
  } finally {
    await subscription.cancel();
  }
}
