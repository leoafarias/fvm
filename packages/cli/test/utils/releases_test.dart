import 'package:fvm/src/runner.dart';

@Timeout(Duration(minutes: 5))
import 'package:test/test.dart';

void main() {
  test('Can run releases', () async {
    try {
      await fvmRunner(['releases']);

      expect(true, true);
    } on Exception {
      rethrow;
    }
  });
}
