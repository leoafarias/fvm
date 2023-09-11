import 'dart:io';

import 'package:fvm/src/utils/logger.dart';

Future<ProcessResult> runCommand(
  String command, {
  /// Listen for stdout and stderr
  String? workingDirectory,
  Map<String, String>? environment,
  bool throwOnError = true,
  bool echoOutput = false,
}) async {
  List<String> arguments = command.split(' ');
  final processCommand = arguments.removeAt(0);

  logger
    ..detail('')
    ..detail('Running: $command')
    ..detail('');

  final process = await Process.start(
    processCommand,
    arguments,
    environment: environment,
    runInShell: true,
    workingDirectory: workingDirectory,
    mode: echoOutput ? ProcessStartMode.inheritStdio : ProcessStartMode.normal,
  );

  final results = await Future.wait([
    process.exitCode,
    process.stdout.transform(const SystemEncoding().decoder).join(),
    process.stderr.transform(const SystemEncoding().decoder).join(),
  ]);

  final processResult = ProcessResult(
    process.pid,
    results[0] as int,
    echoOutput ? null : results[1] as String,
    echoOutput ? null : results[2] as String,
  );

  if (throwOnError) {
    _throwIfProcessFailed(processResult, processCommand, arguments);
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
