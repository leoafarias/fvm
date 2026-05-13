import 'dart:async';
import 'dart:io';

import 'base_service.dart';

class ProcessService extends ContextualService {
  ProcessService(super.context);

  /// Long-running children we should clean up if we receive a termination
  /// signal. Short-lived blocking spawns (Process.run / Process.runSync) don't
  /// need tracking because they cannot outlive the caller.
  final Set<Process> _liveChildren = <Process>{};

  void _track(Process child) {
    _liveChildren.add(child);
    unawaited(
      child.exitCode.whenComplete(() => _liveChildren.remove(child)),
    );
  }

  /// Sends [signal] to every tracked child, waits up to [graceful] for them to
  /// exit, then SIGKILLs any survivors.
  ///
  /// This handles catchable termination of `fvm` itself (Ctrl-C / SIGINT,
  /// `kill <pid>` / SIGTERM, terminal close / SIGHUP). It does NOT — and
  /// cannot in pure Dart — handle SIGKILL of the fvm process, which is
  /// uncatchable and leaves descendants orphaned to init.
  Future<void> killAllChildren({
    ProcessSignal signal = ProcessSignal.sigterm,
    Duration graceful = const Duration(seconds: 2),
  }) async {
    if (_liveChildren.isEmpty) return;
    final snapshot = List<Process>.from(_liveChildren);
    for (final p in snapshot) {
      _safeKill(p, signal);
    }
    await Future.any([
      Future.wait(snapshot.map((p) => p.exitCode)),
      Future<void>.delayed(graceful),
    ]);
    for (final p in _liveChildren) {
      _safeKill(p, ProcessSignal.sigkill);
    }
  }

  void _safeKill(Process p, ProcessSignal signal) {
    try {
      p.kill(signal);
    } catch (_) {
      // Process may have already exited between snapshot and kill; ignore.
    }
  }

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
    bool runInShell = true,
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
    // Track the long-running proxy child so signal handlers can clean it up.
    _track(process);

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

  /// Public API for other services (e.g. GitService) to register a long-running
  /// process they spawned directly via `Process.start`, so it participates in
  /// signal-forwarded cleanup.
  void register(Process process) => _track(process);
}

extension ProcessResultX on ProcessResult {
  // Note: `this.exitCode` is intentional -- without the explicit receiver,
  // Dart resolves to `dart:io`'s top-level `exitCode` getter.
  bool get isSuccess => this.exitCode == 0;

  bool get isFailure => this.exitCode != 0;
}
