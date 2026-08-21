import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/project_registry_service.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  List<String> registeredPaths(FvmContext context) {
    final decoded =
        jsonDecode(File(context.projectsRegistryPath).readAsStringSync())
            as Map<String, dynamic>;

    return (decoded['projects'] as List).cast<String>();
  }

  group('track', () {
    test('creates schema version 1 with the canonical project root', () {
      final context = TestFactory.fastContext();
      final projectDir = createConfiguredProject(name: 'my_app');

      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(projectDir),
          );

      final decoded =
          jsonDecode(File(context.projectsRegistryPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(decoded['schemaVersion'], 1);
      expect(decoded['projects'], [projectDir.resolveSymbolicLinksSync()]);
    });

    test('records a project reached through a symlink only once', () {
      final context = TestFactory.fastContext();
      final projectDir = createConfiguredProject(name: 'my_app');
      final alias = Link(p.join(createTempDir('alias_parent').path, 'alias'));
      try {
        alias.createSync(projectDir.path);
      } on FileSystemException {
        return;
      }

      final service = context.get<ProjectRegistryService>();
      service.track(Project.loadFromDirectory(Directory(alias.path)));
      service.track(Project.loadFromDirectory(projectDir));

      expect(registeredPaths(context), [projectDir.resolveSymbolicLinksSync()]);
    });

    test('skips tracking in CI', () {
      final projectDir = createConfiguredProject(name: 'ci_app');
      final context = TestFactory.fastContext(
        environmentOverrides: const {'CI': 'true'},
      );

      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(projectDir),
          );

      expect(File(context.projectsRegistryPath).existsSync(), isFalse);
    });

    test('test contexts do not inherit CI from the host environment', () {
      expect(TestFactory.fastContext().isCI, isFalse);
    });

    test('leaves a registry it cannot parse untouched, and warns', () {
      final context = TestFactory.fastContext();
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');

      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(createConfiguredProject(name: 'warn')),
          );

      expect(
        File(context.projectsRegistryPath).readAsStringSync(),
        'not-json',
      );
      expect(
        context.get<Logger>().outputs.any(
              (line) => line.contains(context.projectsRegistryPath),
            ),
        isTrue,
      );
    });
  });

  group('calculateUsage', () {
    test('maps flutter and flavor pins to the projects that use them', () {
      final context = TestFactory.fastContext();
      final projectDir = createConfiguredProject(
        name: 'flavored',
        flutter: 'stable',
        flavors: const {'dev': 'beta', 'legacy': 'beta'},
      );
      final service = context.get<ProjectRegistryService>();
      service.track(Project.loadFromDirectory(projectDir));

      final usage = service.calculateUsage();

      expect(usage.countFor('stable'), 1);
      expect(usage.countFor('beta'), 1);
      expect(usage.countFor('3.10.0'), 0);
      expect(usage.projectPaths, [projectDir.resolveSymbolicLinksSync()]);
    });

    test('reads live config instead of the recorded snapshot', () {
      final context = TestFactory.fastContext();
      final projectDir = createConfiguredProject(name: 'live');
      final service = context.get<ProjectRegistryService>();
      service.track(Project.loadFromDirectory(projectDir));

      createProjectConfig(const ProjectConfig(flutter: 'beta'), projectDir);

      final usage = service.calculateUsage();
      expect(usage.countFor('stable'), 0);
      expect(usage.countFor('beta'), 1);
    });

    test('skips deleted and unconfigured projects without pruning them', () {
      final context = TestFactory.fastContext();
      final deleted = createConfiguredProject(name: 'gone');
      final unconfigured = createConfiguredProject(name: 'plain');
      final service = context.get<ProjectRegistryService>();
      service.track(Project.loadFromDirectory(deleted));
      service.track(Project.loadFromDirectory(unconfigured));

      deleted.deleteSync(recursive: true);
      File(p.join(unconfigured.path, kFvmConfigFileName)).deleteSync();
      final legacy = File(
        p.join(unconfigured.path, kFvmDirName, kFvmLegacyConfigFileName),
      );
      if (legacy.existsSync()) legacy.deleteSync();

      final usage = service.calculateUsage();
      expect(usage.countFor('stable'), 0);
      expect(usage.projectPaths, isEmpty);
      expect(registeredPaths(context), hasLength(2));
    });

    test('skips a project whose config is valid JSON of the wrong shape', () {
      final context = TestFactory.fastContext();
      final good = createConfiguredProject(name: 'good');
      final broken = createConfiguredProject(name: 'broken');
      final service = context.get<ProjectRegistryService>();
      service.track(Project.loadFromDirectory(good));
      service.track(Project.loadFromDirectory(broken));

      // Throws a TypeError rather than an Exception when decoded.
      File(p.join(broken.path, kFvmConfigFileName)).writeAsStringSync('[]');

      final usage = service.calculateUsage();
      expect(usage.countFor('stable'), 1);
      expect(usage.projectPaths, [good.resolveSymbolicLinksSync()]);
    });

    test('ignores pins that cannot be parsed', () {
      final context = TestFactory.fastContext();
      final projectDir = createConfiguredProject(name: 'invalid');
      final service = context.get<ProjectRegistryService>();
      service.track(Project.loadFromDirectory(projectDir));
      File(p.join(projectDir.path, kFvmConfigFileName)).writeAsStringSync(
        '{"flutter":"3.10.0@notachannel","flavors":{"ok":"beta"}}',
      );

      final usage = service.calculateUsage();
      expect(usage.countFor('beta'), 1);
      expect(usage.projectCountByVersion.keys, ['beta']);
    });

    test('matches a forked channel-qualified pin to its installed SDK',
        () async {
      // A forked `x@channel` pin installs to `<fork>/x`, so matching on
      // FlutterVersion.nameWithAlias would report the SDK in use here unused.
      final context = TestFactory.fastContext();
      final projectDir = createConfiguredProject(
        name: 'forked',
        flutter: 'myfork/3.10.0@beta',
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('myfork/3.10.0@beta'),
      );
      final service = context.get<ProjectRegistryService>()
        ..track(Project.loadFromDirectory(projectDir));

      final usage = service.calculateUsage();
      final installed = await context.get<CacheService>().getAllVersions();

      expect(installed, hasLength(1));
      expect(usage.isUnused(installed.single.nameWithAlias), isFalse);
    });

    test('keeps fork and channel-qualified pins distinct', () {
      final context = TestFactory.fastContext();
      final projectDir = createConfiguredProject(
        name: 'qualified',
        flutter: '3.10.0@beta',
      );
      final service = context.get<ProjectRegistryService>();
      service.track(Project.loadFromDirectory(projectDir));

      final usage = service.calculateUsage();
      expect(usage.countFor('3.10.0@beta'), 1);
      expect(usage.countFor('3.10.0'), 0);
    });

    test('counts an unregistered current project only when passed', () {
      final projectDir = createConfiguredProject(name: 'transient');
      final context = TestFactory.fastContext(
        workingDirectoryOverride: projectDir.path,
      );
      final project = Project.loadFromDirectory(projectDir);
      final service = context.get<ProjectRegistryService>();

      expect(service.calculateUsage().countFor('stable'), 0);
      expect(
        service.calculateUsage(includeCurrent: project).countFor('stable'),
        1,
      );
      expect(File(context.projectsRegistryPath).existsSync(), isFalse);
    });

    test('does not double count an already registered current project', () {
      final projectDir = createConfiguredProject(name: 'registered');
      final context = TestFactory.fastContext(
        workingDirectoryOverride: projectDir.path,
      );
      final project = Project.loadFromDirectory(projectDir);
      final service = context.get<ProjectRegistryService>()..track(project);

      expect(registeredPaths(context), [projectDir.resolveSymbolicLinksSync()]);

      final usage = service.calculateUsage(includeCurrent: project);
      expect(usage.countFor('stable'), 1);
      expect(usage.projectPaths, hasLength(1));
    });

    test('throws when the registry cannot be parsed', () {
      final context = TestFactory.fastContext();
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');

      expect(
        () => context.get<ProjectRegistryService>().calculateUsage(),
        throwsA(
          isA<ProjectRegistryException>().having(
            (error) => error.message,
            'message',
            contains(context.projectsRegistryPath),
          ),
        ),
      );
    });
  });

  group('command tracking', () {
    test('fvm use registers the project root from a nested directory',
        () async {
      final projectDir = createConfiguredProject(name: 'nested');
      final nested = Directory(p.join(projectDir.path, 'lib'))..createSync();
      final context = TestFactory.fastContext(
        workingDirectoryOverride: nested.path,
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
      expect(registeredPaths(context), [projectDir.resolveSymbolicLinksSync()]);
    });

    test('fvm install registers the surrounding project', () async {
      final projectDir = createConfiguredProject(name: 'installed');
      final context = TestFactory.fastContext(
        workingDirectoryOverride: projectDir.path,
      );
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode =
          await runner.run(['fvm', 'install', 'beta', '--no-setup']);

      expect(exitCode, ExitCode.success.code);
      expect(registeredPaths(context), [projectDir.resolveSymbolicLinksSync()]);
    });

    test('fvm install outside a configured project records nothing', () async {
      final context = TestFactory.fastContext(
        workingDirectoryOverride: createTempDir('empty').path,
      );
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode =
          await runner.run(['fvm', 'install', 'stable', '--no-setup']);

      expect(exitCode, ExitCode.success.code);
      expect(File(context.projectsRegistryPath).existsSync(), isFalse);
    });

    test('a malformed registry does not fail fvm use', () async {
      final projectDir = createConfiguredProject(name: 'resilient');
      final context = TestFactory.fastContext(
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
      expect(
        File(p.join(projectDir.path, kFvmConfigFileName)).existsSync(),
        isTrue,
      );
    });
  });
}
