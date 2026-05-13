#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/utils/context.dart';

Future<void> main(List<String> args) async {
  final updatableArgs = [...args];
  final skipInput = updatableArgs.remove('--fvm-skip-input');
  final controller = FvmContext.create(skipInput: skipInput);

  // Forward catchable termination signals to children so a Ctrl-C, git
  // pre-commit hook cancellation, or `kill <fvm-pid>` doesn't leave
  // long-running grandchildren (flutter, dart, dependency_validator, …)
  // pegging a CPU at 100% after the parent exits.
  //
  // SIGHUP isn't representable on Windows.
  final signals = <ProcessSignal>[
    ProcessSignal.sigint,
    ProcessSignal.sigterm,
    if (!Platform.isWindows) ProcessSignal.sighup,
  ];
  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  for (final sig in signals) {
    subscriptions.add(sig.watch().listen((_) async {
      try {
        await controller.get<ProcessService>().killAllChildren();
      } catch (_) {
        // Best effort — never block exit on cleanup failure.
      }
      // 128 + signal number is the conventional shell convention. We use 130
      // (SIGINT) as a reasonable default since we don't distinguish here.
      await _flushThenExit(130);
    }));
  }

  try {
    final exitCode = await FvmCommandRunner(controller).run(updatableArgs);
    try {
      await controller.get<ProcessService>().killAllChildren();
    } catch (_) {}
    await _flushThenExit(exitCode);
  } finally {
    for (final sub in subscriptions) {
      unawaited(sub.cancel());
    }
  }
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then((_) => exit(status));
}
