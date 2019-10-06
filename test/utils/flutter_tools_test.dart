import 'package:test/test.dart';
import 'package:fvm/utils/flutter_tools.dart';

void main() {
  test('gitClone', () async {
    await flutterChannelClone('v1.8.4');
    expect(true, true);
  });

  test('flutterSdkInfo', () async {
    await flutterSdkInfo('master');
    expect(true, true);
  });

  test('listSdkVersions', () async {
    await listSdkVersions();
    expect(true, true);
  });

  test('flutterListInstalledSdks', () async {
    await flutterListInstalledSdks();
    expect(true, true);
  });
}
