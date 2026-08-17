import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Config command:', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('fvm config --no-update-check persists disableUpdateCheck', () async {
      final exitCode = await runner.runOrThrow([
        'fvm',
        'config',
        '--no-update-check',
      ]);

      expect(exitCode, ExitCode.success.code);

      final updatedConfig = LocalAppConfig.read(
        path: runner.context.appConfigPath,
      );
      expect(updatedConfig.disableUpdateCheck, isTrue);
    });

    test(
      'fvm config --update-check sets disableUpdateCheck to false',
      () async {
        // First disable update check
        await runner.runOrThrow(['fvm', 'config', '--no-update-check']);

        // Then re-enable it
        final exitCode = await runner.runOrThrow([
          'fvm',
          'config',
          '--update-check',
        ]);

        expect(exitCode, ExitCode.success.code);

        final updatedConfig = LocalAppConfig.read(
          path: runner.context.appConfigPath,
        );
        expect(updatedConfig.disableUpdateCheck, isFalse);
      },
    );

    test('does not overwrite malformed configuration', () async {
      const malformedConfig = '{"cachePath":';
      final configFile = File(runner.context.appConfigPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(malformedConfig);

      final exitCode = await runner.run(['fvm', 'config', '--no-update-check']);

      expect(exitCode, ExitCode.data.code);
      expect(configFile.readAsStringSync(), malformedConfig);
      expect(
        runner.context.get<Logger>().outputs.join('\n'),
        contains('configuration file is invalid'),
      );
    });

    test(
      'preserves unrelated global values when changing flutter URL',
      () async {
        final before = LocalAppConfig(
          useGitCache: false,
          disableUpdateCheck: true,
          forks: {
            const FlutterFork(name: 'team', url: 'https://example.com/team'),
          },
        )..save(path: runner.context.appConfigPath);

        final exitCode = await runner.runOrThrow([
          'fvm',
          'config',
          '--flutter-url',
          'https://example.com/flutter.git',
        ]);
        final after = LocalAppConfig.read(
          path: runner.context.appConfigPath,
          requireValid: true,
        );

        expect(exitCode, ExitCode.success.code);
        expect(before.useGitCache, after.useGitCache);
        expect(before.disableUpdateCheck, after.disableUpdateCheck);
        expect(before.forks, after.forks);
        expect(after.flutterUrl, 'https://example.com/flutter.git');
      },
    );
  });
}
