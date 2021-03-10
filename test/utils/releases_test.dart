@Timeout(Duration(minutes: 5))
import 'package:fvm/src/runner.dart';
import 'package:test/test.dart';

final fvmRunner = FvmCommandRunner();
void main() {
  test('Can run releases', () async {
    try {
      await fvmRunner.run(['releases']);

      expect(true, true);
    } on Exception {
      rethrow;
    }
  });
}
