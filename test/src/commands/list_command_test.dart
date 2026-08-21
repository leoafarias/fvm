import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/api/models/json_response.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/project_registry_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  String plainOutput(Logger logger) {
    return logger.outputs.join('\n').replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
  }

  /// Matches the Projects cell, not the explanatory line below the table.
  final unusedCell = matches(RegExp(r'\u2502\s*Unused\s*\u2502'));

  group('fvm list', () {
    test('marks cached versions no known project pins as unused', () async {
      final projectDir = createConfiguredProject(name: 'local');
      final context = TestFactory.fastContext(
        workingDirectoryOverride: projectDir.path,
      );
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('beta'));
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(projectDir),
          );
      expect(File(context.projectsRegistryPath).existsSync(), isTrue);
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'list']);

      expect(exitCode, ExitCode.success.code);
      final output = plainOutput(context.get<Logger>());
      expect(output, unusedCell);
      expect(output, contains('no project known to FVM pins that SDK'));
    });

    test('marks a forked channel-qualified SDK as local and in use', () async {
      final projectDir = createConfiguredProject(
        name: 'forked',
        flutter: 'myfork/3.10.0@beta',
      );
      final context = TestFactory.fastContext(
        workingDirectoryOverride: projectDir.path,
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('myfork/3.10.0@beta'),
      );
      final runner = TestFactory.fastCommandRunner(context: context);

      expect(await runner.run(['fvm', 'list']), ExitCode.success.code);

      final output = plainOutput(context.get<Logger>());
      expect(
        output,
        matches(
          RegExp(
            r'\u2502\s*myfork/3\.10\.0\s*\u2502[^\n]*'
            r'\u2502\s*\u25cf\s*\u2502\s*1\s*\u2502',
          ),
        ),
      );
    });

    test('does not call the global version unused', () async {
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      final cache = context.get<CacheService>();
      cache.setGlobal(cache.getVersion(FlutterVersion.parse('stable'))!);
      final runner = TestFactory.fastCommandRunner(context: context);

      expect(await runner.run(['fvm', 'list']), ExitCode.success.code);
      expect(plainOutput(context.get<Logger>()), isNot(unusedCell));
    });

    test('still lists versions when the registry is malformed', () async {
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'list']);

      expect(exitCode, ExitCode.success.code);
      expect(
        File(context.projectsRegistryPath).readAsStringSync(),
        'not-json',
      );
      final output = plainOutput(context.get<Logger>());
      expect(output, contains(context.projectsRegistryPath));
      expect(output, isNot(unusedCell));
    });
  });

  group('fvm api list', () {
    test('reports recorded projects and unreferenced versions', () async {
      final projectDir = createConfiguredProject(name: 'api_app');
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('stable'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(projectDir),
          );
      final runner = TestFactory.fastCommandRunner(context: context);

      final printed = await runnerZoned(runner, [
        'fvm',
        'api',
        'list',
        '--compress',
      ]);

      final response = GetCacheVersionsResponse.fromJson(printed.join());
      expect(response.projects, [projectDir.resolveSymbolicLinksSync()]);
      expect(response.unreferencedVersions, ['3.10.0']);
    });

    test('fails on a malformed registry without rewriting it', () async {
      final context = TestFactory.fastContext();
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'api', 'list']);

      expect(exitCode, isNot(ExitCode.success.code));
      expect(
        File(context.projectsRegistryPath).readAsStringSync(),
        'not-json',
      );
    });

    test('returns empty arrays when nothing is recorded', () async {
      final context = TestFactory.fastContext();
      final runner = TestFactory.fastCommandRunner(context: context);

      final printed = await runnerZoned(runner, [
        'fvm',
        'api',
        'list',
        '--compress',
      ]);

      final decoded = jsonDecode(printed.join()) as Map<String, dynamic>;
      expect(decoded['projects'], isEmpty);
      expect(decoded['unreferencedVersions'], isEmpty);
    });
  });
}
