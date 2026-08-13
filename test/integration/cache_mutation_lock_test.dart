@Tags(['git'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
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

final class _CorruptCloneGitService extends GitService {
  _CorruptCloneGitService(super.context);

  @override
  Future<void> ensureBareCacheIfPresent() async {}

  @override
  Future<void> updateLocalMirror() async {}

  @override
  Future<T> withPreparedGitCacheForClone<T>(
    Future<T> Function() cloneAction,
  ) async {
    throw ProcessException('git', const ['clone'], 'bad object', 128);
  }
}

final class _DeferredMaintenanceFailureFlutterService
    extends FakeFlutterService {
  _DeferredMaintenanceFailureFlutterService(super.context);

  final maintenanceStarted = Completer<void>();
  final releaseMaintenance = Completer<void>();

  @override
  Future<void> install(
    FlutterVersion version, {
    bool useGitCache = true,
    void Function(GitCacheMaintenance maintenance)?
        onGitCacheMaintenanceDeferred,
  }) async {
    await super.install(
      version,
      useGitCache: useGitCache,
      onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
    );
    if (!get<GitService>().isGitCacheLockHeld ||
        onGitCacheMaintenanceDeferred == null) {
      throw StateError('Expected Git-cache maintenance to be deferred.');
    }
    onGitCacheMaintenanceDeferred(
      GitCacheMaintenance.removeCorruptedMirror,
    );
  }

  @override
  Future<void> performDeferredGitCacheMaintenance(
    GitCacheMaintenance maintenance,
  ) async {
    maintenanceStarted.complete();
    await releaseMaintenance.future;
    throw const GitCacheDependentSdkRemovalException(
      'Intentional deferred maintenance failure.',
    );
  }
}

final class _TrackingInvalidMirrorGitService extends GitService {
  _TrackingInvalidMirrorGitService(super.context);

  int completedInvalidMirrorRevalidations = 0;

  @override
  Future<bool> removeLocalMirrorIfInvalid({
    bool requireSuccess = false,
    void Function(FileSystemException error)? onFinalError,
  }) async {
    final wasInvalid = await super.removeLocalMirrorIfInvalid(
      requireSuccess: requireSuccess,
      onFinalError: onFinalError,
    );
    completedInvalidMirrorRevalidations++;
    return wasInvalid;
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

Future<void> _waitForLog(Logger logger, String message) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!logger.outputs.any((output) => output.contains(message))) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for log message "$message".');
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  group('SDK cache mutation process locks', () {
    late Directory tempDir;
    late Directory remote;
    late String fvmDir;
    late String gitCachePath;
    late FvmContext context;
    final workers = <_WorkerProcess>[];

    FvmContext createContext({
      bool useGitCache = false,
      bool skipInput = false,
      String? flutterUrl,
      Map<Type, Generator>? generators,
    }) {
      return FvmContext.create(
        isTest: true,
        skipInput: skipInput,
        workingDirectoryOverride: tempDir.path,
        appConfigPath: path.join(tempDir.path, 'config', '.fvmrc'),
        configOverrides: AppConfig(
          cachePath: fvmDir,
          gitCachePath: gitCachePath,
          flutterUrl: flutterUrl ?? Uri.file(remote.path).toString(),
          useGitCache: useGitCache,
          disableUpdateCheck: true,
        ),
        generatorsOverride: generators,
      );
    }

    setUp(() async {
      tempDir = createTempDir('fvm_cache_mutation_lock');
      remote = await _createFakeFlutterRemote(tempDir);
      fvmDir = path.join(tempDir.path, 'fvm');
      gitCachePath = path.join(tempDir.path, 'cache.git');
      context = createContext();
    });

    tearDown(() async {
      final testWorkers = workers.toList(growable: false);
      workers.clear();
      for (final worker in testWorkers) {
        worker.process.kill(ProcessSignal.sigkill);
      }
      await Future.wait(testWorkers.map((worker) => worker.wait())).timeout(
        const Duration(seconds: 10),
      );
    });

    Future<_WorkerProcess> startWorker({
      required String signalName,
      required String delay,
      String version = 'master',
      String operation = 'install',
      bool useGitCache = false,
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
        operation,
        fvmDir,
        gitCachePath,
        Uri.file(remote.path).toString(),
        version,
        signalPath,
        delay,
        '$useGitCache',
      ]);
      final worker = _WorkerProcess(process);
      workers.add(worker);
      await _waitForFile(File('$signalPath.started'));

      return worker;
    }

    test(
      'deferred corruption cleanup still runs when remote fallback fails',
      () async {
        final cacheDir = Directory(gitCachePath)..createSync(recursive: true);
        File(path.join(cacheDir.path, 'corrupt-object'))
            .writeAsStringSync('corrupt');
        final missingRemote = path.join(tempDir.path, 'missing-remote.git');
        final failingContext = createContext(
          useGitCache: true,
          flutterUrl: Uri.file(missingRemote).toString(),
          generators: {
            GitService: (context) => _CorruptCloneGitService(context),
          },
        );

        await expectLater(
          EnsureCacheWorkflow(failingContext).call(
            FlutterVersion.parse('master'),
            shouldInstall: true,
          ),
          throwsA(isA<AppException>()),
        );

        expect(
          cacheDir.existsSync(),
          isFalse,
          reason:
              'corruption cleanup must run after installation locks unwind, '
              'even when the remote fallback also fails',
        );
      },
    );

    test(
      'stale deferred corruption cleanup preserves a healthy replacement',
      () async {
        final gitCacheContext = createContext(useGitCache: true);
        await gitCacheContext.get<GitService>().updateLocalMirror();

        await gitCacheContext
            .get<FlutterService>()
            .performDeferredGitCacheMaintenance(
              GitCacheMaintenance.removeCorruptedMirror,
            );

        expect(Directory(gitCachePath).existsSync(), isTrue);
        expect(await isBareGitRepository(gitCachePath), isTrue);
      },
    );

    test(
      'deferred maintenance failure preserves an SDK observed after install',
      () async {
        final maintenanceContext = createContext(
          useGitCache: true,
          generators: {
            FlutterService: (context) =>
                _DeferredMaintenanceFailureFlutterService(context),
            GitService: (context) => FakeGitService(context),
          },
        );
        final flutterService = maintenanceContext.get<FlutterService>()
            as _DeferredMaintenanceFailureFlutterService;
        final version = FlutterVersion.parse('3.10.0');
        final installation = EnsureCacheWorkflow(maintenanceContext).call(
          version,
          shouldInstall: true,
        );

        await flutterService.maintenanceStarted.future.timeout(
          const Duration(seconds: 10),
        );
        final observed = await EnsureCacheWorkflow(maintenanceContext).call(
          version,
          shouldInstall: true,
        );
        final observedMarker = File(
          path.join(observed.directory, 'observed-after-install'),
        )..writeAsStringSync('keep');
        final installationFailure = expectLater(
          installation,
          throwsA(isA<GitCacheDependentSdkRemovalException>()),
        );

        flutterService.releaseMaintenance.complete();
        await installationFailure;

        expect(maintenanceContext.get<CacheService>().getVersion(version),
            isNotNull);
        expect(observedMarker.existsSync(), isTrue);
      },
    );

    test(
      'deferred corruption cleanup revalidates a missing mirror under locks',
      () async {
        final cleanupContext = createContext(
          useGitCache: true,
          generators: {
            GitService: (context) => _TrackingInvalidMirrorGitService(context),
          },
        );
        final gitService = cleanupContext.get<GitService>()
            as _TrackingInvalidMirrorGitService;

        expect(Directory(gitCachePath).existsSync(), isFalse);
        await cleanupContext
            .get<FlutterService>()
            .performDeferredGitCacheMaintenance(
              GitCacheMaintenance.removeCorruptedMirror,
            );

        expect(gitService.completedInvalidMirrorRevalidations, 1);
      },
    );

    test(
      'git-cache clone acquires cache then Git then version locks',
      () async {
        final gitCacheContext = createContext(
          useGitCache: true,
          generators: {Logger: (context) => TestLogger(context)},
        );
        await gitCacheContext.get<GitService>().updateLocalMirror();

        final releaseGitLock = path.join(tempDir.path, 'release-git-lock');
        final gitLockHolder = await startWorker(
          operation: 'hold-git-lock',
          signalName: 'git-lock-held',
          delay: 'wait:$releaseGitLock',
          useGitCache: true,
        );
        await _waitForFile(File(path.join(tempDir.path, 'git-lock-held')));

        final installer = await startWorker(
          operation: 'install-without-preflight',
          signalName: 'git-cache-installer',
          delay: '0',
          useGitCache: true,
        );
        await _waitForFile(
          File(
            path.join(tempDir.path, 'git-cache-installer.git-lock-wait'),
          ),
        );

        final releaseVersionProbe = path.join(
          tempDir.path,
          'release-version-probe',
        );
        final versionProbe = await startWorker(
          operation: 'hold-version-lock',
          signalName: 'version-probe-acquired',
          delay: 'wait:$releaseVersionProbe',
          useGitCache: true,
        );
        await _waitForFile(
          File(path.join(tempDir.path, 'version-probe-acquired.attempting')),
        );
        final versionProbeAcquired = _waitForFile(
          File(path.join(tempDir.path, 'version-probe-acquired')),
        );

        await versionProbeAcquired.timeout(
          const Duration(seconds: 5),
          onTimeout: () => fail(
            'The install acquired its version lock before the contended Git '
            'lock.',
          ),
        );
        File(releaseVersionProbe).writeAsStringSync('go');
        final probeResult = await versionProbe.wait();
        expect(
          probeResult.exitCode,
          ExitCode.success.code,
          reason: probeResult.stderr,
        );

        final releaseMaintenanceProbe = path.join(
          tempDir.path,
          'release-maintenance-probe',
        );
        final maintenanceProbe = await startWorker(
          operation: 'hold-all-versions-lock',
          signalName: 'maintenance-probe-acquired',
          delay: 'wait:$releaseMaintenanceProbe',
        );
        await _waitForFile(
          File(
            path.join(tempDir.path, 'maintenance-probe-acquired.attempting'),
          ),
        );
        await _waitForFile(
          File(
            path.join(
              tempDir.path,
              'maintenance-probe-acquired.cache-lock-wait',
            ),
          ),
        );

        File(releaseGitLock).writeAsStringSync('go');
        final gitHolderResult = await gitLockHolder.wait();
        expect(
          gitHolderResult.exitCode,
          ExitCode.success.code,
          reason: gitHolderResult.stderr,
        );

        final installResult = await installer.wait().timeout(
              const Duration(seconds: 15),
            );
        expect(
          installResult.exitCode,
          ExitCode.success.code,
          reason: 'stdout: ${installResult.stdout}\n'
              'stderr: ${installResult.stderr}',
        );

        await _waitForFile(
          File(path.join(tempDir.path, 'maintenance-probe-acquired')),
        );
        File(releaseMaintenanceProbe).writeAsStringSync('go');
        final maintenanceResult = await maintenanceProbe.wait();
        expect(
          maintenanceResult.exitCode,
          ExitCode.success.code,
          reason: maintenanceResult.stderr,
        );
      },
    );

    test(
      'legacy git-cache migration waits for a dependent SDK version lock before deleting it',
      () async {
        final gitCacheContext = createContext(
          useGitCache: true,
          generators: {Logger: (context) => TestLogger(context)},
        );
        await runGitCommand([
          'clone',
          remote.path,
          gitCachePath,
        ]);

        final dependentVersion = FlutterVersion.parse('broken');
        final dependentDir = gitCacheContext
            .get<CacheService>()
            .getVersionCacheDir(dependentVersion);
        final alternatesFile = File(
          path.join(
            dependentDir.path,
            '.git',
            'objects',
            'info',
            'alternates',
          ),
        )..createSync(recursive: true);
        alternatesFile.writeAsStringSync(
          '${path.join(gitCachePath, '.git', 'objects')}\n',
        );
        File(path.join(dependentDir.path, 'version'))
            .writeAsStringSync('broken\n');

        final releaseDependentLock = path.join(
          tempDir.path,
          'release-dependent-lock',
        );
        final dependentLockHolder = await startWorker(
          operation: 'hold-version-lock',
          signalName: 'dependent-lock-held',
          delay: 'wait:$releaseDependentLock',
          version: dependentVersion.name,
          useGitCache: true,
        );
        await _waitForFile(
          File(path.join(tempDir.path, 'dependent-lock-held')),
        );

        final migration =
            gitCacheContext.get<GitService>().ensureBareCacheIfPresent();

        await _waitForLog(
          gitCacheContext.get<Logger>(),
          'Waiting for SDK cache maintenance lock',
        );
        expect(dependentDir.existsSync(), isTrue);

        File(releaseDependentLock).writeAsStringSync('go');
        final holderResult = await dependentLockHolder.wait();
        expect(
          holderResult.exitCode,
          ExitCode.success.code,
          reason: holderResult.stderr,
        );

        await migration.timeout(const Duration(seconds: 15));
        expect(dependentDir.existsSync(), isFalse);
        expect(await isBareGitRepository(gitCachePath), isTrue);
      },
    );

    test(
      'version-mismatch move waits for the destination SDK version lock',
      () async {
        final mismatchContext = createContext(
          generators: {
            FlutterService: (context) => FakeFlutterService(context),
            Logger: (context) => TestLogger(context)
              ..setSelectResponse('How would you like to resolve this?', 0),
          },
        );
        mismatchContext.environment.removeWhere(
          (key, _) => kCiEnvironmentVariables.contains(key),
        );
        expect(mismatchContext.isCI, isFalse);
        expect(mismatchContext.skipInput, isFalse);
        final expectedVersion = FlutterVersion.parse('3.10.0');
        final actualVersion = FlutterVersion.parse('3.10.5');
        final sourceDir = mismatchContext
            .get<CacheService>()
            .getVersionCacheDir(expectedVersion);
        final targetDir = mismatchContext
            .get<CacheService>()
            .getVersionCacheDir(actualVersion);

        FakeFlutterSdkFixture.install(
          mismatchContext,
          expectedVersion,
          state: FakeFlutterSdkState.versionMismatch,
          mismatchCachedVersion: actualVersion.name,
        );
        final sourceMarker = File(path.join(sourceDir.path, 'mismatch-marker'))
          ..writeAsStringSync('move me');

        final releaseTargetLock = path.join(
          tempDir.path,
          'release-mismatch-target-lock',
        );
        final targetLockHolder = await startWorker(
          operation: 'hold-version-lock',
          signalName: 'mismatch-target-lock-held',
          delay: 'wait:$releaseTargetLock',
          version: actualVersion.name,
        );
        await _waitForFile(
          File(path.join(tempDir.path, 'mismatch-target-lock-held')),
        );

        final repair = EnsureCacheWorkflow(mismatchContext).call(
          expectedVersion,
          shouldInstall: true,
        );

        await _waitForLog(
          mismatchContext.get<Logger>(),
          'Waiting for SDK version cache lock',
        );
        expect(sourceMarker.existsSync(), isTrue);
        expect(targetDir.existsSync(), isFalse);

        File(releaseTargetLock).writeAsStringSync('go');
        final holderResult = await targetLockHolder.wait();
        expect(
          holderResult.exitCode,
          ExitCode.success.code,
          reason: holderResult.stderr,
        );

        final result = await repair.timeout(const Duration(seconds: 15));
        expect(result.name, expectedVersion.name);
        expect(sourceDir.existsSync(), isTrue);
        expect(
          File(path.join(targetDir.path, 'mismatch-marker')).readAsStringSync(),
          'move me',
        );
      },
    );

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

        await _waitForFile(
          File(path.join(tempDir.path, 'second-ready.version-lock-wait')),
        );
        expect(File(path.join(tempDir.path, 'second-ready')).existsSync(),
            isFalse);
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
      await _waitForLog(
        context.get<Logger>(),
        'Waiting for SDK version cache lock',
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
      await _waitForLog(
        removeContext.get<Logger>(),
        'Waiting for SDK cache maintenance lock',
      );

      File(path.join(tempDir.path, 'release-install')).writeAsStringSync('go');
      final installResult = await installer.wait();
      expect(installResult.exitCode, 0, reason: installResult.stderr);
      expect(await removal, ExitCode.success.code);
      expect(Directory(context.versionsCachePath).existsSync(), isFalse);
    });

    test('exception unwinding releases locks while the worker remains alive',
        () async {
      final failing = await startWorker(
        operation: 'install-catch-failure',
        signalName: 'failing-ready',
        delay: 'fail-wait:${path.join(tempDir.path, 'release-failure')}',
      );
      await _waitForFile(File(path.join(tempDir.path, 'failing-ready')));

      final next = await startWorker(
        signalName: 'next-ready',
        delay: '0',
      );
      final nextResult = next.wait();
      await _waitForFile(
        File(path.join(tempDir.path, 'next-ready.version-lock-wait')),
      );

      File(path.join(tempDir.path, 'release-failure')).writeAsStringSync('go');
      await _waitForFile(
        File(path.join(tempDir.path, 'failing-ready.failure-caught')),
      );
      await _waitForFile(File(path.join(tempDir.path, 'next-ready')));
      File(path.join(tempDir.path, 'failing-ready.allow-exit'))
          .writeAsStringSync('go');

      final failure = await failing.wait();
      expect(failure.exitCode, 42, reason: failure.stderr);
      final success = await nextResult.timeout(const Duration(seconds: 10));
      expect(success.exitCode, 0, reason: success.stderr);
    });

    test(
      'locks release when the holding child process is terminated',
      () async {
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
        await _waitForFile(
          File(path.join(tempDir.path, 'next-ready.version-lock-wait')),
        );

        expect(holding.process.kill(ProcessSignal.sigkill), isTrue);
        final killed = await holding.wait();
        expect(killed.exitCode, isNot(0));

        final success = await nextResult.timeout(const Duration(seconds: 10));
        expect(success.exitCode, 0, reason: success.stderr);
      },
      skip: Platform.isWindows
          ? 'SIGKILL process-termination semantics are POSIX-only.'
          : false,
    );
  });
}
