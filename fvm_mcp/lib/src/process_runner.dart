import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';

class ProcessRunner {
  final String exe;
  final bool hasSkipInput;
  final ProcessStartMode startMode;
  final bool runInShell;

  void Function(ProgressNotification notification)? _notify;

  ProcessRunner({
    required this.exe,
    required this.hasSkipInput,
    ProcessStartMode? startMode,
    bool? runInShell,
  })  : startMode = startMode ?? ProcessStartMode.normal,
        runInShell = runInShell ?? Platform.isWindows;

  Future<CallToolResult> _runCore(
    List<String> args, {
    String? cwd,
    Duration timeout = const Duration(minutes: 2),
    String? progressLabel,
    MetaWithProgressToken? meta,
  }) async {
    final proc = await Process.start(
      exe,
      args,
      workingDirectory: cwd,
      runInShell: runInShell,
      mode: startMode,
    );

    final outBuf = StringBuffer();
    final errBuf = StringBuffer();

    final outDone = proc.stdout
        .transform(utf8.decoder)
        .forEach(outBuf.write)
        .catchError((_) {});
    final errDone = proc.stderr
        .transform(utf8.decoder)
        .forEach(errBuf.write)
        .catchError((_) {});

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
      proc.kill(
        Platform.isWindows ? ProcessSignal.sigkill : ProcessSignal.sigterm,
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      proc.kill(ProcessSignal.sigkill);
      code = -1;
    } finally {
      // Let stdio drain after exit/kill; don't cancel streams early.
      try {
        final wait = Future.wait([outDone, errDone]);
        if (timedOut) {
          await wait.timeout(const Duration(seconds: 2));
        } else {
          await wait;
        }
      } catch (_) {
        // Best-effort: if streams don't close, proceed with what we have.
      }
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

  void bindNotifier(void Function(ProgressNotification notification) notify) {
    _notify = notify;
  }

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
      if (hasSkipInput) '--fvm-skip-input',
      ...args,
    ];

    return _runCore(
      full,
      cwd: cwd,
      timeout: timeout,
      progressLabel: progressLabel,
      meta: meta,
    );
  }
}
