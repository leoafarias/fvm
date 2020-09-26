import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/utils/pubdev.dart';
import 'package:test/test.dart';

void main() {
  test('Is Valid Flutter Version', () async {
    expect(await inferFlutterVersion('1.8.1'), 'v1.8.1');
    expect(await inferFlutterVersion('v1.8.1'), 'v1.8.1');

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

  test('Check if FVM latest version', () async {
    var isLatest = await checkIfLatestVersion(currentVersion: '1.0.0');
    expect(isLatest, false);

    isLatest = await checkIfLatestVersion(currentVersion: '5.0.0');
    expect(isLatest, true);
  });
}
