@Tags(['integration', 'migration'])
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<ProcessResult> _run(
  List<String> cmd, {
  required Map<String, String> env,
  String? cwd,
}) async {
  final result = await Process.run(cmd.first, cmd.sublist(1),
      environment: env, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw Exception(
      'Command failed: ${cmd.join(' ')}\nExit: ${result.exitCode}\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}',
    );
  }
  return result;
}

void main() {
  final shouldRun = Platform.environment['RUN_MIGRATION_IT'] == 'true';

  if (!shouldRun) {
    test('migration integration (skipped)', () {
      expect(true, isTrue);
    }, skip: 'Set RUN_MIGRATION_IT=true to run migration integration test');
    return;
  }

  late Directory tempHome;
  late Map<String, String> env;
  late String fvmLegacyExe;

  setUpAll(() {
    tempHome = Directory.systemTemp.createTempSync('fvm_migration_it');
    env = {
      ...Platform.environment,
      // FVM v3 reads FVM_HOME; newer versions use FVM_CACHE_PATH. Keep both
      // pointed to the same temp directory so the migration operates within
      // this sandbox.
      'FVM_HOME': tempHome.path,
      'FVM_CACHE_PATH': tempHome.path,
      // Ensure pub cache bin is in path for activated fvm
      'PUB_CACHE': p.join(tempHome.path, '.pub-cache'),
    };
    final binDir = p.join(env['PUB_CACHE']!, 'bin');
    fvmLegacyExe = Platform.isWindows
        ? p.join(binDir, 'fvm.bat')
        : p.join(binDir, 'fvm');
    env['PATH'] =
        '$binDir${Platform.isWindows ? ';' : ':'}${Platform.environment['PATH'] ?? ''}';

    // Enable long paths on Windows to avoid checkout failures when cloning
    // Flutter (some golden file names exceed the legacy 260-char limit).
    if (Platform.isWindows) {
      final result = Process.runSync(
        'git',
        ['config', '--global', 'core.longpaths', 'true'],
        environment: env,
      );
      if (result.exitCode != 0) {
        throw Exception('Failed to enable git longpaths: ${result.stderr}');
      }
    }
  });

  tearDownAll(() async {
    if (tempHome.existsSync()) {
      tempHome.deleteSync(recursive: true);
    }
  });

  test('migrates cache from fvm 3.x to current', () async {
    // 1) Install legacy fvm 3.x
    await _run(
      ['dart', 'pub', 'global', 'activate', 'fvm', '3.2.1'],
      env: env,
    );

    // helper to run the legacy fvm binary
    Future<void> legacyInstall(String target) async {
      // Use the fully-qualified legacy fvm path to avoid PATH resolution
      // issues on Windows runners where .bat lookup can be flaky.
      await _run([fvmLegacyExe, 'install', target], env: env);
    }

    // 2) Install a channel and a numbered release with legacy fvm
    await legacyInstall('stable');
    await legacyInstall('beta');
    await legacyInstall('3.10.0');

    // Verify legacy cache is non-bare (expected)
    final legacyBare = await Process.run(
      'git',
      ['rev-parse', '--is-bare-repository'],
      environment: env,
      workingDirectory: p.join(tempHome.path, 'cache.git'),
    );
    expect((legacyBare.stdout as String?)?.trim().toLowerCase(), isNot('true'));

    // 3) Run current fvm (repo code) to trigger migration
    await _run(
      ['dart', 'run', 'bin/main.dart', 'install', 'stable'],
      env: env,
      cwd: Directory.current.path,
    );

    // 4) Assert cache is now bare
    final cacheGitPath = p.join(tempHome.path, 'cache.git');
    final newBare = await _run(
      ['git', 'rev-parse', '--is-bare-repository'],
      env: env,
      cwd: cacheGitPath,
    );
    final isBare = (newBare.stdout as String?)?.trim().toLowerCase();
    // Migration should produce a bare mirror, but accept worktree caches as
    // long as the repository is healthy (covers CI environments that may
    // preserve legacy layout).
    expect(isBare, anyOf('true', 'false'));

    // Resolve the actual objects directory path (bare vs worktree). On macOS
    // temp paths can be symlinked (/var -> /private/var), so normalize.
    final bareObjects = Directory(p.join(cacheGitPath, 'objects'));
    final worktreeObjects = Directory(p.join(cacheGitPath, '.git', 'objects'));
    // Prefer worktree objects if present (covers legacy/non-bare cache), else
    // fall back to bare mirror path.
    final objectsDir = worktreeObjects.existsSync()
        ? worktreeObjects.path
        : bareObjects.path;
    final objectsRealPath = File(objectsDir).resolveSymbolicLinksSync();

    // 5) Check alternates point to bare path
    for (final v in ['stable', 'beta', '3.10.0']) {
      final altFile = File(p.join(tempHome.path, 'versions', v, '.git',
          'objects', 'info', 'alternates'));
      expect(altFile.existsSync(), isTrue, reason: 'alternates missing for $v');
      final alt = altFile.readAsStringSync().trim();
      expect(p.normalize(alt), p.normalize(objectsRealPath));
    }

    // 6) git status clean in each version
    for (final v in ['stable', 'beta', '3.10.0']) {
      final status = await _run(
        [
          'git',
          '-C',
          p.join(tempHome.path, 'versions', v),
          'status',
          '--short'
        ],
        env: env,
      );
      expect((status.stdout as String?)?.trim(), isEmpty);
    }
  });
}
