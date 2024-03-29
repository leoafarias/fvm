@Timeout(Duration(minutes: 1))
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  groupWithContext('Flutter Releases', () {
    testWithContext('Can check releases', () async {
      final exitCode = await TestCommandRunner().run('fvm releases');

      expect(exitCode, ExitCode.success.code);
    });
  });
}
