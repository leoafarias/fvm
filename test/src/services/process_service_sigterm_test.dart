import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/run_configured_flutter.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _roleKey = 'FVM_SIGTERM_TEST_ROLE';
const _directoryKey = 'FVM_SIGTERM_TEST_DIRECTORY';
const _harnessKey = 'FVM_SIGTERM_TEST_HARNESS';

// A real non-TTY parent exercises the production inherited-stdio path, which
// TestFactory's test context intentionally bypasses.
Future<void> main() async {
  final role = Platform.environment[_roleKey];
  if (role == 'parent') {
    await _runParent();
    return;
  }
  if (role == 'child') {
    await _runChild();
    return;
  }

  Directory? harnessDirectory;
  late String harnessPath;
  setUpAll(() async {
    final directory =
        await Directory.systemTemp.createTemp('fvm_signal_harness_');
    harnessDirectory = directory;
    harnessPath = p.join(directory.path, 'harness.dill');
    // Repeated source compilation can consume the readiness deadline on CI.
    // All fixture processes use this one kernel compiled by the current SDK.
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'kernel',
      p.join(Directory.current.path,
          'test/src/services/process_service_sigterm_test.dart'),
      '-o',
      harnessPath,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
  tearDownAll(() async {
    await harnessDirectory?.delete(recursive: true);
  });

  for (final useFallback in [false, true]) {
    group(useFallback ? 'system PATH fallback' : 'direct process', () {
      for (final mode in ['pid', 'normal', 'group']) {
        final terminate = mode != 'normal';
        final signalGroup = mode == 'group';
        test(
          signalGroup
              ? 'default group SIGTERM reaches the child once and preserves cleanup'
              : terminate
                  ? 'SIGTERM to a non-TTY parent reaches its child and waits for cleanup'
                  : 'normal inherited-stdio exit releases signal listeners and preserves status',
          () async {
            final directory =
                await Directory.systemTemp.createTemp('fvm_sigterm_');
            final parent = await Process.start(
              Platform.resolvedExecutable,
              [harnessPath],
              environment: {
                ...Platform.environment,
                _roleKey: 'parent',
                _directoryKey: directory.path,
                _harnessKey: harnessPath,
                'FVM_SIGTERM_TEST_COMPLETE': '${!terminate}',
                'FVM_SIGTERM_TEST_FALLBACK': '$useFallback',
                'FVM_SIGTERM_TEST_GROUP': '$signalGroup',
                'FVM_FORWARD_SIGTERM': '${!signalGroup}',
              },
            );
            final diagnostics = StringBuffer();
            final ready = Completer<int>();
            var ownsGroup = false;
            final output = parent.stdout
                .transform(utf8.decoder)
                .transform(const LineSplitter())
                .listen((line) {
              diagnostics.writeln(line);
              if (line == 'OWNED_GROUP:${parent.pid}') ownsGroup = true;
              if (line.startsWith('CHILD_READY:') && !ready.isCompleted) {
                ready
                    .complete(int.parse(line.substring('CHILD_READY:'.length)));
              }
            });
            final errors =
                parent.stderr.transform(utf8.decoder).listen(diagnostics.write);
            final streamsDone = Future.wait([
              output.asFuture<void>(),
              errors.asFuture<void>(),
            ]);
            int? childPid;
            var childExited = false;
            try {
              parent.stdin.writeln('fixture input');
              await parent.stdin.flush();
              childPid = await ready.future.timeout(
                const Duration(seconds: 20),
                onTimeout: () => throw StateError(
                    'Fixture did not become ready:\n$diagnostics'),
              );
              if (signalGroup) {
                expect(ownsGroup, isTrue);
                expect(_signalGroup(parent.pid, ProcessSignal.sigterm), 0);
              } else if (terminate) {
                expect(parent.kill(ProcessSignal.sigterm), isTrue);
              }
              final code =
                  await parent.exitCode.timeout(const Duration(seconds: 10));
              await streamsDone.timeout(const Duration(seconds: 10));
              expect(code, signalGroup ? -15 : (terminate ? 143 : 7),
                  reason: diagnostics.toString());
              expect(
                await File(p.join(directory.path, 'events')).readAsLines(),
                [
                  'child cleanup',
                  if (!signalGroup)
                    terminate ? 'parent exit 143' : 'parent result 7'
                ],
              );
              childExited = true;
              expect(diagnostics.toString(), contains('PARENT_NON_TTY:true'));
              expect(diagnostics.toString(), contains('CHILD_STDERR'));
              expect(diagnostics.toString(),
                  contains('CHILD_STDIN:fixture input'));
              if (terminate) {
                expect(RegExp('CHILD_TERM:').allMatches(diagnostics.toString()),
                    hasLength(1));
                expect(diagnostics.toString(),
                    isNot(contains('WORKFLOW_CONTINUED')));
              }
            } finally {
              // Also clean up when run against the broken implementation: only the
              // fixture child whose PID was recorded by this test may be signalled.
              final pidFile = File(p.join(directory.path, 'child.pid'));
              final child = childPid ??
                  (await pidFile.exists()
                      ? int.parse(await pidFile.readAsString())
                      : null);
              if (child != null && !childExited) {
                Process.killPid(child, ProcessSignal.sigkill);
              }
              parent.kill(ProcessSignal.sigkill);
              if (ownsGroup) _signalGroup(parent.pid, ProcessSignal.sigkill);
              await parent.exitCode;
              await output.cancel();
              await errors.cancel();
              await directory.delete(recursive: true);
            }
          },
          skip: Platform.isWindows && terminate
              ? 'POSIX SIGTERM required'
              : false,
          timeout: const Timeout(Duration(minutes: 1)),
        );
      }
    });
  }
}

Future<void> _runParent() async {
  final directory = Platform.environment[_directoryKey]!;
  if (Platform.environment['FVM_SIGTERM_TEST_GROUP'] == 'true') {
    // Only this fixture creates a session; its parent may then safely signal
    // the private group without touching the test runner's own process group.
    final setsid = DynamicLibrary.process()
        .lookupFunction<Int32 Function(), int Function()>('setsid');
    if (setsid() != pid) throw StateError('Could not create fixture session');
    stdout.writeln('OWNED_GROUP:$pid');
  }
  final separator = Platform.isWindows ? ';' : ':';
  final context = FvmContext.create(
    configOverrides: AppConfig(
      cachePath: p.join(directory, 'cache'),
      gitCachePath: p.join(directory, 'cache.git'),
      useGitCache: false,
      privilegedAccess: false,
      disableUpdateCheck: true,
    ),
    appConfigPath: p.join(directory, 'config.json'),
    workingDirectoryOverride: directory,
    environmentOverrides: {
      _roleKey: 'child',
      'PATH': '${p.dirname(Platform.resolvedExecutable)}$separator'
          '${Platform.environment['PATH'] ?? ''}',
    },
    isTest: false,
  );
  stdout.writeln('PARENT_NON_TTY:${!context.stdinHasTerminal}');
  try {
    final command = p.basename(Platform.resolvedExecutable);
    final args = [Platform.environment[_harnessKey]!];
    final result = Platform.environment['FVM_SIGTERM_TEST_FALLBACK'] == 'true'
        ? await RunConfiguredFlutterWorkflow(context).call(command, args: args)
        : await context.get<ProcessService>().run(
              command,
              args: args,
              environment: context.environment,
              echoOutput: true,
              throwOnError: false,
            );
    stdout.writeln('WORKFLOW_CONTINUED');
    await File(p.join(directory, 'events')).writeAsString(
      'parent result ${result.exitCode}\n',
      mode: FileMode.append,
    );
    exitCode = result.exitCode;
  } on ForceExit catch (error) {
    await File(p.join(directory, 'events')).writeAsString(
      'parent exit ${error.exitCode}\n',
      mode: FileMode.append,
    );
    exitCode = error.exitCode;
  }
}

Future<void> _runChild() async {
  final received = Completer<void>();
  var signalCount = 0;
  final subscription = Platform.isWindows
      ? null
      : ProcessSignal.sigterm.watch().listen((_) {
          stdout.writeln('CHILD_TERM:${++signalCount}');
          // Model tools that escalate a repeated interrupt during cleanup.
          if (signalCount > 1) exit(23);
          if (!received.isCompleted) received.complete();
        });
  try {
    File(p.join(Platform.environment[_directoryKey]!, 'child.pid'))
        .writeAsStringSync('$pid');
    stdout.writeln('CHILD_STDIN:${stdin.readLineSync()}');
    stderr.writeln('CHILD_STDERR');
    await stderr.flush();
    stdout.writeln('CHILD_READY:$pid');
    await stdout.flush();
    if (Platform.environment['FVM_SIGTERM_TEST_COMPLETE'] != 'true') {
      await received.future;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await File(p.join(Platform.environment[_directoryKey]!, 'events'))
        .writeAsString('child cleanup\n', mode: FileMode.append);
    exitCode = 7;
  } finally {
    await subscription?.cancel();
  }
}

int _signalGroup(int groupId, ProcessSignal signal) {
  final kill = DynamicLibrary.process()
      .lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>(
          'kill');
  return kill(-groupId, signal.signalNumber);
}
