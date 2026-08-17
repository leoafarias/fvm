import 'package:noir/noir.dart';
import 'package:test/test.dart';

void main() {
  test('published Noir mounts and disposes through its public API', () {
    final app = runTuiApp(
      const Text('fvm-ready'),
      width: 40,
      height: 10,
      headless: true,
    );

    expect(app.isHeadless, isTrue);
    app.dispose();
    app.dispose();
  });
}
