import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('FvmCommandRunner --version', () {
    test('prints the version when no command is given', () async {
      final runner = TestFactory.fastCommandRunner();

      expect(await runner.run(['fvm', '--version']), ExitCode.success.code);
      expect(await runner.run(['fvm', '-v']), ExitCode.success.code);
    });

    test('reports an unknown command instead of the version', () async {
      final runner = TestFactory.fastCommandRunner();

      await expectLater(
        () => runner.runOrThrow(['fvm', 'fluter', '--version']),
        throwsA(
          isA<UsageException>().having(
            (error) => error.message,
            'message',
            contains('fluter'),
          ),
        ),
      );
      expect(
        await runner.run(['fvm', 'fluter', '--version']),
        ExitCode.usage.code,
      );
    });
  });
}
