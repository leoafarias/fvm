import 'package:test/test.dart';
import 'package:fvm/commands/list.dart';

void main() {
  test('List Command', () async {
    await ListCommand().run();
    expect(true, true);
  });
}
