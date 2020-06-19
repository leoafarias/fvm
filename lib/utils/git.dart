import 'dart:io';

import 'package:io/io.dart';

/// Run Git command
Future<void> runGitProcess(List<String> args, {String workingDirectory}) async {
  final manager = ProcessManager();

  final pr =
      await manager.spawn('git', args, workingDirectory: workingDirectory);
  // final exitCode = await pr.exitCode;

  // exit(exitCode);
}

/// Run Git command
Future<ProcessResult> runGit(List<String> args,
    {bool throwOnError = true, String workingDirectory}) async {
  final pr = await Process.run('git', args,
      workingDirectory: workingDirectory, runInShell: true);

  if (throwOnError) {
    _throwIfProcessFailed(pr, 'git', args);
  }
  return pr;
}

void _throwIfProcessFailed(
    ProcessResult pr, String process, List<String> args) {
  assert(pr != null);
  if (pr.exitCode != 0) {
    final values = {
      'Standard out': pr.stdout.toString().trim(),
      'Standard error': pr.stderr.toString().trim()
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
