import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';

class ProcessRunner {
  final String exe;
  final bool hasSkipInput;
  final ProcessStartMode startMode;

  ProcessRunner({
    required this.exe,
    required this.hasSkipInput,
    ProcessStartMode? startMode,
  }) : startMode = startMode ?? ProcessStartMode.detachedWithStdio;

  void bindNotifier(void Function(ProgressNotification notification) notify) {
    _notify = notify;
  }

  void Function(ProgressNotification notification)? _notify;

  Future<CallToolResult> runJsonApi(
    List<String> args, {
    String? cwd,
    Duration timeout = const Duration(minutes: 2),
    String? progressLabel,
    MetaWithProgressToken? meta,
  }) =>
      _runCore(
        args,
        cwd: cwd,
        timeout: timeout,
        jsonPassthrough: true,
        progressLabel: progressLabel,
        meta: meta,
      );

  Future<CallToolResult> run(
    List<String> args, {
    String? cwd,
    Duration timeout = const Duration(minutes: 2),
    String? progressLabel,
    MetaWithProgressToken? meta,
  }) {
    final full = [
      ...args,
      if (hasSkipInput) '--fvm-skip-input',
    ];
    return _runCore(
      full,
      cwd: cwd,
      timeout: timeout,
      progressLabel: progressLabel,
      meta: meta,
    );
  }

  Future<CallToolResult> _runCore(
    List<String> args, {
    String? cwd,
    Duration timeout = const Duration(minutes: 2),
    bool jsonPassthrough = false,
    String? progressLabel,
    MetaWithProgressToken? meta,
  }) async {
    final proc = await Process.start(
      exe,
      args,
      workingDirectory: cwd,
      runInShell: true,
      mode: startMode,
    );

    final outBuf = StringBuffer();
    final errBuf = StringBuffer();

    final outSub = proc.stdout.transform(utf8.decoder).listen(outBuf.write);
    final errSub = proc.stderr.transform(utf8.decoder).listen(errBuf.write);

    if (meta?.progressToken != null && progressLabel != null) {
      _notify?.call(ProgressNotification(
        progressToken: meta!.progressToken!,
        progress: 0,
        total: 100,
        message: 'Starting $progressLabel…',
      ));
    }

    int code;
    bool timedOut = false;
    try {
      code = await proc.exitCode.timeout(timeout);
    } on TimeoutException {
      timedOut = true;
      proc.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(seconds: 2));
      proc.kill(ProcessSignal.sigkill);
      code = -1;
    } finally {
      await outSub.cancel();
      await errSub.cancel();
    }

    final stdoutText = outBuf.toString().trimRight();
    final stderrText = errBuf.toString().trimRight();

    if (meta?.progressToken != null && progressLabel != null) {
      _notify?.call(ProgressNotification(
        progressToken: meta!.progressToken!,
        progress: 100,
        total: 100,
        message: timedOut ? '$progressLabel timed out' : '$progressLabel done',
      ));
    }

    if (timedOut) {
      return CallToolResult(
        isError: true,
        content: [
          TextContent(text: 'Timeout after ${timeout.inMinutes}m\n$stderrText')
        ],
      );
    }

    if (code != 0) {
      final message = stderrText.isEmpty ? 'fvm exited with $code' : stderrText;
      return CallToolResult(
        isError: true,
        content: [TextContent(text: message)],
      );
    }

    final text = stdoutText.isEmpty ? stderrText : stdoutText;
    return CallToolResult(content: [TextContent(text: text)]);
  }
}
