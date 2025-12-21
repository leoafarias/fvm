import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Config command:', () {
    late TestCommandRunner runner;
    late LocalAppConfig originalConfig;

    setUp(() {
      runner = TestFactory.commandRunner();
      originalConfig = LocalAppConfig.read();
    });

    tearDown(() {
      originalConfig.save();
    });

    test('fvm config --no-update-check persists disableUpdateCheck', () async {
      final exitCode = await runner.runOrThrow([
        'fvm',
        'config',
        '--no-update-check',
      ]);

      expect(exitCode, ExitCode.success.code);

      final updatedConfig = LocalAppConfig.read();
      expect(updatedConfig.disableUpdateCheck, isTrue);
    });

    test('fvm config --update-check sets disableUpdateCheck to false',
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

      final updatedConfig = LocalAppConfig.read();
      expect(updatedConfig.disableUpdateCheck, isFalse);
    });
  });
}
