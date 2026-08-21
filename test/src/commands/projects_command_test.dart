import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/api/models/json_response.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/clock.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';
import '../workflows/test_logger.dart';

void main() {
  Directory configuredProject({
    required String name,
    String flutter = 'stable',
    Map<String, String>? flavors,
  }) {
    final dir = createTempDir(name);
    createPubspecYaml(dir, name: name);
    createProjectConfig(
      ProjectConfig(flutter: flutter, flavors: flavors),
      dir,
    );

    return dir;
  }

  FvmContext registryContext({
    String? workingDirectoryOverride,
    bool skipInput = false,
    Map<Type, Generator>? generators,
  }) {
    return TestFactory.fastContext(
      workingDirectoryOverride: workingDirectoryOverride,
      skipInput: skipInput,
      generators: {
        ProjectRegistryService: (context) => ProjectRegistryService(
              context,
              clock: Clock(() => DateTime.utc(2026, 8, 21, 18, 15)),
            ),
        ...?generators,
      },
    );
  }

  group('projects command', () {
    test('lists registered projects and empty-registry help', () async {
      final emptyContext = registryContext();
      final emptyRunner = TestFactory.fastCommandRunner(context: emptyContext);
      final emptyCode = await emptyRunner.run(['fvm', 'projects']);
      expect(emptyCode, ExitCode.success.code);
      expect(
        emptyContext.get<Logger>().outputs.any(
              (line) => line.contains(emptyContext.projectsRegistryPath),
            ),
        isTrue,
      );

      final projectDir = configuredProject(
        name: 'listed',
        flavors: const {'beta': 'beta'},
      );
      final context = registryContext(workingDirectoryOverride: projectDir.path);
      await context.get<ProjectRegistryService>().upsert(
            Project.loadFromDirectory(projectDir),
          );
      final runner = TestFactory.fastCommandRunner(context: context);
      final exitCode = await runner.run(['fvm', 'projects', 'list']);

      expect(exitCode, ExitCode.success.code);
      final output = context.get<Logger>().outputs.join('\n');
      expect(output, contains('listed'));
      expect(output, contains('stable'));
      expect(output, contains('beta'));
      expect(output, contains('active'));
      expect(output, contains(projectDir.resolveSymbolicLinksSync()));
    });

    test('add rejects an unconfigured path without modifying it', () async {
      final plain = createTempDir('plain');
      createPubspecYaml(plain, name: 'plain');
      final context = registryContext(workingDirectoryOverride: plain.path);
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'projects', 'add']);

      expect(exitCode, isNot(ExitCode.success.code));
      expect(File(p.join(plain.path, kFvmConfigFileName)).existsSync(), isFalse);
      expect(File(context.projectsRegistryPath).existsSync(), isFalse);
    });

    test('add registers a configured project', () async {
      final projectDir = configuredProject(name: 'added');
      final context = registryContext();
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'projects',
        'add',
        projectDir.path,
      ]);

      expect(exitCode, ExitCode.success.code);
      final document =
          await context.get<ProjectRegistryService>().loadDocument();
      expect(document.projects.single.name, 'added');
    });

    test('remove changes only the registry', () async {
      final projectDir = configuredProject(name: 'removed');
      final context = registryContext();
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'projects',
        'remove',
        projectDir.path,
      ]);

      expect(exitCode, ExitCode.success.code);
      expect((await service.loadDocument()).projects, isEmpty);
      expect(File(p.join(projectDir.path, kFvmConfigFileName)).existsSync(), isTrue);

      final missingCode = await runner.run([
        'fvm',
        'projects',
        'remove',
        projectDir.path,
      ]);
      expect(missingCode, ExitCode.success.code);
    });

    test('prune removes missing entries after confirmation', () async {
      final projectDir = configuredProject(name: 'stale');
      late TestLogger logger;
      final context = registryContext(
        generators: {
          Logger: (context) {
            logger = TestLogger(context)
              ..setConfirmResponse('Remove these registry entries', true);

            return logger;
          },
        },
      );
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      projectDir.deleteSync(recursive: true);

      final runner = TestFactory.fastCommandRunner(context: context);
      final exitCode = await runner.run(['fvm', 'projects', 'prune']);

      expect(exitCode, ExitCode.success.code);
      expect((await service.loadDocument()).projects, isEmpty);
    });

    test('prune without force uses the safe non-interactive default', () async {
      final projectDir = configuredProject(name: 'kept');
      final context = registryContext(skipInput: true);
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      projectDir.deleteSync(recursive: true);

      final runner = TestFactory.fastCommandRunner(context: context);
      final exitCode = await runner.run(['fvm', 'projects', 'prune']);

      expect(exitCode, ExitCode.success.code);
      expect((await service.loadDocument()).projects, hasLength(1));
    });

    test('prune keeps invalid entries', () async {
      final projectDir = configuredProject(name: 'broken_pin');
      final context = registryContext();
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      File(p.join(projectDir.path, kFvmConfigFileName)).writeAsStringSync(
        '{"flutter":"3.10.0@notachannel"}',
      );

      final runner = TestFactory.fastCommandRunner(context: context);
      final exitCode = await runner.run([
        'fvm',
        'projects',
        'prune',
        '--force',
      ]);

      expect(exitCode, ExitCode.success.code);
      expect((await service.loadDocument()).projects, hasLength(1));
      expect(
        (await service.listProjects()).single.status,
        ProjectRegistryStatus.invalid,
      );
    });

    test('explicit commands fail on a newer registry schema', () async {
      final projectDir = configuredProject(name: 'blocked');
      final context = registryContext(workingDirectoryOverride: projectDir.path);
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('{"schemaVersion":2,"projects":[]}');
      final runner = TestFactory.fastCommandRunner(context: context);

      expect(
        await runner.run(['fvm', 'projects', 'list']),
        isNot(ExitCode.success.code),
      );
      final exitCode = await runner.run(['fvm', 'projects', 'add']);
      expect(exitCode, isNot(ExitCode.success.code));
      expect(
        jsonDecode(File(context.projectsRegistryPath).readAsStringSync())
            ['schemaVersion'],
        2,
      );
    });
  });

  group('api projects', () {
    test('returns empty arrays for an empty registry', () async {
      final context = registryContext();
      final runner = TestFactory.fastCommandRunner(context: context);
      final printed = await runnerZoned(runner, [
        'fvm',
        'api',
        'projects',
        '--compress',
      ]);

      final decoded = jsonDecode(printed.join()) as Map<String, dynamic>;
      expect(decoded['projects'], isEmpty);
      expect(decoded['versionUsage'], isEmpty);
      expect(decoded['unreferencedVersions'], isEmpty);
      expect(decoded['missingVersions'], isEmpty);
    });

    test('fails on a malformed registry without rewriting it', () async {
      final context = registryContext();
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'api', 'projects']);
      expect(exitCode, isNot(ExitCode.success.code));
      expect(File(context.projectsRegistryPath).readAsStringSync(), 'not-json');
      expect(
        context.get<Logger>().outputs.join('\n'),
        contains(context.projectsRegistryPath),
      );
    });

    test('returns usage metadata and supports pretty JSON', () async {
      final projectDir = configuredProject(
        name: 'api_app',
        flutter: 'stable',
        flavors: const {'preview': 'beta'},
      );
      final context = registryContext(
        workingDirectoryOverride: projectDir.path,
      );
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      await context.get<ProjectRegistryService>().upsert(
            Project.loadFromDirectory(projectDir),
          );
      final runner = TestFactory.fastCommandRunner(context: context);

      final compressed = await runnerZoned(runner, [
        'fvm',
        'api',
        'projects',
        '--compress',
      ]);
      final response = GetProjectsResponse.fromJson(compressed.join());
      expect(response.projects, hasLength(1));
      expect(response.projects.single.status, 'active');
      expect(response.projects.single.referencedVersions, ['beta', 'stable']);
      expect(response.unreferencedVersions, ['3.10.0']);
      expect(response.missingVersions, ['beta']);

      final pretty = await runnerZoned(runner, ['fvm', 'api', 'projects']);
      expect(() => jsonDecode(pretty.join()), returnsNormally);
    });
  });

  group('list usage column', () {
    test('still succeeds when the registry is malformed', () async {
      final context = registryContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'list']);
      expect(exitCode, ExitCode.success.code);
      expect(File(context.projectsRegistryPath).readAsStringSync(), 'not-json');
      final output = context.get<Logger>().outputs.join('\n').replaceAll(
            RegExp(r'\x1B\[[0-9;]*m'),
            '',
          );
      expect(output, contains(context.projectsRegistryPath));
      expect(output, isNot(contains(RegExp(r'\d Unreferenced'))));
    });

    test('labels unreferenced versions and includes a transient project',
        () async {
      final projectDir = configuredProject(name: 'local');
      final context = registryContext(
        workingDirectoryOverride: projectDir.path,
      );
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('beta'));
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'list']);
      expect(exitCode, ExitCode.success.code);
      final output = context.get<Logger>().outputs.join('\n');
      expect(output, contains('Unreferenced'));
      expect(
        output,
        contains(
          'Unreferenced status considers only known, currently reachable projects.',
        ),
      );
    });
  });
}
