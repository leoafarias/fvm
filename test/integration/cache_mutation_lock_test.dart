@Tags(['git'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../src/workflows/test_logger.dart';
import '../testing_utils.dart';

final class _WorkerProcess {
  _WorkerProcess(this.process) {
    _stdoutDone = process.stdout
        .transform(utf8.decoder)
        .listen(_stdout.write)
        .asFuture<void>();
    _stderrDone = process.stderr
        .transform(utf8.decoder)
        .listen(_stderr.write)
        .asFuture<void>();
  }

  final Process process;
  final StringBuffer _stdout = StringBuffer();
  final StringBuffer _stderr = StringBuffer();
  late final Future<void> _stdoutDone;
  late final Future<void> _stderrDone;

  Future<({int exitCode, String stdout, String stderr})> wait() async {
    final code = await process.exitCode;
    await _stdoutDone;
    await _stderrDone;

    return (
      exitCode: code,
      stdout: _stdout.toString(),
      stderr: _stderr.toString(),
    );
  }
}

Future<Directory> _createFakeFlutterRemote(Directory root) async {
  final remote = await createLocalRemoteRepository(
    root: root,
    name: 'flutter_remote',
  );
  final worktree = Directory(path.join(root.path, 'flutter_worktree'));
  await runGitCommand(['clone', remote.path, worktree.path]);
  await runGitCommand(
    ['config', 'user.email', 'tests@fvm.app'],
    workingDirectory: worktree.path,
  );
  await runGitCommand(
    ['config', 'user.name', 'FVM Tests'],
    workingDirectory: worktree.path,
  );

  final flutterExecutable = File(
    path.join(worktree.path, 'bin', flutterExecFileName),
  )
    ..createSync(recursive: true)
    ..writeAsStringSync('#!/usr/bin/env sh\necho fake flutter\n');
  if (!Platform.isWindows) {
    await Process.run('chmod', ['+x', flutterExecutable.path]);
  }
  File(path.join(worktree.path, 'version')).writeAsStringSync('master\n');

  await runGitCommand(['add', '.'], workingDirectory: worktree.path);
  await runGitCommand(
    ['commit', '-m', 'Add fake Flutter executable'],
    workingDirectory: worktree.path,
  );
  await runGitCommand(['push'], workingDirectory: worktree.path);

  return remote;
}

Future<void> _waitForFile(File file) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!file.existsSync()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for worker signal ${file.path}.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Future<bool> _completesWithin(Future<Object?> future, Duration duration) async {
  final sentinel = Object();
  final result = await Future.any<Object?>([
    future,
    Future<Object?>.delayed(duration, () => sentinel),
  ]);

  return !identical(result, sentinel);
}

void main() {
  group('SDK cache mutation process locks', () {
    late Directory tempDir;
    late Directory remote;
    late String fvmDir;
    late String gitCachePath;
    late FvmContext context;
    final workers = <_WorkerProcess>[];

    setUp(() async {
      tempDir = createTempDir('fvm_cache_mutation_lock');
      remote = await _createFakeFlutterRemote(tempDir);
      fvmDir = path.join(tempDir.path, 'fvm');
      gitCachePath = path.join(tempDir.path, 'cache.git');
      context = FvmContext.create(
        isTest: true,
        workingDirectoryOverride: tempDir.path,
        appConfigPath: path.join(tempDir.path, 'config', '.fvmrc'),
        configOverrides: AppConfig(
          cachePath: fvmDir,
          gitCachePath: gitCachePath,
          flutterUrl: Uri.file(remote.path).toString(),
          useGitCache: false,
          disableUpdateCheck: true,
        ),
      );
    });

    tearDown(() async {
      for (final worker in workers) {
        worker.process.kill(ProcessSignal.sigkill);
      }
    });

    Future<_WorkerProcess> startWorker({
      required String signalName,
      required String delay,
      String version = 'master',
    }) async {
      final workerPath = path.absolute(
        'test',
        'fixtures',
        'cache_mutation_worker.dart',
      );
      final packageConfig = path.absolute(
        '.dart_tool',
        'package_config.json',
      );
      final signalPath = path.join(tempDir.path, signalName);
      final process = await Process.start(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        workerPath,
        fvmDir,
        gitCachePath,
        Uri.file(remote.path).toString(),
        version,
        signalPath,
        delay,
      ]);
      final worker = _WorkerProcess(process);
      workers.add(worker);
      await _waitForFile(File('$signalPath.started'));

      return worker;
    }

    test(
      'two concurrent installs of one SDK both succeed with one valid checkout',
      () async {
        final first = await startWorker(
          signalName: 'first-ready',
          delay: 'wait:${path.join(tempDir.path, 'release-first')}',
        );
        await _waitForFile(File(path.join(tempDir.path, 'first-ready')));

        final second = await startWorker(
          signalName: 'second-ready',
          delay: '0',
        );
        final secondResult = second.wait();

        expect(
          await _completesWithin(
            secondResult,
            const Duration(milliseconds: 300),
          ),
          isFalse,
          reason: 'the second process must wait for the active install',
        );
        File(path.join(tempDir.path, 'release-first')).writeAsStringSync('go');

        final results = await Future.wait([first.wait(), secondResult]);
        for (final result in results) {
          expect(
            result.exitCode,
            ExitCode.success.code,
            reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
          );
        }

        final versionDir = context
            .get<CacheService>()
            .getVersionCacheDir(FlutterVersion.parse('master'));
        expect(
          File(
            path.join(versionDir.path, 'bin', flutterExecFileName),
          ).existsSync(),
          isTrue,
        );
        expect(
          File(path.join(fvmDir, '.locks', 'cache.lock')).existsSync(),
          isTrue,
        );
        expect(
          File(
            path.join(fvmDir, '.locks', 'versions', 'master.lock'),
          ).existsSync(),
          isTrue,
        );
        final gitCheck = await runGitCommand(
          ['rev-parse', '--is-inside-work-tree'],
          workingDirectory: versionDir.path,
        );
        expect(gitCheck.stdout.toString().trim(), 'true');
        expect(File(path.join(tempDir.path, 'second-ready')).existsSync(),
            isFalse);
      },
    );

    test('single-version removal waits for an active installation', () async {
      final installer = await startWorker(
        signalName: 'install-ready',
        delay: 'wait:${path.join(tempDir.path, 'release-install')}',
      );
      await _waitForFile(File(path.join(tempDir.path, 'install-ready')));

      final removal = FvmCommandRunner(context).run(['remove', 'master']);
      expect(
        await _completesWithin(removal, const Duration(milliseconds: 300)),
        isFalse,
      );

      File(path.join(tempDir.path, 'release-install')).writeAsStringSync('go');
      final installResult = await installer.wait();
      expect(
        installResult.exitCode,
        0,
        reason: installResult.stderr,
      );
      expect(await removal, ExitCode.success.code);
      expect(
        context
            .get<CacheService>()
            .getVersionCacheDir(FlutterVersion.parse('master'))
            .existsSync(),
        isFalse,
      );
    });

    test('remove --all waits for shared version operations', () async {
      final installer = await startWorker(
        signalName: 'install-ready',
        delay: 'wait:${path.join(tempDir.path, 'release-install')}',
      );
      await _waitForFile(File(path.join(tempDir.path, 'install-ready')));

      final removeContext = FvmContext.create(
        isTest: true,
        workingDirectoryOverride: tempDir.path,
        appConfigPath: path.join(tempDir.path, 'remove-config', '.fvmrc'),
        configOverrides: context.config,
        generatorsOverride: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse('remove all versions', true),
        },
      );
      final removal = FvmCommandRunner(removeContext).run(['remove', '--all']);
      expect(
        await _completesWithin(removal, const Duration(milliseconds: 300)),
        isFalse,
      );

      File(path.join(tempDir.path, 'release-install')).writeAsStringSync('go');
      final installResult = await installer.wait();
      expect(installResult.exitCode, 0, reason: installResult.stderr);
      expect(await removal, ExitCode.success.code);
      expect(Directory(context.versionsCachePath).existsSync(), isFalse);
    });

    test('locks release when an installation throws', () async {
      final failing = await startWorker(
        signalName: 'failing-ready',
        delay: 'fail-wait:${path.join(tempDir.path, 'release-failure')}',
      );
      await _waitForFile(File(path.join(tempDir.path, 'failing-ready')));

      final next = await startWorker(
        signalName: 'next-ready',
        delay: '0',
      );
      final nextResult = next.wait();
      expect(
        await _completesWithin(nextResult, const Duration(milliseconds: 300)),
        isFalse,
      );

      File(path.join(tempDir.path, 'release-failure')).writeAsStringSync('go');
      final failure = await failing.wait();
      expect(failure.exitCode, 42, reason: failure.stderr);
      final success = await nextResult.timeout(const Duration(seconds: 10));
      expect(success.exitCode, 0, reason: success.stderr);
    });

    test('locks release when the holding child process is terminated',
        () async {
      if (Platform.isWindows) return;

      final holding = await startWorker(
        signalName: 'holding-ready',
        delay: 'wait:${path.join(tempDir.path, 'never-release')}',
      );
      await _waitForFile(File(path.join(tempDir.path, 'holding-ready')));

      final next = await startWorker(
        signalName: 'next-ready',
        delay: '0',
      );
      final nextResult = next.wait();
      expect(
        await _completesWithin(nextResult, const Duration(milliseconds: 300)),
        isFalse,
      );

      expect(holding.process.kill(ProcessSignal.sigkill), isTrue);
      final killed = await holding.wait();
      expect(killed.exitCode, isNot(0));

      final success = await nextResult.timeout(const Duration(seconds: 10));
      expect(success.exitCode, 0, reason: success.stderr);
    });
  });
}
