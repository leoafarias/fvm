@Tags(['git'])
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/run_configured_flutter.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test(
    'configured execution defers legacy cache migration until maintenance',
    () async {
      final tempDir = createTempDir('git_cache_hot_path_real');
      final remoteDir = await createLocalRemoteRepository(
        root: tempDir,
        name: 'flutter_remote',
      );
      final projectDir = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      final version = FlutterVersion.parse('3.10.0');
      createProjectConfig(ProjectConfig(flutter: version.name), projectDir);

      final context = FvmContext.create(
        isTest: true,
        workingDirectoryOverride: projectDir.path,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, 'fvm'),
          gitCachePath: p.join(tempDir.path, 'cache.git'),
          flutterUrl: Uri.file(remoteDir.path).toString(),
          useGitCache: true,
        ),
        generatorsOverride: {
          FlutterService: (context) => FakeFlutterService(context),
        },
      );
      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.installedSetup,
      );
      await runGitCommand(['clone', remoteDir.path, context.gitCachePath]);
      expect(await isBareGitRepository(context.gitCachePath), isFalse);

      final result = await RunConfiguredFlutterWorkflow(context).call(
        'flutter',
        args: ['--version'],
      );

      expect(result.exitCode, 0);
      expect(await isBareGitRepository(context.gitCachePath), isFalse);

      await EnsureCacheWorkflow(context).call(version);

      expect(await isBareGitRepository(context.gitCachePath), isTrue);
    },
  );
}
