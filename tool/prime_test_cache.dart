import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/utils/context.dart';

import '../test/testing_helpers/prepare_test_environment.dart';

/// Populates the bare git mirror at the path that `TestFactory.context()`
/// hands to every test in `test/testing_utils.dart`. Run from `grind
/// test-setup` so the test suite finds a warm mirror instead of paying
/// remote-clone fallbacks on every direct `FlutterService.install()` call.
Future<void> main() async {
  final cachePath = getSharedTestGitCachePath();
  Directory(cachePath).parent.createSync(recursive: true);

  final context = FvmContext.create(
    debugLabel: 'prime-test-cache',
    configOverrides: AppConfig(gitCachePath: cachePath, useGitCache: true),
    isTest: true,
  );

  stdout.writeln('Priming test git mirror at $cachePath ...');
  await context.get<GitService>().updateLocalMirror();
  stdout.writeln('Test git mirror ready.');
}
