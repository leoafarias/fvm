import 'dart:convert';
import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:process/process.dart';

/// Default process manager to be used for all the processes
// ignore: constant_identifier_names
const FvmProcessManager = LocalProcessManager();

class ProcessRunner {
  static final LocalProcessManager _process = FvmProcessManager;
  ProcessRunner._();
  static Future<ProcessResult> run(
    String command, {
    /// Listen for stdout and stderr
    String? workingDirectory,
    Map<String, String>? environment,
    bool listen = true,
  }) async {
    List<String> arguments = command.split(' ');

    final process = await _process.start(
      arguments,
      environment: environment,
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    final StringBuffer stdoutBuffer = StringBuffer();
    final StringBuffer stderrBuffer = StringBuffer();

    process.stdout.transform(utf8.decoder).listen((data) {
      stdoutBuffer.write(data);

      if (listen) {
        logger.write('\r$data');
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      stderrBuffer.write(data);

      if (listen) {
        logger.write('\r$data');
      }
    });

    final exitCode = await process.exitCode;

    return ProcessResult(
      process.pid,
      exitCode,
      stdoutBuffer.toString(),
      stderrBuffer.toString(),
    );
  }

  static Future<ProcessResult> runWithProgress(
    String command, {
    /// Description of the command
    required String description,
    Map<String, String>? environment,
    String? workingDirectory,
  }) async {
    logger
      ..detail('\n Running: $description')
      ..detail('command: $command \n');

    final progress = logger.progress(description);

    final result = await run(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      listen: false,
    );

    if (result.exitCode != 0) {
      progress.fail(description);

      throw FvmProcessRunnerException(
        'Could not complete: $description',
        result: result,
      );
    }

    progress.complete(description);

    return result;
  }
}
