import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _FakeProcessService extends ProcessService {
  _FakeProcessService(super.context);

  ProcessException? exception;
  final runs = <_ProcessRun>[];

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
    runs.add(_ProcessRun(command: command, args: List<String>.from(args)));

    if (exception != null) {
      throw exception!;
    }

    return ProcessResult(0, 0, '', '');
  }
}

class _ProcessRun {
  final String command;
  final List<String> args;

  const _ProcessRun({required this.command, required this.args});
}

void main() {
  group('GitService', () {
    late FvmContext context;
    late GitService gitService;
    late _FakeProcessService processService;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fvm_git_service_test_');

      context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, 'cache'),
          gitCachePath: p.join(tempDir.path, 'git_cache'),
          useGitCache: true,
        ),
        generatorsOverride: {
          ProcessService: (ctx) {
            processService = _FakeProcessService(ctx);
            return processService;
          },
        },
      );

      gitService = GitService(context);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('uses --git-dir for bare repositories', () async {
      context.get<ProcessService>();

      final initResult = Process.runSync('git', [
        'init',
        '--bare',
        context.gitCachePath,
      ]);
      expect(
        initResult.exitCode,
        0,
        reason: 'Failed to create bare git cache: ${initResult.stderr}',
      );

      await gitService.updateLocalMirror();

      expect(
        processService.runs.map((run) => run.command),
        everyElement(equals('git')),
      );
      expect(
        processService.runs.map((run) => run.args).toList(),
        equals([
          ['--git-dir', context.gitCachePath, 'remote', 'prune', 'origin'],
          [
            '--git-dir',
            context.gitCachePath,
            'fetch',
            '--all',
            '--tags',
            '--prune',
          ],
        ]),
      );
    });

    test('uses -C and working-tree hygiene for non-bare repositories',
        () async {
      context.get<ProcessService>();

      final initResult = Process.runSync('git', ['init', context.gitCachePath]);
      expect(
        initResult.exitCode,
        0,
        reason: 'Failed to create non-bare git cache: ${initResult.stderr}',
      );

      await gitService.updateLocalMirror();

      expect(
        processService.runs.map((run) => run.command),
        everyElement(equals('git')),
      );
      expect(
        processService.runs.map((run) => run.args).toList(),
        equals([
          ['-C', context.gitCachePath, 'reset', '--hard', 'HEAD'],
          ['-C', context.gitCachePath, 'clean', '-fd'],
          ['-C', context.gitCachePath, 'remote', 'prune', 'origin'],
          ['-C', context.gitCachePath, 'fetch', '--all', '--tags', '--prune'],
          ['-C', context.gitCachePath, 'status', '--porcelain'],
        ]),
      );
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
  });
}
