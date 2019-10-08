import 'package:test/test.dart';
import 'package:fvm/utils/helpers.dart';

void main() {
  test('Is Valid Flutter Version', () async {
    final validVersion = await isValidFlutterVersion('1.8.0') &&
        await isValidFlutterVersion('1.9.6') &&
        await isValidFlutterVersion('1.10.5') &&
        await isValidFlutterVersion('1.9.1+hotfix.4');
    expect(validVersion, true);
  });

  test('Not Valid Flutter Version', () async {
    final validVersion = await isValidFlutterVersion('1.8.0.2');
    expect(validVersion, false);
  });
}
