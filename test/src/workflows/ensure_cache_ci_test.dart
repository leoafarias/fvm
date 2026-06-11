import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../testing_utils.dart';

class _UpdateFailingGitService extends GitService {
  _UpdateFailingGitService(super.context);

  @override
  Future<void> updateLocalMirror() async {
    throw Exception('forced mirror update failure');
  }
}

void main() {
  late TempDirectoryTracker tempDirs;

  setUp(() {
    tempDirs = TempDirectoryTracker();
  });

  tearDown(() {
    tempDirs.cleanUp();
  });

  group('EnsureCache CI/CD Behavior', () {
    test(
      'version mismatch in CI mode auto-selects safe default',
      () async {
        final context = TestFactory.fastContext(
          environmentOverrides: {'CI': 'true'},
        );
        final flutterService =
            context.get<FlutterService>() as FakeFlutterService;

        final version = FlutterVersion.parse('3.10.0');
        final cacheService = context.get<CacheService>();
        final ensureCache = EnsureCacheWorkflow(context);

        FakeFlutterSdkFixture.install(
          context,
          version,
          state: FakeFlutterSdkState.versionMismatch,
          mismatchCachedVersion: '3.10.5',
        );

        final mismatchedVersion = cacheService.getVersion(version);
        expect(mismatchedVersion, isNotNull);
        expect(
          await cacheService.verifyCacheIntegrity(mismatchedVersion!),
          equals(CacheIntegrity.versionMismatch),
        );

        final installCountBefore = flutterService.installedVersions.length;
        final result = await ensureCache(version);

        expect(result, isNotNull);
        expect(result.name, equals('3.10.0'));
        expect(
          flutterService.installedVersions.length,
          greaterThan(installCountBefore),
        );
        expect(flutterService.installedVersions.last.name, equals('3.10.0'));
      },
    );

    test(
      '--fvm-skip-input flag handles version mismatch gracefully',
      () async {
        final context = TestFactory.fastContext(
          skipInput: true,
        );
        final flutterService =
            context.get<FlutterService>() as FakeFlutterService;

        final version = FlutterVersion.parse('3.10.0');
        final cacheService = context.get<CacheService>();
        final ensureCache = EnsureCacheWorkflow(context);

        FakeFlutterSdkFixture.install(
          context,
          version,
          state: FakeFlutterSdkState.versionMismatch,
          mismatchCachedVersion: '3.10.5',
        );

        final mismatchedVersion = cacheService.getVersion(version);
        expect(
          await cacheService.verifyCacheIntegrity(mismatchedVersion!),
          equals(CacheIntegrity.versionMismatch),
        );

        final installCountBefore = flutterService.installedVersions.length;
        final result = await ensureCache(version);

        expect(result, isNotNull);
        expect(result.name, equals('3.10.0'));
        expect(
          flutterService.installedVersions.length,
          greaterThan(installCountBefore),
        );
      },
    );

    test(
      'GitHub Actions environment handles version mismatch',
      () async {
        final context = TestFactory.fastContext(
          environmentOverrides: {'GITHUB_ACTIONS': 'true', 'CI': 'true'},
        );
        final flutterService =
            context.get<FlutterService>() as FakeFlutterService;

        final version = FlutterVersion.parse('3.10.0');
        final cacheService = context.get<CacheService>();
        final ensureCache = EnsureCacheWorkflow(context);

        FakeFlutterSdkFixture.install(
          context,
          version,
          state: FakeFlutterSdkState.versionMismatch,
          mismatchCachedVersion: '3.10.5',
        );

        final mismatchedVersion = cacheService.getVersion(version);
        expect(
          await cacheService.verifyCacheIntegrity(mismatchedVersion!),
          equals(CacheIntegrity.versionMismatch),
        );

        final installCountBefore = flutterService.installedVersions.length;
        final result = await ensureCache(version);

        expect(result, isNotNull);
        expect(
          flutterService.installedVersions.length,
          greaterThan(installCountBefore),
        );
      },
    );

    test(
      'CI environment variables properly detected from multiple sources',
      () {
        final ciVariables = [
          'CI',
          'TRAVIS',
          'CIRCLECI',
          'GITHUB_ACTIONS',
          'GITLAB_CI',
          'JENKINS_URL',
          'BAMBOO_BUILD_NUMBER',
          'TEAMCITY_VERSION',
          'TF_BUILD',
        ];

        for (final ciVar in ciVariables) {
          final context = TestFactory.context(
            environmentOverrides: {ciVar: 'true'},
          );

          expect(
            context.isCI,
            isTrue,
            reason: 'Failed CI detection for $ciVar',
          );
          expect(
            context.skipInput,
            isTrue,
            reason: 'Failed skipInput for $ciVar',
          );
        }

        final multiCiContext = TestFactory.context(
          environmentOverrides: {'CI': 'true', 'GITHUB_ACTIONS': 'true'},
        );

        expect(multiCiContext.isCI, isTrue);
        expect(multiCiContext.skipInput, isTrue);
      },
    );
  });

  group('EnsureCache useArchive propagation', () {
    test('useArchive is preserved through corrupted cache reinstall', () async {
      final context = TestFactory.context(
        debugLabel: 'archive-propagation-test',
      );
      final runner = TestCommandRunner(context);
      final flutterService =
          context.get<FlutterService>() as MockFlutterService;

      // First install using --archive
      await runner.run(['fvm', 'install', 'stable', '--archive', '--no-setup']);

      // Corrupt the cache by removing the flutter executable
      final cacheService = context.get<CacheService>();
      final version = FlutterVersion.parse('stable');
      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);

      final execName = Platform.isWindows ? 'flutter.bat' : 'flutter';
      final flutterBin =
          File(path.join(cacheVersion!.directory, 'bin', execName));
      if (flutterBin.existsSync()) {
        flutterBin.deleteSync();
      }

      // Reset markers before triggering reinstall
      flutterService
        ..lastUseArchive = null
        ..lastInstallVersion = null;

      final ensureCache = EnsureCacheWorkflow(context);
      final result = await ensureCache(version, useArchive: true);

      expect(result, isNotNull);
      expect(flutterService.lastUseArchive, isTrue);
      expect(flutterService.lastInstallVersion?.name, 'stable');
    });

    test('useArchive is preserved through version mismatch reinstall',
        () async {
      final context = TestFactory.context(
        debugLabel: 'archive-version-mismatch-test',
        environmentOverrides: {'CI': 'true'}, // auto-select reinstall
      );
      final runner = TestCommandRunner(context);
      final flutterService =
          context.get<FlutterService>() as MockFlutterService;

      // First install using --archive
      await runner.run(['fvm', 'install', '3.10.0', '--archive', '--no-setup']);

      // Create version mismatch by modifying SDK version file
      final version = FlutterVersion.parse('3.10.0');
      final cacheService = context.get<CacheService>();
      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);
      File(path.join(cacheVersion!.directory, 'version'))
          .writeAsStringSync('3.10.5');

      // Reset markers before triggering reinstall
      flutterService
        ..lastUseArchive = null
        ..lastInstallVersion = null;

      final ensureCache = EnsureCacheWorkflow(context);
      final result = await ensureCache(version, useArchive: true);

      expect(result, isNotNull);
      expect(result.name, equals('3.10.0'));
      expect(flutterService.lastUseArchive, isTrue);
    });

    test('useArchive flag is forwarded in workflow call signature', () async {
      final context = TestFactory.context();
      final ensureCache = EnsureCacheWorkflow(context);

      // This test verifies that the workflow accepts useArchive parameter
      // The actual propagation through _handleNonExecutable and
      // _handleVersionMismatch is tested via integration
      final version = FlutterVersion.parse('stable');

      // Call with useArchive=true - should not throw
      final result = await ensureCache(
        version,
        shouldInstall: true,
        useArchive: true,
      );

      expect(result, isNotNull);

      // Verify the mock captured useArchive
      final flutterService =
          context.get<FlutterService>() as MockFlutterService;
      expect(flutterService.lastUseArchive, isTrue);
    });
  });

  group('EnsureCache archive prechecks', () {
    test('archive installs skip git URL validation', () async {
      final context = TestFactory.context(
        debugLabel: 'archive-invalid-git-url',
        flutterUrl: 'not a git url',
      );
      final ensureCache = EnsureCacheWorkflow(context);
      final flutterService =
          context.get<FlutterService>() as MockFlutterService;

      final result = await ensureCache(
        FlutterVersion.parse('stable'),
        shouldInstall: true,
        useArchive: true,
      );

      expect(result, isNotNull);
      expect(flutterService.lastUseArchive, isTrue);
    });
  });

  group('EnsureCache mirror fallback', () {
    test('uses remote clone when mirror update fails for channel install',
        () async {
      final tempDir = tempDirs.create();
      final remoteDir = await createLocalRemoteRepository(
        root: tempDir,
        name: 'flutter_remote',
        branch: 'stable',
      );
      final remoteUrl = remoteDir.uri.toString();

      final gitCachePath = path.join(tempDir.path, 'cache.git');
      await runGitCommand(['clone', '--mirror', remoteUrl, gitCachePath]);
      final staleHead = (await runGitCommand(
        ['rev-parse', 'stable'],
        workingDirectory: gitCachePath,
      ))
          .stdout
          .toString()
          .trim();

      final workDir = Directory(path.join(tempDir.path, 'remote_work'));
      await runGitCommand(['clone', '-b', 'stable', remoteUrl, workDir.path]);
      await runGitCommand(
        ['config', 'user.email', 'tests@fvm.app'],
        workingDirectory: workDir.path,
      );
      await runGitCommand(
        ['config', 'user.name', 'FVM Tests'],
        workingDirectory: workDir.path,
      );
      File(path.join(workDir.path, 'REVISION')).writeAsStringSync('remote-b');
      await runGitCommand(['add', '.'], workingDirectory: workDir.path);
      await runGitCommand(
        ['commit', '-m', 'advance stable'],
        workingDirectory: workDir.path,
      );
      await runGitCommand(
        ['push', 'origin', 'stable'],
        workingDirectory: workDir.path,
      );

      final latestHead = (await runGitCommand(
        ['rev-parse', 'HEAD'],
        workingDirectory: workDir.path,
      ))
          .stdout
          .toString()
          .trim();
      expect(latestHead, isNot(staleHead));

      final context = FvmContext.create(
        isTest: true,
        skipInput: true,
        configOverrides: AppConfig(
          cachePath: path.join(tempDir.path, '.fvm'),
          gitCachePath: gitCachePath,
          flutterUrl: remoteUrl,
          useGitCache: true,
        ),
        generatorsOverride: {
          GitService: _UpdateFailingGitService.new,
        },
      );

      final result = await EnsureCacheWorkflow(context)(
        FlutterVersion.parse('stable'),
        shouldInstall: true,
      );
      final installedHead = (await runGitCommand(
        ['rev-parse', 'HEAD'],
        workingDirectory: result.directory,
      ))
          .stdout
          .toString()
          .trim();

      expect(installedHead, latestHead);
      expect(installedHead, isNot(staleHead));
    });
  });
}
