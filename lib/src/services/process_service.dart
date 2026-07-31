import 'dart:async';
import 'dart:io';

import '../utils/exceptions.dart';
import 'base_service.dart';

class ProcessService extends ContextualService {
  const ProcessService(super.context);

  void _throwIfProcessFailed(
    ProcessResult pr,
    String process,
    List<String> args,
  ) {
    if (pr.exitCode != 0) {
      final values = {
        if (pr.stdout != null) 'stdout': pr.stdout.toString().trim(),
        if (pr.stderr != null) 'stderr': pr.stderr.toString().trim(),
      }..removeWhere((k, v) => v.isEmpty);

      String message;
      if (values.isEmpty) {
        message = 'Unknown error';
      } else if (values.length == 1) {
        message = values.values.single;
      } else {
        if (values['stderr'] != null) {
          message = values['stderr']!;
        } else {
          message = values['stdout']!;
        }
      }

      throw ProcessException(process, args, message, pr.exitCode);
    }
  }

  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],

    /// Listen for stdout and stderr
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = true,
  }) async {
    logger
      ..debug('')
      ..debug('Running: $command')
      ..debug('');
    ProcessResult processResult;
    if (!echoOutput || context.isTest) {
      processResult = await Process.run(
        command,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: runInShell,
      );

      if (throwOnError) {
        _throwIfProcessFailed(processResult, command, args);
      }

      return processResult;
    }
    StreamSubscription<ProcessSignal>? sigintSubscription;
    var interrupted = false;
    if (!Platform.isWindows && context.stdinHasTerminal) {
      sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
        interrupted = true;
      });
    }

    late final Process process;
    late final int processExitCode;
    try {
      process = await Process.start(
        command,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: runInShell,
        mode: ProcessStartMode.inheritStdio,
      );

      if (interrupted) {
        process.kill(ProcessSignal.sigint);
      }
      processExitCode = await process.exitCode;
    } finally {
      await sigintSubscription?.cancel();
    }

    if (interrupted) {
      throw ForceExit('', 128 + ProcessSignal.sigint.signalNumber);
    }

    processResult = ProcessResult(
      process.pid,
      processExitCode,
      null,
      null,
    );
    if (throwOnError) {
      _throwIfProcessFailed(processResult, command, args);
    }

    return processResult;
  }
}

extension ProcessResultX on ProcessResult {
  // Note: `this.exitCode` is intentional -- without the explicit receiver,
  // Dart resolves to `dart:io`'s top-level `exitCode` getter.
  bool get isSuccess => this.exitCode == 0;

  bool get isFailure => this.exitCode != 0;
}
