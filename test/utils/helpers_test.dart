import 'package:test/test.dart';
import 'package:fvm/utils/helpers.dart';

void main() {
  test('Is Valid Flutter Version', () async {
    expect(await coerceValidFlutterVersion('1.8.0'), 'v1.8.0');
    expect(await coerceValidFlutterVersion('v1.8.0'), 'v1.8.0');

    expect(await coerceValidFlutterVersion('1.9.6'), 'v1.9.6');
    expect(await coerceValidFlutterVersion('v1.9.6'), 'v1.9.6');

    expect(await coerceValidFlutterVersion('1.10.5'), 'v1.10.5');
    expect(await coerceValidFlutterVersion('v1.10.5'), 'v1.10.5');

    expect(await coerceValidFlutterVersion('1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');
    expect(await coerceValidFlutterVersion('v1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');

    expect(await coerceValidFlutterVersion('1.17.0-dev.3.1'), '1.17.0-dev.3.1');
  });

  test('Not Valid Flutter Version', () async {
    expect(coerceValidFlutterVersion('1.8.0.2'), throws);
    expect(coerceValidFlutterVersion('v1.17.0-dev.3.1'), throws);
  });
}
