import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../src/workflows/test_logger.dart';
import '../testing_utils.dart';

void main() {
  group('single optional version operand', () {
    test('surfaces multiple operands as a UsageException', () async {
      final runner = TestFactory.fastCommandRunner();

      expect(
        () => runner.runOrThrow(['fvm', 'install', 'stable', 'beta']),
        throwsA(isA<UsageException>()),
      );
    });

    test('install rejects extra operands without installing either SDK',
        () async {
      final runner = TestFactory.fastCommandRunner();
      final flutter =
          runner.context.get<FlutterService>() as FakeFlutterService;

      final exitCode = await runner.run(['fvm', 'install', 'stable', 'beta']);

      expect(exitCode, ExitCode.usage.code);
      expect(flutter.installedVersions, isEmpty);
      expect(
          await runner.context.get<CacheService>().getAllVersions(), isEmpty);
    });

    test('use rejects extra operands without writing project configuration',
        () async {
      final projectDir = createTempDir('use-extra-operands');
      createPubspecYaml(projectDir);
      final runner = TestFactory.fastCommandRunner(
        context: TestFactory.fastContext(
          workingDirectoryOverride: projectDir.path,
        ),
      );
      final flutter =
          runner.context.get<FlutterService>() as FakeFlutterService;
      final project = runner.context.get<ProjectService>().findAncestor();

      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        'beta',
        '--force',
        '--skip-setup',
      ]);

      expect(exitCode, ExitCode.usage.code);
      expect(flutter.installedVersions, isEmpty);
      expect(File(project.configPath).existsSync(), isFalse);
    });

    test('remove rejects extra operands without removing the first SDK',
        () async {
      final runner = TestFactory.fastCommandRunner();
      final cacheVersion = FakeFlutterSdkFixture.install(
        runner.context,
        FlutterVersion.parse('stable'),
      );

      final exitCode = await runner.run(['fvm', 'remove', 'stable', 'beta']);

      expect(exitCode, ExitCode.usage.code);
      expect(Directory(cacheVersion.directory).existsSync(), isTrue);
    });

    test('global rejects extra operands without creating the global link',
        () async {
      final runner = TestFactory.fastCommandRunner();
      FakeFlutterSdkFixture.install(
        runner.context,
        FlutterVersion.parse('stable'),
      );

      final exitCode = await runner.run(['fvm', 'global', 'stable', 'beta']);

      expect(exitCode, ExitCode.usage.code);
      expect(Link(runner.context.globalCacheLink).existsSync(), isFalse);
    });
  });

  group('operand-free modes', () {
    test('remove --all rejects an operand without clearing the cache',
        () async {
      final context = TestFactory.fastContext(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse('remove all versions', true),
        },
      );
      final runner = TestCommandRunner(context);
      final cacheVersion = FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('stable'),
      );

      final exitCode = await runner.run([
        'fvm',
        'remove',
        '--all',
        'stable',
      ]);

      expect(exitCode, ExitCode.usage.code);
      expect(Directory(cacheVersion.directory).existsSync(), isTrue);
    });

    test('global --unlink rejects an operand without unlinking the SDK',
        () async {
      final runner = TestFactory.fastCommandRunner();
      final cacheService = runner.context.get<CacheService>();
      final cacheVersion = FakeFlutterSdkFixture.install(
        runner.context,
        FlutterVersion.parse('stable'),
      );
      cacheService.setGlobal(cacheVersion);

      final exitCode = await runner.run([
        'fvm',
        'global',
        '--unlink',
        'stable',
      ]);

      expect(exitCode, ExitCode.usage.code);
      expect(Link(runner.context.globalCacheLink).existsSync(), isTrue);
      expect(cacheService.getGlobal()?.name, 'stable');
    });
  });

  group('zero-operand behavior', () {
    test('use keeps selecting an installed SDK interactively', () async {
      final projectDir = createTempDir('use-version-selector');
      createPubspecYaml(projectDir);
      final context = TestFactory.fastContext(
        workingDirectoryOverride: projectDir.path,
        generators: {
          Logger: (context) => TestLogger(context)
            ..setVersionResponse('Select a version', 'stable'),
        },
      );
      final runner = TestCommandRunner(context);
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));

      final exitCode = await runner.run([
        'fvm',
        'use',
        '--force',
        '--skip-setup',
      ]);

      expect(exitCode, ExitCode.success.code);
      expect(
        context.get<ProjectService>().findAncestor().pinnedVersion?.name,
        'stable',
      );
    });

    test('remove keeps selecting an installed SDK interactively', () async {
      final context = TestFactory.fastContext(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setVersionResponse('Select a version', 'stable'),
        },
      );
      final runner = TestCommandRunner(context);
      final cacheVersion = FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('stable'),
      );

      final exitCode = await runner.run(['fvm', 'remove']);

      expect(exitCode, ExitCode.success.code);
      expect(Directory(cacheVersion.directory).existsSync(), isFalse);
    });

    test('global keeps selecting an installed SDK interactively', () async {
      final context = TestFactory.fastContext(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setVersionResponse('Select a version', 'stable'),
        },
      );
      final runner = TestCommandRunner(context);
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));

      final exitCode = await runner.run(['fvm', 'global']);

      expect(exitCode, ExitCode.success.code);
      expect(context.get<CacheService>().getGlobal()?.name, 'stable');
    });
  });
}
