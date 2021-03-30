import 'dart:io';

import 'package:fvm/constants.dart';

import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/pubdev.dart';
import 'package:fvm/src/version.dart';
import 'package:path/path.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:test/test.dart';

Future<String> _inferVersionString(String version) async {
  final valid = await FlutterTools.inferVersion(version);
  return valid.version;
}

void main() {
  test('Is Valid Flutter Version', () async {
    expect(await _inferVersionString('1.8.1'), 'v1.8.1');
    expect(await _inferVersionString('v1.8.1'), 'v1.8.1');

    expect(await _inferVersionString('1.9.6'), 'v1.9.6');
    expect(await _inferVersionString('v1.9.6'), 'v1.9.6');

    expect(await _inferVersionString('2.0.2'), '2.0.2');
    expect(await _inferVersionString('v1.10.5'), 'v1.10.5');

    expect(await _inferVersionString('1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');
    expect(await _inferVersionString('v1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');

    expect(await _inferVersionString('1.17.0-dev.3.1'), '1.17.0-dev.3.1');
  });

  test('Not Valid Flutter Version', () async {
    expect(_inferVersionString('1.8.0.2'), throwsA(anything));
    expect(_inferVersionString('v1.17.0-dev.3.1'), throwsA(anything));
  });

  test('Check if FVM latest version', () async {
    var isLatest = await checkIfLatestVersion(currentVersion: '1.0.0');
    expect(isLatest, false);

    isLatest = await checkIfLatestVersion(currentVersion: '5.0.0');
    expect(isLatest, true);
  });

  test('Does CLI version match', () async {
    final pubspec = File(
      join(kWorkingDirectory.path, 'pubspec.yaml'),
    ).readAsStringSync().toPubspecYaml();
    expect(pubspec.version.valueOr(() => null), packageVersion);
  });

  test('Test update env variables', () async {
    final envVars = Platform.environment;
    // final version = 'stable';
    final envName = 'PATH';
    final fakePath = 'FAKE_PATH';

    final newEnvVar = updateFlutterEnvVariables('FAKE_PATH');

    // expect(newEnvVar[envName], envVars[envName]);
    expect(newEnvVar[envName].contains(fakePath), true);
    expect(envVars, isNot(newEnvVar));
  });
}
