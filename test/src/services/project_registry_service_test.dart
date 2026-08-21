import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/clock.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  late DateTime currentTime;

  Clock steppingClock() {
    return Clock(() {
      final value = currentTime;
      currentTime = currentTime.add(const Duration(minutes: 15));

      return value;
    });
  }

  FvmContext contextWithClock({
    Map<String, String>? environmentOverrides,
    String? workingDirectoryOverride,
  }) {
    return TestFactory.fastContext(
      environmentOverrides: environmentOverrides,
      workingDirectoryOverride: workingDirectoryOverride,
      generators: {
        ProjectRegistryService: (context) => ProjectRegistryService(
              context,
              clock: steppingClock(),
            ),
      },
    );
  }

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

  setUp(() {
    currentTime = DateTime.utc(2026, 8, 21, 18, 15);
  });

  group('ProjectRegistryService persistence', () {
    test('creates schema version 1 and registers a project', () async {
      final context = contextWithClock();
      final projectDir = configuredProject(name: 'my_app');
      final service = context.get<ProjectRegistryService>();

      await service.upsert(Project.loadFromDirectory(projectDir));

      final file = File(context.projectsRegistryPath);
      expect(file.existsSync(), isTrue);
      expect(file.path, startsWith(context.fvmDir));

      final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['schemaVersion'], 1);
      expect(decoded['projects'], hasLength(1));
      expect(decoded['projects'][0]['name'], 'my_app');
      expect(decoded['projects'][0]['flutter'], 'stable');
      expect(decoded['projects'][0]['flavors'], isEmpty);
      expect(decoded['projects'][0]['firstSeenAt'], '2026-08-21T18:15:00.000Z');
      expect(decoded['projects'][0]['lastSeenAt'], '2026-08-21T18:15:00.000Z');
    });

    test('refresh preserves firstSeenAt and updates snapshot', () async {
      final context = contextWithClock();
      final projectDir = configuredProject(name: 'my_app');
      final service = context.get<ProjectRegistryService>();

      await service.upsert(Project.loadFromDirectory(projectDir));
      createProjectConfig(
        const ProjectConfig(
          flutter: 'beta',
          flavors: {'legacy': '3.10.0'},
        ),
        projectDir,
      );
      createPubspecYaml(projectDir, name: 'renamed_app');
      await service.upsert(Project.loadFromDirectory(projectDir));

      final decoded = jsonDecode(
        File(context.projectsRegistryPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(decoded['projects'], hasLength(1));
      expect(decoded['projects'][0]['name'], 'renamed_app');
      expect(decoded['projects'][0]['flutter'], 'beta');
      expect(decoded['projects'][0]['flavors'], {'legacy': '3.10.0'});
      expect(decoded['projects'][0]['firstSeenAt'], '2026-08-21T18:15:00.000Z');
      expect(decoded['projects'][0]['lastSeenAt'], '2026-08-21T18:30:00.000Z');
    });

    test('resolves symlink aliases to one canonical entry', () async {
      final context = contextWithClock();
      final projectDir = configuredProject(name: 'my_app');
      final aliasParent = createTempDir('alias_parent');
      final alias = Link(p.join(aliasParent.path, 'alias'));
      try {
        alias.createSync(projectDir.path);
      } on FileSystemException {
        return;
      }

      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(Directory(alias.path)));
      await service.upsert(Project.loadFromDirectory(projectDir));

      final document = await service.loadDocument();
      expect(document.projects, hasLength(1));
      expect(
        document.projects.single.path,
        projectDir.resolveSymbolicLinksSync(),
      );
    });

    test('writes projects in canonical path order', () async {
      final context = contextWithClock();
      final zDir = configuredProject(name: 'z_app');
      final aDir = configuredProject(name: 'a_app');
      final service = context.get<ProjectRegistryService>();

      await service.upsert(Project.loadFromDirectory(zDir));
      await service.upsert(Project.loadFromDirectory(aDir));

      final decoded = jsonDecode(
        File(context.projectsRegistryPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      final paths = [
        for (final project in decoded['projects'] as List)
          (project as Map)['path'] as String,
      ];
      expect(paths, [paths.first, paths.last]);
      expect(paths.first.compareTo(paths.last), lessThan(0));
    });

    test('retains both entries during concurrent registration', () async {
      final context = contextWithClock();
      final first = configuredProject(name: 'one');
      final second = configuredProject(name: 'two');
      final service = context.get<ProjectRegistryService>();

      await Future.wait([
        service.upsert(Project.loadFromDirectory(first)),
        service.upsert(Project.loadFromDirectory(second)),
      ]);

      final document = await service.loadDocument();
      expect(document.projects, hasLength(2));
      jsonDecode(File(context.projectsRegistryPath).readAsStringSync());
    });

    test('does not overwrite a newer schema version', () async {
      final context = contextWithClock();
      final file = File(context.projectsRegistryPath)
        ..createSync(recursive: true);
      const newer = '{"schemaVersion":2,"projects":[],"extra":true}';
      file.writeAsStringSync(newer);

      final service = context.get<ProjectRegistryService>();
      expect(
        () => service.upsert(
          Project.loadFromDirectory(configuredProject(name: 'my_app')),
        ),
        throwsA(
          isA<ProjectRegistryException>().having(
            (error) => error.registryPath,
            'registryPath',
            context.projectsRegistryPath,
          ),
        ),
      );
      expect(file.readAsStringSync(), newer);
    });

    test('does not replace malformed JSON', () async {
      final context = contextWithClock();
      final file = File(context.projectsRegistryPath)
        ..createSync(recursive: true);
      file.writeAsStringSync('not-json');

      final service = context.get<ProjectRegistryService>();
      expect(
        () => service.upsert(
          Project.loadFromDirectory(configuredProject(name: 'my_app')),
        ),
        throwsA(isA<ProjectRegistryException>()),
      );
      expect(file.readAsStringSync(), 'not-json');
    });
  });

  group('ProjectRegistryService status', () {
    test('marks a deleted root as missing without mutating the registry',
        () async {
      final context = contextWithClock();
      final projectDir = configuredProject(name: 'gone');
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      final original = File(context.projectsRegistryPath).readAsStringSync();

      projectDir.deleteSync(recursive: true);
      final listed = await service.listProjects();

      expect(listed, hasLength(1));
      expect(listed.single.status, ProjectRegistryStatus.missing);
      expect(listed.single.usesLastKnownSnapshot, isTrue);
      expect(listed.single.referencedVersions, ['stable']);
      expect(File(context.projectsRegistryPath).readAsStringSync(), original);
    });

    test('marks a reachable project without config as unconfigured', () async {
      final context = contextWithClock();
      final projectDir = configuredProject(name: 'plain');
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));

      File(p.join(projectDir.path, kFvmConfigFileName)).deleteSync();
      final legacyConfig = File(
        p.join(projectDir.path, kFvmDirName, kFvmLegacyConfigFileName),
      );
      if (legacyConfig.existsSync()) {
        legacyConfig.deleteSync();
      }

      final listed = await service.listProjects();
      expect(listed.single.status, ProjectRegistryStatus.unconfigured);
      expect(listed.single.referencedVersions, ['stable']);
    });

    test('keeps a readable .fvmrc when pubspec cannot be parsed', () async {
      final context = contextWithClock();
      final projectDir = configuredProject(name: 'broken_pubspec');
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      File(p.join(projectDir.path, 'pubspec.yaml')).writeAsStringSync(
        'not: [yaml',
      );

      final listed = await service.listProjects();
      expect(listed.single.status, ProjectRegistryStatus.active);
      expect(listed.single.flutter, 'stable');
      expect(listed.single.usesLastKnownSnapshot, isFalse);
    });

    test('uses live .fvmrc values for active projects', () async {
      final context = contextWithClock();
      final projectDir = configuredProject(name: 'live');
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      createProjectConfig(const ProjectConfig(flutter: 'beta'), projectDir);

      final listed = await service.listProjects();
      expect(listed.single.status, ProjectRegistryStatus.active);
      expect(listed.single.flutter, 'beta');
      expect(listed.single.usesLastKnownSnapshot, isFalse);
    });

    test('counts only parsed references for invalid configs', () async {
      final context = contextWithClock();
      final projectDir = configuredProject(
        name: 'invalid',
        flutter: 'stable',
        flavors: const {'ok': 'beta'},
      );
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      File(p.join(projectDir.path, kFvmConfigFileName)).writeAsStringSync(
        '{"flutter":"3.10.0@notachannel","flavors":{"ok":"beta"}}',
      );

      final listed = await service.listProjects();
      expect(listed.single.status, ProjectRegistryStatus.invalid);
      expect(listed.single.referencedVersions, ['beta']);
    });
  });

  group('ProjectRegistryService usage', () {
    test('counts distinct flavor and primary versions', () async {
      final context = contextWithClock();
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('stable'),
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('beta'),
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('3.10.0'),
      );

      final projectDir = configuredProject(
        name: 'flavored',
        flutter: 'stable',
        flavors: const {'dev': 'beta', 'legacy': 'beta'},
      );
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));

      final usage = await service.calculateUsage();
      final byVersion = {
        for (final item in usage.versionUsage) item.version: item,
      };
      expect(byVersion['stable']!.projectCount, 1);
      expect(byVersion['beta']!.projectCount, 1);
      expect(byVersion['3.10.0']!.projectCount, 0);
      expect(byVersion['3.10.0']!.unreferenced, isTrue);
      expect(usage.unreferencedVersions, ['3.10.0']);
    });

    test('does not mark the global version unreferenced', () async {
      final context = contextWithClock();
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('stable'),
      );
      context.get<CacheService>().setGlobal(
            context.get<CacheService>().getVersion(
                  FlutterVersion.parse('stable'),
                )!,
          );

      final usage = await context.get<ProjectRegistryService>().calculateUsage();
      expect(usage.versionUsage.single.global, isTrue);
      expect(usage.versionUsage.single.unreferenced, isFalse);
      expect(usage.unreferencedVersions, isEmpty);
    });

    test('does not count last-known refs from missing projects', () async {
      final context = contextWithClock();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      final projectDir = configuredProject(name: 'gone_usage');
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));
      projectDir.deleteSync(recursive: true);

      final usage = await service.calculateUsage();
      expect(usage.projects.single.referencedVersions, ['stable']);
      expect(usage.versionUsage.single.projectCount, 0);
      expect(usage.versionUsage.single.unreferenced, isTrue);
    });

    test('can ignore registry errors when calculating usage', () async {
      final context = contextWithClock();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');
      final service = context.get<ProjectRegistryService>();

      await expectLater(
        service.calculateUsage(),
        throwsA(isA<ProjectRegistryException>()),
      );

      final usage = await service.calculateUsage(ignoreRegistryErrors: true);
      expect(usage.projects, isEmpty);
      expect(usage.versionUsage.single.unreferenced, isFalse);
      expect(usage.unreferencedVersions, isEmpty);
      expect(File(context.projectsRegistryPath).readAsStringSync(), 'not-json');
      expect(
        context.get<Logger>().outputs.any(
              (line) => line.contains(context.projectsRegistryPath),
            ),
        isTrue,
      );
    });

    test('includes an unregistered current project only when requested',
        () async {
      final projectDir = configuredProject(name: 'transient');
      final context = contextWithClock(
        workingDirectoryOverride: projectDir.path,
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('stable'),
      );
      final project = Project.loadFromDirectory(projectDir);
      final service = context.get<ProjectRegistryService>();

      final withoutTransient = await service.calculateUsage();
      expect(withoutTransient.versionUsage.single.projectCount, 0);

      final withTransient = await service.calculateUsage(
        includeTransient: project,
      );
      expect(withTransient.versionUsage.single.projectCount, 1);
      expect(File(context.projectsRegistryPath).existsSync(), isFalse);
    });

    test('keeps fork and channel-qualified versions distinct', () async {
      final context = contextWithClock();
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('3.10.0'),
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('3.10.0@beta'),
      );

      final projectDir = configuredProject(
        name: 'qualified',
        flutter: '3.10.0@beta',
      );
      final service = context.get<ProjectRegistryService>();
      await service.upsert(Project.loadFromDirectory(projectDir));

      final usage = await service.calculateUsage();
      final byVersion = {
        for (final item in usage.versionUsage) item.version: item,
      };
      expect(byVersion['3.10.0']!.projectCount, 0);
      expect(byVersion['3.10.0@beta']!.projectCount, 1);
    });
  });

  group('automatic tracking', () {
    test('skips registration when context.isCI is true', () async {
      final projectDir = configuredProject(name: 'ci_app');
      final context = contextWithClock(
        environmentOverrides: const {'CI': 'true'},
        workingDirectoryOverride: projectDir.path,
      );
      final service = context.get<ProjectRegistryService>();

      await service.trackAutomatically(Project.loadFromDirectory(projectDir));

      expect(File(context.projectsRegistryPath).existsSync(), isFalse);
    });

    test('warns and leaves a malformed registry unchanged', () async {
      final context = contextWithClock();
      final file = File(context.projectsRegistryPath)
        ..createSync(recursive: true);
      file.writeAsStringSync('not-json');

      await context.get<ProjectRegistryService>().trackAutomatically(
            Project.loadFromDirectory(configuredProject(name: 'warn')),
          );

      expect(file.readAsStringSync(), 'not-json');
      expect(
        context.get<Logger>().outputs.any(
              (line) => line.contains(context.projectsRegistryPath),
            ),
        isTrue,
      );
    });
  });

  group('command tracking', () {
    test('fvm use registers the project root', () async {
      final projectDir = configuredProject(name: 'used');
      final context = contextWithClock(
        workingDirectoryOverride: projectDir.path,
      );
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
        '--skip-pub-get',
      ]);

      expect(exitCode, ExitCode.success.code);
      final document =
          await context.get<ProjectRegistryService>().loadDocument();
      expect(document.projects, hasLength(1));
      expect(document.projects.single.flutter, 'stable');
    });

    test('nested directory use refreshes one ancestor entry', () async {
      final projectDir = configuredProject(name: 'nested');
      final nested = Directory(p.join(projectDir.path, 'lib'))
        ..createSync();
      final context = contextWithClock(workingDirectoryOverride: nested.path);
      final runner = TestFactory.fastCommandRunner(context: context);

      await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
        '--skip-pub-get',
      ]);
      await runner.run([
        'fvm',
        'use',
        'beta',
        '--force',
        '--skip-setup',
        '--skip-pub-get',
      ]);

      final document =
          await context.get<ProjectRegistryService>().loadDocument();
      expect(document.projects, hasLength(1));
      expect(
        document.projects.single.path,
        projectDir.resolveSymbolicLinksSync(),
      );
      expect(document.projects.single.flutter, 'beta');
    });

    test('use --flavor records the complete flavor map', () async {
      final projectDir = configuredProject(
        name: 'flavors',
        flutter: 'stable',
        flavors: const {'legacy': '3.10.0'},
      );
      final context = contextWithClock(
        workingDirectoryOverride: projectDir.path,
      );
      final runner = TestFactory.fastCommandRunner(context: context);

      await runner.run([
        'fvm',
        'use',
        'beta',
        '--flavor',
        'preview',
        '--force',
        '--skip-setup',
        '--skip-pub-get',
      ]);

      final document =
          await context.get<ProjectRegistryService>().loadDocument();
      expect(document.projects.single.flutter, 'beta');
      expect(document.projects.single.flavors, {
        'legacy': '3.10.0',
        'preview': 'beta',
      });
    });

    test('install without a version tracks through use exactly once', () async {
      final projectDir = configuredProject(name: 'installed');
      final context = contextWithClock(
        workingDirectoryOverride: projectDir.path,
      );
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'install',
        '--no-setup',
        '--skip-pub-get',
      ]);

      expect(exitCode, ExitCode.success.code);
      final document =
          await context.get<ProjectRegistryService>().loadDocument();
      expect(document.projects, hasLength(1));
      expect(
        document.projects.single.firstSeenAt,
        document.projects.single.lastSeenAt,
      );
    });

    test('install <version> records the project pin, not the argument',
        () async {
      final projectDir = configuredProject(name: 'pinned', flutter: 'stable');
      final context = contextWithClock(
        workingDirectoryOverride: projectDir.path,
      );
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'install', 'beta', '--no-setup']);

      expect(exitCode, ExitCode.success.code);
      final document =
          await context.get<ProjectRegistryService>().loadDocument();
      expect(document.projects.single.flutter, 'stable');
    });

    test('install <version> outside a configured project creates no entry',
        () async {
      final emptyDir = createTempDir('empty');
      final context = contextWithClock(workingDirectoryOverride: emptyDir.path);
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'install',
        'stable',
        '--no-setup',
      ]);

      expect(exitCode, ExitCode.success.code);
      expect(File(context.projectsRegistryPath).existsSync(), isFalse);
    });

    test('automatic registry failure does not fail use', () async {
      final projectDir = configuredProject(name: 'resilient');
      final context = contextWithClock(
        workingDirectoryOverride: projectDir.path,
      );
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
        '--skip-pub-get',
      ]);

      expect(exitCode, ExitCode.success.code);
      expect(File(p.join(projectDir.path, kFvmConfigFileName)).existsSync(), isTrue);
    });
  });
}
