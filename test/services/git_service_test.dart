import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

class _FakeProcessService extends ProcessService {
  _FakeProcessService(super.context);

  ProcessException? exception;
  String? lastCommand;
  List<String>? lastArgs;
  String? lastWorkingDirectory;

  @override
  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = true,
  }) async {
    lastCommand = command;
    lastArgs = args;
    lastWorkingDirectory = workingDirectory;

    if (exception != null) {
      throw exception!;
    }

    return ProcessResult(0, 0, '', '');
  }
}

void main() {
  group('GitService', () {
    late FvmContext context;
    late GitService gitService;
    late _FakeProcessService processService;

    setUp(() {
      context = TestFactory.context(
        generators: {
          ProcessService: (ctx) {
            processService = _FakeProcessService(ctx);
            return processService;
          },
        },
      );

      gitService = GitService(context);
    });

    test('throws AppException when git command fails', () async {
      context.get<ProcessService>();
      processService.exception = ProcessException(
        'git',
        ['ls-remote', '--tags', '--branches', context.flutterUrl],
        'fatal: git not found',
        127,
      );

      await expectLater(
        gitService.isGitReference('stable'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Failed to fetch git references from'),
              contains('Ensure git is installed'),
            ),
          ),
        ),
      );
    });

    test('AppException message includes flutter URL', () async {
      context.get<ProcessService>();
      processService.exception = ProcessException(
        'git',
        const ['ls-remote'],
        'fatal: unable to access',
        128,
      );

      await expectLater(
        gitService.isGitReference('beta'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains(context.flutterUrl),
          ),
        ),
      );
    });

    test('setOriginUrl delegates to ProcessService', () async {
      context.get<ProcessService>();
      const repoPath = '/tmp/fvm-test-repo';
      const url = 'https://example.com/flutter.git';

      await gitService.setOriginUrl(
        repositoryPath: repoPath,
        url: url,
      );

      expect(processService.lastCommand, equals('git'));
      expect(
        processService.lastArgs,
        equals(['remote', 'set-url', 'origin', url]),
      );
      expect(processService.lastWorkingDirectory, equals(repoPath));
    });
  });

  group('GitService cache state detection', () {
    late Directory tempDir;
    late Directory remoteDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('fvm_cache_state_test_');
      remoteDir = await createLocalRemoteRepository(
        root: tempDir,
        name: 'flutter_remote',
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates mirror when cache directory is missing', () async {
      final gitCachePath = p.join(tempDir.path, 'cache.git');
      final context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, '.fvm'),
          gitCachePath: gitCachePath,
          flutterUrl: remoteDir.path,
          useGitCache: true,
        ),
      );

      expect(Directory(gitCachePath).existsSync(), isFalse);

      final gitService = GitService(context);
      await gitService.updateLocalMirror();

      expect(Directory(gitCachePath).existsSync(), isTrue);
      expect(await isBareGitRepository(gitCachePath), isTrue);
    });

    test('skips recreation when cache is already bare mirror', () async {
      final gitCachePath = p.join(tempDir.path, 'cache.git');

      // Create a bare mirror first
      await runGitCommand(['clone', '--mirror', remoteDir.path, gitCachePath]);
      expect(await isBareGitRepository(gitCachePath), isTrue);

      final context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, '.fvm'),
          gitCachePath: gitCachePath,
          flutterUrl: remoteDir.path,
          useGitCache: true,
        ),
      );

      final gitService = GitService(context);
      await gitService.updateLocalMirror();

      // Should still be bare (not recreated)
      expect(await isBareGitRepository(gitCachePath), isTrue);
    });

    test('recreates mirror when cache directory is invalid', () async {
      final gitCachePath = p.join(tempDir.path, 'cache.git');

      // Create invalid cache (just an empty directory, not a git repo)
      Directory(gitCachePath).createSync(recursive: true);
      expect(Directory(gitCachePath).existsSync(), isTrue);

      final context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, '.fvm'),
          gitCachePath: gitCachePath,
          flutterUrl: remoteDir.path,
          useGitCache: true,
        ),
      );

      final gitService = GitService(context);
      await gitService.updateLocalMirror();

      // Should now be a valid bare mirror
      expect(await isBareGitRepository(gitCachePath), isTrue);
    });

    test('removeLocalMirror deletes git cache directory', () async {
      final gitCachePath = p.join(tempDir.path, 'cache.git');
      final context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, '.fvm'),
          gitCachePath: gitCachePath,
          flutterUrl: remoteDir.path,
          useGitCache: true,
        ),
      );

      final cacheDir = Directory(gitCachePath)..createSync(recursive: true);
      File(p.join(cacheDir.path, 'marker')).writeAsStringSync('cache');
      expect(cacheDir.existsSync(), isTrue);

      final gitService = GitService(context);
      final deleted = await gitService.removeLocalMirror();

      expect(deleted, isTrue);
      expect(cacheDir.existsSync(), isFalse);
    });

    test('waits for cache lock before running cache migration checks',
        () async {
      final gitCachePath = p.join(tempDir.path, 'cache.git');
      final lockFilePath = '$gitCachePath.lock';
      final context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, '.fvm'),
          gitCachePath: gitCachePath,
          flutterUrl: remoteDir.path,
          useGitCache: true,
        ),
      );

      final lockHelper = File(
        p.join(tempDir.path, 'hold_git_cache_lock.dart'),
      )..writeAsStringSync('''
import 'dart:io';

Future<void> main(List<String> args) async {
  final lockFile = File(args[0]);
  lockFile.parent.createSync(recursive: true);
  final handle = await lockFile.open(mode: FileMode.write);
  await handle.lock(FileLock.exclusive);
  stdout.writeln('locked');
  await stdout.flush();
  await Future<void>.delayed(Duration(milliseconds: int.parse(args[1])));
  await handle.unlock();
  await handle.close();
}
''');

      final lockProcess = await Process.start(Platform.resolvedExecutable, [
        lockHelper.path,
        lockFilePath,
        '1200',
      ]);

      final lockReady = lockProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .firstWhere((line) => line.trim() == 'locked');

      await lockReady.timeout(const Duration(seconds: 5));

      final gitService = GitService(context);
      var completed = false;
      final operation = gitService.ensureBareCacheIfPresent().then((_) {
        completed = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(completed, isFalse);

      final lockExitCode = await lockProcess.exitCode.timeout(
        const Duration(seconds: 5),
      );
      expect(lockExitCode, 0);

      await operation.timeout(const Duration(seconds: 5));
      expect(completed, isTrue);
    });
  });
}
