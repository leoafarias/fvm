import 'dart:io';

import 'package:fvm/src/services/process_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('ProcessService git environment scrubbing', () {
    late Directory tempDir;
    late ProcessService processService;

    setUp(() {
      tempDir = createTempDir('fvm_process_service_test');
      processService = ProcessService(TestFactory.context());
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'git commands ignore repository-scoped environment variables',
      () async {
        final repoA = Directory(p.join(tempDir.path, 'repo_a'))
          ..createSync(recursive: true);
        final repoB = Directory(p.join(tempDir.path, 'repo_b'))
          ..createSync(recursive: true);
        await runGitCommand(['init'], workingDirectory: repoA.path);
        await runGitCommand(['init'], workingDirectory: repoB.path);

        // Hooks of linked worktrees export an absolute GIT_DIR, which would
        // redirect the command away from its working directory.
        final result = await processService.run(
          'git',
          args: ['rev-parse', '--absolute-git-dir'],
          workingDirectory: repoA.path,
          environment: {'GIT_DIR': p.join(repoB.path, '.git')},
        );

        final resolvedRepoA = repoA.resolveSymbolicLinksSync();
        expect(
          p.equals(
            (result.stdout as String).trim(),
            p.join(resolvedRepoA, '.git'),
          ),
          isTrue,
          reason: 'GIT_DIR must not redirect git away from workingDirectory',
        );
      },
    );

    test(
      'dart commands ignore repository-scoped environment variables',
      () async {
        // The SDK tools spawn git subprocesses that inherit this environment.
        final script = File(p.join(tempDir.path, 'print_git_dir.dart'))
          ..writeAsStringSync(
            "import 'dart:io';\n"
            "void main() {\n"
            "  stdout.write(Platform.environment['GIT_DIR'] ?? 'unset');\n"
            '}\n',
          );

        final result = await processService.run(
          'dart',
          args: [script.path],
          environment: {'GIT_DIR': 'leaked'},
        );

        expect(result.stdout as String, 'unset');
      },
    );

    test(
      'non-git commands keep caller-provided environment variables',
      () async {
        final result = await processService.run(
          'sh',
          args: ['-c', r'printf %s "$GIT_DIR"'],
          environment: {'GIT_DIR': 'passthrough'},
          runInShell: false,
        );

        expect(result.stdout as String, 'passthrough');
      },
      skip: Platform.isWindows ? 'POSIX shell required' : false,
    );
  });
}
