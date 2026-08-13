import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/cache_mutation_lock.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/utils/process_lock.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:path/path.dart' as path;

const _installOperation = 'install';
const _installWithoutPreflightOperation = 'install-without-preflight';
const _holdGitLockOperation = 'hold-git-lock';
const _holdVersionLockOperation = 'hold-version-lock';
const _holdAllVersionsLockOperation = 'hold-all-versions-lock';

void _writeSignal(String signalPath) {
  final signal = File(signalPath);
  signal.parent.createSync(recursive: true);
  signal.writeAsStringSync('ready');
}

Future<void> _waitForFile(String filePath) async {
  final file = File(filePath);
  while (!file.existsSync()) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

final class _SignalingLogger extends Logger {
  _SignalingLogger(super.context, this.signalPath);

  final String signalPath;

  @override
  void debug([String message = '']) {
    super.debug(message);
    if (message.contains('Waiting for git cache lock')) {
      _writeSignal('$signalPath.git-lock-wait');
    }
  }
}

final class _NoOpPreflightGitService extends GitService {
  _NoOpPreflightGitService(super.context, this.signalPath);

  final String signalPath;

  @override
  Future<void> ensureBareCacheIfPresent() async {}

  @override
  Future<void> updateLocalMirror() async {}

  @override
  Future<T> withGitCacheLock<T>(Future<T> Function() action) {
    _writeSignal('$signalPath.git-lock-attempt');

    return super.withGitCacheLock(action);
  }
}

final class _ControllableFlutterService extends FlutterService {
  const _ControllableFlutterService(
    super.context, {
    required this.signalPath,
    required this.delay,
    required this.fail,
    this.releasePath,
  });

  final String signalPath;
  final Duration delay;
  final bool fail;
  final String? releasePath;

  @override
  Future<void> install(
    FlutterVersion version, {
    bool useGitCache = true,
    bool gitCacheLockHeld = false,
    bool deferGitCacheMaintenance = false,
    void Function(GitCacheMaintenance maintenance)?
        onGitCacheMaintenanceDeferred,
  }) async {
    _writeSignal(signalPath);

    if (releasePath case final releasePath?) {
      await _waitForFile(releasePath);
    } else {
      await Future<void>.delayed(delay);
    }
    if (fail) {
      throw const AppException('Intentional cache mutation worker failure.');
    }

    await super.install(
      version,
      useGitCache: useGitCache,
      gitCacheLockHeld: gitCacheLockHeld,
      deferGitCacheMaintenance: deferGitCacheMaintenance,
      onGitCacheMaintenanceDeferred: onGitCacheMaintenanceDeferred,
    );
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 8) {
    stderr.writeln(
      'Usage: cache_mutation_worker.dart '
      '<operation> <fvm-dir> <git-cache> <remote-url> <version> <signal> '
      '<delay-ms|wait:path|fail-wait:path> <use-git-cache>',
    );
    exitCode = 64;

    return;
  }

  final operation = args[0];
  final fvmDir = args[1];
  final gitCachePath = args[2];
  final flutterUrl = args[3];
  final version = FlutterVersion.parse(args[4]);
  final signalPath = args[5];
  final control = args[6];
  final useGitCache = bool.parse(args[7]);
  final shouldFail = control.startsWith('fail-wait:');
  final releasePath = switch (control) {
    final value when value.startsWith('wait:') =>
      value.substring('wait:'.length),
    final value when value.startsWith('fail-wait:') =>
      value.substring('fail-wait:'.length),
    _ => null,
  };
  final delayMilliseconds = releasePath == null ? int.parse(control) : 0;
  final delay = Duration(milliseconds: delayMilliseconds);

  final context = FvmContext.create(
    isTest: true,
    workingDirectoryOverride: path.dirname(fvmDir),
    appConfigPath: path.join(fvmDir, '.worker-config'),
    configOverrides: AppConfig(
      cachePath: fvmDir,
      gitCachePath: gitCachePath,
      flutterUrl: flutterUrl,
      useGitCache: useGitCache,
      disableUpdateCheck: true,
    ),
    generatorsOverride: {
      FlutterService: (context) => _ControllableFlutterService(
            context,
            signalPath: signalPath,
            delay: delay,
            fail: shouldFail,
            releasePath: releasePath,
          ),
      Logger: (context) => _SignalingLogger(context, signalPath),
      if (operation == _installWithoutPreflightOperation)
        GitService: (context) => _NoOpPreflightGitService(context, signalPath),
    },
  );

  try {
    _writeSignal('$signalPath.started');
    switch (operation) {
      case _installOperation:
      case _installWithoutPreflightOperation:
        await EnsureCacheWorkflow(context).call(version, shouldInstall: true);
        stdout.writeln('installed');
      case _holdGitLockOperation:
        if (releasePath == null) {
          throw const FormatException(
            'hold-git-lock requires a wait:<path> control',
          );
        }
        _writeSignal('$signalPath.attempting');
        await withProcessFileLock(
          lockFile: File('$gitCachePath.lock'),
          lockMode: FileLock.exclusive,
          description: 'git cache',
          logger: context.get(),
          action: () async {
            _writeSignal(signalPath);
            await _waitForFile(releasePath);
          },
        );
        stdout.writeln('git lock released');
      case _holdVersionLockOperation:
        if (releasePath == null) {
          throw const FormatException(
            'hold-version-lock requires a wait:<path> control',
          );
        }
        _writeSignal('$signalPath.attempting');
        await withVersionCacheMutationLock(context, version, () async {
          _writeSignal(signalPath);
          await _waitForFile(releasePath);
        });
        stdout.writeln('version lock released');
      case _holdAllVersionsLockOperation:
        if (releasePath == null) {
          throw const FormatException(
            'hold-all-versions-lock requires a wait:<path> control',
          );
        }
        _writeSignal('$signalPath.attempting');
        await withAllVersionsCacheMutationLock(context, () async {
          _writeSignal(signalPath);
          await _waitForFile(releasePath);
        });
        stdout.writeln('all-versions lock released');
      default:
        throw FormatException('Unknown worker operation: $operation');
    }
  } on Exception catch (error, stackTrace) {
    stderr
      ..writeln(error)
      ..writeln(stackTrace);
    exitCode = 42;
  }
}
