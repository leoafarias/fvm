import 'dart:async';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/version.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

Future<String> _inferVersionString(String version) async {
  final valid = await FlutterTools.inferValidVersion(version);
  return valid.name;
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

    expect(await _inferVersionString('f4c74a6ec3'), 'f4c74a6ec3');
  });

  test('Not Valid Flutter Version', () async {
    expect(_inferVersionString('1.8.0.2'), throwsA(anything));
    expect(_inferVersionString('v1.17.0-dev.3.1'), throwsA(anything));
  });

  test('Does CLI version match', () async {
    final yaml = File(
      join(kWorkingDirectory.path, 'pubspec.yaml'),
    ).readAsStringSync();
    final pubspec = loadYamlNode(yaml);
    expect(pubspec.value['version'], packageVersion);
  });

  test('Test update env variables', () async {
    final envVars = Platform.environment;
    // final version = 'stable';
    final envName = 'PATH';
    final fakePath = 'FAKE_PATH';

    final newEnvVar = updateFlutterEnvVariables('FAKE_PATH');

    // expect(newEnvVar[envName], envVars[envName]);
    expect(newEnvVar[envName]!.contains(fakePath), true);
    expect(envVars, isNot(newEnvVar));
  });

  test('Assigns version weights', () async {
    expect('500.0.0', assignVersionWeight('0941968447'));
    expect('500.0.0', assignVersionWeight('ce18d702e9'));
    expect(
      '500.0.0',
      assignVersionWeight('ce18d702e90d3dff9fee53d61a770c94f14f2811'),
    );
    expect('400.0.0', assignVersionWeight('master'));
    expect('300.0.0', assignVersionWeight('stable'));
    expect('200.0.0', assignVersionWeight('beta'));
    expect('100.0.0', assignVersionWeight('dev'));
  });
}
