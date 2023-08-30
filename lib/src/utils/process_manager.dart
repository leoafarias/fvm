import 'dart:convert';
import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:process/process.dart';

class ProcessRunner {
  static final LocalProcessManager _process = LocalProcessManager();
  ProcessRunner._();
  static Future<ProcessResult> start(
    String command, {
    /// Listen for stdout and stderr
    String? workingDirectory,
    bool listen = true,
  }) async {
    List<String> arguments = command.split(' ');
    final process = await _process.start(
      arguments,
      workingDirectory: workingDirectory,
    );
    final StringBuffer stdoutBuffer = StringBuffer();
    final StringBuffer stderrBuffer = StringBuffer();

    process.stdout.transform(utf8.decoder).listen((data) {
      stdoutBuffer.write(data);
      if (listen) {
        stdout.write('\r$data');
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      stderrBuffer.write(data);
      if (listen) {
        stderr.write('\r$data');
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

  static Future<ProcessResult> run(
    String command, {
    String? workingDirectory,
  }) async {
    List<String> arguments = command.split(' ');
    final result = await _process.run(
      arguments,
      workingDirectory: workingDirectory,
    );

    return result;
  }

  static Future<void> runOrThrow(
    String command, {
    /// Error message to throw
    /// Will also log stderr
    required String errorMessage,
    String? workingDirectory,
  }) async {
    final result = await run(
      command,
      workingDirectory: workingDirectory,
    );

    if (result.exitCode != 0) {
      throw FvmProcessRunnerException(
        errorMessage,
        result: result,
      );
    }
  }

  static Future<void> startOrThrow(
    String command, {
    /// Error message to throw
    /// Will also log stderr
    required String errorMessage,
    String? workingDirectory,
  }) async {
    final result = await start(
      command,
      workingDirectory: workingDirectory,
    );

    if (result.exitCode != 0) {
      throw FvmProcessRunnerException(
        errorMessage,
        result: result,
      );
    }
  }
}

Future<ProcessResult> runProcess(
  String command, {
  String? workingDirectory,
}) async {
  return await ProcessRunner.run(
    command,
    workingDirectory: workingDirectory,
  );
}

Future<ProcessResult> startProcess(
  String command, {
  String? workingDirectory,
  bool listen = true,
}) async {
  return ProcessRunner.start(
    command,
    workingDirectory: workingDirectory,
    listen: listen,
  );
}
