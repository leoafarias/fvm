@Timeout(Duration(minutes: 5))
import 'package:fvm/src/runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

final fvmRunner = FvmCommandRunner();
void main() {
  test('Can check releases', () async {
    final exitCode = await TestFvmCommandRunner().run('fvm releases');

    expect(exitCode, ExitCode.success.code);
  });
}
