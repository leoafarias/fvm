#!/usr/bin/env dart

import 'dart:io';

import 'package:fvm/src/runner.dart';
import 'package:fvm/src/utils/context.dart';

Future<void> main(List<String> args) async {
  final updatableArgs = [...args];
  final skipInput = updatableArgs.remove('--fvm-skip-input');
  final controller = FvmContext.create(skipInput: skipInput);

  await _flushThenExit(
    await FvmCommandRunner(controller).run(updatableArgs),
  );
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
