import 'dart:convert';
import 'dart:io';

import '../utils/exceptions.dart';
import 'base_service.dart';
import 'operation_cancellation.dart';

final class OperationCanceledException extends AppException {
  const OperationCanceledException() : super('Operation cancelled.');
}

final class ProcessCancellation implements OperationCancellation {
  Process? _process;
  bool _cancelled = false;

  void attach(Process process) {
    _process = process;
    if (_cancelled) process.kill(ProcessSignal.sigterm);
  }

  void detach() => _process = null;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _process?.kill(ProcessSignal.sigterm);
  }

  @override
  bool get isCancelled => _cancelled;
}

class ProcessService extends ContextualService {
  const ProcessService(super.context);

  static String _linesToOutput(List<String> lines) =>
      lines.isEmpty ? '' : '${lines.join('\n')}\n';

  void _throwIfProcessFailed(
    ProcessResult pr,
    String process,
    List<String> args,
  ) {
    if (pr.exitCode == 0) return;

    final stderr = pr.stderr?.toString().trim();
    final stdout = pr.stdout?.toString().trim();

    var message = 'Unknown error';
    if (stderr?.isNotEmpty == true) {
      message = stderr!;
    } else if (stdout?.isNotEmpty == true) {
      message = stdout!;
    }

    throw ProcessException(process, args, message, pr.exitCode);
  }

  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],

    /// Listen for stdout and stderr
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = false,
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
    final process = await Process.start(
      command,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: runInShell,
      mode: ProcessStartMode.inheritStdio,
    );

    processResult = ProcessResult(
      process.pid,
      await process.exitCode,
      null,
      null,
    );
    if (throwOnError) {
      _throwIfProcessFailed(processResult, command, args);
    }

    return processResult;
  }

  Future<ProcessResult> runStreaming(
    String command, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool runInShell = false,
    void Function(String)? onStdoutLine,
    void Function(String)? onStderrLine,
    ProcessCancellation? cancellation,
  }) async {
    logger
      ..debug('')
      ..debug('Running: $command')
      ..debug('');

    final process = await Process.start(
      command,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: runInShell,
    );
    cancellation?.attach(process);

    final stdoutLines = <String>[];
    final stderrLines = <String>[];
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stdoutLines.add(line);
          onStdoutLine?.call(line);
        })
        .asFuture<void>();
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stderrLines.add(line);
          onStderrLine?.call(line);
        })
        .asFuture<void>();

    try {
      final exitCode = await process.exitCode;
      await Future.wait([stdoutDone, stderrDone]);
      if (cancellation?.isCancelled ?? false) {
        throw const OperationCanceledException();
      }

      final result = ProcessResult(
        process.pid,
        exitCode,
        _linesToOutput(stdoutLines),
        _linesToOutput(stderrLines),
      );
      if (throwOnError) _throwIfProcessFailed(result, command, args);

      return result;
    } finally {
      cancellation?.detach();
    }
  }
}

extension ProcessResultX on ProcessResult {
  // Note: `this.exitCode` is intentional -- without the explicit receiver,
  // Dart resolves to `dart:io`'s top-level `exitCode` getter.
  bool get isSuccess => this.exitCode == 0;

  bool get isFailure => this.exitCode != 0;
}
