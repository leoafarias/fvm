import 'dart:io';

import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/context.dart';

Future<ProcessResult> runCommand(
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

  if (!echoOutput || ctx.isTest) {
    final processResult = await Process.run(
      command,
      args,
      environment: environment,
      runInShell: true,
      workingDirectory: workingDirectory,
    );

    if (throwOnError) {
      _throwIfProcessFailed(processResult, command, args);
    }
    return processResult;
  }

  final process = await Process.start(
    command,
    args,
    environment: environment,
    runInShell: true,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );

  final results = await Future.wait([
    process.exitCode,
    process.stdout.transform(const SystemEncoding().decoder).join(),
    process.stderr.transform(const SystemEncoding().decoder).join(),
  ]);

  final processResult = ProcessResult(
    process.pid,
    results[0] as int,
    results[1] as String,
    results[2] as String,
  );

  if (throwOnError) {
    _throwIfProcessFailed(processResult, command, args);
  }
  return processResult;
}

void _throwIfProcessFailed(
  ProcessResult pr,
  String process,
  List<String> args,
) {
  if (pr.exitCode != 0) {
    final values = {
      if (pr.stdout != null) 'Standard out': pr.stdout.toString().trim(),
      if (pr.stderr != null) 'Standard error': pr.stderr.toString().trim(),
    }..removeWhere((k, v) => v.isEmpty);

    String message;
    if (values.isEmpty) {
      message = 'Unknown error';
    } else if (values.length == 1) {
      message = values.values.single;
    } else {
      message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
    }

    throw ProcessException(process, args, message, pr.exitCode);
  }
}
