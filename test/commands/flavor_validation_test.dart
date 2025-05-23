import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Flavor name validation:', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('rejects flavor name that is a Flutter channel', () async {
      // Try to use a flavor with the same name as a channel
      var exitCode =
          await runner.run(['fvm', 'use', '3.10.0', '--flavor', 'stable']);
      expect(exitCode, ExitCode.usage.code);

      exitCode = await runner.run(['fvm', 'use', '3.10.0', '--flavor', 'beta']);
      expect(exitCode, ExitCode.usage.code);

      exitCode = await runner.run(['fvm', 'use', '3.10.0', '--flavor', 'dev']);
      expect(exitCode, ExitCode.usage.code);

      exitCode =
          await runner.run(['fvm', 'use', '3.10.0', '--flavor', 'master']);
      expect(exitCode, ExitCode.usage.code);
    });

    test('accepts valid flavor names', () async {
      // Create a temp project to test with (with force flag to avoid project checks)
      expect(
        () => runner.run([
          'fvm',
          'use',
          '3.10.0',
          '--flavor',
          'prod',
          '--force',
          '--skip-setup'
        ]),
        returnsNormally,
      );

      expect(
        () => runner.run([
          'fvm',
          'use',
          '3.10.0',
          '--flavor',
          'staging',
          '--force',
          '--skip-setup'
        ]),
        returnsNormally,
      );

      expect(
        () => runner.run([
          'fvm',
          'use',
          '3.10.0',
          '--flavor',
          'development',
          '--force',
          '--skip-setup'
        ]),
        returnsNormally,
      );
    });

    test('cannot use flavor flag when using flavor name as version', () async {
      // Set up a project with a flavor
      await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'prod',
        '--force',
        '--skip-setup'
      ]);

      // Try to use the flavor name with --flavor option
      final exitCode = await runner.run([
        'fvm',
        'use',
        'prod',
        '--flavor',
        'staging',
        '--force',
        '--skip-setup'
      ]);

      expect(exitCode, ExitCode.usage.code);
    });

    test('validates semver-style flavor names', () async {
      // Semver style versions should be rejected as flavor names
      final exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        '1.0.0',
        '--force',
        '--skip-setup'
      ]);

      expect(exitCode, ExitCode.usage.code);
    });

    test('validates git-hash-style flavor names', () async {
      // Git commit hashes should be rejected as flavor names
      final exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'abcdef1234567890',
        '--force',
        '--skip-setup'
      ]);

      expect(exitCode, ExitCode.usage.code);
    });

    test('rejects flavor names with invalid characters', () async {
      // Flavor names should only contain alphanumeric, underscore, and hyphen characters
      var exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'prod@env',
        '--force',
        '--skip-setup'
      ]);
      expect(exitCode, ExitCode.usage.code);

      exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'prod space',
        '--force',
        '--skip-setup'
      ]);
      expect(exitCode, ExitCode.usage.code);

      exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'prod.env',
        '--force',
        '--skip-setup'
      ]);
      expect(exitCode, ExitCode.usage.code);
    });

    test('rejects flavor names that start with numbers', () async {
      // Flavor names should start with a letter
      final exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        '1prod',
        '--force',
        '--skip-setup'
      ]);

      expect(exitCode, ExitCode.usage.code);
    });

    test('rejects reserved words as flavor names', () async {
      // Certain words shouldn't be used as flavor names
      var exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'flutter',
        '--force',
        '--skip-setup'
      ]);
      expect(exitCode, ExitCode.usage.code);

      exitCode = await runner.run([
        'fvm',
        'use',
        '3.10.0',
        '--flavor',
        'version',
        '--force',
        '--skip-setup'
      ]);
      expect(exitCode, ExitCode.usage.code);
    });

    test('accepts flavor names with underscores and hyphens', () async {
      // Valid flavor names can have underscores and hyphens
      expect(
        () => runner.run([
          'fvm',
          'use',
          '3.10.0',
          '--flavor',
          'prod_env',
          '--force',
          '--skip-setup'
        ]),
        returnsNormally,
      );

      expect(
        () => runner.run([
          'fvm',
          'use',
          '3.10.0',
          '--flavor',
          'staging-env',
          '--force',
          '--skip-setup'
        ]),
        returnsNormally,
      );
    });
  });
}
