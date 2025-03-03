import 'dart:io';

import 'package:io/io.dart';

import 'base_service.dart';

class ProcessService extends ContextualService {
  ProcessService(super.context);

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
  }) async {
    logger
      ..detail('')
      ..detail('Running: $command')
      ..detail('');
    ProcessResult processResult;
    if (!echoOutput || context.isTest) {
      processResult = await Process.run(
        command,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: true,
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
      runInShell: true,
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
}

extension ProcessResultX on ProcessResult {
  bool get isSuccess => exitCode == ExitCode.success.code;

  bool get isFailure => exitCode != ExitCode.success.code;
}
