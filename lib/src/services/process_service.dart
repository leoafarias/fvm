import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/exceptions.dart';
import 'base_service.dart';

class ProcessService extends ContextualService {
  /// Environment variables that bind a git invocation to a specific
  /// repository (the set reported by `git rev-parse --local-env-vars`).
  ///
  /// These override git's repository discovery, and git hooks export some
  /// of them (linked-worktree hooks export an absolute `GIT_DIR`), so
  /// inheriting them would redirect FVM's git commands away from the
  /// directory they run in. Transport and authentication variables such
  /// as `GIT_SSH_COMMAND` and `GIT_ASKPASS` are preserved.
  static const _gitRepositoryScopedEnvVars = {
    'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_CONFIG',
    'GIT_CONFIG_PARAMETERS',
    'GIT_CONFIG_COUNT',
    'GIT_OBJECT_DIRECTORY',
    'GIT_DIR',
    'GIT_WORK_TREE',
    'GIT_IMPLICIT_WORK_TREE',
    'GIT_GRAFT_FILE',
    'GIT_INDEX_FILE',
    'GIT_NO_REPLACE_OBJECTS',
    'GIT_REPLACE_REF_BASE',
    'GIT_PREFIX',
    'GIT_SHALLOW_FILE',
    'GIT_COMMON_DIR',
  };

  const ProcessService(super.context);

  /// Whether [command] operates on git repositories FVM manages: git
  /// itself, and the Flutter/Dart SDK tools (which spawn their own git
  /// subprocesses). Commands with other names keep their environment.
  static bool _needsGitEnvScrubbing(String command) {
    final name = p.basenameWithoutExtension(command).toLowerCase();

    return name == 'git' || name == 'flutter' || name == 'dart';
  }

  Map<String, String> _scrubbedGitEnvironment(
    Map<String, String>? environment,
  ) {
    return {...context.environment, ...?environment}..removeWhere(
        (key, _) => _gitRepositoryScopedEnvVars.contains(key.toUpperCase()),
      );
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
    bool? runInShell,
  }) async {
    logger
      ..debug('')
      ..debug('Running: $command')
      ..debug('');
    final scrubGitEnv = _needsGitEnvScrubbing(command);
    final effectiveEnvironment =
        scrubGitEnv ? _scrubbedGitEnvironment(environment) : environment;
    ProcessResult processResult;
    if (!echoOutput || context.isTest) {
      processResult = await Process.run(
        command,
        args,
        workingDirectory: workingDirectory,
        environment: effectiveEnvironment,
        includeParentEnvironment: !scrubGitEnv,
        runInShell: runInShell ?? true,
      );

      if (throwOnError) {
        _throwIfProcessFailed(processResult, command, args);
      }

      return processResult;
    }
    StreamSubscription<ProcessSignal>? sigintSubscription;
    StreamSubscription<ProcessSignal>? sigtermSubscription;
    Process? activeProcess;
    var interrupted = false;
    var terminated = false;
    final forwardSigterm = !Platform.isWindows &&
        context.environment['FVM_FORWARD_SIGTERM'] == 'true';
    if (forwardSigterm) {
      // CI and process supervisors may signal only FVM, rather than the
      // terminal's foreground group. Keep the child owned until it exits.
      sigtermSubscription = ProcessSignal.sigterm.watch().listen((_) {
        terminated = true;
        activeProcess?.kill(ProcessSignal.sigterm);
      });
    }
    if (!Platform.isWindows && context.stdinHasTerminal) {
      sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
        interrupted = true;
      });
    }

    final Process process;
    final int processExitCode;
    try {
      process = await Process.start(
        command,
        args,
        workingDirectory: workingDirectory,
        environment: effectiveEnvironment,
        includeParentEnvironment: !scrubGitEnv,
        // PID-only forwarding must reach the executable, not an intermediary
        // POSIX shell. Otherwise preserve the existing shell launch behavior.
        runInShell: runInShell ?? !forwardSigterm,
        mode: ProcessStartMode.inheritStdio,
      );

      // Read by the signal callback after the asynchronous spawn completes.
      // ignore: avoid-unused-assignment
      activeProcess = process;
      // A signal received while Process.start was pending must not be lost.
      if (terminated) {
        process.kill(ProcessSignal.sigterm);
      }
      if (interrupted) {
        process.kill(ProcessSignal.sigint);
      }
      processExitCode = await process.exitCode;
    } finally {
      // Stop forwarding before yielding to any other subscription cleanup.
      await sigtermSubscription?.cancel();
      await sigintSubscription?.cancel();
    }

    if (terminated) {
      throw ForceExit('', 128 + ProcessSignal.sigterm.signalNumber);
    }
    if (interrupted) {
      throw ForceExit('', 128 + ProcessSignal.sigint.signalNumber);
    }

    processResult = ProcessResult(process.pid, processExitCode, null, null);
    if (throwOnError) {
      _throwIfProcessFailed(processResult, command, args);
    }

    return processResult;
  }
}

extension ProcessResultX on ProcessResult {
  // Note: `this.exitCode` is intentional -- without the explicit receiver,
  // Dart resolves to `dart:io`'s top-level `exitCode` getter.
  bool get isSuccess => this.exitCode == 0;

  bool get isFailure => this.exitCode != 0;
}
