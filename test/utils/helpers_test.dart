import 'package:test/test.dart';
import 'package:fvm/utils/helpers.dart';

void main() {
  test('Is Valid Flutter Version', () async {
    expect(await inferFlutterVersion('1.8.0'), 'v1.8.0');
    expect(await inferFlutterVersion('v1.8.0'), 'v1.8.0');

    expect(await inferFlutterVersion('1.9.6'), 'v1.9.6');
    expect(await inferFlutterVersion('v1.9.6'), 'v1.9.6');

    expect(await inferFlutterVersion('1.10.5'), 'v1.10.5');
    expect(await inferFlutterVersion('v1.10.5'), 'v1.10.5');

    expect(await inferFlutterVersion('1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');
    expect(await inferFlutterVersion('v1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');

    expect(await inferFlutterVersion('1.17.0-dev.3.1'), '1.17.0-dev.3.1');
  });

  test('Not Valid Flutter Version', () async {
    expect(inferFlutterVersion('1.8.0.2'), throwsA(anything));
    expect(inferFlutterVersion('v1.17.0-dev.3.1'), throwsA(anything));
  });
}
