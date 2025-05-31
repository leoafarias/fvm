import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Flutter Releases', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('Can check releases', () async {
      final exitCode = await runner.run(['fvm', 'releases']);

      expect(exitCode, ExitCode.success.code);
    });
  });
}
