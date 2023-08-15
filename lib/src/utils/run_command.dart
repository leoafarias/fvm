import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:process_run/cmd_run.dart';

class ProcessRunner {
  final String? workingDirectory;
  ProcessRunner({
    this.workingDirectory,
  });
  Future<ProcessResult> start(
    String command,
    List<String> arguments, {
    ProcessStartMode? mode,
  }) async {
    final process = await Process.start(
      command,
      arguments,
      workingDirectory: workingDirectory,
      mode: mode ?? ProcessStartMode.normal,
    );
    final stdoutStream =
        process.stdout.transform(utf8.decoder).asBroadcastStream();
    final stderrStream =
        process.stderr.transform(utf8.decoder).asBroadcastStream();

    await Future.wait([
      stdoutStream.listen(print).asFuture(),
      stderrStream.listen(print).asFuture(),
    ]);

    final exitCode = await process.exitCode;

    return ProcessResult(
      process.pid,
      exitCode,
      await stdoutStream.join(),
      await stderrStream.join(),
    );
  }
}

Future<ProcessResult> runProcess(
  String command, {
  String? workingDirectory,
}) async {
  List<String> arguments = command.split(' ');
  final executable = arguments.removeAt(0);

  final runner = ProcessRunner();

  return runner.start(executable, arguments);
}

Future<ProcessResult> runGit(
  String command, {
  String? workingDirectory,
}) async {
  List<String> commandParts = command.split(' ');
  return await Process.run(
    'git',
    commandParts,
    workingDirectory: workingDirectory,
  );
}

Future<ProcessResult> runFlutter(
  CacheVersion version,
  String command, {
  String? workingDirectory,
}) async {
  List<String> commandParts = command.split(' ');
  return await runExecutableArguments(
    version.flutterExec,
    commandParts,
    workingDirectory: workingDirectory,
  );
}
