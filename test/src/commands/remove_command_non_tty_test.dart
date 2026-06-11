import 'dart:io';

import 'package:fvm/src/utils/constants.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

/// Regression guard for the non-interactive prompt hang.
///
/// `fvm remove` with no version argument reaches the cached-version selector
/// (`Logger.select` with no default selection). Before the fix, that entered
/// `interact.Select`, whose `readKey()` loop spun forever on EOF when stdin was
/// not a terminal — leaving a CPU-spinning orphan process. The fix makes
/// `FvmContext.skipInput` true when stdin is not a TTY, so `select` exits with
/// the usage code instead of blocking.
///
/// This is deliberately a black-box subprocess test: the failure mode is a
/// *hang* (a wall-clock property a unit test cannot observe), and the no-default
/// `select` path calls `exit()`, which tears down the VM and so cannot be
/// exercised in-process.
void main() {
  test(
    'remove with no arg exits instead of hanging when stdin is not a TTY',
    () async {
      final cacheDir = createTempDir('fvm_non_tty_remove');

      // Minimal cached SDK so getAllVersions() returns one entry and the
      // selector prompt is actually reached. An empty cache throws an
      // AppException before the prompt and would not exercise the hang path.
      // CacheService._looksLikeFlutterSdk treats a `version` file as an SDK.
      final versionDir = Directory('${cacheDir.path}/versions/3.10.0')
        ..createSync(recursive: true);
      File('${versionDir.path}/version').writeAsStringSync('3.10.0');

      // Inherit the parent environment so `dart`/`pub` resolve, then neutralize
      // every signal that could make skipInput true for a reason OTHER than the
      // non-TTY stdin under test:
      //   - strip CI markers     -> isCI == false
      //   - point cache at temp   -> isolated from the real FVM cache
      //   - drop legacy FVM_HOME  -> no stray real cache via the fallback
      // We never pass --fvm-skip-input, so `!stdinHasTerminal` is the only
      // remaining trigger. Without this isolation the test would pass via the
      // isCI branch in CI even if the non-TTY guard were reverted.
      final env = Map<String, String>.from(Platform.environment)
        ..removeWhere((key, _) => kCiEnvironmentVariables.contains(key))
        ..remove('FVM_HOME')
        ..['FVM_CACHE_PATH'] = cacheDir.path;

      // A spawned child's stdin is a pipe, not a terminal, so stdin.hasTerminal
      // is false. Do NOT use ProcessStartMode.inheritStdio: that would attach
      // the test runner's stdin (possibly a real TTY) and defeat the premise.
      final process = await Process.start(
        'dart',
        ['run', 'bin/main.dart', 'remove'],
        environment: env,
        workingDirectory: Directory.current.path,
      );
      await process.stdin.close(); // force EOF immediately

      // Drain output so a chatty child can never deadlock on a full pipe buffer.
      final stdoutDrained = process.stdout.drain<void>();
      final stderrDrained = process.stderr.drain<void>();

      // The timeout is a hang ceiling, not the expected runtime (a cold
      // `dart run` compile is well under this). On the fixed code the child
      // exits promptly; a reverted guard spins past the ceiling and fails here.
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      await stdoutDrained;
      await stderrDrained;

      expect(
        exitCode,
        ExitCode.usage.code, // 64: select() with no default exits in non-TTY
        reason:
            'remove must exit on a non-TTY prompt, not hang (-1 == timed out)',
      );
    },
    // Must exceed the in-test 60s hang ceiling so the framework does not kill
    // the test before the onTimeout handler can record the failure.
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
