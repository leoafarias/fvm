import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/run_configured_flutter.workflow.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('Git cache command hot path', () {
    test('installed SDK skips shared git cache maintenance', () async {
      final context = TestFactory.fastContext();
      final version = FlutterVersion.parse('3.10.0');
      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.installedSetup,
      );

      final gitService = context.get<GitService>() as FakeGitService;
      final result = await EnsureCacheWorkflow(context).call(
        version,
        maintainGitCache: false,
      );

      expect(result.name, version.name);
      expect(gitService.ensureBareCacheCalls, 0);
      expect(gitService.updateLocalMirrorCalls, 0);
    });

    test('cache miss still prepares the git cache before install', () async {
      final context = TestFactory.fastContext();
      final version = FlutterVersion.parse('3.10.0');
      final gitService = context.get<GitService>() as FakeGitService;
      final flutterService =
          context.get<FlutterService>() as FakeFlutterService;

      final result = await EnsureCacheWorkflow(context).call(
        version,
        shouldInstall: true,
        maintainGitCache: false,
      );

      expect(result.name, version.name);
      expect(gitService.ensureBareCacheCalls, 1);
      expect(gitService.updateLocalMirrorCalls, 1);
      expect(flutterService.installUseGitCacheValues, equals([true]));
    });

    test('flutter and dart proxy commands do not maintain shared cache',
        () async {
      final context = TestFactory.fastContext();
      final version = FlutterVersion.parse('3.10.0');
      final cachedVersion = FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.installedSetup,
      );
      context.get<CacheService>().setGlobal(cachedVersion);

      final gitService = context.get<GitService>() as FakeGitService;
      final flutterService =
          context.get<FlutterService>() as FakeFlutterService;
      final workflow = RunConfiguredFlutterWorkflow(context);

      final flutterResult = await workflow.call(
        'flutter',
        args: ['--version'],
      );
      final dartResult = await workflow.call(
        'dart',
        args: ['--version'],
      );

      expect(flutterResult.exitCode, 0);
      expect(dartResult.exitCode, 0);
      expect(gitService.ensureBareCacheCalls, 0);
      expect(gitService.updateLocalMirrorCalls, 0);
      expect(
        flutterService.runCalls.map((call) => call.cmd),
        equals(['flutter', 'dart']),
      );
    });
  });
}
