import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/project_registry_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('fvm cleanup', () {
    test('shows unused SDK names', () async {
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run(['fvm', 'cleanup']);

      expect(exitCode, ExitCode.success.code);
      expect(
        context.get<Logger>().outputs.join('\n'),
        contains('fvm cleanup --remove-unused'),
      );
      expect(
        context.get<CacheService>().getVersion(FlutterVersion.parse('3.10.0')),
        isNotNull,
      );
    });

    test('removes unused SDKs only with explicit confirmation', () async {
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'cleanup',
        '--remove-unused',
        '--yes',
      ]);

      expect(exitCode, ExitCode.success.code);
      expect(
        context.get<CacheService>().getVersion(FlutterVersion.parse('3.10.0')),
        isNull,
      );
    });

    test('shows the project command for a cached patch upgrade', () async {
      final projectDir = createConfiguredProject(
        name: 'cleanup_upgrade',
        flutter: '3.10.0',
      );
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('3.10.0'),
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('3.10.5'),
      );
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(projectDir),
          );
      final runner = TestFactory.fastCommandRunner(context: context);

      expect(await runner.run(['fvm', 'cleanup']), ExitCode.success.code);

      final output = context.get<Logger>().outputs.join('\n');
      expect(output, contains('3.10.0 → 3.10.5'));
      expect(output, contains(projectDir.resolveSymbolicLinksSync()));
      expect(output, contains('fvm use 3.10.5'));
      expect(
        output,
        contains(
          'Newer cached patches recommended as upgrade targets are not',
        ),
      );
    });

    test('does not remove unused SDKs without confirmation', () async {
      final context = TestFactory.fastContext(skipInput: true);
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'cleanup',
        '--remove-unused',
      ]);

      expect(exitCode, ExitCode.success.code);
      expect(
        context.get<CacheService>().getVersion(FlutterVersion.parse('3.10.0')),
        isNotNull,
      );
      expect(
        context.get<Logger>().outputs.join('\n'),
        contains('No SDKs were removed.'),
      );
    });

    test('keeps the recommended patch when removing unused SDKs', () async {
      final projectDir = createConfiguredProject(
        name: 'keep_target_cleanup',
        flutter: '3.10.0',
      );
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.5'));
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(projectDir),
          );
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'cleanup',
        '--remove-unused',
        '--yes',
      ]);

      expect(exitCode, ExitCode.success.code);
      expect(
        context.get<CacheService>().getVersion(FlutterVersion.parse('3.10.0')),
        isNotNull,
      );
      expect(
        context.get<CacheService>().getVersion(FlutterVersion.parse('3.10.5')),
        isNotNull,
      );
    });

    test('does not remove SDKs when the registry is malformed', () async {
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      File(context.projectsRegistryPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not-json');
      final runner = TestFactory.fastCommandRunner(context: context);

      final exitCode = await runner.run([
        'fvm',
        'cleanup',
        '--remove-unused',
        '--yes',
      ]);

      expect(exitCode, isNot(ExitCode.success.code));
      expect(
        context.get<CacheService>().getVersion(FlutterVersion.parse('3.10.0')),
        isNotNull,
      );
    });
  });
}
